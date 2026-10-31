import {
  assertCurrentDatabaseIsTest,
  safeCleanupTestDatabase,
  validateTestDatabaseTarget,
} from './test-database-safety.util';

describe('Database Safety Validation (Fail-Closed)', () => {
  describe('validateTestDatabaseTarget', () => {
    it('throws fail-closed error when TEST_DATABASE_URL is missing or empty', () => {
      expect(() => validateTestDatabaseTarget(undefined)).toThrow(
        /TEST_DATABASE_URL is missing or empty/i,
      );
      expect(() => validateTestDatabaseTarget('')).toThrow(
        /TEST_DATABASE_URL is missing or empty/i,
      );
      expect(() => validateTestDatabaseTarget('   ')).toThrow(
        /TEST_DATABASE_URL is missing or empty/i,
      );
    });

    it('throws fail-closed error for non-postgresql protocols', () => {
      expect(() =>
        validateTestDatabaseTarget('mysql://root:password@localhost:5432/fixo_test'),
      ).toThrow(/Unsupported database protocol/i);
      expect(() =>
        validateTestDatabaseTarget('http://localhost:5432/fixo_test'),
      ).toThrow(/Unsupported database protocol/i);
    });

    it('rejects remote or non-local hosts to protect staging and production environments', () => {
      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@staging-db.fixo.eg:5432/fixo_test',
        ),
      ).toThrow(/Unsafe test database host/i);

      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@192.168.1.100:5432/fixo_test',
        ),
      ).toThrow(/Unsafe test database host/i);

      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@prod-cluster.rds.amazonaws.com:5432/fixo_test',
        ),
      ).toThrow(/Unsafe test database host/i);
    });

    it('rejects unexpected database ports', () => {
      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@localhost:5433/fixo_test',
        ),
      ).toThrow(/Unexpected test database port "5433"/i);

      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@127.0.0.1:3306/fixo_test',
        ),
      ).toThrow(/Unexpected test database port "3306"/i);
    });

    it('strictly rejects any database name other than fixo_test (e.g. fixo_dev, postgres)', () => {
      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@localhost:5432/fixo_dev',
        ),
      ).toThrow(/Refusing to target database "fixo_dev"/i);

      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@localhost:5432/postgres',
        ),
      ).toThrow(/Refusing to target database "postgres"/i);

      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:pass@localhost:5432/production',
        ),
      ).toThrow(/Refusing to target database "production"/i);
    });

    it('accepts valid local fixo_test targets', () => {
      const result1 = validateTestDatabaseTarget(
        'postgresql://fixo_user:pass@localhost:5432/fixo_test?schema=public',
      );
      expect(result1).toEqual({
        host: 'localhost',
        port: 5432,
        database: 'fixo_test',
      });

      const result2 = validateTestDatabaseTarget(
        'postgresql://fixo_user:pass@127.0.0.1:5432/fixo_test',
      );
      expect(result2).toEqual({
        host: '127.0.0.1',
        port: 5432,
        database: 'fixo_test',
      });
    });
  });

  describe('assertCurrentDatabaseIsTest', () => {
    it('returns fixo_test when PostgreSQL reports current_database() is fixo_test', async () => {
      const mockPrisma = {
        $queryRaw: jest.fn().mockResolvedValue([{ current_database: 'fixo_test' }]),
      };

      const result = await assertCurrentDatabaseIsTest(mockPrisma as any);
      expect(result).toBe('fixo_test');
      expect(mockPrisma.$queryRaw).toHaveBeenCalledTimes(1);
    });

    it('throws fail-closed error if connected database is fixo_dev or any other database', async () => {
      const mockPrisma = {
        $queryRaw: jest.fn().mockResolvedValue([{ current_database: 'fixo_dev' }]),
      };

      await expect(assertCurrentDatabaseIsTest(mockPrisma as any)).rejects.toThrow(
        /Connected runtime database is "fixo_dev", NOT "fixo_test"/i,
      );
    });
  });

  describe('safeCleanupTestDatabase (Fail-Closed Execution)', () => {
    it('NEVER executes truncate if the database URL points to fixo_dev', async () => {
      const mockPrisma = {
        isDatabaseConnected: jest.fn().mockReturnValue(true),
        $queryRaw: jest.fn(),
        $executeRawUnsafe: jest.fn(),
      };

      await expect(
        safeCleanupTestDatabase(mockPrisma as any, {
          testDatabaseUrl:
            'postgresql://fixo_user:pass@localhost:5432/fixo_dev',
        }),
      ).rejects.toThrow(/Refusing to target database "fixo_dev"/i);

      expect(mockPrisma.$executeRawUnsafe).toHaveBeenCalledTimes(0);
      expect(mockPrisma.$queryRaw).toHaveBeenCalledTimes(0);
    });

    it('NEVER executes truncate if the host is non-local', async () => {
      const mockPrisma = {
        isDatabaseConnected: jest.fn().mockReturnValue(true),
        $queryRaw: jest.fn(),
        $executeRawUnsafe: jest.fn(),
      };

      await expect(
        safeCleanupTestDatabase(mockPrisma as any, {
          testDatabaseUrl:
            'postgresql://fixo_user:pass@remote-staging:5432/fixo_test',
        }),
      ).rejects.toThrow(/Unsafe test database host "remote-staging"/i);

      expect(mockPrisma.$executeRawUnsafe).toHaveBeenCalledTimes(0);
      expect(mockPrisma.$queryRaw).toHaveBeenCalledTimes(0);
    });

    it('NEVER executes truncate if runtime database check returns fixo_dev', async () => {
      const mockPrisma = {
        isDatabaseConnected: jest.fn().mockReturnValue(true),
        $queryRaw: jest.fn().mockResolvedValue([{ current_database: 'fixo_dev' }]),
        $executeRawUnsafe: jest.fn(),
      };

      await expect(
        safeCleanupTestDatabase(mockPrisma as any, {
          testDatabaseUrl:
            'postgresql://fixo_user:pass@localhost:5432/fixo_test',
        }),
      ).rejects.toThrow(/NOT "fixo_test"/i);

      expect(mockPrisma.$executeRawUnsafe).toHaveBeenCalledTimes(0);
    });

    it('safely executes truncate ONLY when all safety guards pass', async () => {
      const mockPrisma = {
        isDatabaseConnected: jest.fn().mockReturnValue(true),
        $queryRaw: jest.fn().mockResolvedValue([{ current_database: 'fixo_test' }]),
        $executeRawUnsafe: jest.fn().mockResolvedValue(1),
      };

      await safeCleanupTestDatabase(mockPrisma as any, {
        testDatabaseUrl:
          'postgresql://fixo_user:pass@localhost:5432/fixo_test',
      });

      expect(mockPrisma.$queryRaw).toHaveBeenCalledTimes(1);
      expect(mockPrisma.$executeRawUnsafe).toHaveBeenCalledTimes(1);
      expect(mockPrisma.$executeRawUnsafe).toHaveBeenCalledWith(
        'TRUNCATE TABLE "RefreshToken", "OtpChallenge", "User" CASCADE;',
      );
    });
  });
});
