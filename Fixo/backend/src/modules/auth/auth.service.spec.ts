import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test, TestingModule } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { UsersController } from '../users/users.controller';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthModule } from './auth.module';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { DevSmsProvider, SMS_PROVIDER } from './sms/sms.provider';
import { normalizeEgyptPhone } from './utils/egypt-phone.util';

describe('AuthModule & UsersController (Phase 2 Authentication)', () => {
  let moduleRef: TestingModule;
  let authController: AuthController;
  let authService: AuthService;
  let usersController: UsersController;
  let smsProvider: DevSmsProvider;
  let memoryStore: InMemoryStoreService;
  let jwtGuard: JwtAuthGuard;

  beforeEach(async () => {
    moduleRef = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule, UsersModule],
      controllers: [UsersController],
    }).compile();

    authController = moduleRef.get(AuthController);
    authService = moduleRef.get(AuthService);
    usersController = moduleRef.get(UsersController);
    smsProvider = moduleRef.get<DevSmsProvider>(SMS_PROVIDER);
    memoryStore = moduleRef.get(InMemoryStoreService);
    jwtGuard = moduleRef.get(JwtAuthGuard);

    authService.configureSecurity({
      accessSecret: 'fc6d177aaf07dbda39de2f010ab7f954026f1a34e6f30bbeed9ed531dc09341c',
      refreshSecret: 'dc804b09046d9998a37fd864f4fa830f0f74bc9b35a46710013ce371baa6fbea',
      otpHmacSecret: '694ccf28dbdf0583c830c87b751ad463bb6096d171bff9425419c324c1d76964',
      smsProviderType: 'DEV_SANDBOX_SMS',
      isProduction: false,
      allowDevSms: true,
      allowInMemoryFallback: true,
      allowTestFixedOtp: true,
    });

    memoryStore.resetToSeedState();
  });

  describe('Egyptian phone number normalization (+20)', () => {
    it('normalizes valid Egyptian mobile prefixes (010, 011, 012, 015) to E.164', () => {
      expect(normalizeEgyptPhone('010 2345 6789')).toBe('+201023456789');
      expect(normalizeEgyptPhone('+20 112 345 6789')).toBe('+201123456789');
      expect(normalizeEgyptPhone('00201287776655')).toBe('+201287776655');
      expect(normalizeEgyptPhone('1551234567')).toBe('+201551234567');
    });

    it('rejects non-Egyptian or malformed mobile numbers', () => {
      expect(() => normalizeEgyptPhone('+14155552671')).toThrow(BadRequestException);
      expect(() => normalizeEgyptPhone('01912345678')).toThrow(BadRequestException);
      expect(() => normalizeEgyptPhone('01012345')).toThrow(BadRequestException);
    });
  });

  describe('POST /api/v1/auth/otp/request & verify', () => {
    it('hashes OTP in storage, dispatches via DevSmsProvider, and issues JWT pair on valid code', async () => {
      const reqRes = await authController.requestOtp({ phone: '010 2345 6789' });
      expect(reqRes.phone).toBe('+201023456789');
      expect(reqRes.challengeId).toBeDefined();
      expect(reqRes.resendAvailableInSec).toBe(45);
      expect(reqRes.smsProvider).toBe('DEV_SANDBOX_SMS');

      const storedChallenge = memoryStore.findOtpChallengeById(reqRes.challengeId);
      const sentCode = smsProvider.getLastDispatchedCodeForPhone('+201023456789');
      expect(sentCode).toBe('482910');
      expect(storedChallenge).not.toBeNull();
      // Stored hash must NEVER equal plaintext code
      expect(storedChallenge?.codeHash).not.toBe(sentCode);
      expect(storedChallenge?.codeHash).toHaveLength(64);

      const verifyRes = await authController.verifyOtp({
        phone: '+201023456789',
        code: sentCode!,
        challengeId: reqRes.challengeId,
      });

      expect(verifyRes.accessToken).toBeDefined();
      expect(verifyRes.refreshToken).toBeDefined();
      expect(verifyRes.user.phone).toBe('+201023456789');
      expect(verifyRes.user.fullName).toBe('Salma El-Shazly');
      expect(verifyRes.user.role).toBe(UserRole.CUSTOMER);
    });

    it('strictly assigns CUSTOMER role to new accounts and never escalates privileges', async () => {
      const reqRes = await authController.requestOtp({ phone: '+201559876543' });
      const verifyRes = await authController.verifyOtp({
        phone: '+201559876543',
        code: '482910',
        challengeId: reqRes.challengeId,
      });

      expect(verifyRes.user.role).toBe(UserRole.CUSTOMER);
    });

    it('rejects wrong OTP codes and locks challenge after 5 failed attempts', async () => {
      const reqRes = await authController.requestOtp({ phone: '+201023456789' });

      for (let i = 1; i <= 4; i++) {
        await expect(
          authController.verifyOtp({
            phone: '+201023456789',
            code: '000000',
            challengeId: reqRes.challengeId,
          }),
        ).rejects.toThrow(UnauthorizedException);
      }

      // 5th failed attempt triggers 429 lockout
      await expect(
        authController.verifyOtp({
          phone: '+201023456789',
          code: '000000',
          challengeId: reqRes.challengeId,
        }),
      ).rejects.toThrow(HttpException);

      // Even the correct code is rejected once locked
      await expect(
        authController.verifyOtp({
          phone: '+201023456789',
          code: '482910',
          challengeId: reqRes.challengeId,
        }),
      ).rejects.toThrow(HttpException);
    });

    it('rejects expired OTP challenges', async () => {
      const reqRes = await authController.requestOtp({ phone: '+201023456789' });
      const challenge = memoryStore.findOtpChallengeById(reqRes.challengeId);
      expect(challenge).not.toBeNull();
      challenge!.expiresAt = new Date(Date.now() - 1000);

      await expect(
        authController.verifyOtp({
          phone: '+201023456789',
          code: '482910',
          challengeId: reqRes.challengeId,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('enforces rate limiting after 5 OTP requests within 15 minutes', async () => {
      const phone = '+201112223344';
      for (let i = 0; i < 5; i++) {
        const req = await authController.requestOtp({ phone });
        // Age the challenge past the 45s resend cooldown but within the 15-min window
        const challenge = memoryStore.findOtpChallengeById(req.challengeId);
        if (challenge) {
          challenge.createdAt = new Date(Date.now() - 50 * 1000 * (5 - i));
        }
      }

      await expect(authController.requestOtp({ phone })).rejects.toMatchObject({
        status: HttpStatus.TOO_MANY_REQUESTS,
      });
    });
  });

  describe('POST /api/v1/auth/refresh, logout & GET /api/v1/users/me', () => {
    it('rotates refresh tokens, rejects replay of rotated tokens, and revokes on logout', async () => {
      const otpReq = await authController.requestOtp({ phone: '+201023456789' });
      const initialAuth = await authController.verifyOtp({
        phone: '+201023456789',
        code: '482910',
        challengeId: otpReq.challengeId,
      });

      const rotatedAuth = await authController.refresh({
        refreshToken: initialAuth.refreshToken,
      });
      expect(rotatedAuth.accessToken).toBeDefined();
      expect(rotatedAuth.refreshToken).toBeDefined();
      expect(rotatedAuth.refreshToken).not.toBe(initialAuth.refreshToken);

      // Replaying old refresh token must fail and trigger family revocation
      await expect(
        authController.refresh({ refreshToken: initialAuth.refreshToken }),
      ).rejects.toThrow(UnauthorizedException);

      // Due to family revocation, rotated token is also terminated
      await expect(
        authController.refresh({ refreshToken: rotatedAuth.refreshToken }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('revokes refresh token and terminates session on POST /api/v1/auth/logout', async () => {
      const otpReq = await authController.requestOtp({ phone: '+201023456789' });
      const auth = await authController.verifyOtp({
        phone: '+201023456789',
        code: '482910',
        challengeId: otpReq.challengeId,
      });

      const logoutRes = await authController.logout({
        refreshToken: auth.refreshToken,
      });
      expect(logoutRes.revoked).toBe(true);

      await expect(
        authController.refresh({ refreshToken: auth.refreshToken }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('validates JWT bearer token and returns current user on GET /api/v1/users/me', async () => {
      const otpReq = await authController.requestOtp({ phone: '+201023456789' });
      const auth = await authController.verifyOtp({
        phone: '+201023456789',
        code: '482910',
        challengeId: otpReq.challengeId,
      });

      const payload = authService.verifyAccessToken(auth.accessToken);
      const meResponse = await usersController.getMe(payload);
      expect(meResponse.user.id).toBe('u-salma-01');
      expect(meResponse.user.fullName).toBe('Salma El-Shazly');
      expect(meResponse.user.phone).toBe('+201023456789');
    });

    it('enforces JwtAuthGuard and RolesGuard authorization rules', () => {
      expect(() =>
        jwtGuard.canActivate({
          switchToHttp: () => ({
            getRequest: () => ({ headers: {} }),
          }),
        } as never),
      ).toThrow(UnauthorizedException);

      const reflector = new Reflector();
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN]);
      const rolesGuard = new RolesGuard(reflector);

      expect(() =>
        rolesGuard.canActivate({
          getHandler: () => ({}),
          getClass: () => ({}),
          switchToHttp: () => ({
            getRequest: () => ({
              user: { sub: 'u-1', phone: '+201023456789', role: UserRole.CUSTOMER },
            }),
          }),
        } as never),
      ).toThrow(ForbiddenException);
    });
  });
});
