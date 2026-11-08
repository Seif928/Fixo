import { PrismaClient } from '@prisma/client';
import {
  EGYPT_COVERAGE_ZONES,
  EGYPT_SERVICE_CATEGORIES,
  EGYPT_SERVICE_OFFERINGS,
  EGYPT_SERVICE_SUB_SKILLS,
} from './egypt-demo-seed.data';

export interface EntitySeedStats {
  created: number;
  preserved: number;
  total: number;
}

export interface CatalogSeedSummary {
  coverageZones: EntitySeedStats;
  serviceCategories: EntitySeedStats;
  serviceOfferings: EntitySeedStats;
}

/**
 * Idempotently seeds FIXO catalog data (CoverageZone, ServiceCategory, ServiceOffering)
 * inside a single database transaction using stable unique keys (`slug`).
 *
 * Guarantees:
 * - Atomic transaction execution (with rollback on any unexpected error).
 * - Idempotency: Repeated executions never create duplicate records.
 * - Non-destructive preservation: Existing records and any custom administrator
 *   edits (e.g. customized names, pricing, descriptions) are never overwritten.
 * - Strict catalog-only scope: Never creates users, professionals, bookings, or auth data.
 */
export async function seedCatalog(
  prisma: PrismaClient,
): Promise<CatalogSeedSummary> {
  return await prisma.$transaction(
    async (tx) => {
      // 1. Seed Coverage Zones (stable unique key: slug)
      const existingZonesList = await tx.coverageZone.findMany({
        select: { id: true, slug: true },
      });
      const existingZoneSlugs = new Set(existingZonesList.map((z) => z.slug));
      let zonesCreated = 0;
      let zonesPreserved = 0;

      const zonesToCreate = [];
      for (const zone of EGYPT_COVERAGE_ZONES) {
        if (!existingZoneSlugs.has(zone.slug)) {
          zonesToCreate.push({
            id: zone.id,
            slug: zone.slug,
            nameEn: zone.nameEn,
            nameAr: zone.nameAr,
            governorate: zone.governorate,
            isActive: zone.isActive,
          });
          zonesCreated++;
        } else {
          zonesPreserved++;
        }
      }
      if (zonesToCreate.length > 0) {
        await tx.coverageZone.createMany({ data: zonesToCreate });
      }

      // 2. Seed Service Categories (stable unique key: slug)
      const existingCatsList = await tx.serviceCategory.findMany({
        select: { id: true, slug: true },
      });
      const categoryIdBySlug = new Map<string, string>(
        existingCatsList.map((c) => [c.slug, c.id]),
      );
      let categoriesCreated = 0;
      let categoriesPreserved = 0;

      const catsToCreate = [];
      for (const category of EGYPT_SERVICE_CATEGORIES) {
        if (!categoryIdBySlug.has(category.slug)) {
          catsToCreate.push({
            id: category.id,
            slug: category.slug,
            nameEn: category.nameEn,
            nameAr: category.nameAr,
            subtitleEn: category.subtitleEn,
            subtitleAr: category.subtitleAr,
            iconName: category.iconName,
            startingPriceEgp: category.startingPriceEgp,
            sortOrder: category.sortOrder,
            isActive: category.isActive,
          });
          categoryIdBySlug.set(category.slug, category.id);
          categoriesCreated++;
        } else {
          categoriesPreserved++;
        }
      }
      if (catsToCreate.length > 0) {
        await tx.serviceCategory.createMany({ data: catsToCreate });
      }

      // 2b. Seed Service Sub-Skills (if tx.serviceSubSkill is available)
      if ((tx as any).serviceSubSkill) {
        const existingSubsList = await tx.serviceSubSkill.findMany({
          select: { slug: true },
        });
        const existingSubSlugs = new Set(existingSubsList.map((s) => s.slug));
        const subsToCreate = [];
        for (const subSkill of EGYPT_SERVICE_SUB_SKILLS) {
          const catId = categoryIdBySlug.get(subSkill.categorySlug);
          if (catId && !existingSubSlugs.has(subSkill.slug)) {
            subsToCreate.push({
              id: subSkill.id,
              categoryId: catId,
              slug: subSkill.slug,
              nameEn: subSkill.nameEn,
              nameAr: subSkill.nameAr,
            });
          }
        }
        if (subsToCreate.length > 0) {
          await tx.serviceSubSkill.createMany({ data: subsToCreate });
        }
      }

      // 3. Seed Service Offerings (stable unique key: slug)
      const existingOfferingsList = await tx.serviceOffering.findMany({
        select: { id: true, slug: true },
      });
      const existingOfferingSlugs = new Set(
        existingOfferingsList.map((o) => o.slug),
      );
      let offeringsCreated = 0;
      let offeringsPreserved = 0;

      const offeringsToCreate = [];
      for (const offering of EGYPT_SERVICE_OFFERINGS) {
        const catId = categoryIdBySlug.get(offering.categorySlug);
        if (!catId) {
          throw new Error(
            `Cannot seed offering "${offering.slug}": referenced category slug "${offering.categorySlug}" does not exist in the database.`,
          );
        }

        if (!existingOfferingSlugs.has(offering.slug)) {
          offeringsToCreate.push({
            id: offering.id,
            categoryId: catId,
            slug: offering.slug,
            titleEn: offering.titleEn,
            titleAr: offering.titleAr,
            descriptionEn: offering.descriptionEn,
            descriptionAr: offering.descriptionAr,
            badgeEn: offering.badgeEn,
            badgeAr: offering.badgeAr,
            providerTagEn: offering.providerTagEn,
            providerTagAr: offering.providerTagAr,
            baseInspectionEgp: offering.baseInspectionEgp,
            serviceFeeEgp: offering.serviceFeeEgp,
            flatPriceEgp: offering.flatPriceEgp,
            estimatedDurationMins: offering.estimatedDurationMins,
            isSeasonalPromo: offering.isSeasonalPromo,
            isBundle: offering.isBundle,
          });
          offeringsCreated++;
        } else {
          offeringsPreserved++;
        }
      }
      if (offeringsToCreate.length > 0) {
        await tx.serviceOffering.createMany({ data: offeringsToCreate });
      }

      return {
        coverageZones: {
          created: zonesCreated,
          preserved: zonesPreserved,
          total: zonesCreated + zonesPreserved,
        },
        serviceCategories: {
          created: categoriesCreated,
          preserved: categoriesPreserved,
          total: categoriesCreated + categoriesPreserved,
        },
        serviceOfferings: {
          created: offeringsCreated,
          preserved: offeringsPreserved,
          total: offeringsCreated + offeringsPreserved,
        },
      };
    },
    { timeout: 120000, maxWait: 20000 },
  );
}

/**
 * Direct CLI entrypoint when executed directly via Node / ts-node.
 */
async function main(): Promise<void> {
  const prisma = new PrismaClient();
  try {
    console.log('[FIXO CATALOG SEED] Executing catalog seed transaction...');
    const result = await seedCatalog(prisma);
    console.log('[FIXO CATALOG SEED] Transaction completed successfully:');
    console.log(
      `  - Coverage Zones:    ${result.coverageZones.created} created, ${result.coverageZones.preserved} preserved (total: ${result.coverageZones.total})`,
    );
    console.log(
      `  - Service Categories: ${result.serviceCategories.created} created, ${result.serviceCategories.preserved} preserved (total: ${result.serviceCategories.total})`,
    );
    console.log(
      `  - Service Offerings:  ${result.serviceOfferings.created} created, ${result.serviceOfferings.preserved} preserved (total: ${result.serviceOfferings.total})`,
    );
  } catch (error) {
    console.error('[FIXO CATALOG SEED] Seed transaction failed and was rolled back:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  void main();
}

