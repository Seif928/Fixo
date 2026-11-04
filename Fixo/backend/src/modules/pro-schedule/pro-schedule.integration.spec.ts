import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import {
  BookingStatus,
  DayOfWeek,
  LeaveReason,
  LeaveStatus,
  ProVerificationStatus,
  TimeWindow,
  UserRole,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { AppModule } from '../../app.module';
import { AuthService } from '../auth/auth.service';
import { FirebaseSessionPolicy } from '../auth/firebase-session-policy.service';
import { PushService } from '../communications/push.service';
import { PrismaService } from '../../prisma/prisma.service';
import {
  assertCurrentDatabaseIsTest,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { ensureDispatchOffer } from '../pro/dispatch-offers';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Professional Schedule & Leaves (Guarded PostgreSQL)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let authService: AuthService;
  let url: string;

  const users: string[] = [];
  const proProfiles: string[] = [];
  const categories: string[] = [];
  const offerings: string[] = [];
  const zones: string[] = [];
  const bookings: string[] = [];
  const identities = new Map<string, string>();

  let proUserA: any;
  let proProfileA: any;
  let proUserB: any;
  let proProfileB: any;
  let customerUser: any;
  let testOffering: any;
  let testZone: any;

  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(FirebaseSessionPolicy)
      .useValue({
        readVerifiedAccount: async (uid: string) => ({
          uid,
          email: identities.get(uid),
        }),
      })
      .overrideProvider(PushService)
      .useValue({ notify: jest.fn(async () => ({ accepted: false })) })
      .compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
    await app.listen(0, '127.0.0.1');

    url = await app.getUrl();

    prisma = app.get(PrismaService);
    authService = app.get(AuthService);
    await assertCurrentDatabaseIsTest(prisma);

    // Setup Test Data
    const zone = await prisma.coverageZone.create({
      data: {
        nameEn: 'Schedule Test Zone',
        nameAr: 'منطقة اختبار المواعيد',
        slug: `schedule-zone-${randomUUID().substring(0, 8)}`,
        governorate: 'Cairo',
      },
    });
    zones.push(zone.id);
    testZone = zone;

    const cat = await prisma.serviceCategory.create({
      data: {
        slug: `schedule-cat-${randomUUID().substring(0, 8)}`,
        nameEn: 'Schedule Cat',
        nameAr: 'قسم المواعيد',
        subtitleEn: 'Test Subtitle',
        subtitleAr: 'وصف تجريبي',
        iconName: 'calendar',
        startingPriceEgp: 200,
      },
    });
    categories.push(cat.id);

    const off = await prisma.serviceOffering.create({
      data: {
        categoryId: cat.id,
        slug: `schedule-off-${randomUUID().substring(0, 8)}`,
        titleEn: 'Schedule Service',
        titleAr: 'خدمة مواعيد',
        descriptionEn: 'Test Service Description',
        descriptionAr: 'تفاصيل الخدمة',
        baseInspectionEgp: 150,
        serviceFeeEgp: 50,
      },
    });
    offerings.push(off.id);
    testOffering = off;

    // Create Pro A
    proUserA = await createUser(UserRole.PRO);
    proProfileA = await prisma.proProfile.create({
      data: {
        userId: proUserA.id,
        dossierCode: `PRO-${randomUUID().substring(0, 6)}`,
        nationalIdSynthetic: '12345678901234',
        legalName: 'Pro Technician A',
        primaryCategoryId: cat.id,
        primaryZoneId: zone.id,
        verificationStatus: ProVerificationStatus.APPROVED,
        isOnline: true,
      },
    });
    proProfiles.push(proProfileA.id);

    // Create Pro B
    proUserB = await createUser(UserRole.PRO);
    proProfileB = await prisma.proProfile.create({
      data: {
        userId: proUserB.id,
        dossierCode: `PRO-${randomUUID().substring(0, 6)}`,
        nationalIdSynthetic: '12345678901235',
        legalName: 'Pro Technician B',
        primaryCategoryId: cat.id,
        primaryZoneId: zone.id,
        verificationStatus: ProVerificationStatus.APPROVED,
        isOnline: true,
      },
    });
    proProfiles.push(proProfileB.id);

    // Create Customer
    customerUser = await createUser(UserRole.CUSTOMER);
  });

  afterAll(async () => {
    if (prisma) {
      await assertCurrentDatabaseIsTest(prisma);
      await prisma.proLeave.deleteMany({
        where: { proProfileId: { in: proProfiles } },
      });
      await prisma.proWeeklySchedule.deleteMany({
        where: { proProfileId: { in: proProfiles } },
      });
      await prisma.jobOffer.deleteMany({
        where: { proProfileId: { in: proProfiles } },
      });
      await prisma.booking.deleteMany({
        where: { id: { in: bookings } },
      });
      await prisma.customerAddress.deleteMany({
        where: { userId: { in: users } },
      });
      await prisma.proProfile.deleteMany({
        where: { id: { in: proProfiles } },
      });
      await prisma.refreshToken.deleteMany({
        where: { userId: { in: users } },
      });
      await prisma.serviceOffering.deleteMany({
        where: { id: { in: offerings } },
      });
      await prisma.serviceCategory.deleteMany({
        where: { id: { in: categories } },
      });
      await prisma.coverageZone.deleteMany({
        where: { id: { in: zones } },
      });
      await prisma.user.deleteMany({
        where: { id: { in: users } },
      });
    }
    if (app) {
      await app.close();
    }
  });

  async function createUser(role: UserRole) {
    const uid = randomUUID();
    const u = await prisma.user.create({
      data: {
        firebaseUid: uid,
        phone: `+201${Math.floor(100000000 + Math.random() * 900000000)}`,
        fullName: `User ${role} ${uid.substring(0, 6)}`,
        email: `${uid}@example.test`,
        role,
      },
    });
    identities.set(uid, u.email!);
    users.push(u.id);
    return u;
  }

  async function getAuthToken(user: any) {
    const session = await authService.issueVerifiedUserSession(user.id);
    return session.accessToken;
  }

  describe('Milestone 2: Weekly Working Schedule', () => {
    it('returns 7-day schedule with defaults on initial GET', async () => {
      const token = await getAuthToken(proUserA);
      const res = await fetch(`${url}/api/v1/pro/schedule`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.weeklySchedule).toHaveLength(7);

      const friday = data.weeklySchedule.find(
        (s: any) => s.dayOfWeek === DayOfWeek.FRIDAY,
      );
      expect(friday.isActive).toBe(false);

      const sunday = data.weeklySchedule.find(
        (s: any) => s.dayOfWeek === DayOfWeek.SUNDAY,
      );
      expect(sunday.isActive).toBe(true);
      expect(sunday.startMinute).toBe(540);
      expect(sunday.endMinute).toBe(1080);
    });

    it('denies customer from accessing professional schedule', async () => {
      const token = await getAuthToken(customerUser);
      const res = await fetch(`${url}/api/v1/pro/schedule`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(403);
    });

    it('updates weekly working shifts and persists changes', async () => {
      const token = await getAuthToken(proUserA);
      const updatePayload = {
        days: [
          {
            dayOfWeek: DayOfWeek.SUNDAY,
            startMinute: 600, // 10:00
            endMinute: 1200,  // 20:00
            isActive: true,
          },
          {
            dayOfWeek: DayOfWeek.FRIDAY,
            startMinute: 840,
            endMinute: 1320,
            isActive: true,
          },
        ],
      };

      const res = await fetch(`${url}/api/v1/pro/schedule`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updatePayload),
      });

      expect(res.status).toBe(200);
      const data = await res.json();

      const sunday = data.weeklySchedule.find(
        (s: any) => s.dayOfWeek === DayOfWeek.SUNDAY,
      );
      expect(sunday.startMinute).toBe(600);
      expect(sunday.endMinute).toBe(1200);

      const friday = data.weeklySchedule.find(
        (s: any) => s.dayOfWeek === DayOfWeek.FRIDAY,
      );
      expect(friday.isActive).toBe(true);
      expect(friday.startMinute).toBe(840);
    });

    it('rejects shift with startMinute >= endMinute on active day', async () => {
      const token = await getAuthToken(proUserA);
      const invalidPayload = {
        days: [
          {
            dayOfWeek: DayOfWeek.MONDAY,
            startMinute: 1000,
            endMinute: 500, // End before start
            isActive: true,
          },
        ],
      };

      const res = await fetch(`${url}/api/v1/pro/schedule`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(invalidPayload),
      });

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.message).toContain('Shift start must be earlier');
    });
  });

  describe('Milestone 2: Leaves & Invariant Booking Conflicts', () => {
    let leaveId: string;

    it('creates leave period successfully when no bookings conflict', async () => {
      const token = await getAuthToken(proUserA);
      const payload = {
        startDate: '2026-07-01T00:00:00.000Z',
        endDate: '2026-07-05T23:59:59.000Z',
        reason: LeaveReason.VACATION,
        notes: 'Summer vacation with family',
      };

      const res = await fetch(`${url}/api/v1/pro/leaves`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.id).toBeDefined();
      expect(data.status).toBe(LeaveStatus.APPROVED);
      expect(data.reason).toBe(LeaveReason.VACATION);
      expect(data.notes).toBe('Summer vacation with family');
      leaveId = data.id;
    });

    it('rejects leave if endDate is earlier than startDate', async () => {
      const token = await getAuthToken(proUserA);
      const res = await fetch(`${url}/api/v1/pro/leaves`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          startDate: '2026-08-10T00:00:00.000Z',
          endDate: '2026-08-01T00:00:00.000Z',
          reason: LeaveReason.PERSONAL,
        }),
      });

      expect(res.status).toBe(400);
    });

    it('rejects leave creation when pro has active confirmed booking in that timeframe', async () => {
      // Create address for customer
      const addr = await prisma.customerAddress.create({
        data: {
          userId: customerUser.id,
          zoneId: testZone.id,
          label: 'Home',
          buildingLine: '10 El-Thawra St',
          districtLine: 'Heliopolis',
        },
      });

      // Create confirmed booking for Pro A on July 20, 2026
      const booking = await prisma.booking.create({
        data: {
          orderCode: `FX-LV-${randomUUID().substring(0, 6)}`,
          customerId: customerUser.id,
          proProfileId: proProfileA.id,
          offeringId: testOffering.id,
          addressId: addr.id,
          status: BookingStatus.CONFIRMED,
          scheduledDate: new Date('2026-07-20T11:00:00.000Z'),
          timeWindow: TimeWindow.MORNING_09_12,
          baseInspectionEgp: 150,
          serviceFeeEgp: 50,
          totalEgp: 200,
          platformFeeEgp: 30,
          netArtisanEgp: 170,
          arrivalPinCode: '9988',
        },
      });
      bookings.push(booking.id);

      const token = await getAuthToken(proUserA);
      // Attempt to schedule leave overlapping July 20
      const res = await fetch(`${url}/api/v1/pro/leaves`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          startDate: '2026-07-18T00:00:00.000Z',
          endDate: '2026-07-22T23:59:59.000Z',
          reason: LeaveReason.PERSONAL,
        }),
      });

      expect(res.status).toBe(409);
      const body = await res.json();
      expect(body.code).toBe('BOOKING_CONFLICT');
      expect(body.conflictingBookingsCount).toBe(1);
    });

    it('excludes technician from dispatch matching when on approved leave', async () => {
      const addr = await prisma.customerAddress.create({
        data: {
          userId: customerUser.id,
          zoneId: testZone.id,
          label: 'Work',
          buildingLine: '50 Abbas El-Akkad St',
          districtLine: 'Nasr City',
        },
      });

      // Booking scheduled during Pro A's existing leave (July 2, 2026)
      const bookingToDispatch = await prisma.booking.create({
        data: {
          orderCode: `FX-DSP-${randomUUID().substring(0, 6)}`,
          customerId: customerUser.id,
          offeringId: testOffering.id,
          addressId: addr.id,
          status: BookingStatus.PENDING_DISPATCH,
          scheduledDate: new Date('2026-07-02T10:00:00.000Z'),
          timeWindow: TimeWindow.MORNING_09_12,
          baseInspectionEgp: 150,
          serviceFeeEgp: 50,
          totalEgp: 200,
          platformFeeEgp: 30,
          netArtisanEgp: 170,
          arrivalPinCode: '5544',
        },
      });
      bookings.push(bookingToDispatch.id);

      // Attempt dispatch to Pro A who is on leave on July 2
      const resultA = await ensureDispatchOffer(
        prisma,
        bookingToDispatch.id,
        proProfileA.id,
      );
      // Pro A is on approved leave -> excluded from dispatch
      expect(resultA).toBeNull();

      // Dispatch to Pro B (not on leave) -> succeeds!
      const resultB = await ensureDispatchOffer(
        prisma,
        bookingToDispatch.id,
        proProfileB.id,
      );
      expect(resultB).not.toBeNull();
      expect(resultB?.created).toBe(true);
    });

    it('prevents Pro B from cancelling Pro A leave (isolation)', async () => {
      const tokenB = await getAuthToken(proUserB);
      const res = await fetch(`${url}/api/v1/pro/leaves/${leaveId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${tokenB}` },
      });
      expect(res.status).toBe(404);
    });

    it('allows pro to cancel own leave', async () => {
      const tokenA = await getAuthToken(proUserA);
      const res = await fetch(`${url}/api/v1/pro/leaves/${leaveId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(res.status).toBe(200);

      // Verify leave is cancelled
      const scheduleRes = await fetch(`${url}/api/v1/pro/schedule`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      const data = await scheduleRes.json();
      const activeLeave = data.leaves.find((l: any) => l.id === leaveId);
      expect(activeLeave).toBeUndefined();
    });
  });
});
