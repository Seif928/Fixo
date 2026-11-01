import { PrismaClient } from '@prisma/client';
import { seedCatalog } from './seed-catalog';
import {
  assertCurrentDatabaseIsTest,
  safeCleanupBookingTestTables,
  validateTestDatabaseTarget,
} from './test-database-safety.util';

/**
 * Prepares the local `fixo_test` database for the Customer Booking E2E verification:
 * 1. Validates strictly that the target database is `fixo_test` on localhost:5432.
 * 2. Cleans up any leftover bookings, addresses, or test users.
 * 3. Idempotently seeds the catalog (zones, categories, offerings).
 */
async function main(): Promise<void> {
  const dbUrl = process.env.DATABASE_URL ?? process.env.TEST_DATABASE_URL;
  validateTestDatabaseTarget(dbUrl);

  const prisma = new PrismaClient({
    datasources: { db: { url: dbUrl } },
  });

  try {
    await prisma.$connect();
    await assertCurrentDatabaseIsTest(prisma);

    console.log('[E2E PREPARE] Cleaning test bookings, addresses, and users in fixo_test...');
    await safeCleanupBookingTestTables(
      {
        $queryRaw: prisma.$queryRaw.bind(prisma),
        $executeRawUnsafe: prisma.$executeRawUnsafe.bind(prisma),
        isDatabaseConnected: () => true,
      },
      { testDatabaseUrl: dbUrl },
    );

    console.log('[E2E PREPARE] Seeding catalog in fixo_test...');
    const seedResult = await seedCatalog(prisma);
    console.log(
      `[E2E PREPARE] Catalog ready: ${seedResult.coverageZones.total} zones, ${seedResult.serviceCategories.total} categories, ${seedResult.serviceOfferings.total} offerings.`,
    );
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  void main();
}
