import { ConflictException, ServiceUnavailableException } from '@nestjs/common';
import { PushService, PushSender } from './push.service';

describe('Private device push registration and sending', () => {
  let db: any, sender: any, service: PushService;
  beforeEach(() => {
    db = { isDatabaseConnected: () => true,
      pushDevice: { findUnique: jest.fn().mockResolvedValue(null), upsert: jest.fn().mockResolvedValue({ id: 'device', platform: 'ANDROID' }), count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([{ id: 'device', token: 'private-token' }]), deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      user: { findUnique: jest.fn().mockResolvedValue({ arrivalAlertsEnabled: true, preferredLocale: 'en' }) },
    };
    db.$queryRaw = jest.fn().mockResolvedValue([{ id: 'customer' }]);
    db.$transaction = jest.fn(callback => callback(db));
    sender = { configured: jest.fn().mockReturnValue(true), send: jest.fn().mockResolvedValue({ acceptedCount: 1, invalidTokens: [] }) };
    service = new PushService(db, sender);
  });
  it('requires an active sender before storing device registrations', async () => {
    sender.configured.mockReturnValue(false);
    await expect(service.register('customer', { token: 'a'.repeat(150), platform: 'ANDROID' })).rejects.toThrow(ServiceUnavailableException);
    expect(db.pushDevice.upsert).not.toHaveBeenCalled();
  });
  it('derives ownership from the session and never returns a registration token', async () => {
    const result = await service.register('customer', { token: 'a'.repeat(150), platform: 'ANDROID' });
    expect(result).toEqual({ id: 'device', platform: 'ANDROID' });
    expect(db.pushDevice.upsert.mock.calls[0][0].create.userId).toBe('customer');
  });
  it('does not steal a token already associated with a different account', async () => {
    db.pushDevice.findUnique.mockResolvedValue({ id: 'device', userId: 'other' });
    await expect(service.register('customer', { token: 'a'.repeat(150), platform: 'WEB' })).rejects.toThrow(ConflictException);
  });
  it('unregister is always scoped to the authenticated account', async () => {
    await service.unregister('customer', 'device');
    expect(db.pushDevice.deleteMany).toHaveBeenCalledWith({ where: { id: 'device', userId: 'customer' } });
  });
  it('respects notification preferences and keeps message bodies out of payloads', async () => {
    db.user.findUnique.mockResolvedValueOnce({ arrivalAlertsEnabled: false });
    await service.notify('customer', 'booking');
    expect(sender.send).not.toHaveBeenCalled();
    await service.notify('customer', 'booking');
    const payload = sender.send.mock.calls[0][1];
    expect(payload.data).toEqual({ bookingId: 'booking' });
    expect(JSON.stringify(payload)).not.toContain('private-token');
  });
  it('sender failure never reports delivery or rolls back a saved booking/message', async () => {
    sender.send.mockRejectedValue(new Error('provider unavailable'));
    await expect(service.notify('customer', 'booking')).resolves.toEqual({ accepted: false });
  });
});
