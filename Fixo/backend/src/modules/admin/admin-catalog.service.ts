import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAccessService, AdminActor } from './admin-access.service';
import type {
  CatalogQueryDto,
  CatalogUpdateDto,
  CreateCatalogDraftDto,
} from './admin-catalog.controller';

@Injectable()
export class AdminCatalogService {
  constructor(
    private readonly db: PrismaService,
    private readonly access: AdminAccessService,
  ) {}

  async list(query: CatalogQueryDto) {
    const where: Prisma.AdminCatalogDraftWhereInput = {
      ...(query.category ? { categorySlug: query.category } : {}),
      ...(query.search
        ? {
            OR: ['titleEn', 'titleAr', 'slug'].map((key) => ({
              [key]: { contains: query.search, mode: 'insensitive' },
            })),
          }
        : {}),
    };
    const [items, total, categories] = await this.db.$transaction([
      this.db.adminCatalogDraft.findMany({
        where,
        orderBy: [{ categorySlug: 'asc' }, { slug: 'asc' }],
        skip: (query.page - 1) * 20,
        take: 20,
      }),
      this.db.adminCatalogDraft.count({ where }),
      this.db.adminCatalogDraft.findMany({
        distinct: ['categorySlug'],
        select: {
          categorySlug: true,
          categoryNameEn: true,
          categoryNameAr: true,
        },
        orderBy: { categorySlug: 'asc' },
      }),
    ]);
    return {
      items,
      categories,
      meta: {
        page: query.page,
        total,
        totalPages: Math.max(1, Math.ceil(total / 20)),
      },
    };
  }

  async createDraft(actor: AdminActor, dto: CreateCatalogDraftDto) {
    const rawSlug = dto.slug?.trim() || dto.titleEn.trim();
    const slug = rawSlug
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');

    if (!slug || slug.length < 2) {
      throw new BadRequestException(
        'A valid alphanumeric slug of at least 2 characters is required.',
      );
    }

    if (!dto.titleEn?.trim() || !dto.titleAr?.trim()) {
      throw new BadRequestException('Bilingual titles are required.');
    }
    if (!dto.descriptionEn?.trim() || !dto.descriptionAr?.trim()) {
      throw new BadRequestException('Bilingual descriptions are required.');
    }
    if (!dto.categorySlug?.trim()) {
      throw new BadRequestException('A category slug is required.');
    }

    const id = randomUUID();

    return this.access.mutate(
      actor,
      false,
      'CATALOG_DRAFT_CREATED',
      id,
      async (tx) => {
        const existingDraft = await tx.adminCatalogDraft.findUnique({
          where: { slug },
        });
        if (existingDraft) {
          throw new ConflictException({
            code: 'ADMIN_CATALOG_SLUG_EXISTS',
            message: `A service draft with slug '${slug}' already exists.`,
          });
        }
        const existingOffering = await tx.serviceOffering.findUnique({
          where: { slug },
        });
        if (existingOffering) {
          throw new ConflictException({
            code: 'ADMIN_CATALOG_SLUG_EXISTS',
            message: `A published service with slug '${slug}' already exists.`,
          });
        }

        const category = await tx.serviceCategory.findUnique({
          where: { slug: dto.categorySlug },
        });
        const existingDraftWithCat = await tx.adminCatalogDraft.findFirst({
          where: { categorySlug: dto.categorySlug },
        });

        const knownNameEn =
          category?.nameEn || existingDraftWithCat?.categoryNameEn;
        const knownNameAr =
          category?.nameAr || existingDraftWithCat?.categoryNameAr;
        const knownIcon =
          category?.iconName || existingDraftWithCat?.categoryIcon;

        if (!knownNameEn || !knownNameAr) {
          if (!dto.categoryNameEn?.trim() || !dto.categoryNameAr?.trim()) {
            throw new BadRequestException({
              code: 'ADMIN_CATALOG_CATEGORY_NAMES_REQUIRED',
              message:
                'Both English and Arabic category names are required for an unknown category.',
            });
          }
        }

        const categoryNameEn = dto.categoryNameEn?.trim() || knownNameEn!;
        const categoryNameAr = dto.categoryNameAr?.trim() || knownNameAr!;
        const categoryIcon =
          dto.categoryIcon?.trim() || knownIcon || 'home_repair_service';

        const value = await tx.adminCatalogDraft.create({
          data: {
            id,
            slug,
            categorySlug: dto.categorySlug.trim(),
            categoryNameEn,
            categoryNameAr,
            categoryIcon,
            titleEn: dto.titleEn.trim(),
            titleAr: dto.titleAr.trim(),
            descriptionEn: dto.descriptionEn.trim(),
            descriptionAr: dto.descriptionAr.trim(),
            baseInspectionEgp: dto.baseInspectionEgp ?? null,
            serviceFeeEgp: dto.serviceFeeEgp ?? null,
            estimatedDurationMins: dto.estimatedDurationMins ?? null,
            version: 1,
            publishedVersion: null,
            offeringId: null,
            isActive: true,
          },
        });

        return {
          value,
          details: {
            version: value.version,
            slug: value.slug,
            categorySlug: value.categorySlug,
          },
        };
      },
    );
  }

