import {
  BookingStatus,
  JobOfferStatus,
  ProVerificationStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { coversServiceArea } from '../services/coverage-policy';

export const jobOfferDetailsInclude = {
  booking: {
    include: {
      offering: { include: { category: true } },
      address: { include: { zone: true } },
      customer: { select: { id: true, fullName: true, rewardPoints: true } },
    },
  },
} as const;

/** Shared final dispatch decision. Lock order: Booking -> ProProfile -> JobOffer. */
export async function ensureDispatchOffer(
  prisma: PrismaService,
  bookingId: string,
  proProfileId: string,
  renewExpired = false,
): Promise<{ created: boolean; userId: string } | null> {
  if (!prisma.isDatabaseConnected()) return null;
  return prisma.$transaction(async (tx) => {
    await tx.$queryRaw`SELECT id FROM "Booking" WHERE id = ${bookingId} FOR UPDATE`;
    const booking = await tx.booking.findUnique({
      where: { id: bookingId },
      include: { offering: true, address: { include: { zone: true } } },
    });
    if (
      !booking ||
      booking.proProfileId ||
      ![BookingStatus.PENDING_DISPATCH, BookingStatus.OFFERED_TO_PRO].some(
        (status) => status === booking.status,
      )
    )
      return null;
    await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE id = ${proProfileId} FOR UPDATE`;
    const pro = await tx.proProfile.findUnique({
      where: { id: proProfileId },
      include: { primaryZone: true, coverageZones: true },
    });
    if (
      !pro ||
      pro.verificationStatus !== ProVerificationStatus.APPROVED ||
      !pro.isOnline ||
      pro.userId === booking.customerId ||
      pro.primaryCategoryId !== booking.offering.categoryId ||
      ![
        ...(pro.primaryZone ? [pro.primaryZone] : []),
        ...pro.coverageZones,
      ].some((z) => coversServiceArea(z, booking.address.zone))
    )
      return null;
    const existing = await tx.jobOffer.findFirst({
      where: { bookingId, proProfileId },
      orderBy: { createdAt: 'desc' },
    });
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    if (existing) {
      if (
        renewExpired &&
        existing.status === JobOfferStatus.EXPIRED &&
        booking.status === BookingStatus.PENDING_DISPATCH
      ) {
        await tx.jobOffer.updateMany({
          where: { id: existing.id, status: JobOfferStatus.EXPIRED },
          data: {
            status: JobOfferStatus.PENDING,
            expiresAt,
            respondedAt: null,
          },
        });
      }
      return { created: false, userId: pro.userId };
    }
    await tx.jobOffer.create({
      data: {
        bookingId,
        proProfileId,
        status: JobOfferStatus.PENDING,
        expiresAt,
      },
    });
    return { created: true, userId: pro.userId };
  });
}
