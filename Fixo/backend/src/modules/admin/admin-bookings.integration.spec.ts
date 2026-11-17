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
import { BookingsModule } from '../bookings/bookings.module';
import { ProModule } from '../pro/pro.module';
import { PushService } from '../communications/push.service';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });
describe('Private booking operations (local PostgreSQL only)', () => {
  let app: INestApplication, db: PrismaService, auth: AuthService, url: string;
  let owner: any,
    outsider: any,
    customer: any,
    pro: any,
    category: any,
    zone: any,
    offering: any,
    address: any,
    booking: any;
  const users: string[] = [],
    bookings: string[] = [];
  const identities = new Map<string, string>();
  const notify = jest.fn(async () => ({ accepted: false }));
  const priorOwner = process.env.FIXO_OWNER_EMAIL;
  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';
    const module = await Test.createTestingModule({
      imports: [PrismaModule, BookingsModule, ProModule],
    })
      .overrideProvider(FirebaseSessionPolicy)
      .useValue({
        readVerifiedAccount: async (uid: string) => ({
          uid,
          email: identities.get(uid),
        }),
      })
      .overrideProvider(PushService)
      .useValue({ notify })
      .compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();
    await app.listen(0, '127.0.0.1');
    url = await app.getUrl();
    db = module.get(PrismaService);
    auth = module.get(AuthService);
    await assertCurrentDatabaseIsTest(db);
    const slug = randomUUID();
    category = await db.serviceCategory.create({
      data: {
        slug,
        nameEn: 'Fixture trade',
        nameAr: 'اختبار',
        subtitleEn: 'Fixture',
        subtitleAr: 'اختبار',
        iconName: 'build',
        startingPriceEgp: 100,
      },
    });
    zone = await db.coverageZone.create({
      data: {
        slug,
        nameEn: 'Fixture area',
        nameAr: 'اختبار',
        governorate: 'Fixture',
      },
    });
    offering = await db.serviceOffering.create({
      data: {
        slug,
        categoryId: category.id,
        titleEn: 'Fixture service',
        titleAr: 'اختبار',
        descriptionEn: 'Fixture',
        descriptionAr: 'اختبار',
        estimatedDurationMins: 60,
        baseInspectionEgp: 150,
        serviceFeeEgp: 250,
      },
    });
  });
  const user = async (role: 'CUSTOMER' | 'ADMIN' | 'PRO' = 'CUSTOMER') => {
    const uid = randomUUID();
    const u = await db.user.create({
      data: {
        firebaseUid: uid,
        email: `${uid}@example.test`,
        fullName: 'Fixture',
        role,
      },
    });
    identities.set(uid, u.email!);
    users.push(u.id);
    return u;
  };
  const makeBooking = async (status: any = 'PENDING_DISPATCH') => {
    const b = await db.booking.create({
      data: {
        orderCode: `FX-${randomUUID()}`,
        customerId: customer.id,
        offeringId: offering.id,
        addressId: address.id,
        status,
        scheduledDate: new Date(Date.now() + 86400000),
        timeWindow: 'MORNING_09_12',
        issuePhotoUrls: [],
        baseInspectionEgp: 150,
        serviceFeeEgp: 250,
        transportFeeEgp: 0,
        totalEgp: 400,
        platformFeeEgp: 40,
        netArtisanEgp: 360,
        arrivalPinCode: '9876',
        payment:
          status === 'DRAFT'
            ? undefined
            : {
                create: {
                  method: 'CASH_ON_SERVICE',
                  status: 'PENDING',
                  amountEgp: 400,
                },
              },
        statusEvents: {
          create: {
            toStatus: status,
            actorUserId: customer.id,
            note: 'Fixture status',
          },
        },
      },
    });
    bookings.push(b.id);
    return b;
  };
  beforeEach(async () => {
    notify.mockClear();
    owner = await user();
    outsider = await user('ADMIN');
    customer = await user();
    const technician = await user('PRO');
    pro = await db.proProfile.create({
      data: {
        userId: technician.id,
        dossierCode: randomUUID(),
        legalName: 'Fixture pro',
        nationalIdSynthetic: '00000000000000',
        verificationStatus: 'APPROVED',
        isOnline: true,
        primaryCategoryId: category.id,
        primaryZoneId: zone.id,
        toolkitCommitmentConfirmed: true,
      },
    });
    address = await db.customerAddress.create({
      data: {
        userId: customer.id,
        zoneId: zone.id,
        label: 'Fixture',
        buildingLine: 'Fixture street',
        districtLine: 'Fixture district',
      },
    });
    process.env.FIXO_OWNER_EMAIL = owner.email;
    booking = await makeBooking();
  });
  afterEach(async () => {
    await db.booking.deleteMany({ where: { id: { in: bookings.splice(0) } } });
    await db.adminAuditLog.deleteMany();
    await db.adminMembership.deleteMany();
    await db.user.deleteMany({ where: { id: { in: users.splice(0) } } });
    identities.clear();
  });
  afterAll(async () => {
    if (priorOwner === undefined) delete process.env.FIXO_OWNER_EMAIL;
    else process.env.FIXO_OWNER_EMAIL = priorOwner;
    if (offering)
      await db.serviceOffering.delete({ where: { id: offering.id } });
    if (category)
      await db.serviceCategory.delete({ where: { id: category.id } });
    if (zone) await db.coverageZone.delete({ where: { id: zone.id } });
    if (app) await app.close();
  });
  const request = async (
    actor: any,
    route: string,
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
    return fetch(`${url}/api/v1${route}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  };
  const detail = async () => {
    const r = await request(owner, `/admin/bookings/${booking.id}`);
    expect(r.status).toBe(200);
    return r.json();
  };
  it('denies anonymous/general app ADMIN and legacy cross-owner booking operations', async () => {
    for (const suffix of ['', '/tracking', '/receipt', '/review'])
      expect(
        (await request(outsider, `/bookings/${booking.id}${suffix}`)).status,
      ).toBe(403);
    expect(
      (
        await request(outsider, `/bookings/${booking.id}/cancel`, 'POST', {
          reason: 'Unauthorized',
        })
      ).status,
    ).toBe(403);
    const draft = await makeBooking('DRAFT');
    expect(
      (
        await request(outsider, `/bookings/${draft.id}/checkout`, 'POST', {
          paymentMethod: 'CASH_ON_SERVICE',
        })
      ).status,
    ).toBe(403);
    expect(
      (await db.booking.findUniqueOrThrow({ where: { id: booking.id } }))
        .status,
    ).toBe('PENDING_DISPATCH');
    expect((await request(null, '/admin/bookings')).status).toBe(401);
    expect((await request(outsider, '/admin/bookings')).status).toBe(403);
  });
  it('returns bounded actual history and private contact details, never arrival PIN or storage refs', async () => {
    const r = await request(
      owner,
      '/admin/bookings?status=PENDING_DISPATCH&page=1',
    );
    expect(r.status).toBe(200);
    const list = await r.json();
    expect(list.items.some((b: any) => b.id === booking.id)).toBe(true);
    expect(list.items.length).toBeLessThanOrEqual(20);
    expect(JSON.stringify(list)).not.toContain('arrivalPinCode');
    expect(JSON.stringify(list)).not.toContain('Fixture street');
    await db.bookingStatusEvent.createMany({
      data: [
        { bookingId: booking.id, toStatus: 'PENDING_DISPATCH', note: null },
        {
          bookingId: booking.id,
          toStatus: 'PENDING_DISPATCH',
          note: 'ARRIVAL_PIN_FAILED_ATTEMPT',
        },
      ],
    });
    const d = await detail();
    expect(d.pricing.totalEgp).toBe(400);
    expect(d.payment.status).toBe('PENDING');
    expect(d.history).toHaveLength(2);
    expect(JSON.stringify(d)).not.toContain('ARRIVAL_PIN_FAILED_ATTEMPT');
    expect(JSON.stringify(d)).not.toContain('9876');
    expect(d).not.toHaveProperty('issuePhotoUrls');
    expect(
      (
        await request(
          owner,
          `/admin/bookings/${booking.id}`,
          'GET',
          undefined,
          901,
        )
      ).status,
    ).toBe(403);
  });
  it('cancels only pre-service unpaid bookings, preserves prices and payment amount, and audits once', async () => {
    const d = await detail();
    const payload = {
      version: d.version,
      reason: 'Customer asked support to cancel',
    };
    expect(
      (
        await request(
          owner,
          `/admin/bookings/${booking.id}/cancel`,
          'POST',
          payload,
        )
      ).status,
    ).toBe(200);
    expect(
      (
        await request(
          owner,
          `/admin/bookings/${booking.id}/cancel`,
          'POST',
          payload,
        )
      ).status,
    ).toBe(200);
    const b = await db.booking.findUniqueOrThrow({
      where: { id: booking.id },
      include: { payment: true, statusEvents: true },
    });
    expect(b.status).toBe('CANCELLED');
    expect(b.totalEgp).toBe(400);
    expect(b.payment).toMatchObject({
      status: 'FAILED',
      amountEgp: 400,
      paidAt: null,
    });
    expect(
      b.statusEvents.filter((e) => e.toStatus === 'CANCELLED'),
    ).toHaveLength(1);
    expect(
      await db.adminAuditLog.count({ where: { action: 'BOOKING_CANCELLED' } }),
    ).toBe(1);
  });
  it('blocks stale snapshots, missing reasons, paid bookings, and service already underway', async () => {
    const d = await detail();
    expect(
      (
        await request(
          owner,
          `/admin/bookings/${booking.id}/cancel`,
          'POST',
          { version: d.version, reason: 'Expired confirmation' },
          901,
        )
      ).status,
    ).toBe(403);
    expect(
      (
        await request(owner, `/admin/bookings/${booking.id}/cancel`, 'POST', {
          version: d.version,
          reason: '',
        })
      ).status,
    ).toBe(400);
    await db.booking.update({
      where: { id: booking.id },
      data: { issueDescription: 'Changed' },
    });
    expect(
      (
        await request(owner, `/admin/bookings/${booking.id}/cancel`, 'POST', {
          version: d.version,
          reason: 'Old snapshot',
        })
      ).status,
    ).toBe(409);
    await db.paymentRecord.update({
      where: { bookingId: booking.id },
      data: { status: 'PAID', paidAt: new Date() },
    });
    expect(
      (
        await request(owner, `/admin/bookings/${booking.id}/cancel`, 'POST', {
          version: (await detail()).version,
          reason: 'Paid conflict',
        })
      ).status,
    ).toBe(409);
    await db.paymentRecord.update({
      where: { bookingId: booking.id },
      data: { status: 'PENDING', paidAt: null },
    });
    await db.booking.update({
      where: { id: booking.id },
      data: { status: 'IN_PROGRESS' },
    });
    expect(
      (
        await request(owner, `/admin/bookings/${booking.id}/cancel`, 'POST', {
          version: (await detail()).version,
          reason: 'Too late',
        })
      ).status,
    ).toBe(409);
  });
  it('offers only to an eligible professional without assigning or fabricating acceptance/payment', async () => {
    const d = await detail();
    const candidates = await request(
      owner,
      `/admin/bookings/${booking.id}/candidates`,
    );
    expect(candidates.status).toBe(200);
    expect(
      (await candidates.json()).items.some((p: any) => p.id === pro.id),
    ).toBe(true);
    const payload = { version: d.version, proProfileId: pro.id };
    const results = await Promise.all([
      request(owner, `/admin/bookings/${booking.id}/offer`, 'POST', payload),
      request(owner, `/admin/bookings/${booking.id}/offer`, 'POST', payload),
    ]);
    expect(results.map((r) => r.status)).toEqual([200, 200]);
    expect(
      await db.jobOffer.count({
        where: {
          bookingId: booking.id,
          proProfileId: pro.id,
          status: 'PENDING',
        },
      }),
    ).toBe(1);
    const b = await db.booking.findUniqueOrThrow({
      where: { id: booking.id },
      include: { payment: true },
    });
    expect(b.status).toBe('PENDING_DISPATCH');
    expect(b.proProfileId).toBeNull();
    expect(b.payment).toMatchObject({ status: 'PENDING', paidAt: null });
    expect(
      await db.adminAuditLog.count({ where: { action: 'BOOKING_OFFER_SENT' } }),
    ).toBe(1);
    expect(notify).toHaveBeenCalledTimes(1);
    const technician = await db.user.findUniqueOrThrow({
      where: { id: pro.userId },
    });
    const offer = await db.jobOffer.findFirstOrThrow({
      where: { bookingId: booking.id, status: 'PENDING' },
    });
    expect(
      (await request(technician, `/pro/job-offers/${offer.id}/accept`, 'POST'))
        .status,
    ).toBe(200);
    const accepted = await db.booking.findUniqueOrThrow({
      where: { id: booking.id },
      include: { payment: true },
    });
    expect(accepted.status).toBe('CONFIRMED');
    expect(accepted.proProfileId).toBe(pro.id);
    expect(accepted.payment).toMatchObject({
      status: 'PENDING',
      amountEgp: 400,
      paidAt: null,
    });
  });
  it('rechecks coverage, category, online/approval and payment eligibility inside the locked operation', async () => {
    const d = await detail();
    for (const patch of [
      { isOnline: false },
      { isOnline: true, verificationStatus: 'SUSPENDED' as const },
      { verificationStatus: 'APPROVED' as const, primaryZoneId: null },
      { primaryZoneId: zone.id, primaryCategoryId: null },
      { primaryCategoryId: category.id, userId: customer.id },
    ]) {
      await db.proProfile.update({ where: { id: pro.id }, data: patch });
      expect(
        (
          await request(owner, `/admin/bookings/${booking.id}/offer`, 'POST', {
            version: d.version,
            proProfileId: pro.id,
          })
        ).status,
      ).toBe(409);
    }
    expect(await db.jobOffer.count({ where: { bookingId: booking.id } })).toBe(
      0,
    );
  });
  it('allows the actual second member without app ADMIN and denies actions immediately after revocation', async () => {
    const d = await detail();
    const friend = await user();
    expect(
      (await request(owner, '/admin/member', 'PUT', { email: friend.email }))
        .status,
    ).toBe(200);
    expect(
      (
        await request(friend, `/admin/bookings/${booking.id}/offer`, 'POST', {
          version: d.version,
          proProfileId: pro.id,
        })
      ).status,
    ).toBe(200);
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: friend.id } })).role,
    ).toBe('CUSTOMER');
    expect((await request(owner, '/admin/member', 'DELETE')).status).toBe(200);
    expect(
      (
        await request(friend, `/admin/bookings/${booking.id}/cancel`, 'POST', {
          version: d.version,
          reason: 'Revoked permission',
        })
      ).status,
    ).toBe(403);
    expect(
      (await db.booking.findUniqueOrThrow({ where: { id: booking.id } }))
        .status,
    ).toBe('PENDING_DISPATCH');
  });
  it('rolls back booking, payment, offers and history if the administration audit write fails', async () => {
    const d = await detail();
    const original = db.$transaction.bind(db);
    const spy = jest.spyOn(db, '$transaction').mockImplementation(((
      operation: any,
      options?: any,
    ) =>
      original(
        (tx: any) =>
          operation(
            new Proxy(tx, {
              get(target, key) {
                if (key === 'adminAuditLog')
                  return {
                    ...target.adminAuditLog,
                    create: async ({ data }: any) => {
                      if (
                        ['BOOKING_CANCELLED', 'BOOKING_OFFER_SENT'].includes(
                          data.action,
                        )
                      )
                        throw new Error('Controlled audit failure');
                      return target.adminAuditLog.create({ data });
                    },
                  };
                return target[key];
              },
            }),
          ),
        options,
      )) as any);
    try {
      expect(
        (
          await request(owner, `/admin/bookings/${booking.id}/offer`, 'POST', {
            version: d.version,
            proProfileId: pro.id,
          })
        ).status,
      ).toBe(500);
      expect(
        await db.jobOffer.count({ where: { bookingId: booking.id } }),
      ).toBe(0);
      expect(
        (
          await request(owner, `/admin/bookings/${booking.id}/cancel`, 'POST', {
            version: d.version,
            reason: 'Rollback fixture',
          })
        ).status,
      ).toBe(500);
    } finally {
      spy.mockRestore();
    }
    const b = await db.booking.findUniqueOrThrow({
      where: { id: booking.id },
      include: { payment: true, statusEvents: true },
    });
    expect(b.status).toBe('PENDING_DISPATCH');
    expect(b.payment?.status).toBe('PENDING');
    expect(b.statusEvents).toHaveLength(1);
  });
});
