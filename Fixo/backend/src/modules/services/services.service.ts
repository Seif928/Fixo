import { Injectable, NotFoundException } from '@nestjs/common';
import {
  SeedCoverageZone,
  SeedProfessionalRecord,
  SeedServiceCategory,
  SeedServiceOffering,
} from '../../prisma/egypt-demo-seed.data';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import { PrismaService, StoragePersistenceMode } from '../../prisma/prisma.service';
import { QueryProfessionalsDto, QueryServicesDto } from './dto/query-services.dto';

export interface PaginatedResponse<T> {
  items: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    currency: 'EGP';
    market: 'EG';
    storageMode: StoragePersistenceMode;
    databaseConnected: boolean;
  };
}

@Injectable()
export class ServicesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly memoryStore: InMemoryStoreService,
  ) {}

  async listCategories(): Promise<{
    categories: SeedServiceCategory[];
    zones: SeedCoverageZone[];
    meta: {
      total: number;
      currency: 'EGP';
      market: 'EG';
      storageMode: StoragePersistenceMode;
      databaseConnected: boolean;
    };
  }> {
    let categories: SeedServiceCategory[];
    let zones: SeedCoverageZone[];

    if (this.prisma.isDatabaseConnected()) {
      const [dbCategories, dbZones] = await Promise.all([
        this.prisma.serviceCategory.findMany({
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        }),
        this.prisma.coverageZone.findMany({
          where: { isActive: true },
        }),
      ]);
      categories = dbCategories;
      zones = dbZones;
    } else {
      categories = this.memoryStore.getCategories();
      zones = this.memoryStore.getZones();
    }

    return {
      categories,
      zones,
      meta: {
        total: categories.length,
        currency: 'EGP',
        market: 'EG',
        storageMode: this.prisma.getStorageMode(),
        databaseConnected: this.prisma.isDatabaseConnected(),
      },
    };
  }

  async listServices(
    query: QueryServicesDto,
  ): Promise<PaginatedResponse<SeedServiceOffering>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const search = query.search?.trim().toLowerCase();
    const categoryFilter = query.categoryId?.trim().toLowerCase();

    let allOfferings = await this.loadAllOfferings();

    if (categoryFilter) {
      allOfferings = allOfferings.filter(
        (item) =>
          item.categoryId.toLowerCase() === categoryFilter ||
          item.categorySlug.toLowerCase() === categoryFilter,
      );
    }

    if (typeof query.featured === 'boolean') {
      allOfferings = allOfferings.filter(
        (item) => item.isSeasonalPromo === query.featured,
      );
    }

    if (typeof query.bundle === 'boolean') {
      allOfferings = allOfferings.filter(
        (item) => item.isBundle === query.bundle,
      );
    }

    if (search) {
      allOfferings = allOfferings.filter((item) => {
        const haystack = [
          item.titleEn,
          item.titleAr,
          item.descriptionEn,
          item.descriptionAr,
          item.categorySlug,
          item.badgeEn ?? '',
          item.providerTagEn ?? '',
        ]
          .join(' ')
          .toLowerCase();
        return haystack.includes(search);
      });
    }

    const total = allOfferings.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
    const offset = (page - 1) * limit;
    const items = allOfferings.slice(offset, offset + limit);

    return {
      items,
      meta: {
        page,
        limit,
        total,
        totalPages,
        currency: 'EGP',
        market: 'EG',
        storageMode: this.prisma.getStorageMode(),
        databaseConnected: this.prisma.isDatabaseConnected(),
      },
    };
  }

  async getServiceById(idOrSlug: string): Promise<{
    service: SeedServiceOffering;
    meta: {
      currency: 'EGP';
      market: 'EG';
      storageMode: StoragePersistenceMode;
      databaseConnected: boolean;
    };
  }> {
    const allOfferings = await this.loadAllOfferings();
    const match = allOfferings.find(
      (item) => item.id === idOrSlug || item.slug === idOrSlug,
    );

    if (!match) {
      throw new NotFoundException(`Service '${idOrSlug}' was not found.`);
    }

    return {
      service: match,
      meta: {
        currency: 'EGP',
        market: 'EG',
        storageMode: this.prisma.getStorageMode(),
        databaseConnected: this.prisma.isDatabaseConnected(),
      },
    };
  }

  async listProfessionals(
    query: QueryProfessionalsDto,
  ): Promise<PaginatedResponse<SeedProfessionalRecord>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const search = query.search?.trim().toLowerCase();
    const categoryFilter = query.categoryId?.trim().toLowerCase();
    const zoneFilter = query.zone?.trim().toLowerCase();

    let allPros = await this.loadAllProfessionals();

    if (categoryFilter) {
      allPros = allPros.filter(
        (pro) =>
          pro.primaryCategoryId.toLowerCase() === categoryFilter ||
          pro.primaryCategorySlug.toLowerCase() === categoryFilter,
      );
    }

    if (zoneFilter) {
      // Allow matching zone slug or label, or return all Greater Cairo & Giza pros if general zone
      const zoneMatches = allPros.filter((pro) => {
        const zoneHaystack = [
          pro.primaryZoneSlug,
          pro.zonesLabelEn,
          pro.zonesLabelAr,
        ]
          .join(' ')
          .toLowerCase();
        return zoneHaystack.includes(zoneFilter);
      });
      allPros = zoneMatches;
    }

    if (search) {
      allPros = allPros.filter((pro) => {
        const haystack = [
          pro.fullNameEn,
          pro.fullNameAr,
          pro.specialtyEn,
          pro.specialtyAr,
          pro.zonesLabelEn,
          pro.zonesLabelAr,
          pro.badgeEn,
          pro.primaryCategorySlug,
        ]
          .join(' ')
          .toLowerCase();
        return haystack.includes(search);
      });
    }

    const total = allPros.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
    const offset = (page - 1) * limit;
    const items = allPros.slice(offset, offset + limit);

    return {
      items,
      meta: {
        page,
        limit,
        total,
        totalPages,
        currency: 'EGP',
        market: 'EG',
        storageMode: this.prisma.getStorageMode(),
        databaseConnected: this.prisma.isDatabaseConnected(),
      },
    };
  }

  private async loadAllOfferings(): Promise<SeedServiceOffering[]> {
    if (this.prisma.isDatabaseConnected()) {
      const rows = await this.prisma.serviceOffering.findMany({
        include: { category: true },
      });
      if (rows.length > 0) {
        return rows.map((row) => ({
          id: row.id,
          categoryId: row.categoryId,
          categorySlug: row.category.slug,
          slug: row.slug,
          titleEn: row.titleEn,
          titleAr: row.titleAr,
          descriptionEn: row.descriptionEn,
          descriptionAr: row.descriptionAr,
          badgeEn: row.badgeEn,
          badgeAr: row.badgeAr,
          providerTagEn: row.providerTagEn,
          providerTagAr: row.providerTagAr,
          baseInspectionEgp: row.baseInspectionEgp,
          serviceFeeEgp: row.serviceFeeEgp,
          flatPriceEgp: row.flatPriceEgp ?? row.baseInspectionEgp + row.serviceFeeEgp,
          estimatedDurationMins: row.estimatedDurationMins,
          isSeasonalPromo: row.isSeasonalPromo,
          isBundle: row.isBundle,
        }));
      }
    }
    return this.memoryStore.getOfferings();
  }

  private async loadAllProfessionals(): Promise<SeedProfessionalRecord[]> {
    if (this.prisma.isDatabaseConnected()) {
      const rows = await this.prisma.proProfile.findMany({
        include: {
          user: true,
          primaryCategory: true,
          primaryZone: true,
        },
      });
      if (rows.length > 0) {
        return rows.map((row) => ({
          id: row.id,
          userId: row.userId,
          fullNameEn: row.user.fullName ?? 'Cairo Technician',
          fullNameAr: row.user.fullName ?? 'فني القاهرة',
          phone: row.user.phone,
          dossierCode: row.dossierCode,
          primaryCategoryId: row.primaryCategoryId ?? 'cat-ac-maintenance',
          primaryCategorySlug: row.primaryCategory?.slug ?? 'ac-maintenance',
          primaryZoneSlug: row.primaryZone?.slug ?? 'sheikh-zayed',
          specialtyEn: row.specialtyEn ?? 'Certified Artisan',
          specialtyAr: row.specialtyAr ?? 'فني معتمد',
          zonesLabelEn: row.zonesLabelEn ?? 'Cairo & Giza',
          zonesLabelAr: row.zonesLabelAr ?? 'القاهرة والجيزة',
          ratingAvg: row.ratingAvg,
          reviewsCount: row.reviewsCount,
          completedJobsCount: row.completedJobsCount,
          acceptanceRatePct: row.acceptanceRatePct,
          estimatedPriceEgp: row.estimatedPriceEgp,
          badgeEn: row.badgeEn ?? 'Verified Master Pro',
          badgeAr: row.badgeAr ?? 'فني خبير معتمد',
          badgeVariant:
            row.badgeEn?.toLowerCase().includes('fast')
              ? 'fast_responder'
              : 'verified_master',
          transportMode: row.transportMode,
          experienceTier: row.experienceTier,
          verificationStatus: row.verificationStatus,
          isOnline: row.isOnline,
        }));
      }
    }
    return this.memoryStore.getProfessionals();
  }
}

