import { PrismaService } from './prisma.service';

export interface ValidatedTestDatabaseTarget {
  host: string;
  port: number;
  database: 'fixo_test';
}

/**
 * Validates that a database URL strictly targets the local, isolated
 * `fixo_test` PostgreSQL database on localhost:5432.
 *
 * Fail-closed security rule:
 * Rejects missing URLs, non-local hosts, non-5432 ports, or any database
 * name other than `fixo_test` (such as `fixo_dev`, `production`, `postgres`, etc.).
 */
export function validateTestDatabaseTarget(
  databaseUrl?: string,
): ValidatedTestDatabaseTarget {
  if (!databaseUrl || databaseUrl.trim() === '') {
    throw new Error(
      'FAIL-CLOSED DATABASE SAFETY: TEST_DATABASE_URL is missing or empty. Refusing to connect or execute tests without explicit test target.',
    );
  }

  let parsed: URL;
  try {
    parsed = new URL(databaseUrl);
  } catch (err) {
    throw new Error(
      `FAIL-CLOSED DATABASE SAFETY: Invalid TEST_DATABASE_URL format: ${err instanceof Error ? err.message : 'Unknown parse error'}`,
    );
  }

  // 1. Validate protocol
  if (parsed.protocol !== 'postgresql:' && parsed.protocol !== 'postgres:') {
    throw new Error(
      `FAIL-CLOSED DATABASE SAFETY: Unsupported database protocol "${parsed.protocol}". Expected "postgresql:".`,
    );
  }

  // 2. Validate host (strictly localhost / 127.0.0.1)
  const host = parsed.hostname.toLowerCase();
  const allowedHosts = ['localhost', '127.0.0.1'];
  if (!allowedHosts.includes(host)) {
    throw new Error(
      `FAIL-CLOSED DATABASE SAFETY: Unsafe test database host "${host}". Only "localhost" or "127.0.0.1" is permitted for test operations.`,
    );
  }

  // 3. Validate port (must be 5432)
  const port = parsed.port ? parseInt(parsed.port, 10) : 5432;
  if (port !== 5432) {
    throw new Error(
      `FAIL-CLOSED DATABASE SAFETY: Unexpected test database port "${port}". Expected port 5432.`,
    );
  }

  // 4. Validate database name (strictly fixo_test)
  const dbName = parsed.pathname.replace(/^\//, '').split('?')[0];
  if (dbName !== 'fixo_test') {
    throw new Error(
      `FAIL-CLOSED DATABASE SAFETY: Refusing to target database "${dbName}". Destructive test operations are strictly limited to "fixo_test".`,
    );
  }

  return {
    host,
    port,
    database: 'fixo_test',
  };
}

/**
 * Queries PostgreSQL directly to verify the active runtime database
 * name is `fixo_test` before performing any cleanup.
 */
export async function assertCurrentDatabaseIsTest(
  prisma: Pick<PrismaService, '$queryRaw'>,
): Promise<string> {
  const rows = await prisma.$queryRaw<Array<{ current_database: string }>>`
    SELECT current_database() AS current_database;
  `;

  const currentDb = rows[0]?.current_database;
  if (currentDb !== 'fixo_test') {
    throw new Error(
      `FAIL-CLOSED INTEGRITY CHECK FAILED: Connected runtime database is "${currentDb}", NOT "fixo_test". Refusing to perform destructive cleanup!`,
    );
  }

  return currentDb;
}

/**
 * Performs fail-closed destructive cleanup of test tables strictly inside
 * the verified `fixo_test` database.
 */
export async function safeCleanupTestDatabase(
  prisma: Pick<PrismaService, '$queryRaw' | '$executeRawUnsafe' | 'isDatabaseConnected'>,
  options?: { testDatabaseUrl?: string },
): Promise<void> {
  // Guard 1: Verify test database URL configuration
  const targetUrl =
    options?.testDatabaseUrl ??
    process.env.TEST_DATABASE_URL ??
    process.env.DATABASE_URL;

  validateTestDatabaseTarget(targetUrl);

  // Guard 2: Verify active connection status
  if (!prisma.isDatabaseConnected()) {
    return;
  }

  // Guard 3: Verify PostgreSQL runtime database identity
  await assertCurrentDatabaseIsTest(prisma);

  // Execute safe truncation only after all three guards have passed
  await prisma.$executeRawUnsafe(
    'TRUNCATE TABLE "RefreshToken", "OtpChallenge", "User" CASCADE;',
  );
}
