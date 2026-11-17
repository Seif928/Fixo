import { PrismaClient } from '@prisma/client';
import * as dotenv from 'dotenv';
import { randomUUID } from 'crypto';
import {
  validateTestDatabaseTarget,
  assertCurrentDatabaseIsTest,
} from '../../prisma/test-database-safety.util';
import { LocationService } from './location.service';

dotenv.config();
describe('Cross-instance PostgreSQL geocoder gates', () => {
  let prisma: PrismaClient;
  const ids = Array.from({ length: 8 }, () => randomUUID());
  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    prisma = new PrismaClient({
      datasources: { db: { url: process.env.TEST_DATABASE_URL } },
    });
    await assertCurrentDatabaseIsTest(prisma);
    await prisma.coverageZone.upsert({
      where: { slug: 'cairo' },
      update: {},
      create: {
        slug: 'cairo',
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        governorate: 'Cairo',
      },
    });
  });
  afterAll(async () => {
    await prisma?.$disconnect();
  });
  afterEach(async () => {
    jest.restoreAllMocks();
    await assertCurrentDatabaseIsTest(prisma);
    await prisma.geoRequestGate.deleteMany({
      where: {
        key: { in: ['nominatim:global', ...ids.map((id) => 'user:' + id)] },
      },
    });
    await prisma.geoLookupCache.deleteMany({
      where: { key: 'ar:v1:30.901:31.901' },
    });
  });
  it('permits one provider call across concurrent requests from different instances', async () => {
    await prisma.geoRequestGate.deleteMany({
      where: { key: 'nominatim:global' },
    });
    await prisma.geoLookupCache.deleteMany({
      where: { key: 'ar:v1:30.901:31.901' },
    });
    jest
      .spyOn(global, 'fetch')
      .mockImplementation(
        async () =>
          new Response(
            JSON.stringify({
              address: { country_code: 'eg', state: 'القاهرة' },
            }),
          ),
      );
    const results = await Promise.allSettled(
      ids.map((id) =>
        new LocationService(
          Object.assign(prisma, { isDatabaseConnected: () => true }) as any,
        ).reverse(id, 30.901, 31.901),
      ),
    );
    expect(fetch).toHaveBeenCalledTimes(1);
    expect(
      results.filter((r) => r.status === 'fulfilled').length,
    ).toBeGreaterThanOrEqual(1);
    for (const result of results)
      if (result.status === 'rejected')
        expect(result.reason.getStatus()).toBe(429);
  });
});
