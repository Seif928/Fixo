import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, ProVerificationStatus } from '@prisma/client';
import {
  SeedCoverageZone,
  SeedServiceCategory,
  SeedServiceOffering,
} from '../../prisma/egypt-demo-seed.data';
import {
  coversServiceArea,
  professionalCoverageWhere,
} from './coverage-policy';
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
    const rawSearch = query.search?.trim();
    const search = rawSearch?.toLowerCase();
    const categoryFilter = query.categoryId?.trim().toLowerCase();
    const offset = (page - 1) * limit;

    if (this.prisma.isDatabaseConnected()) {
      const andClauses: Record<string, unknown>[] = [];
      if (categoryFilter) {
        andClauses.push({
          OR: [
            { categoryId: { equals: categoryFilter, mode: 'insensitive' } },
            {
              category: {
                slug: { equals: categoryFilter, mode: 'insensitive' },
              },
            },
          ],
        });
      }
      if (rawSearch) {
        const tokens = rawSearch.split(/\s+/).filter(Boolean);
        for (const token of tokens) {
          andClauses.push({
            OR: [
              { titleEn: { contains: token, mode: 'insensitive' } },
              { titleAr: { contains: token, mode: 'insensitive' } },
              { descriptionEn: { contains: token, mode: 'insensitive' } },
              { descriptionAr: { contains: token, mode: 'insensitive' } },
              { badgeEn: { contains: token, mode: 'insensitive' } },
              { providerTagEn: { contains: token, mode: 'insensitive' } },
              {
                category: {
                  slug: { contains: token, mode: 'insensitive' },
                },
              },
            ],
          });
        }
      }

      const where = {
        isActive: true,
        ...(typeof query.featured === 'boolean'
          ? { isSeasonalPromo: query.featured }
          : {}),
        ...(typeof query.bundle === 'boolean'
          ? { isBundle: query.bundle }
          : {}),
        ...(andClauses.length > 0 ? { AND: andClauses } : {}),
      };

      const needInMemoryPhraseFilter = Boolean(
        search && rawSearch && rawSearch.includes(' '),
      );

      if (!needInMemoryPhraseFilter) {
        const rows = await this.prisma.serviceOffering.findMany({
          where,
          include: { category: true },
          orderBy: { id: 'asc' },
          skip: offset,
          take: limit,
        });
        const total =
          offset === 0 && rows.length < limit
            ? rows.length
            : await this.prisma.serviceOffering.count({ where });

        return {
          items: rows.map((row) => this.mapOfferingRow(row)),
          meta: {
            page,
            limit,
            total,
            totalPages: Math.max(1, Math.ceil(total / limit)),
            currency: 'EGP',
            market: 'EG',
            storageMode: this.prisma.getStorageMode(),
            databaseConnected: true,
          },
        };
      }

      const filteredRows = await this.prisma.serviceOffering.findMany({
        where,
        include: { category: true },
        orderBy: { id: 'asc' },
      });
      const phraseMatches = filteredRows
        .map((row) => this.mapOfferingRow(row))
        .filter((item) => this.matchesServiceSearch(item, search!));
      const total = phraseMatches.length;

      return {
        items: phraseMatches.slice(offset, offset + limit),
        meta: {
          page,
          limit,
          total,
          totalPages: Math.max(1, Math.ceil(total / limit)),
          currency: 'EGP',
          market: 'EG',
          storageMode: this.prisma.getStorageMode(),
          databaseConnected: true,
        },
      };
    }

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
      allOfferings = allOfferings.filter((item) =>
        this.matchesServiceSearch(item, search),
      );
    }

    const total = allOfferings.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
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

  private matchesServiceSearch(
    item: SeedServiceOffering,
    searchLower: string,
  ): boolean {
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
    return haystack.includes(searchLower);
  }

  private mapOfferingRow(row: {
    id: string;
    categoryId: string;
    category?: { slug: string } | null;
    slug: string;
    titleEn: string;
    titleAr: string;
    descriptionEn: string;
    descriptionAr: string;
    badgeEn: string | null;
    badgeAr: string | null;
    providerTagEn: string | null;
    providerTagAr: string | null;
    baseInspectionEgp: number;
    serviceFeeEgp: number;
    flatPriceEgp: number | null;
    estimatedDurationMins: number;
    isSeasonalPromo: boolean;
    isBundle: boolean;
  }): SeedServiceOffering {
    return {
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
    let match: SeedServiceOffering | undefined;

    if (this.prisma.isDatabaseConnected()) {
      const rows = await this.prisma.serviceOffering.findMany({
        where: {
          isActive: true,
          OR: [{ id: idOrSlug }, { slug: idOrSlug }],
        },
        include: { category: true },
        take: 1,
      });
      const matchedRow = rows.find(
        (row) => row.id === idOrSlug || row.slug === idOrSlug,
      );
      match = matchedRow ? this.mapOfferingRow(matchedRow) : undefined;
    } else {
      const allOfferings = await this.loadAllOfferings();
      match = allOfferings.find(
        (item) => item.id === idOrSlug || item.slug === idOrSlug,
      );
    }

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
    const rawSearch = query.search?.trim();
    const search = rawSearch?.toLowerCase();
    const categoryFilter = query.categoryId?.trim().toLowerCase();
    const zoneFilter = query.zone?.trim().toLowerCase();
    const offset = (page - 1) * limit;

    if (this.prisma.isDatabaseConnected()) {
      const selectedZone = zoneFilter
        ? await this.prisma.coverageZone.findUnique({
            where: { slug: zoneFilter },
          })
        : null;

      if (zoneFilter && !selectedZone) {
        return {
          items: [],
          meta: {
            page,
            limit,
            total: 0,
            totalPages: 1,
            currency: 'EGP',
            market: 'EG',
            storageMode: this.prisma.getStorageMode(),
            databaseConnected: this.prisma.isDatabaseConnected(),
          },
        };
      }

      const andClauses: Prisma.ProProfileWhereInput[] = [];
      if (categoryFilter) {
        andClauses.push({
          OR: [
            {
              primaryCategoryId: { equals: categoryFilter, mode: 'insensitive' },
            },
            {
              primaryCategory: {
                slug: { equals: categoryFilter, mode: 'insensitive' },
              },
            },
          ],
        });
      }
      if (selectedZone) {
        andClauses.push(professionalCoverageWhere(selectedZone));
      }
      if (rawSearch) {
        const tokens = rawSearch.split(/\s+/).filter(Boolean);
        for (const token of tokens) {
          andClauses.push({
            OR: [
              { user: { fullName: { contains: token, mode: 'insensitive' } } },
              { specialtyEn: { contains: token, mode: 'insensitive' } },
              { specialtyAr: { contains: token, mode: 'insensitive' } },
              { zonesLabelEn: { contains: token, mode: 'insensitive' } },
              { zonesLabelAr: { contains: token, mode: 'insensitive' } },
              { badgeEn: { contains: token, mode: 'insensitive' } },
              {
                primaryCategory: {
                  slug: { contains: token, mode: 'insensitive' },
                },
              },
            ],
          });
        }
      }

      const where: Prisma.ProProfileWhereInput = {
        verificationStatus: ProVerificationStatus.APPROVED,
        ...(andClauses.length > 0 ? { AND: andClauses } : {}),
      };
      const proInclude = {
        user: { select: { fullName: true } },
        primaryCategory: true,
        primaryZone: true,
        coverageZones: true,
      } satisfies Prisma.ProProfileInclude;
      const needInMemoryPhraseFilter = Boolean(
        search && rawSearch && rawSearch.includes(' '),
      );

      if (!needInMemoryPhraseFilter) {
        const rows = await this.prisma.proProfile.findMany({
          where,
          include: proInclude,
          orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
          skip: offset,
          take: limit,
        });
        const mapped = rows.map((row) => this.mapProfessionalRow(row));
        const filtered = this.filterProfessionals(mapped, {
          categoryFilter,
          selectedZone,
          search,
        });
        const mockIgnoredWhere = filtered.length < mapped.length;
        const pageRows = mockIgnoredWhere
          ? filtered.slice(offset, offset + limit)
          : filtered;
        const items = pageRows.map(
          ({ coverage, ...publicFields }) => publicFields,
        );
        const total = mockIgnoredWhere
          ? filtered.length
          : offset === 0 && rows.length < limit
            ? rows.length
            : typeof (this.prisma.proProfile as { count?: unknown }).count ===
                'function'
              ? await this.prisma.proProfile.count({ where })
              : rows.length;
        const totalPages = Math.max(1, Math.ceil(total / limit));

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

      const candidateRows = await this.prisma.proProfile.findMany({
        where,
        include: proInclude,
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      });
      const mappedCandidates = candidateRows.map((row) =>
        this.mapProfessionalRow(row),
      );
      const filtered = this.filterProfessionals(mappedCandidates, {
        categoryFilter,
        selectedZone,
        search,
      });
      const total = filtered.length;
      const totalPages = Math.max(1, Math.ceil(total / limit));
      const items = filtered
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

    let allPros = await this.loadAllProfessionals();
    const selected = zoneFilter
      ? (this.memoryStore.getZones().find((z) => z.slug === zoneFilter) ?? null)
      : undefined;
    allPros =
      zoneFilter && !selected
        ? []
        : this.filterProfessionals(allPros, {
            categoryFilter,
            selectedZone: selected ?? null,
            search,
          });

    const total = allPros.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
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

  private filterProfessionals(
    pros: DiscoveryProfessional[],
    filters: {
      categoryFilter?: string;
      selectedZone?: Parameters<typeof coversServiceArea>[1] | null;
      search?: string;
    },
  ): DiscoveryProfessional[] {
    let result = pros;
    if (filters.categoryFilter) {
      result = result.filter(
        (pro) =>
          pro.primaryCategorySlug.toLowerCase() === filters.categoryFilter ||
          pro.primaryCategoryId?.toLowerCase() === filters.categoryFilter,
      );
    }
    if (filters.selectedZone) {
      const target = filters.selectedZone;
      result = result.filter((pro) =>
        (pro.coverage ?? []).some((z) => coversServiceArea(z, target)),
      );
    }
    if (filters.search) {
      const needle = filters.search;
      result = result.filter((pro) => {
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
        return haystack.includes(needle);
      });
    }
    return result;
  }

  private mapProfessionalRow(row: {
    id: string;
    user: { fullName: string | null };
    primaryCategoryId: string | null;
    primaryCategory: { id: string; slug: string; nameEn: string } | null;
    primaryZone: SeedCoverageZone | null;
    coverageZones: SeedCoverageZone[] | null;
    specialtyEn: string | null;
    specialtyAr: string | null;
    zonesLabelEn: string | null;
    zonesLabelAr: string | null;
    ratingAvg: number;
    reviewsCount: number;
    completedJobsCount: number;
    acceptanceRatePct: number;
    estimatedPriceEgp: number;
    badgeEn: string | null;
    badgeAr: string | null;
    isOnline: boolean;
  }): DiscoveryProfessional {
    return {
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
      return rows.map((row) => this.mapOfferingRow(row));
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
          user: { select: { fullName: true } },
          primaryCategory: true,
          primaryZone: true,
          coverageZones: true,
        },
      });

      return rows.map((row) => this.mapProfessionalRow(row));
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
