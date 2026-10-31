import {
  HttpException,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
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
 * verifying real database connectivity, advisory locks, transactions,
 * single-use OTP constraints, refresh token rotation, replay revocation persistence,
 * rollback behavior, and readiness probes.
 */
describe('PostgreSQL Real Database Integration Suite (fixo_test)', () => {
  let moduleRef: TestingModule;
  let prisma: PrismaService;
  let authService: AuthService;
  let authController: AuthController;
  let healthController: HealthController;
  let usersController: UsersController;
  let smsProvider: DevSmsProvider;
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
    originalDbUrl = process.env.DATABASE_URL;
    originalForcePrisma = process.env.FIXO_TEST_FORCE_PRISMA;
    originalInMemoryFallback = process.env.ALLOW_IN_MEMORY_FALLBACK;

    // Direct tests to the dedicated test database
    if (process.env.DATABASE_URL && process.env.DATABASE_URL.includes('/fixo_dev')) {
      process.env.DATABASE_URL = process.env.DATABASE_URL.replace('/fixo_dev', '/fixo_test');
    }
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
  });

  afterAll(async () => {
    if (prisma && prisma.isDatabaseConnected()) {
      await prisma.$executeRawUnsafe(
        'TRUNCATE TABLE "RefreshToken", "OtpChallenge", "User" CASCADE',
      );
    }
    if (moduleRef) {
      await moduleRef.close();
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
    // Clean test tables in fixo_test before each test
    await prisma.$executeRawUnsafe(
      'TRUNCATE TABLE "RefreshToken", "OtpChallenge", "User" CASCADE',
    );
  });

  describe('1. Real Database Readiness Probe', () => {
    it('executes a real-time live ping to PostgreSQL and returns ready with POSTGRESQL_PRISMA', async () => {
      const liveCheck = await prisma.checkReadiness();
      expect(liveCheck.ready).toBe(true);
      expect(liveCheck.storageMode).toBe('POSTGRESQL_PRISMA');

      const readinessRes = await healthController.getReadiness();
      expect(readinessRes.status).toBe('ready');
      expect(readinessRes.database.ready).toBe(true);
      expect(readinessRes.database.storageMode).toBe('POSTGRESQL_PRISMA');
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

  describe('3. Real PostgreSQL Concurrent OTP Requests (pg_advisory_xact_lock)', () => {
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

  describe('4. Real PostgreSQL Refresh Token Rotation', () => {
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

  describe('5. Real PostgreSQL Replay Revocation Persistence', () => {
    it('commits family revocation to PostgreSQL on token replay before throwing UnauthorizedException', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      const initialAuth = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      // Legitimate user rotates token: initial is revoked, rotated is active
      const rotatedAuth = await authController.refresh({
        refreshToken: initialAuth.refreshToken,
      });

      const rotatedHash = hashTokenSha256(rotatedAuth.refreshToken);
      const rotatedDbBefore = await prisma.refreshToken.findUnique({
        where: { tokenHash: rotatedHash },
      });
      expect(rotatedDbBefore!.revokedAt).toBeNull(); // Active before replay

      // Attacker replays initial token (which is already revoked)
      await expect(
        authController.refresh({
          refreshToken: initialAuth.refreshToken,
        }),
      ).rejects.toThrow(/replay attack detected/i);

      // Verify that family revocation PERSISTED in PostgreSQL!
      const rotatedDbAfter = await prisma.refreshToken.findUnique({
        where: { tokenHash: rotatedHash },
      });
      expect(rotatedDbAfter!.revokedAt).not.toBeNull(); // Confirmed revoked in real PostgreSQL!

      // Legitimate user's active token is now terminated
      await expect(
        authController.refresh({
          refreshToken: rotatedAuth.refreshToken,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('6. Real PostgreSQL Transaction Rollback Verification', () => {
    it('rolls back database modifications when a transaction encounters an error', async () => {
      const user = await prisma.user.create({
        data: {
          phone: '+201055554444',
          fullName: 'Rollback Test User',
          role: UserRole.CUSTOMER,
        },
      });

      const tokenHash = 'test-rollback-token-hash-123456789';
      const expiresAt = new Date(Date.now() + 60000);

      // Execute a transaction that attempts to insert a token and then throws an error
      await expect(
        prisma.$transaction(async (tx) => {
          await tx.refreshToken.create({
            data: {
              userId: user.id,
              tokenHash,
              expiresAt,
            },
          });
          throw new Error('Simulated failure inside transaction');
        }),
      ).rejects.toThrow('Simulated failure inside transaction');

      // Verify that the token was NOT persisted in PostgreSQL due to ROLLBACK
      const persistedToken = await prisma.refreshToken.findUnique({
        where: { tokenHash },
      });
      expect(persistedToken).toBeNull();
    });
  });
});

