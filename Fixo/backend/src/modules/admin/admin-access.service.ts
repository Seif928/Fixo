import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FirebaseSessionPolicy } from '../auth/firebase-session-policy.service';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';

export interface AdminActor {
  userId: string;
  role: 'OWNER' | 'ADMIN';
  authTime: number;
}

@Injectable()
export class AdminAccessService {
  constructor(
    private readonly db: PrismaService,
    private readonly provider: FirebaseSessionPolicy,
  ) {}
  private async lock(tx: Prisma.TransactionClient) {
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext('fixo_admin_access_v1'))`;
  }
  private fresh(actor: AdminActor) {
    if (Date.now() / 1000 - actor.authTime > 900)
      throw new ForbiddenException({
        code: 'ADMIN_REAUTH_REQUIRED',
        message:
          'Confirm your account before changing administration settings.',
      });
  }
  async resolve(payload: FixoJwtPayload): Promise<AdminActor> {
    if (!this.db.isDatabaseConnected())
      throw new ServiceUnavailableException(
        'Administration requires database persistence.',
      );
    const time = payload.firebaseAuthTime;
    if (
      !Number.isSafeInteger(time) ||
      !time ||
      time < Date.now() / 1000 - 12 * 3600
    )
      throw new ForbiddenException({
        code: 'ADMIN_REAUTH_REQUIRED',
        message: 'Sign in again for administration access.',
      });
    const user = await this.db.user.findUnique({ where: { id: payload.sub } });
    if (!user?.firebaseUid || !user.email)
      throw new ForbiddenException(
        'Administration access is not available for this account.',
      );
    const identity = await this.provider.readVerifiedAccount(
      user.firebaseUid,
      time,
    );
    const email = user.email.trim().toLowerCase();
    if (
      identity.uid !== user.firebaseUid ||
      identity.email?.trim().toLowerCase() !== email
    )
      throw new ForbiddenException(
        'Administration identity could not be confirmed.',
      );
    const member = await this.db.$transaction(async (tx) => {
      await this.lock(tx);
      let member = await tx.adminMembership.findUnique({ where: { email } });
      const configured = process.env.FIXO_OWNER_EMAIL?.trim().toLowerCase();
      if (
        !member &&
        configured === email &&
        !(await tx.adminMembership.findUnique({ where: { slot: 1 } }))
      ) {
        member = await tx.adminMembership.create({
          data: { slot: 1, email, userId: user.id, role: 'OWNER' },
        });
        await tx.adminAuditLog.create({
          data: {
            actorUserId: user.id,
            action: 'OWNER_INITIALIZED',
            entityId: '1',
            details: { slot: 1 },
          },
        });
      }
      if (
        !member?.isActive ||
        (member.expiresAt && member.expiresAt <= new Date()) ||
        (member.userId && member.userId !== user.id)
      )
        throw new ForbiddenException(
          'Administration access is not available for this account.',
        );
      if (!member.userId) {
        member = await tx.adminMembership.update({
          where: { slot: member.slot },
          data: { userId: user.id, expiresAt: null },
        });
        await tx.adminAuditLog.create({
          data: {
            actorUserId: user.id,
            action: 'ADMIN_INVITE_ACCEPTED',
            entityId: '2',
            details: { slot: 2 },
          },
        });
      }
      return member;
    });
    return { userId: user.id, role: member.role, authTime: time };
  }
  async mutate<T>(
    actor: AdminActor,
    ownerOnly: boolean,
    action: string,
    entityId: string,
    operation: (
      tx: Prisma.TransactionClient,
    ) => Promise<{ value: T; details: Prisma.InputJsonValue }>,
  ) {
    this.fresh(actor);
    return this.db.$transaction(async (tx) => {
      await this.lock(tx);
      const current = await tx.adminMembership.findUnique({
        where: { userId: actor.userId },
      });
      if (!current?.isActive || (ownerOnly && current.role !== 'OWNER'))
        throw new ForbiddenException(
          'Your administration permission has ended.',
        );
      const result = await operation(tx);
      await tx.adminAuditLog.create({
        data: {
          actorUserId: actor.userId,
          action,
          entityId,
          details: result.details,
        },
      });
      return result.value;
    });
  }
  async members(actor: AdminActor) {
    if (actor.role !== 'OWNER')
      throw new ForbiddenException(
        'Only the owner can manage administration access.',
      );
    return this.db.adminMembership.findMany({
      orderBy: { slot: 'asc' },
      select: {
        slot: true,
        email: true,
        role: true,
        isActive: true,
        expiresAt: true,
        userId: true,
      },
    });
  }
  async invite(actor: AdminActor, email: string) {
    email = email.trim().toLowerCase();
    return this.mutate(actor, true, 'ADMIN_INVITED', '2', async (tx) => {
      const owner = await tx.adminMembership.findUniqueOrThrow({
        where: { slot: 1 },
      });
      if (owner.email === email)
        throw new BadRequestException(
          'The owner cannot be added as the second administrator.',
        );
      const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);
      const value = await tx.adminMembership.upsert({
        where: { slot: 2 },
        create: { slot: 2, email, role: 'ADMIN', expiresAt },
        update: { email, userId: null, isActive: true, expiresAt },
      });
      return {
        value: {
          slot: value.slot,
          email: value.email,
          role: value.role,
          isActive: value.isActive,
          expiresAt: value.expiresAt,
        },
        details: { slot: 2 },
      };
    });
  }
  async revoke(actor: AdminActor) {
    return this.mutate(actor, true, 'ADMIN_REVOKED', '2', async (tx) => {
      await tx.adminMembership.updateMany({
        where: { slot: 2 },
        data: { isActive: false, userId: null, expiresAt: null },
      });
      return { value: { revoked: true }, details: { slot: 2 } };
    });
  }
  async audit() {
    return {
      items: await this.db.adminAuditLog.findMany({
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 20,
      }),
    };
  }
  async summary() {
    // One consistent database snapshot; never infer collections from booking totals.
    return this.db.$transaction(
      async (tx) => {
        const users = await tx.user.count();
        const professionals = await tx.proProfile.count();
        const pendingReviews = await tx.proProfile.count({
          where: { verificationStatus: 'PENDING_REVIEW' },
        });
        const activeBookings = await tx.booking.count({
          where: {
            status: {
              in: [
                'PENDING_DISPATCH',
                'OFFERED_TO_PRO',
                'CONFIRMED',
                'PRO_EN_ROUTE',
                'ARRIVED',
                'IN_PROGRESS',
              ],
            },
          },
        });
        const cash = await tx.paymentRecord.aggregate({
          where: {
            method: 'CASH_ON_SERVICE',
            status: 'PAID',
            paidAt: { not: null },
          },
          _sum: { amountEgp: true },
        });
        return {
          users,
          professionals,
          pendingReviews,
          activeBookings,
          collectedCashEgp: cash._sum.amountEgp ?? 0,
        };
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead },
    );
  }
}
