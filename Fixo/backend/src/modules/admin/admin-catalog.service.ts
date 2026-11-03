import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAccessService, AdminActor } from './admin-access.service';
import type {
  CatalogQueryDto,
  CatalogUpdateDto,
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
        if (draft.publishedVersion === version && draft.offeringId) {
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
          data: { offeringId: offering.id, publishedVersion: version },
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
  private stale(): never {
    throw new ConflictException({
      code: 'ADMIN_CATALOG_VERSION_CONFLICT',
      message:
        'This service changed. Reload its saved version before continuing.',
    });
  }
}
