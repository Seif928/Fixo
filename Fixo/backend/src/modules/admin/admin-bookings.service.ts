import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, Prisma } from '@prisma/client';
import { createHash } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { PushService } from '../communications/push.service';
import {
  professionalCoverageWhere,
  coversServiceArea,
} from '../services/coverage-policy';
import { INTERNAL_FAILED_PIN_EVENT_NOTE } from '../bookings/bookings.service';
import { AdminAccessService, AdminActor } from './admin-access.service';
import type {
  AdminBookingQueryDto,
  AdminCancelBookingDto,
  AdminOfferBookingDto,
} from './admin-bookings.controller';

const cancellable: BookingStatus[] = [
  'DRAFT',
  'PENDING_DISPATCH',
  'OFFERED_TO_PRO',
  'CONFIRMED',
];
const dispatchable: BookingStatus[] = ['PENDING_DISPATCH', 'OFFERED_TO_PRO'];
const paymentSelect = {
  id: true,
  method: true,
  status: true,
  amountEgp: true,
  tipEgp: true,
  paidAt: true,
} as const;
const snapshotSelect = {
  id: true,
  updatedAt: true,
  status: true,
  customerId: true,
  proProfileId: true,
  totalEgp: true,
  cancellationReason: true,
  payment: { select: paymentSelect },
} as const;
type Snapshot = Prisma.BookingGetPayload<{ select: typeof snapshotSelect }>;
function version(b: Snapshot) {
  return createHash('sha256')
    .update(
      JSON.stringify([
        b.id,
        b.updatedAt,
        b.status,
        b.proProfileId,
        b.totalEgp,
        b.payment,
      ]),
    )
    .digest('hex');
}
function pendingCash(b: Snapshot) {
  return (
    b.payment?.method === 'CASH_ON_SERVICE' &&
    b.payment.status === 'PENDING' &&
    b.payment.paidAt === null &&
    b.payment.amountEgp === b.totalEgp
  );
}
function unpaid(b: Snapshot) {
  return (b.status === 'DRAFT' && !b.payment) || pendingCash(b);
}

