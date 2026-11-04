import { Injectable, NotFoundException } from '@nestjs/common';
import { ProVerificationStatus } from '@prisma/client';
import {
  SeedCoverageZone,
  SeedServiceCategory,
  SeedServiceOffering,
} from '../../prisma/egypt-demo-seed.data';
import { coversServiceArea } from './coverage-policy';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import {
  PrismaService,
  StoragePersistenceMode,
} from '../../prisma/prisma.service';
import { PublicProfessionalDto } from './dto/public-professional.dto';
import {
  QueryProfessionalsDto,
  QueryServicesDto,
} from './dto/query-services.dto';

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

type DiscoveryProfessional = PublicProfessionalDto & {
  coverage?: Array<{ slug: string; governorate: string }>;
};

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
      // Database-connected mode: Categories and zones come EXCLUSIVELY from PostgreSQL.
      // Never substitute in-memory/demo data when connected.
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
      // Offline fallback: demo seed allowed only when not in production and ENABLE_DEMO_SEED !== 'false'
      if (
        process.env.NODE_ENV === 'production' ||
        process.env.ENABLE_DEMO_SEED === 'false'
      ) {
        categories = [];
        zones = [];
      } else {
        categories = this.memoryStore.getCategories();
        zones = this.memoryStore.getZones();
      }
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
  ): Promise<PaginatedResponse<PublicProfessionalDto>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const search = query.search?.trim().toLowerCase();
    const categoryFilter = query.categoryId?.trim().toLowerCase();
    const zoneFilter = query.zone?.trim().toLowerCase();

    let allPros = await this.loadAllProfessionals();

    if (categoryFilter) {
      allPros = allPros.filter(
        (pro) =>
          pro.primaryCategorySlug.toLowerCase() === categoryFilter ||
          pro.primaryCategoryId?.toLowerCase() === categoryFilter,
      );
    }

    if (zoneFilter) {
      const selected = this.prisma.isDatabaseConnected()
        ? await this.prisma.coverageZone.findUnique({
            where: { slug: zoneFilter },
          })
        : this.memoryStore.getZones().find((z) => z.slug === zoneFilter);
      allPros = selected
        ? allPros.filter((pro) =>
            (pro.coverage ?? []).some((z) => coversServiceArea(z, selected)),
          )
        : [];
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
          pro.badgeEn ?? '',
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
    const items = allPros
      .slice(offset, offset + limit)
      .map(({ coverage, ...publicFields }) => publicFields);

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
      // Database-connected mode: Offerings come EXCLUSIVELY from PostgreSQL.
      // Never substitute in-memory/demo data when connected.
      const rows = await this.prisma.serviceOffering.findMany({
        where: { isActive: true },
        include: { category: true },
      });
      return rows.map((row) => ({
        id: row.id,
        categoryId: row.categoryId,
        categorySlug: row.category?.slug ?? '',
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
        flatPriceEgp:
          row.flatPriceEgp ?? row.baseInspectionEgp + row.serviceFeeEgp,
        estimatedDurationMins: row.estimatedDurationMins,
        isSeasonalPromo: row.isSeasonalPromo,
        isBundle: row.isBundle,
      }));
    }

    if (
      process.env.NODE_ENV === 'production' ||
      process.env.ENABLE_DEMO_SEED === 'false'
    ) {
      return [];
    }

    return this.memoryStore.getOfferings();
  }

  private async loadAllProfessionals(): Promise<DiscoveryProfessional[]> {
    if (this.prisma.isDatabaseConnected()) {
      // Database-connected mode: Professionals come EXCLUSIVELY from PostgreSQL.
      // Security Invariant: Only APPROVED profiles appear in public discovery.
      // DRAFT, PENDING_REVIEW, ACTION_REQUIRED, SUSPENDED are strictly excluded.
      // Returns genuine empty results when no approved pros exist in DB.
      const rows = await this.prisma.proProfile.findMany({
        where: {
          verificationStatus: ProVerificationStatus.APPROVED,
        },
        include: {
          user: true,
          primaryCategory: true,
          primaryZone: true,
          coverageZones: true,
        },
      });

      return rows.map((row) => ({
        id: row.id,
        fullNameEn: row.user.fullName ?? 'FIXO technician',
        fullNameAr: row.user.fullName ?? 'فني معتمد',
        specialtyEn: row.specialtyEn ?? row.primaryCategory?.nameEn ?? '',
        specialtyAr: row.specialtyAr ?? 'فني معتمد',
        primaryCategorySlug: row.primaryCategory?.slug ?? '',
        primaryCategoryId:
          row.primaryCategoryId ?? row.primaryCategory?.id ?? '',
        primaryZoneSlug: row.primaryZone?.slug ?? '',
        coverage: [
          ...(row.coverageZones ?? []),
          ...(row.primaryZone ? [row.primaryZone] : []),
        ],
        zonesLabelEn: row.zonesLabelEn ?? row.primaryZone?.nameEn ?? '',
        zonesLabelAr: row.zonesLabelAr ?? row.primaryZone?.nameAr ?? '',
        ratingAvg: row.reviewsCount > 0 ? row.ratingAvg : 0,
        reviewsCount: row.reviewsCount,
        completedJobsCount: row.completedJobsCount,
        acceptanceRatePct: row.acceptanceRatePct,
        estimatedPriceEgp: row.estimatedPriceEgp,
        badgeEn: row.badgeEn,
        badgeAr: row.badgeAr,
        badgeVariant: row.badgeEn
          ? row.badgeEn.toLowerCase().includes('fast')
            ? 'fast_responder'
            : 'verified_master'
          : null,
        isOnline: row.isOnline,
      }));
    }

    // In-memory fallback: strictly prohibited from synthetic demo leaking in production or when demo seed is false
    if (
      process.env.NODE_ENV === 'production' ||
      process.env.ENABLE_DEMO_SEED === 'false'
    ) {
      return [];
    }

    const demoPros = this.memoryStore
      .getProfessionals()
      .filter(
        (pro) => pro.verificationStatus === ProVerificationStatus.APPROVED,
      );

    return demoPros.map((pro) => ({
      id: pro.id,
      fullNameEn: pro.fullNameEn,
      fullNameAr: pro.fullNameAr,
      specialtyEn: pro.specialtyEn,
      specialtyAr: pro.specialtyAr,
      primaryCategorySlug: pro.primaryCategorySlug,
      primaryCategoryId:
        this.memoryStore
          .getCategories()
          .find((c) => c.slug === pro.primaryCategorySlug)?.id ?? '',
      primaryZoneSlug: pro.primaryZoneSlug,
      coverage: this.memoryStore
        .getZones()
        .filter((z) => z.slug === pro.primaryZoneSlug),
      zonesLabelEn: pro.zonesLabelEn,
      zonesLabelAr: pro.zonesLabelAr,
      ratingAvg: pro.ratingAvg,
      reviewsCount: pro.reviewsCount,
      completedJobsCount: pro.completedJobsCount,
      acceptanceRatePct: pro.acceptanceRatePct,
      estimatedPriceEgp: pro.estimatedPriceEgp,
      badgeEn: pro.badgeEn,
      badgeAr: pro.badgeAr,
      badgeVariant: pro.badgeVariant,
      isOnline: pro.isOnline,
    }));
  }
}
