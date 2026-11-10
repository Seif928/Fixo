import { ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaService } from '../../prisma/prisma.service';
import { seedCatalog } from '../../prisma/seed-catalog';
import { assertCurrentDatabaseIsTest, validateTestDatabaseTarget } from '../../prisma/test-database-safety.util';
import { CommunicationsService } from './communications.service';
import { PushService, PushSender } from './push.service';
import { PrivateStorageService } from '../media/private-storage.service';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Communications persisted in local fixo_test', () => {
  let db: PrismaClient;
  let service: CommunicationsService;
  let customerId: string;
  let proUserId: string;
  let outsiderId: string;
  let bookingId: string;
  const createdUsers: string[] = [];

  beforeAll(async () => {
    const url = process.env.TEST_DATABASE_URL;
    validateTestDatabaseTarget(url);
    db = new PrismaClient({ datasources: { db: { url } } });
    await db.$connect();
    await assertCurrentDatabaseIsTest(db);
    service = new CommunicationsService(Object.assign(db, { isDatabaseConnected: () => true }) as unknown as PrismaService);
    await seedCatalog(db);
    const suffix = randomUUID();
    for (const role of ['customer', 'pro', 'stranger']) {
      const user = await db.user.create({ data: { phone: `test-communications-${role}-${suffix}` } });
      createdUsers.push(user.id);
    }
    [customerId, proUserId, outsiderId] = createdUsers;
    const zone = await db.coverageZone.findFirstOrThrow();
    const offering = await db.serviceOffering.findFirstOrThrow();
    const address = await db.customerAddress.create({ data: {
      userId: customerId, zoneId: zone.id, label: 'LOCAL TEST', buildingLine: 'Synthetic test building', districtLine: 'Synthetic test district',
    } });
    const pro = await db.proProfile.create({ data: {
      userId: proUserId, dossierCode: `test-${suffix}`, nationalIdSynthetic: `SYNTHETIC-${suffix}`, verificationStatus: 'APPROVED',
    } });
    const booking = await db.booking.create({ data: {
      customerId, proProfileId: pro.id, offeringId: offering.id, addressId: address.id,
      orderCode: `TEST-${suffix}`, status: 'CONFIRMED', scheduledDate: new Date(), timeWindow: 'AFTERNOON_13_16',
      issuePhotoUrls: [], baseInspectionEgp: 150, serviceFeeEgp: 200, transportFeeEgp: 0,
      totalEgp: 350, platformFeeEgp: 35, netArtisanEgp: 315, arrivalPinCode: '0000',
    } });
    bookingId = booking.id;
  });

  afterAll(async () => {
    if (!db) return;
    try {
      await assertCurrentDatabaseIsTest(db);
      if (bookingId) await db.booking.deleteMany({ where: { id: bookingId } });
      if (createdUsers.length) await db.user.deleteMany({ where: { id: { in: createdUsers } } });
    } finally { await db.$disconnect(); }
  });

  it('persists one private device per token and prevents another account from deleting or taking it', async () => {
    const service = new PushService(db as unknown as PrismaService, { configured: () => true } as PushSender);
    const dto = { token: `TEST_ONLY_${randomUUID()}_${randomUUID()}`, platform: 'ANDROID' };
    const first = await service.register(customerId, dto);
    expect(await service.register(customerId, dto)).toEqual(first);
    expect(await db.pushDevice.count({ where: { userId: customerId } })).toBe(1);
    expect(first).not.toHaveProperty('token');
    await expect(service.register(outsiderId, dto)).rejects.toThrow(/previous account/);
    expect(await service.unregister(outsiderId, first.id)).toEqual({ count: 0 });
    expect(await service.unregister(customerId, first.id)).toEqual({ count: 1 });
  });

  it('enforces the ten-device limit when registrations arrive concurrently', async () => {
    const service = new PushService(db as unknown as PrismaService, { configured: () => true } as PushSender);
    const results = await Promise.allSettled(Array.from({ length: 14 }, () => service.register(outsiderId, {
      token: `TEST_ONLY_CONCURRENT_${randomUUID()}`, platform: 'ANDROID',
    })));
    expect(results.filter(result => result.status === 'fulfilled')).toHaveLength(10);
    expect(await db.pushDevice.count({ where: { userId: outsiderId } })).toBe(10);
    await db.pushDevice.deleteMany({ where: { userId: outsiderId } });
  });

  it('stores participant messages, marks incoming read, and scopes notifications', async () => {
    const sent = await service.sendMessage(customerId, bookingId, { body: '  Local persisted message  ' });
    expect(await db.chatMessage.findUnique({ where: { id: sent.id } })).toMatchObject({ body: 'Local persisted message', senderUserId: customerId, readAt: null });
    expect((await service.listMessages(proUserId, bookingId, {})).items.map(m => m.id)).toContain(sent.id);
    await expect(service.listMessages(outsiderId, bookingId, {})).rejects.toThrow(ForbiddenException);
    expect((await service.notificationFeed(proUserId)).items.map(n => n.id)).toContain(`message:${sent.id}`);
    expect((await service.notificationFeed(outsiderId)).items).toEqual([]);
    expect(await service.markMessageRead(customerId, bookingId, sent.id)).toEqual({ updatedCount: 0 });
    expect(await service.markMessageRead(proUserId, bookingId, sent.id)).toEqual({ updatedCount: 1 });
    expect(await service.markMessageRead(proUserId, bookingId, sent.id)).toEqual({ updatedCount: 0 });
    expect((await service.notificationFeed(proUserId)).items.map(n => n.id)).not.toContain(`message:${sent.id}`);
  });

  it('pages without gaps when multiple persisted messages have the same timestamp', async () => {
    const at = new Date();
    await db.chatMessage.createMany({ data: [1, 2, 3].map(n => ({
      id: `same-time-${n}-${bookingId}`, bookingId, senderUserId: customerId, body: `Page ${n}`, createdAt: at,
    })) });
    const page1 = await service.listMessages(customerId, bookingId, { limit: 2 });
    expect(page1.nextCursor).not.toBeNull();
    const page2 = await service.listMessages(customerId, bookingId, { limit: 2, before: page1.nextCursor! });
    expect(page1.items.some(a => page2.items.some(b => b.id === a.id))).toBe(false);
    expect(new Set([...page1.items, ...page2.items].map(m => m.id)).size).toBe(4);
  });

  it('produces real booking notifications without exposing notes or arrival PIN', async () => {
    const event = await db.bookingStatusEvent.create({ data: { bookingId, fromStatus: 'PENDING_DISPATCH', toStatus: 'CONFIRMED', note: 'PRIVATE INTERNAL NOTE' } });
    const feed = await service.notificationFeed(customerId);
    expect(feed.items).toEqual(expect.arrayContaining([expect.objectContaining({ id: `event:${event.id}`, status: 'CONFIRMED' })]));
    expect(JSON.stringify(feed)).not.toContain('PRIVATE INTERNAL NOTE');
    expect(JSON.stringify(feed)).not.toContain('arrivalPinCode');
    await db.user.update({ where: { id: customerId }, data: { arrivalAlertsEnabled: false } });
    expect((await service.notificationFeed(customerId)).items.some(n => n.kind === 'BOOKING_STATUS')).toBe(false);
  });

  it('persists photo ownership in PostgreSQL and serves only to current participants', async () => {
    const objects = new Map<string, Buffer>();
    const storage = {
      put: async (key: string, bytes: Buffer) => { objects.set(key, bytes); return key; },
      get: async (key: string) => objects.get(key)!,
      remove: async (key: string) => { objects.delete(key); },
    } as unknown as PrivateStorageService;
    const photos = new CommunicationsService(Object.assign(db, { isDatabaseConnected: () => true }) as unknown as PrismaService, undefined, storage);
    const sharp = require('sharp');
    const buffer = await sharp({ create: { width: 2, height: 2, channels: 3, background: '#556677' } }).png().toBuffer();
    const sent = await photos.sendPhoto(customerId, bookingId, { buffer, mimetype: 'image/png' });
    const persisted = await db.chatMessage.findUniqueOrThrow({ where: { id: sent.id } });
    expect(persisted).toMatchObject({ bookingId, senderUserId: customerId, body: '', readAt: null });
    expect(persisted.attachmentUrl).toMatch(new RegExp(`^bookings/${bookingId}/chat-`));
    expect(sent).not.toHaveProperty('attachmentUrl');
    const page = await photos.listMessages(proUserId, bookingId, {});
    expect(page.items.find(item => item.id === sent.id)).toMatchObject({ hasAttachment: true });
    expect(JSON.stringify(page)).not.toContain(persisted.attachmentUrl!);
    expect(await photos.readPhoto(proUserId, bookingId, sent.id)).toEqual(objects.get(persisted.attachmentUrl!));
    await expect(photos.readPhoto(outsiderId, bookingId, sent.id)).rejects.toThrow(ForbiddenException);
    await db.chatMessage.delete({ where: { id: sent.id } });
  });
});