@Injectable()
export class AdminBookingsService {
  constructor(
    private readonly db: PrismaService,
    private readonly access: AdminAccessService,
    private readonly push: PushService,
  ) {}
  async list(query: AdminBookingQueryDto) {
    const where: Prisma.BookingWhereInput = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.search
        ? { orderCode: { contains: query.search, mode: 'insensitive' } }
        : {}),
    };
    const [items, total] = await this.db.$transaction([
      this.db.booking.findMany({
        where,
        skip: (query.page - 1) * 20,
        take: 20,
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        select: {
          id: true,
          orderCode: true,
          status: true,
          scheduledDate: true,
          timeWindow: true,
          totalEgp: true,
          offering: { select: { titleEn: true, titleAr: true } },
          address: {
            select: { zone: { select: { nameEn: true, nameAr: true } } },
          },
        },
      }),
      this.db.booking.count({ where }),
    ]);
    return {
      items,
      meta: {
        page: query.page,
        total,
        totalPages: Math.max(1, Math.ceil(total / 20)),
      },
    };
  }
  detail(actor: AdminActor, id: string) {
    return this.access.mutate(
      actor,
      false,
      'BOOKING_DETAILS_ACCESSED',
      id,
      async (tx) => {
        const b = await tx.booking.findUnique({
          where: { id },
          select: {
            ...snapshotSelect,
            orderCode: true,
            scheduledDate: true,
            timeWindow: true,
            issueDescription: true,
            baseInspectionEgp: true,
            serviceFeeEgp: true,
            transportFeeEgp: true,
            completedAt: true,
            customer: { select: { fullName: true, phone: true } },
            proProfile: {
              select: {
                id: true,
                user: { select: { fullName: true, phone: true } },
              },
            },
            offering: { select: { titleEn: true, titleAr: true } },
            address: {
              select: {
                label: true,
                buildingLine: true,
                districtLine: true,
                gateNotes: true,
                zone: { select: { nameEn: true, nameAr: true } },
              },
            },
            statusEvents: {
              where: {
                OR: [
                  { note: null },
                  { note: { not: INTERNAL_FAILED_PIN_EVENT_NOTE } },
                ],
              },
              orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
              take: 201,
              select: {
                id: true,
                fromStatus: true,
                toStatus: true,
                note: true,
                createdAt: true,
              },
            },
          },
        });
        if (!b) throw new NotFoundException('Booking was not found.');
        const {
          statusEvents,
          baseInspectionEgp,
          serviceFeeEgp,
          transportFeeEgp,
          totalEgp,
          updatedAt,
          customerId,
          proProfileId,
          ...safe
        } = b;
        return {
          value: {
            ...safe,
            version: version(b),
            pricing: {
              baseInspectionEgp,
              serviceFeeEgp,
              transportFeeEgp,
              totalEgp,
            },
            history: statusEvents.slice(0, 200).reverse(),
            hasOlderHistory: statusEvents.length > 200,
            canCancel: cancellable.includes(b.status) && unpaid(b),
            canOffer:
              dispatchable.includes(b.status) &&
              !proProfileId &&
              pendingCash(b),
          },
          details: { bookingId: id },
        };
      },
    );
  }
  private async locked(tx: Prisma.TransactionClient, id: string) {
    await tx.$queryRaw`SELECT id FROM "Booking" WHERE id = ${id} FOR UPDATE`;
    const b = await tx.booking.findUnique({
      where: { id },
      select: snapshotSelect,
    });
    if (!b) throw new NotFoundException('Booking was not found.');
    return b;
  }
  private current(b: Snapshot, expected: string) {
    if (version(b) !== expected)
      throw new ConflictException({
        code: 'BOOKING_VERSION_CONFLICT',
        message: 'This booking changed. Reload before making a decision.',
      });
  }
  async cancel(actor: AdminActor, id: string, dto: AdminCancelBookingDto) {
    const reason = dto.reason.trim();
    const result = await this.access.mutate(
      actor,
      false,
      'BOOKING_CANCELLED',
      id,
      async (tx) => {
        const b = await this.locked(tx, id);
        if (b.status === 'CANCELLED' && b.cancellationReason === reason)
          return {
            value: {
              changed: false,
              customerId: b.customerId,
              proProfileId: b.proProfileId,
            },
            details: {},
            recordAudit: false,
          };
        this.current(b, dto.version);
        if (!cancellable.includes(b.status) || !unpaid(b))
          throw new ConflictException(
            'Only unpaid pre-service bookings can be cancelled.',
          );
        await tx.booking.update({
          where: { id },
          data: { status: 'CANCELLED', cancellationReason: reason },
        });
        await tx.jobOffer.updateMany({
          where: { bookingId: id, status: 'PENDING' },
          data: { status: 'EXPIRED', respondedAt: new Date() },
        });
        if (b.payment)
          await tx.paymentRecord.update({
            where: { id: b.payment.id },
            data: { status: 'FAILED' },
          });
        await tx.bookingStatusEvent.create({
          data: {
            bookingId: id,
            fromStatus: b.status,
            toStatus: 'CANCELLED',
            actorUserId: actor.userId,
            note: reason,
          },
        });
        return {
          value: {
            changed: true,
            customerId: b.customerId,
            proProfileId: b.proProfileId,
          },
          details: { fromStatus: b.status, toStatus: 'CANCELLED' },
        };
      },
    );
    if (result.changed) {
      const professional = result.proProfileId
        ? await this.db.proProfile.findUnique({
            where: { id: result.proProfileId },
            select: { userId: true },
          })
        : null;
      await this.push.notify(result.customerId, id);
      if (professional) await this.push.notify(professional.userId, id);
    }
    return { status: 'CANCELLED' };
  }
  async candidates(id: string, page: number) {
    const b = await this.db.booking.findUnique({
      where: { id },
      include: { offering: true, address: { include: { zone: true } } },
    });
    if (!b) throw new NotFoundException('Booking was not found.');
    if (!dispatchable.includes(b.status) || b.proProfileId)
      return { items: [], meta: { page, total: 0, totalPages: 1 } };
    const where: Prisma.ProProfileWhereInput = {
      verificationStatus: 'APPROVED',
      isOnline: true,
      userId: { not: b.customerId },
      primaryCategoryId: b.offering.categoryId,
      ...professionalCoverageWhere(b.address.zone),
    };
    const [items, total] = await this.db.$transaction([
      this.db.proProfile.findMany({
        where,
        skip: (page - 1) * 20,
        take: 20,
        orderBy: [{ ratingAvg: 'desc' }, { id: 'asc' }],
        select: {
          id: true,
          dossierCode: true,
          user: { select: { fullName: true } },
        },
      }),
      this.db.proProfile.count({ where }),
    ]);
    return {
      items,
      meta: { page, total, totalPages: Math.max(1, Math.ceil(total / 20)) },
    };
  }
  async offer(actor: AdminActor, id: string, dto: AdminOfferBookingDto) {
    const result = await this.access.mutate(
      actor,
      false,
      'BOOKING_OFFER_SENT',
      id,
      async (tx) => {
        const b = await this.locked(tx, id);
        this.current(b, dto.version);
        if (
          !dispatchable.includes(b.status) ||
          b.proProfileId ||
          !pendingCash(b)
        )
          throw new ConflictException(
            'Booking is no longer eligible for dispatch.',
          );
        const location = await tx.booking.findUniqueOrThrow({
          where: { id },
          select: {
            offering: { select: { categoryId: true } },
            address: { select: { zone: true } },
          },
        });
        // Same order as professional acceptance and automated dispatch: Booking -> ProProfile -> JobOffer.
        await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE id = ${dto.proProfileId} FOR UPDATE`;
        const p = await tx.proProfile.findUnique({
          where: { id: dto.proProfileId },
          include: { primaryZone: true, coverageZones: true },
        });
        if (
          !p ||
          p.verificationStatus !== 'APPROVED' ||
          !p.isOnline ||
          p.userId === b.customerId ||
          p.primaryCategoryId !== location.offering.categoryId ||
          ![...(p.primaryZone ? [p.primaryZone] : []), ...p.coverageZones].some(
            (z) => coversServiceArea(z, location.address.zone),
          )
        )
          throw new ConflictException(
            'Professional is no longer eligible for this service and area.',
          );
        const latest = await tx.jobOffer.findFirst({
          where: { bookingId: id, proProfileId: p.id },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        });
        const now = new Date();
        if (latest?.status === 'PENDING' && latest.expiresAt > now)
          return {
            value: { created: false, userId: p.userId },
            details: {},
            recordAudit: false,
          };
        if (latest && !['PENDING', 'EXPIRED'].includes(latest.status))
          throw new ConflictException(
            'The professional already responded to this booking.',
          );
        if (latest?.status === 'PENDING')
          await tx.jobOffer.update({
            where: { id: latest.id },
            data: { status: 'EXPIRED', respondedAt: now },
          });
        await tx.jobOffer.create({
          data: {
            bookingId: id,
            proProfileId: p.id,
            expiresAt: new Date(now.getTime() + 300000),
          },
        });
        return {
          value: { created: true, userId: p.userId },
          details: { proProfileId: p.id },
        };
      },
    );
    if (result.created) await this.push.notify(result.userId, id);
    return { offered: true, alreadyPending: !result.created };
  }
}
