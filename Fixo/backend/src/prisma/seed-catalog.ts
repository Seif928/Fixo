import { PrismaClient } from '@prisma/client';
import {
  EGYPT_COVERAGE_ZONES,
  EGYPT_SERVICE_CATEGORIES,
  EGYPT_SERVICE_OFFERINGS,
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
      let zonesCreated = 0;
      let zonesPreserved = 0;

      for (const zone of EGYPT_COVERAGE_ZONES) {
        const existing = await tx.coverageZone.findUnique({
          where: { slug: zone.slug },
          select: { id: true },
        });

        if (!existing) {
          await tx.coverageZone.create({
            data: {
              id: zone.id,
              slug: zone.slug,
              nameEn: zone.nameEn,
              nameAr: zone.nameAr,
              governorate: zone.governorate,
              isActive: zone.isActive,
            },
          });
          zonesCreated++;
        } else {
          zonesPreserved++;
        }
      }

      // 2. Seed Service Categories (stable unique key: slug)
      let categoriesCreated = 0;
      let categoriesPreserved = 0;

      for (const category of EGYPT_SERVICE_CATEGORIES) {
        const existing = await tx.serviceCategory.findUnique({
          where: { slug: category.slug },
          select: { id: true },
        });

        if (!existing) {
          await tx.serviceCategory.create({
            data: {
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
            },
          });
          categoriesCreated++;
        } else {
          categoriesPreserved++;
        }
      }

      // 3. Seed Service Offerings (stable unique key: slug)
      let offeringsCreated = 0;
      let offeringsPreserved = 0;

      for (const offering of EGYPT_SERVICE_OFFERINGS) {
        // Find category dynamically by categorySlug to ensure valid FK relation
        const category = await tx.serviceCategory.findUnique({
          where: { slug: offering.categorySlug },
          select: { id: true },
        });

        if (!category) {
          throw new Error(
            `Cannot seed offering "${offering.slug}": referenced category slug "${offering.categorySlug}" does not exist in the database.`,
          );
        }

        const existing = await tx.serviceOffering.findUnique({
          where: { slug: offering.slug },
          select: { id: true },
        });

        if (!existing) {
          await tx.serviceOffering.create({
            data: {
              id: offering.id,
              categoryId: category.id,
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
            },
          });
          offeringsCreated++;
        } else {
          offeringsPreserved++;
        }
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
    { timeout: 30000, maxWait: 10000 },
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

