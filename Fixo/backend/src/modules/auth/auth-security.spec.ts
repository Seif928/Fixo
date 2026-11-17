import { HttpException, HttpStatus, UnauthorizedException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { AuthController } from './auth.controller';
import { AuthModule } from './auth.module';
import { AuthService } from './auth.service';
import { validateAuthSecurityConfig } from './config/auth-security.config';
import {
  DevSmsProvider,
  ProductionTelecomSmsProvider,
  SMS_PROVIDER,
} from './sms/sms.provider';
import { hashTokenSha256 } from './utils/jwt-token.util';

describe('Phase 2.1.1 Critical Backend Security Hardening Suite', () => {
  let moduleRef: TestingModule;
  let authController: AuthController;
  let authService: AuthService;
  let memoryStore: InMemoryStoreService;
  let smsProvider: DevSmsProvider;

  const validTestConfig = {
    accessSecret: 'fc6d177aaf07dbda39de2f010ab7f954026f1a34e6f30bbeed9ed531dc09341c',
    refreshSecret: 'dc804b09046d9998a37fd864f4fa830f0f74bc9b35a46710013ce371baa6fbea',
    otpHmacSecret: '694ccf28dbdf0583c830c87b751ad463bb6096d171bff9425419c324c1d76964',
    smsProviderType: 'DEV_SANDBOX_SMS' as const,
    isProduction: false,
    allowDevSms: true,
    allowInMemoryFallback: true,
    allowTestFixedOtp: true,
  };

  beforeEach(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule],
    }).compile();

    authController = moduleRef.get(AuthController);
    authService = moduleRef.get(AuthService);
    memoryStore = moduleRef.get(InMemoryStoreService);
    smsProvider = moduleRef.get<DevSmsProvider>(SMS_PROVIDER);

    authService.configureSecurity(validTestConfig);
    memoryStore.resetToSeedState();
  });

  describe('STEP 2: Cryptographic Secrets & Startup Validation', () => {
    it('fails startup if JWT_ACCESS_SECRET is missing or empty', () => {
      expect(() =>
        validateAuthSecurityConfig({
          JWT_ACCESS_SECRET: '',
          JWT_REFRESH_SECRET: validTestConfig.refreshSecret,
        }),
      ).toThrow(/JWT_ACCESS_SECRET is required/);
    });

    it('fails startup if JWT_ACCESS_SECRET is shorter than 32 characters', () => {
      expect(() =>
        validateAuthSecurityConfig({
          JWT_ACCESS_SECRET: 'short-secret-under-32-chars',
          JWT_REFRESH_SECRET: validTestConfig.refreshSecret,
        }),
      ).toThrow(/must be at least 32 characters long/);
    });

    it('fails startup if JWT_ACCESS_SECRET contains known default or placeholder text', () => {
      expect(() =>
        validateAuthSecurityConfig({
          JWT_ACCESS_SECRET: 'fixo-local-dev-jwt-access-secret-key-2026-eg',
          JWT_REFRESH_SECRET: validTestConfig.refreshSecret,
        }),
      ).toThrow(/known insecure or example value/);
    });

    it('fails startup if JWT_ACCESS_SECRET and JWT_REFRESH_SECRET are identical', () => {
      const sameKey = '32_character_identical_key_string_for_testing!';
      expect(() =>
        validateAuthSecurityConfig({
          JWT_ACCESS_SECRET: sameKey,
          JWT_REFRESH_SECRET: sameKey,
        }),
      ).toThrow(/distinct and independent keys/);
    });

    it('fails startup in production if SMS_PROVIDER_TYPE is DEV_SANDBOX_SMS', () => {
      expect(() =>
        validateAuthSecurityConfig({
          NODE_ENV: 'production',
          JWT_ACCESS_SECRET: validTestConfig.accessSecret,
          JWT_REFRESH_SECRET: validTestConfig.refreshSecret,
          OTP_HMAC_SECRET: validTestConfig.otpHmacSecret,
          SMS_PROVIDER_TYPE: 'DEV_SANDBOX_SMS',
        }),
      ).toThrow(/'DEV_SANDBOX_SMS' is strictly forbidden in production/);
    });

    it('fails startup if SMS_PROVIDER_TYPE is not in allowlist', () => {
      expect(() =>
        validateAuthSecurityConfig({
          JWT_ACCESS_SECRET: validTestConfig.accessSecret,
          JWT_REFRESH_SECRET: validTestConfig.refreshSecret,
          SMS_PROVIDER_TYPE: 'UNKNOWN_TELECOM_GATEWAY' as any,
        }),
      ).toThrow(/Unknown SMS_PROVIDER_TYPE/);
    });

    it('fails startup in production if ALLOW_IN_MEMORY_FALLBACK is true', () => {
      expect(() =>
        validateAuthSecurityConfig({
          NODE_ENV: 'production',
          JWT_ACCESS_SECRET: validTestConfig.accessSecret,
          JWT_REFRESH_SECRET: validTestConfig.refreshSecret,
          OTP_HMAC_SECRET: validTestConfig.otpHmacSecret,
          SMS_PROVIDER_TYPE: 'VICTORYLINK',
          ALLOW_IN_MEMORY_FALLBACK: 'true',
        }),
      ).toThrow(/ALLOW_IN_MEMORY_FALLBACK is strictly forbidden in production/);
    });
  });

  describe('PRIORITY 2: Server-Side Cooldown, Rate Limiting & Atomic Consumption', () => {
    it('enforces 45-second server-side resend cooldown for the same Egyptian number', async () => {
      const phone = '+201011112222';
      const firstReq = await authController.requestOtp({ phone });
      expect(firstReq.challengeId).toBeDefined();

      // Immediate second request within 45s must be rejected by server with 429
      await expect(authController.requestOtp({ phone })).rejects.toMatchObject({
        status: HttpStatus.TOO_MANY_REQUESTS,
        message: expect.stringContaining('Resend cooldown active'),
      });
    });

    it('prevents simultaneous concurrent OTP requests from bypassing the 45s resend cooldown', async () => {
      const phone = '+201088887777';
      const results = await Promise.allSettled([
        authController.requestOtp({ phone }),
        authController.requestOtp({ phone }),
        authController.requestOtp({ phone }),
      ]);

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(2);
      for (const r of rejected) {
        expect((r as PromiseRejectedResult).reason).toMatchObject({
          status: HttpStatus.TOO_MANY_REQUESTS,
        });
      }
    });

    it('never leaks plaintext OTP in API response or public logs', async () => {
      const reqRes = (await authController.requestOtp({
        phone: '+201099998888',
      })) as unknown as Record<string, unknown>;

      expect(reqRes['demoHint']).toBeUndefined();
      expect(reqRes['code']).toBeUndefined();
      expect(reqRes['otpCode']).toBeUndefined();
    });

    it('strictly redacts OTP codes from logs and masks Egyptian mobile numbers', async () => {
      const originalEnv = process.env.NODE_ENV;
      const logSpy = jest.spyOn((smsProvider as any).logger, 'log');
      try {
        process.env.NODE_ENV = 'development';
        const phone = '+201023456789';
        await smsProvider.sendOtpCode(phone, '948215', 300);

        expect(logSpy).toHaveBeenCalled();
        for (const call of logSpy.mock.calls) {
          const loggedMessage = call.join(' ');
          expect(loggedMessage).not.toContain('948215'); // OTP code MUST NOT appear in logs
          expect(loggedMessage).toContain('+2010*****789'); // Phone number MUST be masked
          expect(loggedMessage).toContain('simulated: true');
        }
      } finally {
        process.env.NODE_ENV = originalEnv;
        logSpy.mockRestore();
      }
    });

    it('consumes OTP challenge atomically: single-use only', async () => {
      const phone = '+201099998888';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      expect(code).toBeDefined();

      // First verification succeeds
      const verifyRes = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });
      expect(verifyRes.accessToken).toBeDefined();

      // Second verification on already-consumed challenge MUST fail with 401
      await expect(
        authController.verifyOtp({
          phone,
          code,
          challengeId: reqRes.challengeId,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('prevents concurrent verification requests from independently consuming the same challenge', async () => {
      const phone = '+201066665555';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      const results = await Promise.allSettled([
        authController.verifyOtp({ phone, code, challengeId: reqRes.challengeId }),
        authController.verifyOtp({ phone, code, challengeId: reqRes.challengeId }),
      ]);

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(1);
      expect((rejected[0] as PromiseRejectedResult).reason).toBeInstanceOf(UnauthorizedException);
    });

    it('locks OTP challenge after 5 failed attempts atomically', async () => {
      const phone = '+201077776666';
      const reqRes = await authController.requestOtp({ phone });
      const validCode = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      for (let i = 1; i <= 4; i++) {
        await expect(
          authController.verifyOtp({
            phone,
            code: '000000',
            challengeId: reqRes.challengeId,
          }),
        ).rejects.toThrow(UnauthorizedException);
      }

      // 5th failed attempt triggers 429 lockout
      await expect(
        authController.verifyOtp({
          phone,
          code: '000000',
          challengeId: reqRes.challengeId,
        }),
      ).rejects.toThrow(HttpException);

      // Subsequent attempt even with the CORRECT code is blocked
      await expect(
        authController.verifyOtp({
          phone,
          code: validCode,
          challengeId: reqRes.challengeId,
        }),
      ).rejects.toThrow(HttpException);
    });
  });

  describe('PRIORITY 1: Refresh Token Rotation & Replay Attack Family Revocation', () => {
    it('rotates refresh token and issues replacement pair', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      const initialTokens = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      const rotatedTokens = await authController.refresh({
        refreshToken: initialTokens.refreshToken,
      });

      expect(rotatedTokens.accessToken).toBeDefined();
      expect(rotatedTokens.refreshToken).toBeDefined();
      expect(rotatedTokens.refreshToken).not.toBe(initialTokens.refreshToken);
    });

    it('detects replay attacks on revoked refresh tokens and executes family revocation', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      const initialTokens = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      // Legitimate user rotates token -> R1 is now REVOKED, R2 is ACTIVE
      const legitimateRotation = await authController.refresh({
        refreshToken: initialTokens.refreshToken,
      });

      // An attacker (or leaked token) replays the revoked token R1
      await expect(
        authController.refresh({
          refreshToken: initialTokens.refreshToken,
        }),
      ).rejects.toThrow(/replay attack detected/i);

      // Due to family revocation, the legitimate user's active replacement token R2 is ALSO terminated!
      await expect(
        authController.refresh({
          refreshToken: legitimateRotation.refreshToken,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('persists revocation to storage upon replay detection and verifies token state', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      const initial = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });
      const rotated = await authController.refresh({ refreshToken: initial.refreshToken });

      // Replay old token -> triggers replay detection and family revocation
      await expect(
        authController.refresh({ refreshToken: initial.refreshToken }),
      ).rejects.toThrow(/replay attack/i);

      // Inspect persisted records in store
      const initialHash = hashTokenSha256(initial.refreshToken);
      const rotatedHash = hashTokenSha256(rotated.refreshToken);

      const storedInitial = memoryStore.findRefreshTokenByHash(initialHash);
      const storedRotated = memoryStore.findRefreshTokenByHash(rotatedHash);

      expect(storedInitial?.revokedAt).not.toBeNull();
      expect(storedRotated?.revokedAt).not.toBeNull(); // Persisted state confirmed revoked!
    });

    it('prevents concurrent refresh requests on the same token from creating multiple surviving sessions', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;
      const initialAuth = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      const results = await Promise.allSettled([
        authController.refresh({ refreshToken: initialAuth.refreshToken }),
        authController.refresh({ refreshToken: initialAuth.refreshToken }),
      ]);

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(1);
    });

    it('rejects expired refresh tokens', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      const tokens = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      // Force expiration in storage
      for (const token of (memoryStore as any).refreshTokensByHash.values()) {
        token.expiresAt = new Date(Date.now() - 1000);
      }

      await expect(
        authController.refresh({
          refreshToken: tokens.refreshToken,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('revokes refresh token upon logout', async () => {
      const phone = '+201023456789';
      const reqRes = await authController.requestOtp({ phone });
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      const tokens = await authController.verifyOtp({
        phone,
        code,
        challengeId: reqRes.challengeId,
      });

      const logoutResult = await authController.logout({
        refreshToken: tokens.refreshToken,
      });
      expect(logoutResult.revoked).toBe(true);

      // Subsequent refresh attempt must fail
      await expect(
        authController.refresh({
          refreshToken: tokens.refreshToken,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('PRIORITY 3: Production Telecom SMS Fail-Closed Invariant', () => {
    it('ProductionTelecomSmsProvider fails closed with HTTP 503 and never fabricates delivery', async () => {
      const prodSms = new ProductionTelecomSmsProvider();
      const original = process.env.SMS_PROVIDER_TYPE;
      try {
        process.env.SMS_PROVIDER_TYPE = 'VICTORYLINK';
        await expect(prodSms.sendOtpCode('+201023456789', '123456', 300)).rejects.toMatchObject({
          status: HttpStatus.SERVICE_UNAVAILABLE,
        });
      } finally {
        process.env.SMS_PROVIDER_TYPE = original;
      }
    });

    it('ProductionTelecomSmsProvider rejects unconfigured or unknown provider with HTTP 500', async () => {
      const prodSms = new ProductionTelecomSmsProvider();
      const original = process.env.SMS_PROVIDER_TYPE;
      try {
        process.env.SMS_PROVIDER_TYPE = 'UNKNOWN_PROVIDER';
        await expect(prodSms.sendOtpCode('+201023456789', '123456', 300)).rejects.toMatchObject({
          status: HttpStatus.INTERNAL_SERVER_ERROR,
        });
      } finally {
        process.env.SMS_PROVIDER_TYPE = original;
      }
    });
  });
});
