import { PrismaClient } from '@prisma/client';
import * as dotenv from 'dotenv';
import * as path from 'path';
import {
  EGYPT_COVERAGE_ZONES,
  EGYPT_SERVICE_CATEGORIES,
  EGYPT_SERVICE_OFFERINGS,
} from './egypt-demo-seed.data';
import { seedCatalog } from './seed-catalog';
import {
  assertCurrentDatabaseIsTest,
  safeCleanupCatalogTestTables,
  validateTestDatabaseTarget,
} from './test-database-safety.util';

// Load .env configuration if available, preserving any pre-set environment variables
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

/**
 * Integration Test Suite for Catalog-Only Seed.
 *
 * Runs strictly against the dedicated local `fixo_test` database on localhost:5432.
 * Validates fail-closed safety guards, exact entity counts, idempotency across
 * multiple executions, preservation of custom administrator edits and custom category IDs,
 * transactional rollback on real constraint conflicts, and zero non-catalog records.
 */
describe('Catalog Seed Integration Suite (fixo_test)', () => {
  let prisma: PrismaClient;
  let originalTestDbUrl: string | undefined;
  let originalDbUrl: string | undefined;

  beforeAll(async () => {
    originalTestDbUrl = process.env.TEST_DATABASE_URL;
    originalDbUrl = process.env.DATABASE_URL;

    // 1. Require explicit TEST_DATABASE_URL without fallbacks or rewriting
    const testDbUrl = process.env.TEST_DATABASE_URL;

    // 2. Fail-closed safety validation: target must be local fixo_test on port 5432
    validateTestDatabaseTarget(testDbUrl);

    process.env.DATABASE_URL = testDbUrl;

    prisma = new PrismaClient({
      datasources: {
        db: {
          url: testDbUrl,
        },
      },
    });

    await prisma.$connect();

    // 3. PostgreSQL runtime database identity check
    const currentDb = await assertCurrentDatabaseIsTest(prisma);
    expect(currentDb).toBe('fixo_test');
  });

  afterAll(async () => {
    if (prisma) {
      await safeCleanupCatalogTestTables({
        $queryRaw: prisma.$queryRaw.bind(prisma),
        $executeRawUnsafe: prisma.$executeRawUnsafe.bind(prisma),
        isDatabaseConnected: () => true,
      });
      await prisma.$disconnect();
    }

    if (originalTestDbUrl !== undefined) {
      process.env.TEST_DATABASE_URL = originalTestDbUrl;
    } else {
      delete process.env.TEST_DATABASE_URL;
    }

    if (originalDbUrl !== undefined) {
      process.env.DATABASE_URL = originalDbUrl;
    } else {
      delete process.env.DATABASE_URL;
    }
  });

  beforeEach(async () => {
    // Truncate catalog test tables before each test case
    await safeCleanupCatalogTestTables({
      $queryRaw: prisma.$queryRaw.bind(prisma),
      $executeRawUnsafe: prisma.$executeRawUnsafe.bind(prisma),
      isDatabaseConnected: () => true,
    });
  });

  it('strictly validates TEST_DATABASE_URL and rejects missing or non-fixo_test targets', () => {
    expect(() => validateTestDatabaseTarget(undefined)).toThrow(
      /TEST_DATABASE_URL is missing or empty/i,
    );
    expect(() => validateTestDatabaseTarget('')).toThrow(
      /TEST_DATABASE_URL is missing or empty/i,
    );
    expect(() =>
      validateTestDatabaseTarget(
        'postgresql://fixo_user:pass@localhost:5432/fixo_dev',
      ),
    ).toThrow(/Refusing to target database "fixo_dev"/i);
    expect(() =>
      validateTestDatabaseTarget(
        'postgresql://fixo_user:pass@remote-host:5432/fixo_test',
      ),
    ).toThrow(/Unsafe test database host/i);
    expect(() =>
      validateTestDatabaseTarget(
        'postgresql://fixo_user:pass@localhost:5433/fixo_test',
      ),
    ).toThrow(/Unexpected test database port "5433"/i);
  });

  it('verifies catalog definitions match expected record counts', () => {
    expect(EGYPT_COVERAGE_ZONES.length).toBe(5);
    expect(EGYPT_SERVICE_CATEGORIES.length).toBe(6);
    expect(EGYPT_SERVICE_OFFERINGS.length).toBe(8);
  });

  it('seeds catalog data cleanly on first run and creates no non-catalog entities', async () => {
    // 1. Initial count check
    expect(await prisma.coverageZone.count()).toBe(0);
    expect(await prisma.serviceCategory.count()).toBe(0);
    expect(await prisma.serviceOffering.count()).toBe(0);

    // 2. Execute first seed run
    const result = await seedCatalog(prisma);

    // 3. Verify returned statistics
    expect(result.coverageZones).toEqual({
      created: 5,
      preserved: 0,
      total: 5,
    });
    expect(result.serviceCategories).toEqual({
      created: 6,
      preserved: 0,
      total: 6,
    });
    expect(result.serviceOfferings).toEqual({
      created: 8,
      preserved: 0,
      total: 8,
    });

    // 4. Verify actual database counts in PostgreSQL
    expect(await prisma.coverageZone.count()).toBe(5);
    expect(await prisma.serviceCategory.count()).toBe(6);
    expect(await prisma.serviceOffering.count()).toBe(8);

    // 5. Verify strict catalog-only boundary: zero user or auth records created
    expect(await prisma.user.count()).toBe(0);
    expect(await prisma.proProfile.count()).toBe(0);
    expect(await prisma.booking.count()).toBe(0);
    expect(await prisma.otpChallenge.count()).toBe(0);
    expect(await prisma.refreshToken.count()).toBe(0);
  });

  it('is completely idempotent and preserves existing customized records on repeated runs', async () => {
    // 1. First run: initial seed
    const firstRun = await seedCatalog(prisma);
    expect(firstRun.coverageZones.created).toBe(5);
    expect(firstRun.serviceCategories.created).toBe(6);
    expect(firstRun.serviceOfferings.created).toBe(8);

    // 2. Simulate customized administrator edits directly in the database
    await prisma.coverageZone.update({
      where: { slug: 'sheikh-zayed' },
      data: { nameEn: 'Customized Sheikh Zayed Zone' },
    });

    await prisma.serviceCategory.update({
      where: { slug: 'ac-maintenance' },
      data: {
        subtitleEn: 'Customized AC Subtitle',
        startingPriceEgp: 999,
      },
    });

    await prisma.serviceOffering.update({
      where: { slug: 'summer-ac-deep-clean-gas-refill' },
      data: {
        titleEn: 'Customized AC Summer Promo',
        flatPriceEgp: 1250,
      },
    });

    // 3. Second run: re-seed catalog
    const secondRun = await seedCatalog(prisma);

    // 4. Verify that second run created 0 new records and preserved all existing
    expect(secondRun.coverageZones).toEqual({
      created: 0,
      preserved: 5,
      total: 5,
    });
    expect(secondRun.serviceCategories).toEqual({
      created: 0,
      preserved: 6,
      total: 6,
    });
    expect(secondRun.serviceOfferings).toEqual({
      created: 0,
      preserved: 8,
      total: 8,
    });

    // 5. Verify total record counts did NOT change (no duplicates created)
    expect(await prisma.coverageZone.count()).toBe(5);
    expect(await prisma.serviceCategory.count()).toBe(6);
    expect(await prisma.serviceOffering.count()).toBe(8);

    // 6. Verify customized values were NOT overwritten by default seed values
    const updatedZone = await prisma.coverageZone.findUnique({
      where: { slug: 'sheikh-zayed' },
    });
    expect(updatedZone?.nameEn).toBe('Customized Sheikh Zayed Zone');

    const updatedCategory = await prisma.serviceCategory.findUnique({
      where: { slug: 'ac-maintenance' },
    });
    expect(updatedCategory?.subtitleEn).toBe('Customized AC Subtitle');
    expect(updatedCategory?.startingPriceEgp).toBe(999);

    const updatedOffering = await prisma.serviceOffering.findUnique({
      where: { slug: 'summer-ac-deep-clean-gas-refill' },
    });
    expect(updatedOffering?.titleEn).toBe('Customized AC Summer Promo');
    expect(updatedOffering?.flatPriceEgp).toBe(1250);
  });

  it('preserves a pre-existing category with a different ID but the same slug, and links new offerings to that existing ID', async () => {
    // 1. Verify clean initial state
    expect(await prisma.serviceCategory.count()).toBe(0);
    expect(await prisma.serviceOffering.count()).toBe(0);

    // 2. Pre-insert a category with a custom UUID and the standard slug 'ac-maintenance'
    const customCategoryId = 'custom-ac-uuid-99999999';
    await prisma.serviceCategory.create({
      data: {
        id: customCategoryId,
        slug: 'ac-maintenance',
        nameEn: 'Pre-existing Custom AC',
        nameAr: 'صيانة تكييف مخصصة مسبقاً',
        subtitleEn: 'Pre-existing custom subtitle',
        subtitleAr: 'وصف مخصص موجود مسبقا',
        iconName: 'mode_fan',
        startingPriceEgp: 499,
        sortOrder: 1,
        isActive: true,
      },
    });

    const preExistingCat = await prisma.serviceCategory.findUnique({
      where: { slug: 'ac-maintenance' },
    });
    expect(preExistingCat?.id).toBe(customCategoryId);

    // 3. Execute seedCatalog
    const result = await seedCatalog(prisma);

    // 4. Verify counts: 5 categories created, 1 preserved (the pre-existing category)
    expect(result.serviceCategories).toEqual({
      created: 5,
      preserved: 1,
      total: 6,
    });
    expect(await prisma.serviceCategory.count()).toBe(6);

    // 5. Verify the pre-existing category retains its custom ID and custom values
    const preservedCat = await prisma.serviceCategory.findUnique({
      where: { slug: 'ac-maintenance' },
    });
    expect(preservedCat?.id).toBe(customCategoryId);
    expect(preservedCat?.nameEn).toBe('Pre-existing Custom AC');
    expect(preservedCat?.subtitleEn).toBe('Pre-existing custom subtitle');
    expect(preservedCat?.startingPriceEgp).toBe(499);

    // 6. Verify new offerings belonging to 'ac-maintenance' link to the pre-existing custom ID
    const acSummerPromo = await prisma.serviceOffering.findUnique({
      where: { slug: 'summer-ac-deep-clean-gas-refill' },
    });
    expect(acSummerPromo).not.toBeNull();
    expect(acSummerPromo?.categoryId).toBe(customCategoryId);

    const acInverterTuneUp = await prisma.serviceOffering.findUnique({
      where: { slug: 'inverter-split-ac-maintenance' },
    });
    expect(acInverterTuneUp).not.toBeNull();
    expect(acInverterTuneUp?.categoryId).toBe(customCategoryId);

    // 7. Verify via relation from category side
    const catWithOfferings = await prisma.serviceCategory.findUnique({
      where: { id: customCategoryId },
      include: { offerings: true },
    });
    expect(catWithOfferings?.offerings.length).toBe(2);
    const offeringSlugs = catWithOfferings?.offerings.map((o) => o.slug);
    expect(offeringSlugs).toContain('summer-ac-deep-clean-gas-refill');
    expect(offeringSlugs).toContain('inverter-split-ac-maintenance');
  });

  it('rolls back all transaction inserts upon a real PostgreSQL constraint conflict, leaving pre-existing records unchanged', async () => {
    // 1. Verify clean initial state
    expect(await prisma.coverageZone.count()).toBe(0);
    expect(await prisma.serviceCategory.count()).toBe(0);
    expect(await prisma.serviceOffering.count()).toBe(0);

    // 2. Pre-insert a baseline record in each table to verify they remain intact after rollback
    const preExistingZone = await prisma.coverageZone.create({
      data: {
        id: 'pre-existing-zone-id',
        slug: 'pre-existing-unique-zone',
        nameEn: 'Pre-existing Heliopolis Zone',
        nameAr: 'منطقة مصر الجديدة',
        governorate: 'Cairo',
        isActive: true,
      },
    });

    const preExistingCat = await prisma.serviceCategory.create({
      data: {
        id: 'pre-existing-cat-id',
        slug: 'pre-existing-appliance-repair',
        nameEn: 'Appliance Repair',
        nameAr: 'صيانة الأجهزة',
        subtitleEn: 'Fridges and Washers',
        subtitleAr: 'ثلاجات وغسالات',
        iconName: 'kitchen',
        startingPriceEgp: 300,
        sortOrder: 99,
        isActive: true,
      },
    });

    // Controlled constraint conflict:
    // Pre-insert an offering using the primary key ID of the second seed offering ('off-home-safety-bundle'),
    // but with a different unique slug ('pre-existing-custom-offering').
    // When seedCatalog runs:
    // - 5 CoverageZones are inserted into PostgreSQL inside the transaction.
    // - 6 ServiceCategories are inserted into PostgreSQL inside the transaction.
    // - Offering 0 ('summer-ac-deep-clean-gas-refill') is inserted inside the transaction.
    // - Offering 1 ('home-safety-inspection-bundle') attempts insertion with id = 'off-home-safety-bundle',
    //   triggering a real PostgreSQL PRIMARY KEY UNIQUE CONSTRAINT VIOLATION!
    const conflictingOfferingId = EGYPT_SERVICE_OFFERINGS[1].id; // 'off-home-safety-bundle'
    const preExistingOffering = await prisma.serviceOffering.create({
      data: {
        id: conflictingOfferingId,
        categoryId: preExistingCat.id,
        slug: 'pre-existing-custom-offering',
        titleEn: 'Pre-existing Conflicting Offering',
        titleAr: 'خدمة مسبقة متعارضة',
        descriptionEn: 'Existing offering that holds the primary key ID',
        descriptionAr: 'خدمة موجودة مسبقاً تحمل نفس المفتاح الأساسي',
        baseInspectionEgp: 100,
        serviceFeeEgp: 100,
        flatPriceEgp: 200,
        estimatedDurationMins: 45,
      },
    });

    // Verify pre-existing counts before running seedCatalog
    expect(await prisma.coverageZone.count()).toBe(1);
    expect(await prisma.serviceCategory.count()).toBe(1);
    expect(await prisma.serviceOffering.count()).toBe(1);

    // 3. Execute seedCatalog and verify that real PostgreSQL rejects it
    await expect(seedCatalog(prisma)).rejects.toThrow();

    // 4. Verify complete transactional rollback in PostgreSQL:
    // None of the earlier inserts from the transaction persisted!
    // CoverageZones must still be exactly 1 (only the pre-existing record)
    expect(await prisma.coverageZone.count()).toBe(1);
    const zones = await prisma.coverageZone.findMany();
    expect(zones[0].id).toBe(preExistingZone.id);
    expect(zones[0].slug).toBe('pre-existing-unique-zone');

    // ServiceCategories must still be exactly 1 (only the pre-existing record)
    expect(await prisma.serviceCategory.count()).toBe(1);
    const categories = await prisma.serviceCategory.findMany();
    expect(categories[0].id).toBe(preExistingCat.id);
    expect(categories[0].slug).toBe('pre-existing-appliance-repair');

    // ServiceOfferings must still be exactly 1 (seed offering 0 was rolled back!)
    expect(await prisma.serviceOffering.count()).toBe(1);
    const offerings = await prisma.serviceOffering.findMany();
    expect(offerings[0].id).toBe(preExistingOffering.id);
    expect(offerings[0].slug).toBe('pre-existing-custom-offering');
    expect(offerings[0].titleEn).toBe('Pre-existing Conflicting Offering');

    // Explicitly verify that seed offering 0 was NOT committed to the database
    const offering0 = await prisma.serviceOffering.findUnique({
      where: { slug: EGYPT_SERVICE_OFFERINGS[0].slug },
    });
    expect(offering0).toBeNull();
  });
});