  update(actor: AdminActor, id: string, dto: CatalogUpdateDto) {
    return this.access.mutate(
      actor,
      false,
      'CATALOG_DRAFT_UPDATED',
      id,
      async (tx) => {
        const draft = await tx.adminCatalogDraft.findUnique({ where: { id } });
        if (!draft) throw new NotFoundException('Catalog draft not found.');
        if (draft.version !== dto.version) this.stale();
        const { version, ...changes } = dto;
        // Null is meaningful only for incomplete pricing. Text must remain usable.
        for (const key of [
          'titleEn',
          'titleAr',
          'descriptionEn',
          'descriptionAr',
        ] as const) {
          if (changes[key] === null)
            throw new BadRequestException('Service text cannot be empty.');
        }
        const value = await tx.adminCatalogDraft.update({
          where: { id },
          data: { ...changes, version: { increment: 1 } },
        });
        return {
          value,
          details: { version: value.version, fields: Object.keys(changes) },
        };
      },
    );
  }

  publish(actor: AdminActor, id: string, version: number) {
    return this.access.mutate(
      actor,
      false,
      'CATALOG_PUBLISHED',
      id,
      async (tx) => {
        const draft = await tx.adminCatalogDraft.findUnique({ where: { id } });
        if (!draft) throw new NotFoundException('Catalog draft not found.');
        if (draft.version !== version) this.stale();
        if (
          draft.publishedVersion === version &&
          draft.offeringId &&
          draft.isActive
        ) {
          return { value: draft, details: { version }, recordAudit: false };
        }
        const { baseInspectionEgp, serviceFeeEgp, estimatedDurationMins } =
          draft;
        if (
          baseInspectionEgp === null ||
          serviceFeeEgp === null ||
          estimatedDurationMins === null ||
          baseInspectionEgp + serviceFeeEgp <= 0
        ) {
          throw new BadRequestException({
            code: 'ADMIN_CATALOG_PRICING_REQUIRED',
            message:
              'Set inspection, service price and duration with a positive total before publishing.',
          });
        }
        let category = await tx.serviceCategory.findUnique({
          where: { slug: draft.categorySlug },
        });
        if (category && !category.isActive)
          throw new BadRequestException('The service category is inactive.');
        if (!category)
          category = await tx.serviceCategory.create({
            data: {
              slug: draft.categorySlug,
              nameEn: draft.categoryNameEn,
              nameAr: draft.categoryNameAr,
              subtitleEn: draft.categoryNameEn,
              subtitleAr: draft.categoryNameAr,
              iconName: draft.categoryIcon,
              startingPriceEgp: baseInspectionEgp + serviceFeeEgp,
              sortOrder: 100,
            },
          });
        const data = {
          categoryId: category.id,
          titleEn: draft.titleEn,
          titleAr: draft.titleAr,
          descriptionEn: draft.descriptionEn,
          descriptionAr: draft.descriptionAr,
          baseInspectionEgp,
          serviceFeeEgp,
          flatPriceEgp: baseInspectionEgp + serviceFeeEgp,
          estimatedDurationMins,
          isActive: true,
        };
        const offering = draft.offeringId
          ? await tx.serviceOffering.update({
              where: { id: draft.offeringId },
              data,
            })
          : await tx.serviceOffering.create({
              data: { ...data, slug: draft.slug },
            });
        const value = await tx.adminCatalogDraft.update({
          where: { id },
          data: {
            offeringId: offering.id,
            publishedVersion: version,
            isActive: true,
          },
        });
        return {
          value,
          details: {
            version,
            offeringId: offering.id,
            baseInspectionEgp,
            serviceFeeEgp,
            totalEgp: data.flatPriceEgp,
          },
        };
      },
    );
  }

