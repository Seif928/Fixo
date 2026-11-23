import { ExecutionContext, HttpException, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import { createHmac } from 'crypto';
import {
  isAllowedCorsOrigin,
  shouldExposeSwaggerDocs,
} from './config/http-security.config';
import { RATE_LIMIT_KEY, RateLimitGuard } from './guards/rate-limit.guard';
import { isSafePhotoReference } from './validators/safe-photo-url.validator';
import { signFixoJwt, verifyFixoJwt } from '../modules/auth/utils/jwt-token.util';
import { JwtAuthGuard } from '../modules/auth/guards/jwt-auth.guard';
import {
  signPrivateUploadAccessToken,
  verifyPrivateUploadAccessToken,
} from '../modules/bookings/private-upload.util';
import { AuthService } from '../modules/auth/auth.service';
import { InMemoryStoreService } from '../prisma/in-memory-store.service';
import { DevSmsProvider } from '../modules/auth/sms/sms.provider';

describe('FIXO Security Hardening Regression Suite', () => {
  beforeEach(() => {
    RateLimitGuard.clearAllForTests();
  });

  describe('RateLimitGuard', () => {
    function buildCtx(ip: string, body: Record<string, unknown> = {}): {
      ctx: ExecutionContext;
      headers: Record<string, string>;
    } {
      const headers: Record<string, string> = {};
      const ctx = {
        getHandler: () => function signIn() {},
        getClass: () => class DummyController {},
        switchToHttp: () => ({
          getRequest: () => ({
            method: 'POST',
            baseUrl: '/api/v1/auth',
            path: '/phone-password',
            ip,
            body,
          }),
          getResponse: () => ({
            setHeader: (k: string, v: string) => {
              headers[k] = v;
            },
          }),
        }),
      } as unknown as ExecutionContext;
      return { ctx, headers };
    }

    it('blocks brute force bursts by IP with HTTP 429 and Retry-After', () => {
      const reflector = {
        getAllAndOverride: () => ({ max: 3, windowMs: 60_000, keyBy: 'ip' as const }),
      } as unknown as Reflector;
      const guard = new RateLimitGuard(reflector);

      for (let i = 0; i < 3; i++) {
        const { ctx, headers } = buildCtx('203.0.113.10');
        expect(guard.canActivate(ctx)).toBe(true);
        expect(headers['X-RateLimit-Limit']).toBe('3');
      }

      const { ctx, headers } = buildCtx('203.0.113.10');
      expect(() => guard.canActivate(ctx)).toThrow(HttpException);
      try {
        guard.canActivate(ctx);
      } catch (err: any) {
        expect(err.getStatus()).toBe(429);
      }
      expect(Number(headers['Retry-After'])).toBeGreaterThanOrEqual(1);
    });

    it('blocks repeated password guesses for the same normalized phone across rotating IPs', () => {
      const reflector = {
        getAllAndOverride: () => ({
          max: 10,
          windowMs: 60_000,
          keyBy: 'phoneAndIp' as const,
          phoneMax: 2,
          phoneWindowMs: 60_000,
        }),
      } as unknown as Reflector;
      const guard = new RateLimitGuard(reflector);

      expect(
        guard.canActivate(buildCtx('198.51.100.1', { phone: '01012345678' }).ctx),
      ).toBe(true);
      expect(
        guard.canActivate(buildCtx('198.51.100.2', { phone: '+201012345678' }).ctx),
      ).toBe(true);
      expect(() =>
        guard.canActivate(buildCtx('198.51.100.3', { phone: '00201012345678' }).ctx),
      ).toThrow(HttpException);
    });
  });

  describe('HTTP Security Config (CORS & Swagger)', () => {
    it('allows FIXO web origins and non-browser clients, but rejects untrusted origins in production', () => {
      const prodEnv = { NODE_ENV: 'production' } as NodeJS.ProcessEnv;
      expect(isAllowedCorsOrigin(undefined, prodEnv)).toBe(true);
      expect(isAllowedCorsOrigin('https://fixo-web-blue.vercel.app', prodEnv)).toBe(true);
      expect(isAllowedCorsOrigin('https://fixo-home-services-6507.web.app', prodEnv)).toBe(true);
      expect(isAllowedCorsOrigin('https://evil-phish.example', prodEnv)).toBe(false);
      expect(isAllowedCorsOrigin('http://localhost:3000', prodEnv)).toBe(false);
      expect(isAllowedCorsOrigin('http://localhost:3000', { NODE_ENV: 'development' })).toBe(true);
    });

    it('disables Swagger docs in production unless explicitly opted in', () => {
      expect(shouldExposeSwaggerDocs({ NODE_ENV: 'production' })).toBe(false);
      expect(
        shouldExposeSwaggerDocs({
          NODE_ENV: 'production',
          ENABLE_SWAGGER_DOCS: 'true',
        }),
      ).toBe(true);
      expect(shouldExposeSwaggerDocs({ NODE_ENV: 'development' })).toBe(true);
    });
  });

  describe('JWT Header & Active Account Enforcement', () => {
    const secret = '0123456789abcdef0123456789abcdef';

    it('rejects JWTs with non-HS256 headers even if signed with the HMAC key', () => {
      const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
      const payload = Buffer.from(
        JSON.stringify({
          sub: 'u1',
          phone: '+201012345678',
          role: 'CUSTOMER',
          type: 'access',
          jti: 'jti-1',
          iat: Math.floor(Date.now() / 1000),
          exp: Math.floor(Date.now() / 1000) + 300,
        }),
      ).toString('base64url');
      const sig = createHmac('sha256', secret)
        .update(`${header}.${payload}`)
        .digest('base64url');

      expect(() => verifyFixoJwt(`${header}.${payload}.${sig}`, secret)).toThrow(
        UnauthorizedException,
      );
    });

    it('rejects deleted users in JwtAuthGuard when database is connected', async () => {
      const accessSecret = 'a'.repeat(40);
      const refreshSecret = 'b'.repeat(40);
      const fakePrisma: any = {
        isDatabaseConnected: () => true,
        getStorageMode: () => 'POSTGRESQL_PRISMA',
        user: {
          findUnique: jest.fn().mockResolvedValue({ isDeleted: true, role: UserRole.CUSTOMER }),
        },
      };
      const authService = new AuthService(
        fakePrisma,
        new InMemoryStoreService(),
        new DevSmsProvider(),
      );
      authService.configureSecurity({
        accessSecret,
        refreshSecret,
        otpHmacSecret: 'c'.repeat(40),
        smsProviderType: 'DEV_SANDBOX_SMS',
        isProduction: false,
        allowDevSms: true,
        allowInMemoryFallback: true,
        allowTestFixedOtp: false,
      });

      const { token } = signFixoJwt(
        { sub: 'deleted-user-1', phone: '', role: UserRole.CUSTOMER, type: 'access' },
        accessSecret,
        300,
      );
      const guard = new JwtAuthGuard(authService);
      const ctx = {
        switchToHttp: () => ({
          getRequest: () => ({
            headers: { authorization: `Bearer ${token}` },
          }),
        }),
      } as unknown as ExecutionContext;

      await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('Private Upload Key & Safe Photo URL Validation', () => {
    it('fails closed in production when no upload signing secret is configured', () => {
      const prevNodeEnv = process.env.NODE_ENV;
      const prevUpload = process.env.PRIVATE_UPLOAD_SECRET;
      const prevAccess = process.env.JWT_ACCESS_SECRET;
      try {
        process.env.NODE_ENV = 'production';
        delete process.env.PRIVATE_UPLOAD_SECRET;
        delete process.env.JWT_ACCESS_SECRET;
        expect(() =>
          signPrivateUploadAccessToken({
            ownerUserId: 'u1',
            purpose: 'BOOKING_ISSUE',
            sha256: 'abc',
            mimeType: 'image/webp',
            fileName: 'photo.webp',
          }),
        ).toThrow(ServiceUnavailableException);
      } finally {
        process.env.NODE_ENV = prevNodeEnv;
        if (prevUpload !== undefined) process.env.PRIVATE_UPLOAD_SECRET = prevUpload;
        else delete process.env.PRIVATE_UPLOAD_SECRET;
        if (prevAccess !== undefined) process.env.JWT_ACCESS_SECRET = prevAccess;
        else delete process.env.JWT_ACCESS_SECRET;
      }
    });

    it('derives a signing key cleanly when JWT_ACCESS_SECRET is configured', () => {
      const prevAccess = process.env.JWT_ACCESS_SECRET;
      try {
        process.env.JWT_ACCESS_SECRET = 'd'.repeat(40);
        const signed = signPrivateUploadAccessToken({
          ownerUserId: 'u1',
          purpose: 'REVIEW_PHOTO',
          sha256: 'deadbeef',
          mimeType: 'image/webp',
          fileName: 'ok.webp',
        });
        const verified = verifyPrivateUploadAccessToken(signed.token);
        expect(verified.ownerUserId).toBe('u1');
      } finally {
        if (prevAccess !== undefined) process.env.JWT_ACCESS_SECRET = prevAccess;
        else delete process.env.JWT_ACCESS_SECRET;
      }
    });

    it('blocks XSS/SSRF URLs while allowing safe HTTPS, relative API paths, and raster data URIs', () => {
      expect(isSafePhotoReference('https://storage.fixo.app/photos/leak.jpg')).toBe(true);
      expect(isSafePhotoReference('/api/v1/bookings/b1/messages/m1/photo')).toBe(true);
      expect(isSafePhotoReference('data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA=')).toBe(true);

      expect(isSafePhotoReference('javascript:alert(1)')).toBe(false);
      expect(isSafePhotoReference('data:image/svg+xml;base64,PHN2Zz4=')).toBe(false);
      expect(isSafePhotoReference('data:text/html;base64,PHNjcmlwdD4=')).toBe(false);
      expect(isSafePhotoReference('https://localhost/admin')).toBe(false);
      expect(isSafePhotoReference('https://169.254.169.254/latest/meta-data')).toBe(false);
      expect(isSafePhotoReference('http://storage.fixo.app/insecure.jpg')).toBe(false);
      expect(isSafePhotoReference('/api/v1/../admin/audit')).toBe(false);
    });
  });
});

