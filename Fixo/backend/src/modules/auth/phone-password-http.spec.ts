import { INestApplication, UnauthorizedException, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { PhonePasswordController } from './phone-password.controller';
import { PhonePasswordService } from './phone-password.service';

describe('Phone/password HTTP contract', () => {
  let app: INestApplication, url: string;
  const service = { signIn: jest.fn().mockResolvedValue({ accessToken: 'TEST_ONLY' }), completeProfile: jest.fn().mockResolvedValue({ id: 'own-user' }) };
  beforeAll(async () => {
    const module = await Test.createTestingModule({ controllers: [PhonePasswordController], providers: [
      { provide: PhonePasswordService, useValue: service },
      { provide: AuthService, useValue: { verifyAccessToken: (value: string) => { if (value !== 'TEST_ONLY') throw new UnauthorizedException(); return { sub: 'own-user' }; } } },
    ] }).compile();
    app = module.createNestApplication(); app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1'); url = await app.getUrl();
  });
  afterAll(async () => { await app?.close(); });
  beforeEach(() => jest.clearAllMocks());
  it('requires an authenticated session to save the first profile', async () => {
    const response = await fetch(url+'/api/v1/auth/first-profile', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ fullName: 'Test Name', phone: '01023456789' }) });
    expect(response.status).toBe(401); expect(service.completeProfile).not.toHaveBeenCalled();
  });
  it('rejects a client supplied user ID and role', async () => {
    for (const payload of [{ fullName: 'Test Name', phone: '01023456789', userId: 'victim' }, { phone: '01023456789', password: 'test-password', role: 'ADMIN' }]) {
      const profile = 'fullName' in payload;
      const response = await fetch(url+'/api/v1/auth/'+(profile ? 'first-profile' : 'phone-password'), { method: 'POST', headers: { 'content-type': 'application/json', authorization: 'Bearer TEST_ONLY' }, body: JSON.stringify(payload) });
      expect(response.status).toBe(400);
    }
    expect(service.completeProfile).not.toHaveBeenCalled(); expect(service.signIn).not.toHaveBeenCalled();
  });
  it('derives profile ownership from the JWT and trims the name', async () => {
    const response = await fetch(url+'/api/v1/auth/first-profile', { method: 'POST', headers: { 'content-type': 'application/json', authorization: 'Bearer TEST_ONLY' }, body: JSON.stringify({ fullName: ' Test Name ', phone: '01023456789' }) });
    expect(response.status).toBe(200);
    expect(service.completeProfile).toHaveBeenCalledWith('own-user', { fullName: 'Test Name', phone: '01023456789' });
  });
});
