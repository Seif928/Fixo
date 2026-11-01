import {
  HttpException,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import {
  assertCurrentDatabaseIsTest,
  safeCleanupTestDatabase,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { HealthController } from '../health/health.controller';
import { HealthModule } from '../health/health.module';
import { UsersController } from '../users/users.controller';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthModule } from './auth.module';
import { AuthService } from './auth.service';
import { DevSmsProvider, SMS_PROVIDER } from './sms/sms.provider';
import { hashTokenSha256 } from './utils/jwt-token.util';

/**
 * Real PostgreSQL Integration Test Suite.
 *
 * Runs strictly against an isolated PostgreSQL test database (`fixo_test`)
 * verifying real database connectivity, fail-closed safety guards,
 * advisory locks, transactional atomicity and rollback on replacement failure,
 * single-use OTP constraints, concurrent OTP verification, concurrent refresh,
 * replay racing with refresh rotation, multi-connection rate limiting,
 * and database failure producing readiness HTTP 503.
 */
describe('PostgreSQL Real Database Integration Suite (fixo_test)', () => {
  let moduleRef: TestingModule;
  let prisma: PrismaService;
  let authService: AuthService;
  let authController: AuthController;
  let healthController: HealthController;
  let usersController: UsersController;
  let smsProvider: DevSmsProvider;
  let originalTestDbUrl: string | undefined;
  let originalDbUrl: string | undefined;
  let originalForcePrisma: string | undefined;
  let originalInMemoryFallback: string | undefined;

  const validTestConfig = {
    accessSecret: 'fc6d177aaf07dbda39de2f010ab7f954026f1a34e6f30bbeed9ed531dc09341c',
    refreshSecret: 'dc804b09046d9998a37fd864f4fa830f0f74bc9b35a46710013ce371baa6fbea',
    otpHmacSecret: '694ccf28dbdf0583c830c87b751ad463bb6096d171bff9425419c324c1d76964',
    smsProviderType: 'DEV_SANDBOX_SMS' as const,
    isProduction: false,
    allowDevSms: true,
    allowInMemoryFallback: false,
    allowTestFixedOtp: true,
  };

  beforeAll(async () => {
    originalTestDbUrl = process.env.TEST_DATABASE_URL;
    originalDbUrl = process.env.DATABASE_URL;
    originalForcePrisma = process.env.FIXO_TEST_FORCE_PRISMA;
    originalInMemoryFallback = process.env.ALLOW_IN_MEMORY_FALLBACK;

    // Resolve dedicated TEST_DATABASE_URL
    const resolvedTestDbUrl =
      process.env.TEST_DATABASE_URL ??
      (process.env.DATABASE_URL && process.env.DATABASE_URL.includes('/fixo_dev')
        ? process.env.DATABASE_URL.replace('/fixo_dev', '/fixo_test')
        : 'postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public');

    // 1. Fail-closed safety validation: target MUST be local fixo_test on port 5432
    validateTestDatabaseTarget(resolvedTestDbUrl);

    process.env.TEST_DATABASE_URL = resolvedTestDbUrl;
    process.env.DATABASE_URL = resolvedTestDbUrl;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    moduleRef = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule, UsersModule, HealthModule],
    }).compile();

    await moduleRef.init();

    prisma = moduleRef.get(PrismaService);
    authService = moduleRef.get(AuthService);
    authController = moduleRef.get(AuthController);
    healthController = moduleRef.get(HealthController);
    usersController = moduleRef.get(UsersController);
    smsProvider = moduleRef.get<DevSmsProvider>(SMS_PROVIDER);

    authService.configureSecurity(validTestConfig);

    // Verify real PostgreSQL connection was established
    expect(prisma.isDatabaseConnected()).toBe(true);
    expect(prisma.getStorageMode()).toBe('POSTGRESQL_PRISMA');

    // Fail-closed verification: runtime database must report fixo_test
    const runtimeDb = await assertCurrentDatabaseIsTest(prisma);
    expect(runtimeDb).toBe('fixo_test');
  });

  afterAll(async () => {
    if (prisma && prisma.isDatabaseConnected()) {
      await safeCleanupTestDatabase(prisma);
    }
    if (moduleRef) {
      await moduleRef.close();
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
    if (originalForcePrisma !== undefined) {
      process.env.FIXO_TEST_FORCE_PRISMA = originalForcePrisma;
    } else {
      delete process.env.FIXO_TEST_FORCE_PRISMA;
    }
    if (originalInMemoryFallback !== undefined) {
      process.env.ALLOW_IN_MEMORY_FALLBACK = originalInMemoryFallback;
    } else {
      delete process.env.ALLOW_IN_MEMORY_FALLBACK;
    }
  });

  beforeEach(async () => {
    // Fail-closed cleanup of test tables in verified fixo_test
    await safeCleanupTestDatabase(prisma);
  });

  describe('1. Database Readiness & Database Failure Simulation', () => {
    it('executes a real-time live ping to PostgreSQL and returns ready with POSTGRESQL_PRISMA', async () => {
      const liveCheck = await prisma.checkReadiness();
      expect(liveCheck.ready).toBe(true);
      expect(liveCheck.storageMode).toBe('POSTGRESQL_PRISMA');

      const readinessRes = await healthController.getReadiness();
      expect(readinessRes.status).toBe('ready');
      expect(readinessRes.database.ready).toBe(true);
      expect(readinessRes.database.storageMode).toBe('POSTGRESQL_PRISMA');
    });

    it('produces HTTP 503 SERVICE_UNAVAILABLE when database ping encounters a connection failure', async () => {
      // Simulate database failure during live ping
      const querySpy = jest
        .spyOn(prisma, '$queryRaw')
        .mockRejectedValueOnce(new Error('Simulated database connection failure'));

      try {
        await healthController.getReadiness();
        fail('Expected getReadiness to throw HTTP 503');
      } catch (err) {
        expect(err).toBeInstanceOf(HttpException);
        const httpErr = err as HttpException;
        expect(httpErr.getStatus()).toBe(HttpStatus.SERVICE_UNAVAILABLE);

        const resp = httpErr.getResponse() as any;
        expect(resp.status).toBe('not_ready');
        expect(resp.database.ready).toBe(false);
        expect(resp.database.storageMode).toBe('POSTGRESQL_PRISMA');
        expect(resp.database.reason).toBe('Database connection check failed');
      } finally {
        querySpy.mockRestore();
      }
    });
  });

  describe('2. Real Database OTP Single-Use & User Provisioning', () => {
    it('persists challenge in PostgreSQL, verifies atomically, sets consumedAt, and creates User', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      expect(reqRes.storageMode).toBe('POSTGRESQL_PRISMA');

      // Verify row in PostgreSQL
      const dbChallengeBefore = await prisma.otpChallenge.findUnique({
        where: { id: reqRes.challengeId },
      });
      expect(dbChallengeBefore).not.toBeNull();
      expect(dbChallengeBefore!.phone).toBe(phone);
      expect(dbChallengeBefore!.consumedAt).toBeNull();
      expect(dbChallengeBefore!.attempts).toBe(0);

      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      expect(code).toBeDefined();

      // First verification succeeds
      const verifyRes = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });
      expect(verifyRes.storageMode).toBe('POSTGRESQL_PRISMA');
      expect(verifyRes.user.phone).toBe(phone);
      expect(verifyRes.user.role).toBe(UserRole.CUSTOMER);

      // Verify row in PostgreSQL has consumedAt set
      const dbChallengeAfter = await prisma.otpChallenge.findUnique({
        where: { id: reqRes.challengeId },
      });
      expect(dbChallengeAfter!.consumedAt).not.toBeNull();

      // Verify User record was created in PostgreSQL
      const dbUser = await prisma.user.findUnique({
        where: { phone },
      });
      expect(dbUser).not.toBeNull();
      expect(dbUser!.phone).toBe(phone);
      expect(dbUser!.role).toBe(UserRole.CUSTOMER);

      // Second verification on same consumed challenge MUST fail with HTTP 401
      await expect(
        authController.verifyOtp({
          phone,
          code,
          challengeId: reqRes.challengeId,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('3. Real PostgreSQL Concurrent Verification of the Same OTP', () => {
    it('allows only ONE concurrent verification to succeed and rejects duplicate with HTTP 401', async () => {
      const phone = '+201011112222';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      // Two concurrent verification requests with the SAME valid code
      const results = await Promise.allSettled([
        authController.verifyOtp({ phone, code, challengeId: reqRes.challengeId }),
        authController.verifyOtp({ phone, code, challengeId: reqRes.challengeId }),
      ]);

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      // Exactly ONE must succeed; the racing request must be rejected
      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(1);

      const err = (rejected[0] as PromiseRejectedResult).reason;
      expect(err).toBeInstanceOf(UnauthorizedException);
      expect(err.message).toContain('already been consumed');

      // Check PostgreSQL: consumedAt is set once, exactly 1 User exists, exactly 1 token issued
      const challenge = await prisma.otpChallenge.findUnique({
        where: { id: reqRes.challengeId },
      });
      expect(challenge!.consumedAt).not.toBeNull();

      const userCount = await prisma.user.count({ where: { phone } });
      expect(userCount).toBe(1);

      const tokenCount = await prisma.refreshToken.count();
      expect(tokenCount).toBe(1);
    });
  });

  describe('4. Real PostgreSQL Concurrent OTP Requests (pg_advisory_xact_lock)', () => {
    it('serializes simultaneous OTP requests for the same phone and enforces 45s cooldown atomically', async () => {
      const phone = '+201099998888';

      // Issue 3 simultaneous requests for the EXACT same phone number
      const results = await Promise.allSettled([
        authController.requestOtp({ phone }),
        authController.requestOtp({ phone }),
        authController.requestOtp({ phone }),
      ]);

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      // Exactly ONE request must succeed; concurrent duplicates must be rejected with 429
      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(2);

      for (const r of rejected) {
        const reason = (r as PromiseRejectedResult).reason as HttpException;
        expect(reason.getStatus()).toBe(HttpStatus.TOO_MANY_REQUESTS);
        expect(reason.message).toContain('Resend cooldown active');
      }

      // Check PostgreSQL: exactly ONE row was created in OtpChallenge table
      const count = await prisma.otpChallenge.count({
        where: { phone },
      });
      expect(count).toBe(1);
    });
  });

  describe('5. Rate Limits Across Independent Service / Database Connections', () => {
    it('enforces cooldown and 5-req/15min rate limits across independent connections sharing PostgreSQL', async () => {
      const phone = '+201077778888';

      // Setup a second independent connection to fixo_test
      const secondaryPrisma = new PrismaService();
      // Configure secondary connection explicitly to TEST_DATABASE_URL
      process.env.FIXO_TEST_FORCE_PRISMA = 'true';
      await secondaryPrisma.onModuleInit();
      expect(secondaryPrisma.isDatabaseConnected()).toBe(true);

      const secondarySms = new DevSmsProvider();
      const secondaryAuthService = new AuthService(
        secondaryPrisma,
        new InMemoryStoreService(),
        secondarySms,
      );
      secondaryAuthService.configureSecurity(validTestConfig);

      try {
        // Connection 1: First OTP Request
        const res1 = await authService.requestOtp({ phone });
        expect(res1.phone).toBe(phone);

        // Connection 2: Immediate request from independent connection MUST hit active cooldown
        await expect(
          secondaryAuthService.requestOtp({ phone }),
        ).rejects.toThrow(
          expect.objectContaining({
            status: HttpStatus.TOO_MANY_REQUESTS,
            message: expect.stringContaining('Resend cooldown active'),
          }),
        );

        // Fast-forward cooldown by updating createdAt in PostgreSQL
        await prisma.$executeRawUnsafe(
          'UPDATE "OtpChallenge" SET "createdAt" = NOW() - INTERVAL \'50 seconds\' WHERE phone = $1',
          phone,
        );

        // Connection 2: Now succeeds after cooldown elapsed
        const res2 = await secondaryAuthService.requestOtp({ phone });
        expect(res2.phone).toBe(phone);

        // Simulate reaching the 5-request limit by adding 3 more challenges in PostgreSQL
        for (let i = 0; i < 3; i++) {
          await prisma.otpChallenge.create({
            data: {
              phone,
              codeHash: 'simulated-hash-' + i,
              expiresAt: new Date(Date.now() + 300000),
              createdAt: new Date(Date.now() - (60 + i * 10) * 1000),
            },
          });
        }

        // Total challenges for this phone in the last 15 mins is now 5
        const currentCount = await prisma.otpChallenge.count({ where: { phone } });
        expect(currentCount).toBe(5);

        // Fast-forward latest challenge past cooldown
        await prisma.$executeRawUnsafe(
          'UPDATE "OtpChallenge" SET "createdAt" = NOW() - INTERVAL \'50 seconds\' WHERE id = $1',
          res2.challengeId,
        );

        // Connection 2: Attempting 6th request MUST be rejected by distributed 15-minute rate limit
        await expect(
          secondaryAuthService.requestOtp({ phone }),
        ).rejects.toThrow(
          expect.objectContaining({
            status: HttpStatus.TOO_MANY_REQUESTS,
            message: expect.stringContaining('Too many OTP requests'),
          }),
        );
      } finally {
        await secondaryPrisma.onModuleDestroy();
      }
    });
  });

  describe('6. Real PostgreSQL Refresh Token Rotation', () => {
    it('claims old token and inserts replacement in the same transaction', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      const initialAuth = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      const initialHash = hashTokenSha256(initialAuth.refreshToken);
      const initialDbToken = await prisma.refreshToken.findUnique({
        where: { tokenHash: initialHash },
      });
      expect(initialDbToken).not.toBeNull();
      expect(initialDbToken!.revokedAt).toBeNull();

      // Rotate token
      const rotatedAuth = await authController.refresh({
        refreshToken: initialAuth.refreshToken,
      });
      expect(rotatedAuth.refreshToken).not.toBe(initialAuth.refreshToken);

      // Verify in PostgreSQL that old token is now REVOKED
      const updatedOldToken = await prisma.refreshToken.findUnique({
        where: { tokenHash: initialHash },
      });
      expect(updatedOldToken!.revokedAt).not.toBeNull();

      // Verify in PostgreSQL that new replacement token is ACTIVE
      const newHash = hashTokenSha256(rotatedAuth.refreshToken);
      const newDbToken = await prisma.refreshToken.findUnique({
        where: { tokenHash: newHash },
      });
      expect(newDbToken).not.toBeNull();
      expect(newDbToken!.revokedAt).toBeNull();
    });
  });

  describe('7. AuthService.refreshTokens Rollback Verification (Forced Replacement Persistence Failure)', () => {
    it('rolls back token revocation when replacement persistence fails: old token remains active and no replacement persists', async () => {
      const phone = '+201044443333';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      const initialAuth = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      const initialHash = hashTokenSha256(initialAuth.refreshToken);
      const initialDbToken = await prisma.refreshToken.findUnique({
        where: { tokenHash: initialHash },
      });
      expect(initialDbToken).not.toBeNull();
      expect(initialDbToken!.revokedAt).toBeNull();

      // Intercept the interactive transaction: let old token claim execute, but force replacement persistence to fail
      const originalTx = prisma.$transaction.bind(prisma);
      const txSpy = jest
        .spyOn(prisma, '$transaction')
        .mockImplementation(async (callback: any, options: any) => {
          return originalTx(async (tx: any) => {
            const originalCreate = tx.refreshToken.create.bind(tx.refreshToken);
            tx.refreshToken.create = jest.fn().mockImplementation(async () => {
              throw new Error('FORCED DATABASE WRITE FAILURE: Simulated disk/constraint error on replacement create');
            });
            return callback(tx);
          }, options);
        });

      // Call AuthService.refreshTokens: must fail because replacement creation throws inside transaction
      await expect(
        authService.refreshTokens({ refreshToken: initialAuth.refreshToken }),
      ).rejects.toThrow('FORCED DATABASE WRITE FAILURE');

      txSpy.mockRestore();

      // CRITICAL VERIFICATION: In real PostgreSQL, verify that transaction rolled back cleanly!
      // 1. The old token must STILL BE ACTIVE (revokedAt is null)
      const oldTokenAfterRollback = await prisma.refreshToken.findUnique({
        where: { tokenHash: initialHash },
      });
      expect(oldTokenAfterRollback).not.toBeNull();
      expect(oldTokenAfterRollback!.revokedAt).toBeNull();

      // 2. No replacement token was persisted in PostgreSQL
      const allTokensForUser = await prisma.refreshToken.findMany({
        where: { userId: initialAuth.user.id },
      });
      expect(allTokensForUser).toHaveLength(1);
      expect(allTokensForUser[0].tokenHash).toBe(initialHash);

      // 3. The old token remains fully usable: subsequent legitimate refresh succeeds!
      const successfulRefresh = await authService.refreshTokens({
        refreshToken: initialAuth.refreshToken,
      });
      expect(successfulRefresh.refreshToken).toBeDefined();
      expect(successfulRefresh.refreshToken).not.toBe(initialAuth.refreshToken);

      // Now old token is revoked and new replacement is active
      const finalOldToken = await prisma.refreshToken.findUnique({
        where: { tokenHash: initialHash },
      });
      expect(finalOldToken!.revokedAt).not.toBeNull();
    });
  });

  describe('8. Real PostgreSQL Concurrent Refresh Using the Same Token', () => {
    it('prevents duplicate token generation when two concurrent requests refresh with the exact same token', async () => {
      const phone = '+201066665555';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      const initialAuth = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      // Concurrently execute two refresh requests using the identical active refresh token
      const results = await Promise.allSettled([
        authService.refreshTokens({ refreshToken: initialAuth.refreshToken }),
        authService.refreshTokens({ refreshToken: initialAuth.refreshToken }),
      ]);

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      // Both CANNOT succeed: at most 1 can succeed
      expect(fulfilled.length).toBeLessThanOrEqual(1);

      // At least one request was rejected
      expect(rejected.length).toBeGreaterThanOrEqual(1);

      for (const rej of rejected) {
        const err = (rej as PromiseRejectedResult).reason;
        // Either caught by replay detection or updateMany zero-claim check
        expect(err).toBeInstanceOf(UnauthorizedException);
      }

      // Check PostgreSQL: Old token is revoked
      const oldHash = hashTokenSha256(initialAuth.refreshToken);
      const oldDbToken = await prisma.refreshToken.findUnique({
        where: { tokenHash: oldHash },
      });
      expect(oldDbToken!.revokedAt).not.toBeNull();

      // Verify that no duplicate active refresh tokens were created
      const activeTokens = await prisma.refreshToken.findMany({
        where: { userId: initialAuth.user.id, revokedAt: null },
      });
      // Active tokens must be at most 1 (or 0 if replay detection triggered family revocation)
      expect(activeTokens.length).toBeLessThanOrEqual(1);
    });
  });

  describe('9. Replay Racing with Refresh Rotation (Family Revocation Race)', () => {
    it('terminates all user sessions when a revoked token replay races with legitimate refresh rotation', async () => {
      const phone = '+201088889999';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      const initialAuth = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      // Legitimate rotation: TokenA -> TokenB
      const rotatedAuth = await authService.refreshTokens({
        refreshToken: initialAuth.refreshToken,
      });
      const tokenA = initialAuth.refreshToken;
      const tokenB = rotatedAuth.refreshToken;

      // TokenA is now revoked; TokenB is currently active
      const tokenAHash = hashTokenSha256(tokenA);
      const tokenAInDb = await prisma.refreshToken.findUnique({
        where: { tokenHash: tokenAHash },
      });
      expect(tokenAInDb!.revokedAt).not.toBeNull();

      // RACE CONDITION: Concurrently execute:
      // 1. Legitimate user refreshing active TokenB
      // 2. Malicious actor replaying already-revoked TokenA
      const [legitResult, replayResult] = await Promise.allSettled([
        authService.refreshTokens({ refreshToken: tokenB }),
        authService.refreshTokens({ refreshToken: tokenA }),
      ]);

      // Replay request MUST be rejected with replay attack detection
      expect(replayResult.status).toBe('rejected');
      const replayErr = (replayResult as PromiseRejectedResult).reason;
      expect(replayErr).toBeInstanceOf(UnauthorizedException);
      expect(replayErr.message).toMatch(/replay attack detected/i);

      // CRITICAL SECURITY ASSERTION:
      // Because TokenA triggered replay detection and family revocation,
      // ALL active tokens for this user must now be revoked in PostgreSQL!
      const activeTokensInDb = await prisma.refreshToken.findMany({
        where: { userId: initialAuth.user.id, revokedAt: null },
      });
      expect(activeTokensInDb).toHaveLength(0);

      // Verify that any subsequent refresh attempt by either party is rejected
      await expect(
        authService.refreshTokens({ refreshToken: tokenB }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('10. Fail-Closed Unsafe Database Target Rejection in Integration Context', () => {
    it('refuses to perform destructive cleanup on any database other than fixo_test', async () => {
      // Create mock PrismaService connected to fixo_dev
      const mockPrisma = {
        isDatabaseConnected: () => true,
        $queryRaw: jest.fn().mockResolvedValue([{ current_database: 'fixo_dev' }]),
        $executeRawUnsafe: jest.fn(),
      };

      await expect(
        safeCleanupTestDatabase(mockPrisma as any, {
          testDatabaseUrl: 'postgresql://fixo_user:pass@localhost:5432/fixo_dev',
        }),
      ).rejects.toThrow(/Refusing to target database "fixo_dev"/i);

      expect(mockPrisma.$executeRawUnsafe).toHaveBeenCalledTimes(0);
    });
  });
});
