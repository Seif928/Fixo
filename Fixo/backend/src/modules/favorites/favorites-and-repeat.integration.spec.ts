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
import { AuthModule } from '../auth/auth.module';
import { FavoritesModule } from './favorites.module';
import { RepeatBookingModule } from '../repeat-booking/repeat-booking.module';
import { ServicesModule } from '../services/services.module';
import { BookingsModule } from '../bookings/bookings.module';
import { PushService } from '../communications/push.service';
import {
  BookingStatus,
  ProVerificationStatus,
  TimeWindow,
} from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Favorites and Repeat Booking (Guarded PostgreSQL)', () => {
  let app: INestApplication;
  let db: PrismaService;
  let auth: AuthService;
  let url: string;

  const users: string[] = [];
  const offerings: string[] = [];
  const bookings: string[] = [];
  const categories: string[] = [];
  const zones: string[] = [];
  const identities = new Map<string, string>();
  const notify = jest.fn(async () => ({ accepted: false }));

  let customerA: any;
  let customerB: any;
  let adminUser: any;
  let proUser: any;
  let proProfile: any;
  let category: any;
  let zone: any;
  let activeOffering: any;
  let addressA: any;

  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    const module = await Test.createTestingModule({
      imports: [
        PrismaModule,
        AuthModule,
        FavoritesModule,
        RepeatBookingModule,
        ServicesModule,
        BookingsModule,
      ],
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

    const testCatSlug = `fav-cat-${randomUUID().slice(0, 8)}`;
    category = await db.serviceCategory.create({
      data: {
        slug: testCatSlug,
        nameEn: 'Appliance Repair',
        nameAr: 'تصليح أجهزة',
        subtitleEn: 'Home appliances',
        subtitleAr: 'أجهزة منزلية',
        iconName: 'appliances',
        startingPriceEgp: 200,
        isActive: true,
      },
    });
    categories.push(category.id);

    const testZoneSlug = `fav-zone-${randomUUID().slice(0, 8)}`;
    zone = await db.coverageZone.create({
      data: {
        slug: testZoneSlug,
        nameEn: 'Heliopolis',
        nameAr: 'مصر الجديدة',
        governorate: 'Cairo',
      },
    });
    zones.push(zone.id);

    activeOffering = await db.serviceOffering.create({
      data: {
        categoryId: category.id,
        slug: `fav-offering-${randomUUID().slice(0, 8)}`,
        titleEn: 'Washing Machine Repair',
        titleAr: 'تصليح غسالات',
        descriptionEn: 'Full diagnostic and pump repair',
        descriptionAr: 'فحص شامل وإصلاح طلمبة',
        baseInspectionEgp: 180,
        serviceFeeEgp: 70,
        flatPriceEgp: 250,
        estimatedDurationMins: 60,
        isActive: true,
      },
    });
    offerings.push(activeOffering.id);
  });

  const createUser = async (
    role: 'CUSTOMER' | 'ADMIN' | 'PRO' = 'CUSTOMER',
  ) => {
    const uid = randomUUID();
    const u = await db.user.create({
      data: {
        firebaseUid: uid,
        email: `${uid}@example.test`,
        fullName: `User ${role} ${uid.slice(0, 6)}`,
        role,
      },
    });
    identities.set(uid, u.email!);
    users.push(u.id);
    return u;
  };

  const getAuthToken = async (user: any) => {
    const session = await auth.issueVerifiedUserSession(user.id);
    return session.accessToken;
  };

  beforeEach(async () => {
    customerA = await createUser('CUSTOMER');
    customerB = await createUser('CUSTOMER');
    adminUser = await createUser('ADMIN');
    proUser = await createUser('PRO');

    proProfile = await db.proProfile.create({
      data: {
        userId: proUser.id,
        dossierCode: `DOS-${randomUUID().slice(0, 8).toUpperCase()}`,
        nationalIdSynthetic: `2900101${randomUUID().slice(0, 7)}`,
        primaryCategoryId: category.id,
        primaryZoneId: zone.id,
        specialtyEn: 'Master Electrician',
        specialtyAr: 'فني كهرباء معتمد',
        verificationStatus: ProVerificationStatus.APPROVED,
        isOnline: true,
        ratingAvg: 4.8,
        reviewsCount: 15,
        completedJobsCount: 42,
      },
    });

    addressA = await db.customerAddress.create({
      data: {
        userId: customerA.id,
        zoneId: zone.id,
        label: 'Home',
        buildingLine: '12 Baghdad St',
        districtLine: 'Korba',
      },
    });
  });

  afterAll(async () => {
    if (db) {
      await assertCurrentDatabaseIsTest(db);
      if (bookings.length) {
        await db.paymentRecord.deleteMany({
          where: { bookingId: { in: bookings } },
        });
        await db.bookingStatusEvent.deleteMany({
          where: { bookingId: { in: bookings } },
        });
        await db.booking.deleteMany({
          where: { id: { in: bookings } },
        });
      }
      await db.favoriteService.deleteMany({
        where: { userId: { in: users } },
      });
      await db.favoriteProfessional.deleteMany({
        where: { userId: { in: users } },
      });
      await db.customerAddress.deleteMany({
        where: { userId: { in: users } },
      });
      await db.proProfile.deleteMany({
        where: { userId: { in: users } },
      });
      if (offerings.length) {
        await db.serviceOffering.deleteMany({
          where: { id: { in: offerings } },
        });
      }
      if (categories.length) {
        await db.serviceCategory.deleteMany({
          where: { id: { in: categories } },
        });
      }
      if (zones.length) {
        await db.coverageZone.deleteMany({
          where: { id: { in: zones } },
        });
      }
      if (users.length) {
        await db.user.deleteMany({
          where: { id: { in: users } },
        });
      }
    }
    if (app) {
      await app.close();
    }
  });

  describe('Milestone B: Customer Favorites', () => {
    it('isolates favorites between users and rejects admin ownership bypass', async () => {
      const tokenA = await getAuthToken(customerA);
      const tokenB = await getAuthToken(customerB);
      const tokenAdmin = await getAuthToken(adminUser);

      // Customer A adds offering to favorites
      const addRes = await fetch(
        `${url}/api/v1/favorites/services/${activeOffering.id}`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(addRes.status).toBe(201);
      const addBody = await addRes.json();
      expect(addBody.favorited).toBe(true);

      // Customer A adds pro to favorites
      const addProRes = await fetch(
        `${url}/api/v1/favorites/professionals/${proProfile.id}`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(addProRes.status).toBe(201);

      // Customer A lists favorites
      const listARes = await fetch(`${url}/api/v1/favorites/services`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(listARes.status).toBe(200);
      const listABody = await listARes.json();
      expect(listABody.items).toHaveLength(1);
      expect(listABody.items[0].offeringId).toBe(activeOffering.id);
      expect(listABody.items[0].isAvailable).toBe(true);

      // Customer B lists favorites -> gets 0 items (strict isolation)
      const listBRes = await fetch(`${url}/api/v1/favorites/services`, {
        headers: { Authorization: `Bearer ${tokenB}` },
      });
      expect(listBRes.status).toBe(200);
      const listBBody = await listBRes.json();
      expect(listBBody.items).toHaveLength(0);

      // Admin user lists favorites -> gets 0 items (no ownership bypass into Customer A's favorites)
      const listAdminRes = await fetch(`${url}/api/v1/favorites/services`, {
        headers: { Authorization: `Bearer ${tokenAdmin}` },
      });
      expect(listAdminRes.status).toBe(200);
      const listAdminBody = await listAdminRes.json();
      expect(listAdminBody.items).toHaveLength(0);

      // Verify getFavoriteIds
      const idsARes = await fetch(`${url}/api/v1/favorites/ids`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(idsARes.status).toBe(200);
      const idsABody = await idsARes.json();
      expect(idsABody.serviceIds).toContain(activeOffering.id);
      expect(idsABody.proProfileIds).toContain(proProfile.id);

      const idsBRes = await fetch(`${url}/api/v1/favorites/ids`, {
        headers: { Authorization: `Bearer ${tokenB}` },
      });
      const idsBBody = await idsBRes.json();
      expect(idsBBody.serviceIds).toHaveLength(0);
      expect(idsBBody.proProfileIds).toHaveLength(0);
    });

    it('performs idempotent add and remove for services and professionals', async () => {
      const tokenA = await getAuthToken(customerA);

      // Repeated add service is idempotent
      await fetch(`${url}/api/v1/favorites/services/${activeOffering.id}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      const secondAdd = await fetch(
        `${url}/api/v1/favorites/services/${activeOffering.id}`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(secondAdd.status).toBe(201);

      // Repeated remove service is idempotent
      const deleteRes1 = await fetch(
        `${url}/api/v1/favorites/services/${activeOffering.id}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(deleteRes1.status).toBe(200);
      const delBody1 = await deleteRes1.json();
      expect(delBody1.favorited).toBe(false);

      const deleteRes2 = await fetch(
        `${url}/api/v1/favorites/services/${activeOffering.id}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(deleteRes2.status).toBe(200);

      // Verify now empty
      const listRes = await fetch(`${url}/api/v1/favorites/services`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      const listBody = await listRes.json();
      expect(listBody.items).toHaveLength(0);

      // Repeated add and remove pro
      await fetch(`${url}/api/v1/favorites/professionals/${proProfile.id}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      const delPro = await fetch(
        `${url}/api/v1/favorites/professionals/${proProfile.id}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(delPro.status).toBe(200);
      const delProAgain = await fetch(
        `${url}/api/v1/favorites/professionals/${proProfile.id}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(delProAgain.status).toBe(200);
    });

    it('clamps pagination bounds to max 50 and handles negative pages', async () => {
      const tokenA = await getAuthToken(customerA);

      const res = await fetch(`${url}/api/v1/favorites/services?limit=1000&page=-5`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.meta.limit).toBe(50);
      expect(body.meta.page).toBe(1);
    });

    it('reports truthful unavailable state for inactive services and suspended pros', async () => {
      const tokenA = await getAuthToken(customerA);

      // Create inactive offering
      const inactiveOffering = await db.serviceOffering.create({
        data: {
          categoryId: category.id,
          slug: `inactive-offering-${randomUUID().slice(0, 8)}`,
          titleEn: 'Inactive Service',
          titleAr: 'خدمة معطلة',
          descriptionEn: 'Inactive description',
          descriptionAr: 'وصف الخدمة المعطلة',
          baseInspectionEgp: 100,
          serviceFeeEgp: 50,
          isActive: false,
        },
      });
      offerings.push(inactiveOffering.id);

      // Create suspended pro
      const suspendedProUser = await createUser('PRO');
      const suspendedPro = await db.proProfile.create({
        data: {
          userId: suspendedProUser.id,
          dossierCode: `DOS-${randomUUID().slice(0, 8).toUpperCase()}`,
          nationalIdSynthetic: `2900101${randomUUID().slice(0, 7)}`,
          primaryCategoryId: category.id,
          primaryZoneId: zone.id,
          specialtyEn: 'Suspended Pro',
          specialtyAr: 'فني معلق',
          verificationStatus: ProVerificationStatus.SUSPENDED,
          isOnline: false,
        },
      });

      // Add both to customer A's favorites
      await fetch(`${url}/api/v1/favorites/services/${inactiveOffering.id}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      await fetch(
        `${url}/api/v1/favorites/professionals/${suspendedPro.id}`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );

      // List services
      const sRes = await fetch(`${url}/api/v1/favorites/services`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      const sBody = await sRes.json();
      const favS = sBody.items.find(
        (i: any) => i.offeringId === inactiveOffering.id,
      );
      expect(favS).toBeDefined();
      expect(favS.isAvailable).toBe(false);
      expect(favS.offering.isActive).toBe(false);

      // List pros
      const pRes = await fetch(`${url}/api/v1/favorites/professionals`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      const pBody = await pRes.json();
      const favP = pBody.items.find(
        (i: any) => i.proProfileId === suspendedPro.id,
      );
      expect(favP).toBeDefined();
      expect(favP.isAvailable).toBe(false);
      expect(favP.verificationStatus).toBe(ProVerificationStatus.SUSPENDED);

      // Response headers check
      expect(sRes.headers.get('cache-control')).toContain('no-store');
    });

    it('returns 404 for non-existent service offering or pro', async () => {
      const tokenA = await getAuthToken(customerA);
      const bogusId = randomUUID();

      const resS = await fetch(`${url}/api/v1/favorites/services/${bogusId}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(resS.status).toBe(404);

      const resP = await fetch(
        `${url}/api/v1/favorites/professionals/${bogusId}`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(resP.status).toBe(404);
    });
  });

  describe('Milestone C: Repeat Booking Quote', () => {
    let customerBooking: any;

    beforeEach(async () => {
      // Create a completed booking for Customer A with activeOffering and proProfile
      customerBooking = await db.booking.create({
        data: {
          orderCode: `FX-${randomUUID().slice(0, 6).toUpperCase()}`,
          customerId: customerA.id,
          proProfileId: proProfile.id,
          offeringId: activeOffering.id,
          addressId: addressA.id,
          status: BookingStatus.COMPLETED,
          scheduledDate: new Date('2026-05-01T10:00:00Z'),
          timeWindow: TimeWindow.MORNING_09_12,
          baseInspectionEgp: 100, // Historical price
          serviceFeeEgp: 40,      // Historical price
          transportFeeEgp: 0,
          totalEgp: 140,          // Historical price
          platformFeeEgp: 20,
          netArtisanEgp: 120,
          arrivalPinCode: '1234',
        },
      });
      bookings.push(customerBooking.id);
    });

    it('denies access to non-owners and never treats ADMIN as ownership bypass', async () => {
      const tokenB = await getAuthToken(customerB);
      const tokenAdmin = await getAuthToken(adminUser);

      // Customer B tries to get quote for Customer A's booking -> 403
      const resB = await fetch(
        `${url}/api/v1/bookings/${customerBooking.id}/repeat-quote`,
        {
          headers: { Authorization: `Bearer ${tokenB}` },
        },
      );
      expect(resB.status).toBe(403);

      // Admin tries to get quote -> 403 (strict ownership, no admin bypass)
      const resAdmin = await fetch(
        `${url}/api/v1/bookings/${customerBooking.id}/repeat-quote`,
        {
          headers: { Authorization: `Bearer ${tokenAdmin}` },
        },
      );
      expect(resAdmin.status).toBe(403);
    });

    it('returns current offering prices instead of historical prices and does not create new records', async () => {
      const tokenA = await getAuthToken(customerA);

      // Current activeOffering price in DB is base: 180, fee: 70, flat: 250
      // Historical price in booking was base: 100, fee: 40, total: 140

      const bookingCountBefore = await db.booking.count();
      const paymentCountBefore = await db.paymentRecord.count();

      const res = await fetch(
        `${url}/api/v1/bookings/${customerBooking.id}/repeat-quote`,
        {
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(res.status).toBe(200);
      expect(res.headers.get('cache-control')).toContain('no-store');

      const body = await res.json();
      expect(body.originalBookingId).toBe(customerBooking.id);
      expect(body.offering.id).toBe(activeOffering.id);
      // Confirms CURRENT prices, NOT historical 100/40
      expect(body.offering.baseInspectionEgp).toBe(180);
      expect(body.offering.serviceFeeEgp).toBe(70);
      expect(body.offering.flatPriceEgp).toBe(250);

      // Pro is verified and approved
      expect(body.preferredPro).toBeDefined();
      expect(body.preferredPro.id).toBe(proProfile.id);

      // Address is populated
      expect(body.defaultAddress).toBeDefined();
      expect(body.defaultAddress.id).toBe(addressA.id);

      // Never creates any new bookings or payments
      const bookingCountAfter = await db.booking.count();
      const paymentCountAfter = await db.paymentRecord.count();
      expect(bookingCountAfter).toBe(bookingCountBefore);
      expect(paymentCountAfter).toBe(paymentCountBefore);
    });

    it('rejects with SERVICE_DEACTIVATED if offering is deactivated', async () => {
      const tokenA = await getAuthToken(customerA);

      // Deactivate offering
      await db.serviceOffering.update({
        where: { id: activeOffering.id },
        data: { isActive: false },
      });

      const res = await fetch(
        `${url}/api/v1/bookings/${customerBooking.id}/repeat-quote`,
        {
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(res.status).toBe(400);
      const body = await res.json();
      const errCode = body.message?.code || body.code || body.message;
      expect(errCode).toBe('SERVICE_DEACTIVATED');

      // Re-activate for other tests
      await db.serviceOffering.update({
        where: { id: activeOffering.id },
        data: { isActive: true },
      });
    });

    it('rejects with CATEGORY_DEACTIVATED if category is deactivated', async () => {
      const tokenA = await getAuthToken(customerA);

      // Deactivate category
      await db.serviceCategory.update({
        where: { id: category.id },
        data: { isActive: false },
      });

      const res = await fetch(
        `${url}/api/v1/bookings/${customerBooking.id}/repeat-quote`,
        {
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(res.status).toBe(400);
      const body = await res.json();
      const errCode = body.message?.code || body.code || body.message;
      expect(errCode).toBe('CATEGORY_DEACTIVATED');

      // Re-activate
      await db.serviceCategory.update({
        where: { id: category.id },
        data: { isActive: true },
      });
    });

    it('returns preferredPro null if pro is no longer approved', async () => {
      const tokenA = await getAuthToken(customerA);

      // Suspend pro
      await db.proProfile.update({
        where: { id: proProfile.id },
        data: { verificationStatus: ProVerificationStatus.SUSPENDED },
      });

      const res = await fetch(
        `${url}/api/v1/bookings/${customerBooking.id}/repeat-quote`,
        {
          headers: { Authorization: `Bearer ${tokenA}` },
        },
      );
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.preferredPro).toBeNull();
    });
  });
});