  deactivate(actor: AdminActor, id: string, version: number) {
    return this.access.mutate(
      actor,
      false,
      'CATALOG_SERVICE_DEACTIVATED',
      id,
      async (tx) => {
        const draft = await tx.adminCatalogDraft.findUnique({ where: { id } });
        if (!draft) throw new NotFoundException('Catalog draft not found.');
        if (draft.version !== version) this.stale();
        if (!draft.offeringId) {
          throw new BadRequestException({
            code: 'ADMIN_CATALOG_NOT_PUBLISHED',
            message: 'Only published services can be deactivated.',
          });
        }
        if (!draft.isActive) {
          return { value: draft, details: { version }, recordAudit: false };
        }

        await tx.serviceOffering.update({
          where: { id: draft.offeringId },
          data: { isActive: false },
        });

        const hadPendingEdits = draft.publishedVersion !== draft.version;
        const nextVersion = draft.version + 1;
        const nextPublishedVersion = hadPendingEdits
          ? draft.publishedVersion
          : nextVersion;
        const value = await tx.adminCatalogDraft.update({
          where: { id },
          data: {
            isActive: false,
            version: nextVersion,
            publishedVersion: nextPublishedVersion,
          },
        });

        return {
          value,
          details: {
            version: value.version,
            offeringId: draft.offeringId,
            isActive: false,
          },
        };
      },
    );
  }

  reactivate(actor: AdminActor, id: string, version: number) {
    return this.access.mutate(
      actor,
      false,
      'CATALOG_SERVICE_REACTIVATED',
      id,
      async (tx) => {
        const draft = await tx.adminCatalogDraft.findUnique({ where: { id } });
        if (!draft) throw new NotFoundException('Catalog draft not found.');
        if (draft.version !== version) this.stale();
        if (!draft.offeringId) {
          throw new BadRequestException({
            code: 'ADMIN_CATALOG_NOT_PUBLISHED',
            message: 'Only published services can be reactivated.',
          });
        }
        if (draft.isActive) {
          return { value: draft, details: { version }, recordAudit: false };
        }

        const category = await tx.serviceCategory.findUnique({
          where: { slug: draft.categorySlug },
        });
        if (category && !category.isActive) {
          throw new BadRequestException('The service category is inactive.');
        }

        await tx.serviceOffering.update({
          where: { id: draft.offeringId },
          data: { isActive: true },
        });

        const hadPendingEdits = draft.publishedVersion !== draft.version;
        const nextVersion = draft.version + 1;
        const nextPublishedVersion = hadPendingEdits
          ? draft.publishedVersion
          : nextVersion;
        const value = await tx.adminCatalogDraft.update({
          where: { id },
          data: {
            isActive: true,
            version: nextVersion,
            publishedVersion: nextPublishedVersion,
          },
        });

        return {
          value,
          details: {
            version: value.version,
            offeringId: draft.offeringId,
            isActive: true,
          },
        };
      },
    );
  }

  private stale(): never {
    throw new ConflictException({
      code: 'ADMIN_CATALOG_VERSION_CONFLICT',
      message:
        'This service changed. Reload its saved version before continuing.',
    });
  }
}
