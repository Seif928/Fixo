import { Injectable, NotFoundException } from '@nestjs/common';
import { ProVerificationStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FavoritesQueryDto } from './favorites.dto';

@Injectable()
export class FavoritesService {
  constructor(private readonly db: PrismaService) {}

  async listFavoriteServices(userId: string, query: FavoritesQueryDto) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await this.db.$transaction([
      this.db.favoriteService.findMany({
        where: { userId },
        include: {
          offering: {
            include: {
              category: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.db.favoriteService.count({ where: { userId } }),
    ]);

    const mapped = items.map((f) => {
      const isAvailable = f.offering.isActive && f.offering.category.isActive;
      return {
        id: f.id,
        offeringId: f.offeringId,
        createdAt: f.createdAt.toISOString(),
        isAvailable,
        offering: {
          id: f.offering.id,
          slug: f.offering.slug,
          titleEn: f.offering.titleEn,
          titleAr: f.offering.titleAr,
          descriptionEn: f.offering.descriptionEn,
          descriptionAr: f.offering.descriptionAr,
          baseInspectionEgp: f.offering.baseInspectionEgp,
          serviceFeeEgp: f.offering.serviceFeeEgp,
          flatPriceEgp:
            f.offering.flatPriceEgp ??
            f.offering.baseInspectionEgp + f.offering.serviceFeeEgp,
          estimatedDurationMins: f.offering.estimatedDurationMins,
          isActive: f.offering.isActive,
          category: {
            id: f.offering.category.id,
            slug: f.offering.category.slug,
            nameEn: f.offering.category.nameEn,
            nameAr: f.offering.category.nameAr,
            iconName: f.offering.category.iconName,
            isActive: f.offering.category.isActive,
          },
        },
      };
    });

    return {
      items: mapped,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async addFavoriteService(userId: string, offeringId: string) {
    const offering = await this.db.serviceOffering.findUnique({
      where: { id: offeringId },
    });
    if (!offering) {
      throw new NotFoundException(`Service offering '${offeringId}' not found.`);
    }

    await this.db.favoriteService.upsert({
      where: {
        userId_offeringId: { userId, offeringId },
      },
      create: { userId, offeringId },
      update: {},
    });

    return { success: true, favorited: true, offeringId };
  }

  async removeFavoriteService(userId: string, offeringId: string) {
    await this.db.favoriteService.deleteMany({
      where: { userId, offeringId },
    });
    return { success: true, favorited: false, offeringId };
  }

  async listFavoriteProfessionals(userId: string, query: FavoritesQueryDto) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await this.db.$transaction([
      this.db.favoriteProfessional.findMany({
        where: { userId },
        include: {
          proProfile: {
            include: {
              user: true,
              primaryCategory: true,
              primaryZone: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.db.favoriteProfessional.count({ where: { userId } }),
    ]);

    const mapped = items.map((f) => {
      const isApproved =
        f.proProfile.verificationStatus === ProVerificationStatus.APPROVED;
      const isAvailable = isApproved && f.proProfile.isOnline;
      return {
        id: f.id,
        proProfileId: f.proProfileId,
        createdAt: f.createdAt.toISOString(),
        isAvailable,
        verificationStatus: f.proProfile.verificationStatus,
        professional: {
          id: f.proProfile.id,
          fullNameEn: f.proProfile.user.fullName ?? 'FIXO technician',
          fullNameAr: f.proProfile.user.fullName ?? 'فني معتمد',
          specialtyEn:
            f.proProfile.specialtyEn ??
            f.proProfile.primaryCategory?.nameEn ??
            '',
          specialtyAr:
            f.proProfile.specialtyAr ??
            f.proProfile.primaryCategory?.nameAr ??
            'فني معتمد',
          ratingAvg:
            f.proProfile.reviewsCount > 0 ? f.proProfile.ratingAvg : 0,
          reviewsCount: f.proProfile.reviewsCount,
          completedJobsCount: f.proProfile.completedJobsCount,
          isOnline: f.proProfile.isOnline,
          verificationStatus: f.proProfile.verificationStatus,
          primaryCategory: f.proProfile.primaryCategory
            ? {
                id: f.proProfile.primaryCategory.id,
                slug: f.proProfile.primaryCategory.slug,
                nameEn: f.proProfile.primaryCategory.nameEn,
                nameAr: f.proProfile.primaryCategory.nameAr,
              }
            : null,
          primaryZone: f.proProfile.primaryZone
            ? {
                id: f.proProfile.primaryZone.id,
                slug: f.proProfile.primaryZone.slug,
                nameEn: f.proProfile.primaryZone.nameEn,
                nameAr: f.proProfile.primaryZone.nameAr,
              }
            : null,
        },
      };
    });

    return {
      items: mapped,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async addFavoriteProfessional(userId: string, proProfileId: string) {
    const pro = await this.db.proProfile.findUnique({
      where: { id: proProfileId },
    });
    if (!pro) {
      throw new NotFoundException(`Professional '${proProfileId}' not found.`);
    }

    await this.db.favoriteProfessional.upsert({
      where: {
        userId_proProfileId: { userId, proProfileId },
      },
      create: { userId, proProfileId },
      update: {},
    });

    return { success: true, favorited: true, proProfileId };
  }

  async removeFavoriteProfessional(userId: string, proProfileId: string) {
    await this.db.favoriteProfessional.deleteMany({
      where: { userId, proProfileId },
    });
    return { success: true, favorited: false, proProfileId };
  }

  async getFavoriteIds(userId: string) {
    const [serviceRows, proRows] = await Promise.all([
      this.db.favoriteService.findMany({
        where: { userId },
        select: { offeringId: true },
      }),
      this.db.favoriteProfessional.findMany({
        where: { userId },
        select: { proProfileId: true },
      }),
    ]);
    return {
      serviceIds: serviceRows.map((r) => r.offeringId),
      proProfileIds: proRows.map((r) => r.proProfileId),
    };
  }
}
