import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { CommunicationsService } from './communications.service';

describe('Private chat photos', () => {
  let db: any, storage: any, service: any;
  let photo: { buffer: Buffer; mimetype: string };
  beforeAll(async () => {
    const sharp = require('sharp');
    photo = { buffer: await sharp({ create: { width: 2, height: 2, channels: 3, background: '#778899' } }).png().toBuffer(), mimetype: 'image/png' };
  });
  beforeEach(() => {
    db = {
      isDatabaseConnected: () => true,
      booking: { findUnique: jest.fn().mockResolvedValue({ id: 'b1', customerId: 'customer', status: 'CONFIRMED', proProfile: { userId: 'pro' } }) },
      chatMessage: { create: jest.fn().mockImplementation(({ data }) => ({ id: 'm1', ...data })), findFirst: jest.fn() },
      $queryRaw: jest.fn(),
    };
    db.$transaction = (fn: any) => fn(db);
    storage = { put: jest.fn().mockImplementation(key => key), get: jest.fn().mockResolvedValue(Buffer.from('private')), remove: jest.fn().mockResolvedValue(undefined) };
    service = Reflect.construct(CommunicationsService, [db, undefined, storage]);
  });
  it('rejects outsiders before storing bytes', async () => {
    await expect(service.sendPhoto('outsider', 'b1', photo)).rejects.toThrow(ForbiddenException);
    expect(storage.put).not.toHaveBeenCalled();
  });
  it('keeps completed conversations read-only', async () => {
    db.booking.findUnique.mockResolvedValue({ customerId: 'customer', status: 'COMPLETED', proProfile: { userId: 'pro' } });
    await expect(service.sendPhoto('customer', 'b1', photo)).rejects.toThrow(BadRequestException);
    expect(storage.put).not.toHaveBeenCalled();
  });
  it('stores normalized private bytes and hides the object reference', async () => {
    const result = await service.sendPhoto('customer', 'b1', photo);
    expect(result).toMatchObject({ id: 'm1', hasAttachment: true, senderUserId: 'customer' });
    expect(result).not.toHaveProperty('attachmentUrl');
    expect(storage.put).toHaveBeenCalledWith(expect.stringMatching(/^bookings\/b1\/chat-.*\.webp$/), expect.any(Buffer), 'image/webp');
  });
  it('removes an uploaded object if database persistence fails', async () => {
    db.chatMessage.create.mockRejectedValue(new Error('database failure'));
    await expect(service.sendPhoto('customer', 'b1', photo)).rejects.toThrow('database failure');
    expect(storage.remove).toHaveBeenCalledWith(storage.put.mock.calls[0][0]);
  });
  it('does not fetch a photo for a different booking or unsafe legacy URL', async () => {
    db.chatMessage.findFirst.mockResolvedValue({ attachmentUrl: 'https://untrusted.example/photo' });
    await expect(service.readPhoto('customer', 'b1', 'm1')).rejects.toThrow(NotFoundException);
    expect(storage.get).not.toHaveBeenCalled();
  });
  it('checks membership before downloading', async () => {
    await expect(service.readPhoto('outsider', 'b1', 'm1')).rejects.toThrow(ForbiddenException);
    expect(storage.get).not.toHaveBeenCalled();
  });
});
