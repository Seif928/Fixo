import { ConflictException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { randomInt, randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaService } from '../../prisma/prisma.service';
import { assertCurrentDatabaseIsTest, validateTestDatabaseTarget } from '../../prisma/test-database-safety.util';
import { PhonePasswordService } from './phone-password.service';
import { AuthService } from './auth.service';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });
describe('First profile persistence in local fixo_test only', () => {
  let db: PrismaClient, service: PhonePasswordService;
  const ids: string[] = [];
  const phone = `+2010${randomInt(10000000, 99999999)}`;
  beforeAll(async () => {
    const url = process.env.TEST_DATABASE_URL;
    validateTestDatabaseTarget(url);
    db = new PrismaClient({ datasources: { db: { url } } });
    await db.$connect(); await assertCurrentDatabaseIsTest(db);
    const suffix = randomUUID();
    for (let index = 0; index < 2; index++) {
      const user = await db.user.create({ data: { firebaseUid: `LOCAL_TEST_${suffix}_${index}`, email: `test-${suffix}-${index}@example.test` } });
      ids.push(user.id);
    }
    service = new PhonePasswordService(Object.assign(db, { isDatabaseConnected: () => true }) as unknown as PrismaService,
      {} as any, {} as any, { findUserById: async (id: string) => ({ id }) } as unknown as AuthService);
  });
  afterAll(async () => {
    if (!db) return;
    try { await assertCurrentDatabaseIsTest(db); await db.user.deleteMany({ where: { id: { in: ids } } }); }
    finally { await db.$disconnect(); }
  });
  it('persists name/phone once without altering the linked identity and safely retries', async () => {
    await service.completeProfile(ids[0], { fullName: '  Local Test Person  ', phone });
    const before = await db.user.findUniqueOrThrow({ where: { id: ids[0] } });
    expect(before).toMatchObject({ fullName: 'Local Test Person', phone, role: 'CUSTOMER' });
    expect(before.firebaseUid).toMatch(/^LOCAL_TEST_/);
    await service.completeProfile(ids[0], { fullName: 'Local Test Person', phone });
    const after = await db.user.findUniqueOrThrow({ where: { id: ids[0] } });
    expect(after.updatedAt).toEqual(before.updatedAt);
    await expect(service.completeProfile(ids[0], { fullName: 'Changed Person', phone })).rejects.toThrow(ConflictException);
  });
  it('a phone collision cannot link or overwrite the other Google account', async () => {
    await expect(service.completeProfile(ids[1], { fullName: 'Other Test Person', phone })).rejects.toThrow(ConflictException);
    expect(await db.user.findUnique({ where: { id: ids[1] } })).toMatchObject({ phone: null, fullName: null });
    expect((await db.user.findUnique({ where: { phone } }))?.id).toBe(ids[0]);
  });
});
