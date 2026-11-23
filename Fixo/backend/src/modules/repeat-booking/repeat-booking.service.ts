import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ProVerificationStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class RepeatBookingService {
  constructor(private readonly db: PrismaService) {}

  async getRepeatQuote(userId: string, bookingId: string) {
    const booking = await this.db.booking.findUnique({
      where: { id: bookingId },
      include: {
        offering: {
          include: { category: true },
        },
        proProfile: {
          include: {
            user: { select: { fullName: true } },
            primaryCategory: true,
            primaryZone: true,
          },
        },
        address: true,
      },
    });

    if (!booking) {
      throw new NotFoundException(`Booking '${bookingId}' was not found.`);
    }

    if (booking.customerId !== userId) {
      throw new ForbiddenException('You do not have access to this booking.');
    }

    if (!booking.offering || !booking.offering.isActive) {
      throw new BadRequestException({
        code: 'SERVICE_DEACTIVATED',
        message: 'This service is no longer active and cannot be booked again.',
      });
    }

    if (!booking.offering.category.isActive) {
      throw new BadRequestException({
        code: 'CATEGORY_DEACTIVATED',
        message: 'This service category is currently inactive.',
      });
    }

    const isProApproved =
      booking.proProfile?.verificationStatus === ProVerificationStatus.APPROVED;
    const preferredPro =
      isProApproved && booking.proProfile
        ? {
            id: booking.proProfile.id,
            fullNameEn: booking.proProfile.user.fullName ?? 'FIXO technician',
            fullNameAr: booking.proProfile.user.fullName ?? 'فني معتمد',
            specialtyEn: booking.proProfile.specialtyEn ?? '',
            specialtyAr: booking.proProfile.specialtyAr ?? '',
            ratingAvg:
              booking.proProfile.reviewsCount > 0
                ? booking.proProfile.ratingAvg
                : 0,
            isOnline: booking.proProfile.isOnline,
          }
        : null;

    const defaultAddress =
      booking.address && booking.address.userId === userId
        ? {
            id: booking.address.id,
            label: booking.address.label,
            buildingLine: booking.address.buildingLine,
            districtLine: booking.address.districtLine,
            zoneId: booking.address.zoneId,
          }
        : null;

    const baseInspectionEgp = booking.offering.baseInspectionEgp;
    const serviceFeeEgp = booking.offering.serviceFeeEgp;
    const flatPriceEgp =
      booking.offering.flatPriceEgp ?? baseInspectionEgp + serviceFeeEgp;

    return {
      originalBookingId: booking.id,
      orderCode: booking.orderCode,
      offering: {
        id: booking.offering.id,
        slug: booking.offering.slug,
        titleEn: booking.offering.titleEn,
        titleAr: booking.offering.titleAr,
        descriptionEn: booking.offering.descriptionEn,
        descriptionAr: booking.offering.descriptionAr,
        baseInspectionEgp,
        serviceFeeEgp,
        flatPriceEgp,
        estimatedDurationMins: booking.offering.estimatedDurationMins,
        categorySlug: booking.offering.category.slug,
        categoryNameEn: booking.offering.category.nameEn,
        categoryNameAr: booking.offering.category.nameAr,
        categoryIcon: booking.offering.category.iconName,
        isActive: booking.offering.isActive,
      },
      preferredPro,
      defaultAddress,
    };
  }
}
