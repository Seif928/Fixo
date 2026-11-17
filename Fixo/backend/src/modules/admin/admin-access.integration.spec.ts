import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import {
  assertCurrentDatabaseIsTest,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { AuthService } from '../auth/auth.service';
import { FirebaseSessionPolicy } from '../auth/firebase-session-policy.service';
import { AdminAccessModule } from './admin-access.module';
import { AdminAccessService } from './admin-access.service';
import { CATALOG_DRAFTS, seedAdminCatalogDrafts } from './admin-catalog.seed';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });
describe('Private two-person admin access (guarded PostgreSQL)', () => {
  let app: INestApplication, db: PrismaService, auth: AuthService, url: string;
  let owner: any, friend: any, outsider: any;
  const identities = new Map<string, string>();
  const policy = { readVerifiedAccount: jest.fn() };
  const oldOwner = process.env.FIXO_OWNER_EMAIL;
  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';
    const module = await Test.createTestingModule({
      imports: [PrismaModule, AdminAccessModule],
    })
      .overrideProvider(FirebaseSessionPolicy)
      .useValue(policy)
      .compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    await app.listen(0, '127.0.0.1');
    url = await app.getUrl();
    db = module.get(PrismaService);
    auth = module.get(AuthService);
    await assertCurrentDatabaseIsTest(db);
  });
  beforeEach(async () => {
    identities.clear();
    const create = async (role: 'CUSTOMER' | 'ADMIN' = 'CUSTOMER') => {
      const id = randomUUID();
      const u = await db.user.create({
        data: {
          email: `${id}@example.test`,
          firebaseUid: id,
          fullName: 'Fixture account',
          role,
        },
      });
      identities.set(id, u.email!);
      return u;
    };
    owner = await create();
    friend = await create();
    outsider = await create('ADMIN');
    process.env.FIXO_OWNER_EMAIL = owner.email;
    policy.readVerifiedAccount
      .mockReset()
      .mockImplementation(async (uid: string) => ({
        uid,
        email: identities.get(uid),
      }));
  });
  afterEach(async () => {
    await (db as any).adminAuditLog.deleteMany();
    await (db as any).adminMembership.deleteMany();
    await db.user.deleteMany({
      where: {
        id: { in: [owner?.id, friend?.id, outsider?.id].filter(Boolean) },
      },
    });
  });
  afterAll(async () => {
    if (oldOwner === undefined) delete process.env.FIXO_OWNER_EMAIL;
    else process.env.FIXO_OWNER_EMAIL = oldOwner;
    if (app) await app.close();
  });
  const request = async (
    actor: any,
    route = '/me',
    method = 'GET',
    body?: object,
    age = 0,
  ) => {
    const session = actor
      ? await auth.issueVerifiedUserSession(
          actor.id,
          Math.floor(Date.now() / 1000) - age,
        )
      : null;
    return fetch(`${url}/api/v1/admin${route}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  };
  it('denies anonymous and ordinary app ADMIN roles', async () => {
    expect((await request(null)).status).toBe(401);
    expect((await request(outsider)).status).toBe(403);
    expect(await (db as any).adminMembership.count()).toBe(0);
    expect((await request(null, '/summary')).status).toBe(401);
    expect((await request(outsider, '/summary')).status).toBe(403);
    expect(policy.readVerifiedAccount).not.toHaveBeenCalled();
  });
  it('keeps unpriced catalog drafts private and publishes only a validated saved version atomically', async () => {
    expect((await request(owner, '/catalog')).status).toBe(200);
    expect((await request(outsider, '/catalog')).status).toBe(403);
    const slug = `catalog-fixture-${randomUUID()}`;
    const drafts = (db as any).adminCatalogDraft;
    const draft = await drafts.create({
      data: {
        slug,
        categorySlug: slug,
        categoryNameEn: 'Fixture',
        categoryNameAr: 'اختبار',
        categoryIcon: 'build',
        titleEn: 'Fixture service',
        titleAr: 'خدمة اختبار',
        descriptionEn: 'Fixture description',
        descriptionAr: 'وصف اختبار',
      },
    });
    try {
      expect(
        await db.serviceOffering.findUnique({ where: { slug } }),
      ).toBeNull();
      const auditBefore = await db.adminAuditLog.count();
      expect(
        (
          await request(owner, `/catalog/${draft.id}/publish`, 'POST', {
            version: 1,
          })
        ).status,
      ).toBe(400);
      expect(await db.adminAuditLog.count()).toBe(auditBefore);
      expect(
        (
          await request(owner, `/catalog/${draft.id}`, 'PUT', {
            version: 1,
            baseInspectionEgp: -1,
          })
        ).status,
      ).toBe(400);
      expect(
        (
          await request(
            owner,
            `/catalog/${draft.id}`,
            'PUT',
            {
              version: 1,
              baseInspectionEgp: 150,
              serviceFeeEgp: 250,
              estimatedDurationMins: 60,
            },
            1000,
          )
        ).status,
      ).toBe(403);
      const saved = await request(owner, `/catalog/${draft.id}`, 'PUT', {
        version: 1,
        baseInspectionEgp: 150,
        serviceFeeEgp: 250,
        estimatedDurationMins: 60,
      });
      expect(saved.status).toBe(200);
      expect((await saved.json()).version).toBe(2);
      expect(
        (
          await request(owner, `/catalog/${draft.id}/publish`, 'POST', {
            version: 1,
          })
        ).status,
      ).toBe(409);
      const published = await request(
        owner,
        `/catalog/${draft.id}/publish`,
        'POST',
        { version: 2 },
      );
      expect(published.status).toBe(201);
      expect((await published.json()).publishedVersion).toBe(2);
      expect(
        (
          await request(owner, `/catalog/${draft.id}/publish`, 'POST', {
            version: 2,
          })
        ).status,
      ).toBe(201);
      expect(await db.serviceOffering.count({ where: { slug } })).toBe(1);
      expect(
        (await db.serviceOffering.findUniqueOrThrow({ where: { slug } }))
          .flatPriceEgp,
      ).toBe(400);
      await request(owner, '/member', 'PUT', { email: friend.email });
      expect(
        (
          await request(friend, `/catalog/${draft.id}`, 'PUT', {
            version: 2,
            serviceFeeEgp: 300,
          })
        ).status,
      ).toBe(200);
      expect(
        (await db.serviceOffering.findUniqueOrThrow({ where: { slug } }))
          .serviceFeeEgp,
      ).toBe(250);
      expect(
        (
          await request(friend, `/catalog/${draft.id}/publish`, 'POST', {
            version: 3,
          })
        ).status,
      ).toBe(201);
      expect(
        (await db.serviceOffering.findUniqueOrThrow({ where: { slug } }))
          .flatPriceEgp,
      ).toBe(450);
      const page = await (
        await request(owner, `/catalog?search=${slug}`)
      ).json();
      expect(page.meta.total).toBe(1);
      expect(page.items[0].publishedVersion).toBe(3);
      const audits = await db.adminAuditLog.findMany({
        where: { entityId: draft.id },
      });
      expect(
        audits.filter((e) => e.action === 'CATALOG_PUBLISHED'),
      ).toHaveLength(2);
      expect(JSON.stringify(audits)).not.toContain('password');
    } finally {
      await drafts.delete({ where: { id: draft.id } });
      await db.serviceOffering.deleteMany({ where: { slug } });
      await db.serviceCategory.deleteMany({ where: { slug } });
    }
  });
  it('seeds drafts idempotently, imports actual existing offers and never overwrites edits or public data', async () => {
    const before = await db.adminCatalogDraft.findMany({
      select: { id: true },
    });
    const publicCount = await db.serviceOffering.count();
    try {
      await seedAdminCatalogDrafts(db as unknown as PrismaClient);
      const first = await db.adminCatalogDraft.count();
      expect(first).toBeGreaterThanOrEqual(CATALOG_DRAFTS.length);
      const edited = await db.adminCatalogDraft.findUniqueOrThrow({
        where: { slug: CATALOG_DRAFTS[0].slug },
      });
      await db.adminCatalogDraft.update({
        where: { id: edited.id },
        data: { titleEn: 'Operator custom title', serviceFeeEgp: 321 },
      });
      const repeat = await seedAdminCatalogDrafts(
        db as unknown as PrismaClient,
      );
      expect(repeat.count).toBe(0);
      expect(await db.adminCatalogDraft.count()).toBe(first);
      expect(
        (
          await db.adminCatalogDraft.findUniqueOrThrow({
            where: { id: edited.id },
          })
        ).titleEn,
      ).toBe('Operator custom title');
      expect(
        (
          await db.adminCatalogDraft.findUniqueOrThrow({
            where: { id: edited.id },
          })
        ).serviceFeeEgp,
      ).toBe(321);
      expect(await db.serviceOffering.count()).toBe(publicCount);
      const secondPage = await (await request(owner, '/catalog?page=2')).json();
      expect(secondPage.items).toHaveLength(20);
      expect(secondPage.meta.page).toBe(2);
      expect(secondPage.categories.length).toBeGreaterThanOrEqual(21);
      for (const offer of await db.serviceOffering.findMany()) {
        const linked = await db.adminCatalogDraft.findUniqueOrThrow({
          where: { offeringId: offer.id },
        });
        expect(linked.baseInspectionEgp).toBe(offer.baseInspectionEgp);
        expect(linked.publishedVersion).toBe(1);
      }
    } finally {
      await db.adminCatalogDraft.deleteMany({
        where: { id: { notIn: before.map((d) => d.id) } },
      });
    }
  });
  it('summarizes persisted records and counts only collected cash, excluding drafts and unsettled payments', async () => {
    const key = randomUUID();
    const category = await db.serviceCategory.create({
      data: {
        slug: key,
        nameEn: 'Fixture',
        nameAr: 'اختبار',
        subtitleEn: 'Fixture',
        subtitleAr: 'اختبار',
        iconName: 'build',
        startingPriceEgp: 10,
      },
    });
    const zone = await db.coverageZone.create({
      data: {
        slug: key,
        nameEn: 'Fixture',
        nameAr: 'اختبار',
        governorate: 'Cairo',
      },
    });
    const offering = await db.serviceOffering.create({
      data: {
        categoryId: category.id,
        slug: key,
        titleEn: 'Fixture',
        titleAr: 'اختبار',
        descriptionEn: 'Fixture',
        descriptionAr: 'اختبار',
        baseInspectionEgp: 10,
        serviceFeeEgp: 90,
      },
    });
    const address = await db.customerAddress.create({
      data: {
        userId: owner.id,
        zoneId: zone.id,
        label: 'Fixture',
        buildingLine: 'Fixture',
        districtLine: 'Fixture',
      },
    });
    try {
      const baseline = await (await request(owner, '/summary')).json();
      await db.proProfile.create({
        data: {
          userId: friend.id,
          dossierCode: key,
          nationalIdSynthetic: '00000000000000',
          verificationStatus: 'PENDING_REVIEW',
        },
      });
      const statuses = [
        'DRAFT',
        'PENDING_DISPATCH',
        'IN_PROGRESS',
        'COMPLETED',
        'CANCELLED',
      ] as const;
      for (const [i, status] of statuses.entries()) {
        await db.booking.create({
          data: {
            orderCode: `${key}-${i}`,
            customerId: owner.id,
            offeringId: offering.id,
            addressId: address.id,
            status,
            scheduledDate: new Date(),
            timeWindow: 'MORNING_09_12',
            issuePhotoUrls: [],
            baseInspectionEgp: 10,
            serviceFeeEgp: 90,
            totalEgp: 100,
            platformFeeEgp: 10,
            netArtisanEgp: 90,
            arrivalPinCode: '1234',
            payment: {
              create: {
                amountEgp: 100,
                tipEgp: 20,
                method: i === 4 ? 'CARD_MEEZA_SANDBOX' : 'CASH_ON_SERVICE',
                status: i === 0 ? 'PENDING' : 'PAID',
                paidAt: i === 1 ? null : new Date(),
              },
            },
          },
        });
      }
      const response = await request(owner, '/summary');
      expect(response.status).toBe(200);
      expect(response.headers.get('cache-control')).toContain('no-store');
      const value = await response.json();
      expect(value.users).toBe(baseline.users);
      expect(value.professionals).toBe(baseline.professionals + 1);
      expect(value.pendingReviews).toBe(baseline.pendingReviews + 1);
      expect(value.activeBookings).toBe(baseline.activeBookings + 2);
      expect(value.collectedCashEgp).toBe(baseline.collectedCashEgp + 200);
      await request(owner, '/member', 'PUT', { email: friend.email });
      expect((await request(friend, '/summary')).status).toBe(200);
    } finally {
      await db.booking.deleteMany({ where: { offeringId: offering.id } });
      await db.customerAddress.delete({ where: { id: address.id } });
      await db.serviceOffering.delete({ where: { id: offering.id } });
      await db.serviceCategory.delete({ where: { id: category.id } });
      await db.coverageZone.delete({ where: { id: zone.id } });
    }
  });
  it('bootstraps exactly one owner under concurrent verified requests without changing app role', async () => {
    const responses = await Promise.all([request(owner), request(owner)]);
    expect(responses.map((r) => r.status)).toEqual([200, 200]);
    expect(await (db as any).adminMembership.count()).toBe(1);
    expect(await (db as any).adminAuditLog.count()).toBe(1);
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: owner.id } })).role,
    ).toBe('CUSTOMER');
  });
  it('binds the invited second member, denies membership management and prevents a third slot', async () => {
    expect((await request(owner)).status).toBe(200);
    expect(
      (await request(owner, '/member', 'PUT', { email: friend.email })).status,
    ).toBe(200);
    expect((await (await request(friend)).json()).role).toBe('ADMIN');
    expect(
      (await request(friend, '/member', 'PUT', { email: outsider.email }))
        .status,
    ).toBe(403);
    await expect(
      db.$executeRawUnsafe(
        `INSERT INTO "AdminMembership" (slot,email,role,"updatedAt") VALUES (3,'third@example.test','ADMIN',NOW())`,
      ),
    ).rejects.toThrow();
    expect(await (db as any).adminMembership.count()).toBe(2);
  });
  it('revokes the second member immediately and never auto-restores an inactive invite', async () => {
    await request(owner);
    await request(owner, '/member', 'PUT', { email: friend.email });
    await request(friend);
    expect((await request(owner, '/member', 'DELETE')).status).toBe(200);
    expect((await request(friend)).status).toBe(403);
  });
  it('rejects mismatched provider emails, old proofs and self-invites', async () => {
    policy.readVerifiedAccount.mockResolvedValueOnce({
      uid: owner.firebaseUid,
      email: 'wrong@example.test',
    });
    expect((await request(owner)).status).toBe(403);
    expect(await (db as any).adminMembership.count()).toBe(0);
    expect(
      (await request(owner, '/me', 'GET', undefined, 13 * 3600)).status,
    ).toBe(403);
    await request(owner);
    expect(
      (await request(owner, '/member', 'PUT', { email: owner.email })).status,
    ).toBe(400);
    expect(
      (await request(owner, '/member', 'PUT', { email: friend.email }, 901))
        .status,
    ).toBe(403);
  });
  it('rejects expired invites and records only successful mutations', async () => {
    await request(owner);
    await request(owner, '/member', 'PUT', { email: friend.email });
    await (db as any).adminMembership.update({
      where: { slot: 2 },
      data: { expiresAt: new Date(0) },
    });
    expect((await request(friend)).status).toBe(403);
    const audit = await (await request(owner, '/audit')).json();
    expect(audit.items).toHaveLength(2);
    expect(JSON.stringify(audit)).not.toContain(friend.email);
  });
  it('rechecks stale authority and rolls back a failed operation together with its audit event', async () => {
    await request(owner);
    await request(owner, '/member', 'PUT', { email: friend.email });
    await request(friend);
    const access = app.get(AdminAccessService);
    const stale = {
      userId: friend.id,
      role: 'ADMIN' as const,
      authTime: Math.floor(Date.now() / 1000),
    };
    await request(owner, '/member', 'DELETE');
    const operation = jest.fn();
    await expect(
      access.mutate(stale, false, 'TEST', 'test', operation),
    ).rejects.toThrow();
    expect(operation).not.toHaveBeenCalled();
    const count = await (db as any).adminAuditLog.count();
    await expect(
      access.mutate(
        {
          userId: owner.id,
          role: 'OWNER',
          authTime: Math.floor(Date.now() / 1000),
        },
        true,
        'TEST',
        'test',
        async (tx) => {
          await tx.user.update({
            where: { id: owner.id },
            data: { fullName: 'Should roll back' },
          });
          throw Error('Synthetic operation failure');
        },
      ),
    ).rejects.toThrow('Synthetic operation failure');
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: owner.id } })).fullName,
    ).toBe('Fixture account');
    expect(await (db as any).adminAuditLog.count()).toBe(count);
  });
});
