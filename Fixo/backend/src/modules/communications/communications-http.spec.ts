import { INestApplication, UnauthorizedException, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuthService } from '../auth/auth.service';
import { CommunicationsController } from './communications.controller';
import { CommunicationsService } from './communications.service';
import { PushController } from './push.controller';
import { PushService } from './push.service';

describe('Communications real HTTP validation and authentication', () => {
  let app: INestApplication;
  let url: string;
  const service = {
    sendPhoto: jest.fn().mockResolvedValue({ id: 'photo1', hasAttachment: true }),
    readPhoto: jest.fn().mockResolvedValue(Buffer.from('private-photo')),
    sendMessage: jest.fn().mockResolvedValue({ id: 'm1' }),
    listMessages: jest.fn().mockResolvedValue({ items: [], nextCursor: null }),
    notificationFeed: jest.fn().mockResolvedValue({ items: [], deliveryChannel: 'IN_APP' }),
    updateNotificationPreference: jest.fn().mockResolvedValue({ arrivalAlertsEnabled: false, deliveryChannel: 'IN_APP' }),
  };
  const push = { status: jest.fn().mockReturnValue({ configured: true }), register: jest.fn().mockResolvedValue({ id: 'device' }), unregister: jest.fn().mockResolvedValue({ count: 1 }) };
  beforeAll(async () => {
    const module = await Test.createTestingModule({ controllers: [CommunicationsController, PushController], providers: [
      { provide: CommunicationsService, useValue: service },
      { provide: PushService, useValue: push },
      { provide: AuthService, useValue: { verifyAccessToken: (token: string) => {
        if (token !== 'TEST-ONLY') throw new UnauthorizedException();
        return { sub: 'authenticated-user' };
      } } },
    ] }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    url = await app.getUrl();
  });
  afterAll(async () => { await app?.close(); });
  beforeEach(() => jest.clearAllMocks());

  it('protects photo upload and download with the same session guard', async () => {
    expect((await fetch(`${url}/api/v1/bookings/b1/messages/photo`, { method: 'POST' })).status).toBe(401);
    expect((await fetch(`${url}/api/v1/bookings/b1/messages/m1/photo`)).status).toBe(401);
    expect(service.sendPhoto).not.toHaveBeenCalled();
    expect(service.readPhoto).not.toHaveBeenCalled();
  });
  it('bounds multipart photos and rejects extra ownership fields', async () => {
    for (const oversized of [true, false]) {
      const data = new FormData();
      data.append('photo', new Blob([Buffer.alloc(oversized ? 2 * 1024 * 1024 + 1 : 10)], { type: 'image/png' }), 'photo.png');
      if (!oversized) data.append('senderUserId', 'victim');
      const response = await fetch(`${url}/api/v1/bookings/b1/messages/photo`, { method: 'POST', headers: { authorization: 'Bearer TEST-ONLY' }, body: data });
      expect(response.status).toBe(oversized ? 413 : 400);
    }
    expect(service.sendPhoto).not.toHaveBeenCalled();
  });
  it('derives photo sender from the session and serves bytes without caching', async () => {
    const data = new FormData();
    data.append('photo', new Blob(['photo'], { type: 'image/png' }), 'photo.png');
    expect((await fetch(`${url}/api/v1/bookings/b1/messages/photo`, { method: 'POST', headers: { authorization: 'Bearer TEST-ONLY' }, body: data })).status).toBe(201);
    expect(service.sendPhoto).toHaveBeenCalledWith('authenticated-user', 'b1', expect.objectContaining({ mimetype: 'image/png' }));
    const response = await fetch(`${url}/api/v1/bookings/b1/messages/m1/photo`, { headers: { authorization: 'Bearer TEST-ONLY' } });
    expect(response.status).toBe(200);
    expect(response.headers.get('cache-control')).toBe('private, no-store');
    expect(response.headers.get('content-type')).toBe('image/webp');
    expect(await response.text()).toBe('private-photo');
  });

  it('protects push configuration and registration behind authentication', async () => {
    expect((await fetch(`${url}/api/v1/users/me/push-status`)).status).toBe(401);
    expect((await fetch(`${url}/api/v1/users/me/push-devices`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ token: 'x'.repeat(150), platform: 'ANDROID' }) })).status).toBe(401);
    expect(push.register).not.toHaveBeenCalled();
  });
  it('rejects forged push ownership and invalid platform or token', async () => {
    for (const data of [{ token: 'x'.repeat(150), platform: 'ANDROID', userId: 'victim' }, { token: 'short', platform: 'ANDROID' }, { token: 'x'.repeat(150), platform: 'DESKTOP' }]) {
      const response = await fetch(`${url}/api/v1/users/me/push-devices`, { method: 'POST', headers: { authorization: 'Bearer TEST-ONLY', 'content-type': 'application/json' }, body: JSON.stringify(data) });
      expect(response.status).toBe(400);
    }
    expect(push.register).not.toHaveBeenCalled();
  });
  it('uses the authenticated identity for push register and unregister', async () => {
    const headers = { authorization: 'Bearer TEST-ONLY', 'content-type': 'application/json' };
    expect((await fetch(`${url}/api/v1/users/me/push-devices`, { method: 'POST', headers, body: JSON.stringify({ token: 'x'.repeat(150), platform: 'ANDROID' }) })).status).toBe(201);
    expect(push.register).toHaveBeenCalledWith('authenticated-user', { token: 'x'.repeat(150), platform: 'ANDROID' });
    await fetch(`${url}/api/v1/users/me/push-devices/device`, { method: 'DELETE', headers });
    expect(push.unregister).toHaveBeenCalledWith('authenticated-user', 'device');
  });

  it('requires a session for history and notifications', async () => {
    for (const route of ['/bookings/b1/messages', '/users/me/notifications']) {
      expect((await fetch(`${url}/api/v1${route}`)).status).toBe(401);
    }
    expect(service.listMessages).not.toHaveBeenCalled();
    expect(service.notificationFeed).not.toHaveBeenCalled();
  });
  it.each([{ body: 'Hello', senderUserId: 'victim' }, { body: '  ' }, { body: 'x'.repeat(2001) }, { body: 123 }])('rejects invalid or forged message payloads', async data => {
    const response = await fetch(`${url}/api/v1/bookings/b1/messages`, { method: 'POST', headers: { authorization: 'Bearer TEST-ONLY', 'content-type': 'application/json' }, body: JSON.stringify(data) });
    expect(response.status).toBe(400);
    expect(service.sendMessage).not.toHaveBeenCalled();
  });
  it('derives the sender from the authenticated session and trims content', async () => {
    const response = await fetch(`${url}/api/v1/bookings/b1/messages`, { method: 'POST', headers: { authorization: 'Bearer TEST-ONLY', 'content-type': 'application/json' }, body: JSON.stringify({ body: '  Hello  ' }) });
    expect(response.status).toBe(201);
    expect(service.sendMessage).toHaveBeenCalledWith('authenticated-user', 'b1', { body: 'Hello' });
  });
  it('rejects unbounded history requests', async () => {
    const response = await fetch(`${url}/api/v1/bookings/b1/messages?limit=999999`, { headers: { authorization: 'Bearer TEST-ONLY' } });
    expect(response.status).toBe(400);
    expect(service.listMessages).not.toHaveBeenCalled();
  });
  it('rejects forged preference ownership and string booleans', async () => {
    for (const data of [{ arrivalAlertsEnabled: false, userId: 'victim' }, { arrivalAlertsEnabled: 'false' }]) {
      const response = await fetch(`${url}/api/v1/users/me/notification-preferences`, { method: 'PATCH', headers: { authorization: 'Bearer TEST-ONLY', 'content-type': 'application/json' }, body: JSON.stringify(data) });
      expect(response.status).toBe(400);
    }
    expect(service.updateNotificationPreference).not.toHaveBeenCalled();
  });
});
