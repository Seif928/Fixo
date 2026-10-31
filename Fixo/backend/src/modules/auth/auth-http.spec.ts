import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { AppModule } from '../../app.module';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import { AuthService } from './auth.service';
import { DevSmsProvider, SMS_PROVIDER } from './sms/sms.provider';

describe('HTTP-Level Integration Suite (Validation Pipes, Guards & Endpoints)', () => {
  let app: INestApplication;
  let baseUrl: string;
  let authService: AuthService;
  let memoryStore: InMemoryStoreService;
  let smsProvider: DevSmsProvider;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    authService = app.get(AuthService);
    memoryStore = app.get(InMemoryStoreService);
    smsProvider = app.get<DevSmsProvider>(SMS_PROVIDER);

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

    await app.listen(0);
    const address = app.getHttpServer().address();
    const port = typeof address === 'string' ? address : address.port;
    baseUrl = `http://127.0.0.1:${port}/api/v1`;
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    memoryStore.resetToSeedState();
  });

  describe('Global ValidationPipe Enforcement', () => {
    it('rejects non-Egyptian mobile phone number with HTTP 400 Bad Request', async () => {
      const response = await fetch(`${baseUrl}/auth/otp/request`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: '+14155552671' }),
      });

      expect(response.status).toBe(400);
      const body = (await response.json()) as Record<string, unknown>;
      expect(body['message']).toEqual(
        expect.arrayContaining([expect.stringContaining('Invalid Egyptian mobile number')]),
      );
    });

    it('rejects unexpected non-whitelisted payload properties with HTTP 400', async () => {
      const response = await fetch(`${baseUrl}/auth/otp/request`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          phone: '+201023456789',
          unrecognizedAttackerPayload: 'injection_attempt',
        }),
      });

      expect(response.status).toBe(400);
      const body = (await response.json()) as Record<string, unknown>;
      expect(body['message']).toEqual(
        expect.arrayContaining([
          expect.stringContaining('property unrecognizedAttackerPayload should not exist'),
        ]),
      );
    });

    it('rejects malformed 3-digit OTP code on verify with HTTP 400', async () => {
      const response = await fetch(`${baseUrl}/auth/otp/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          phone: '+201023456789',
          code: '123',
        }),
      });

      expect(response.status).toBe(400);
      const body = (await response.json()) as Record<string, unknown>;
      expect(body['message']).toEqual(
        expect.arrayContaining([
          expect.stringContaining('OTP verification code must be exactly 6 numeric digits'),
        ]),
      );
    });
  });

  describe('HTTP Authentication & Authorization Guards', () => {
    it('returns HTTP 401 Unauthorized on GET /users/me without Bearer header', async () => {
      const response = await fetch(`${baseUrl}/users/me`);
      expect(response.status).toBe(401);
    });

    it('returns HTTP 401 Unauthorized on GET /users/me with invalid or forged token', async () => {
      const response = await fetch(`${baseUrl}/users/me`, {
        headers: { Authorization: 'Bearer forged.token.signature' },
      });
      expect(response.status).toBe(401);
    });

    it('executes full OTP login and verifies authenticated profile on GET /users/me', async () => {
      const phone = '+201023456789';
      const reqRes = await fetch(`${baseUrl}/auth/otp/request`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      });
      expect(reqRes.status).toBe(200);
      const reqData = (await reqRes.json()) as { challengeId: string };
      const code = smsProvider.getLastDispatchedCodeForPhone(phone)!;

      const verifyRes = await fetch(`${baseUrl}/auth/otp/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          phone,
          code,
          challengeId: reqData.challengeId,
        }),
      });
      expect(verifyRes.status).toBe(200);
      const authData = (await verifyRes.json()) as { accessToken: string };

      const meRes = await fetch(`${baseUrl}/users/me`, {
        headers: { Authorization: `Bearer ${authData.accessToken}` },
      });
      expect(meRes.status).toBe(200);
      const meData = (await meRes.json()) as { user: { phone: string; fullName: string } };
      expect(meData.user.phone).toBe(phone);
      expect(meData.user.fullName).toBe('Salma El-Shazly');
    });
  });

  describe('HTTP Health & Market Diagnostics', () => {
    it('returns HTTP 200 with safe persistence diagnostics and Egyptian market tokens', async () => {
      const response = await fetch(`${baseUrl}/health`);
      expect(response.status).toBe(200);
      const data = (await response.json()) as Record<string, unknown>;
      expect(data['status']).toBe('ok');
      expect(data['market']).toBe('EG');
      expect(data['currency']).toBe('EGP');
      expect(data['persistence']).toBeDefined();
    });

    it('returns HTTP 200 on /health/ready when storage backend is operational', async () => {
      const response = await fetch(`${baseUrl}/health/ready`);
      expect(response.status).toBe(200);
      const data = (await response.json()) as Record<string, unknown>;
      expect(data['status']).toBe('ready');
      expect((data['database'] as any)['ready']).toBe(true);
    });
  });
});

