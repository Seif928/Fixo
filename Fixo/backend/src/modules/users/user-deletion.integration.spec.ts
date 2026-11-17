import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import {
  BookingStatus,
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

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Self-Service Account Deletion & Privacy (Guarded PostgreSQL)', () => {
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

  let adminUser: any;
  let activeCustomer: any;
  let cleanCustomer: any;
  let activeProUser: any;
  let activeProProfile: any;
  let cleanProUser: any;
  let cleanProProfile: any;
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
        nameEn: 'Deletion Zone',
        nameAr: 'منطقة الحذف',
        slug: `del-zone-${randomUUID().substring(0, 8)}`,
        governorate: 'Cairo',
      },
    });
    zones.push(zone.id);
    testZone = zone;

    const cat = await prisma.serviceCategory.create({
      data: {
        slug: `del-cat-${randomUUID().substring(0, 8)}`,
        nameEn: 'Deletion Cat',
        nameAr: 'قسم الحذف',
        subtitleEn: 'Test Subtitle',
        subtitleAr: 'وصف تجريبي',
        iconName: 'trash',
        startingPriceEgp: 200,
      },
    });
    categories.push(cat.id);

    const off = await prisma.serviceOffering.create({
      data: {
        categoryId: cat.id,
        slug: `del-off-${randomUUID().substring(0, 8)}`,
        titleEn: 'Deletion Service',
        titleAr: 'خدمة الحذف',
        descriptionEn: 'Test Service Description',
        descriptionAr: 'تفاصيل الخدمة',
        baseInspectionEgp: 150,
        serviceFeeEgp: 50,
      },
    });
    offerings.push(off.id);
    testOffering = off;

    // Create Admin
    adminUser = await createUser(UserRole.ADMIN);

    // Create Active Customer (has ongoing booking)
    activeCustomer = await createUser(UserRole.CUSTOMER);
    const activeAddr = await prisma.customerAddress.create({
      data: {
        userId: activeCustomer.id,
        zoneId: testZone.id,
        label: 'Home',
        buildingLine: '12 Active St',
        districtLine: 'Maadi',
      },
    });
    const ongoingBooking = await prisma.booking.create({
      data: {
        orderCode: `FX-ACT-${randomUUID().substring(0, 6)}`,
        customerId: activeCustomer.id,
        offeringId: testOffering.id,
        addressId: activeAddr.id,
        status: BookingStatus.CONFIRMED,
        scheduledDate: new Date('2026-06-15T10:00:00.000Z'),
        timeWindow: TimeWindow.MORNING_09_12,
        baseInspectionEgp: 150,
        serviceFeeEgp: 50,
        totalEgp: 200,
        platformFeeEgp: 30,
        netArtisanEgp: 170,
        arrivalPinCode: '1122',
      },
    });
    bookings.push(ongoingBooking.id);

    // Create Clean Customer (has only completed booking)
    cleanCustomer = await createUser(UserRole.CUSTOMER);
    const cleanAddr = await prisma.customerAddress.create({
      data: {
        userId: cleanCustomer.id,
        zoneId: testZone.id,
        label: 'Home',
        buildingLine: '34 Clean St',
        districtLine: 'Zamalek',
      },
    });
    const completedBooking = await prisma.booking.create({
      data: {
        orderCode: `FX-CMP-${randomUUID().substring(0, 6)}`,
        customerId: cleanCustomer.id,
        offeringId: testOffering.id,
        addressId: cleanAddr.id,
        status: BookingStatus.COMPLETED,
        scheduledDate: new Date('2026-05-01T10:00:00.000Z'),
        timeWindow: TimeWindow.MORNING_09_12,
        baseInspectionEgp: 150,
        serviceFeeEgp: 50,
        totalEgp: 200,
        platformFeeEgp: 30,
        netArtisanEgp: 170,
        arrivalPinCode: '3344',
      },
    });
    bookings.push(completedBooking.id);

    // Create Active Pro
    activeProUser = await createUser(UserRole.PRO);
    activeProProfile = await prisma.proProfile.create({
      data: {
        userId: activeProUser.id,
        dossierCode: `PRO-${randomUUID().substring(0, 6)}`,
        nationalIdSynthetic: '12345678901236',
        legalName: 'Active Pro Master',
        primaryCategoryId: cat.id,
        primaryZoneId: zone.id,
        verificationStatus: ProVerificationStatus.APPROVED,
        isOnline: true,
      },
    });
    proProfiles.push(activeProProfile.id);

    // Assign ongoing booking to Active Pro
    await prisma.booking.update({
      where: { id: ongoingBooking.id },
      data: { proProfileId: activeProProfile.id },
    });

    // Create Clean Pro
    cleanProUser = await createUser(UserRole.PRO);
    cleanProProfile = await prisma.proProfile.create({
      data: {
        userId: cleanProUser.id,
        dossierCode: `PRO-${randomUUID().substring(0, 6)}`,
        nationalIdSynthetic: '12345678901237',
        legalName: 'Clean Pro Master',
        primaryCategoryId: cat.id,
        primaryZoneId: zone.id,
        verificationStatus: ProVerificationStatus.APPROVED,
        isOnline: true,
      },
    });
    proProfiles.push(cleanProProfile.id);

    // Add push device & leave for Clean Pro
    await prisma.pushDevice.create({
      data: {
        userId: cleanProUser.id,
        tokenHash: `hash-${randomUUID()}`,
        token: `token-${randomUUID()}`,
        platform: 'android',
      },
    });
    await prisma.proLeave.create({
      data: {
        proProfileId: cleanProProfile.id,
        startDate: new Date('2026-09-01T00:00:00.000Z'),
        endDate: new Date('2026-09-05T23:59:59.000Z'),
        reason: LeaveReason.VACATION,
        status: LeaveStatus.APPROVED,
      },
    });
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
      await prisma.pushDevice.deleteMany({
        where: { userId: { in: users } },
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

  describe('Milestone 3: Self-Service Account Deletion Invariants', () => {
    it.each([{ role: 'OWNER', isActive: true }, { role: 'OWNER', isActive: false }, { role: 'ADMIN', isActive: true }] as const)('protects private $role (active=$isActive) even when the app role is CUSTOMER', async ({ role, isActive }) => {
      const member = await createUser(UserRole.CUSTOMER);
      const slot = role === 'OWNER' ? 1 : 2;
      expect(await prisma.adminMembership.findUnique({ where: { slot } })).toBeNull();
      await prisma.adminMembership.create({ data: { slot, role, isActive, userId: member.id, email: member.email! } });
      try {
        const token = await getAuthToken(member);
        const res = await fetch(`${url}/api/v1/users/me/delete-account`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } });
        expect(res.status).toBe(403);
        expect((await res.json()).code).toBe('ADMIN_ACCOUNT_PROTECTED');
        expect((await prisma.user.findUniqueOrThrow({ where: { id: member.id } })).isDeleted).toBe(false);
        expect(await prisma.refreshToken.count({ where: { userId: member.id } })).toBeGreaterThan(0);
      } finally {
        await prisma.adminMembership.deleteMany({ where: { userId: member.id } });
      }
    });

    it('does not turn a revoked administrator into a permanently undeletable customer account', async () => {
      const formerAdmin = await createUser(UserRole.CUSTOMER);
      expect(await prisma.adminMembership.findUnique({ where: { slot: 2 } })).toBeNull();
      await prisma.adminMembership.create({ data: { slot: 2, role: 'ADMIN', isActive: false, userId: formerAdmin.id, email: formerAdmin.email! } });
      try {
        const token = await getAuthToken(formerAdmin);
        const res = await fetch(`${url}/api/v1/users/me/delete-account`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } });
        expect(res.status).toBe(200);
        expect((await prisma.user.findUniqueOrThrow({ where: { id: formerAdmin.id } })).isDeleted).toBe(true);
        expect(await prisma.refreshToken.count({ where: { userId: formerAdmin.id } })).toBe(0);
      } finally {
        await prisma.adminMembership.deleteMany({ where: { userId: formerAdmin.id } });
      }
    });

    it('protects admin accounts from self-deletion', async () => {
      const token = await getAuthToken(adminUser);
      const res = await fetch(`${url}/api/v1/users/me/delete-account`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(403);
      const data = await res.json();
      expect(data.code).toBe('ADMIN_ACCOUNT_PROTECTED');
    });

    it('rejects deletion when customer has active ongoing bookings', async () => {
      const token = await getAuthToken(activeCustomer);
      const res = await fetch(`${url}/api/v1/users/me/delete-account`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(409);
      const data = await res.json();
      expect(data.code).toBe('ACTIVE_BOOKINGS_EXIST');
      expect(data.activeBookingsCount).toBe(1);
    });

    it('rejects deletion when professional has active assigned jobs', async () => {
      const token = await getAuthToken(activeProUser);
      const res = await fetch(`${url}/api/v1/users/me/delete-account`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(409);
      const data = await res.json();
      expect(data.code).toBe('ACTIVE_PRO_JOBS_EXIST');
      expect(data.activeJobsCount).toBe(1);
    });

    it('successfully deletes and anonymizes customer account with only completed bookings', async () => {
      const token = await getAuthToken(cleanCustomer);
      const res = await fetch(`${url}/api/v1/users/me/delete-account`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.success).toBe(true);

      // Verify user record in database is anonymized
      const dbUser = await prisma.user.findUnique({
        where: { id: cleanCustomer.id },
      });
      expect(dbUser?.isDeleted).toBe(true);
      expect(dbUser?.deletedAt).not.toBeNull();
      expect(dbUser?.fullName).toBe('Deleted User');
      expect(dbUser?.phone).toBeNull();
      expect(dbUser?.email).toBeNull();
      expect(dbUser?.firebaseUid).toBeNull();

      // Verify addresses are redacted for privacy
      const addresses = await prisma.customerAddress.findMany({
        where: { userId: cleanCustomer.id },
      });
      expect(addresses.every((a) => a.buildingLine === 'Redacted')).toBe(true);
      expect(addresses.every((a) => a.label === 'Deleted Address')).toBe(true);

      // Verify completed booking still exists for accounting audit
      const booking = await prisma.booking.findFirst({
        where: { customerId: cleanCustomer.id },
      });
      expect(booking).not.toBeNull();
      expect(booking?.status).toBe(BookingStatus.COMPLETED);

      // Verify subsequent authenticated call with old token fails (user no longer exists)
      const checkRes = await fetch(`${url}/api/v1/users/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect([401, 404]).toContain(checkRes.status);
    });

    it('successfully deletes and anonymizes clean professional account', async () => {
      const token = await getAuthToken(cleanProUser);
      const res = await fetch(`${url}/api/v1/users/me/delete-account`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.success).toBe(true);

      // Verify pro profile is offline and anonymized
      const dbPro = await prisma.proProfile.findUnique({
        where: { id: cleanProProfile.id },
      });
      expect(dbPro?.isOnline).toBe(false);
      expect(dbPro?.legalName).toBe('Deleted Pro');

      // Verify push devices deleted
      const pushDevices = await prisma.pushDevice.findMany({
        where: { userId: cleanProUser.id },
      });
      expect(pushDevices).toHaveLength(0);

      // Verify leaves cancelled
      const leaves = await prisma.proLeave.findMany({
        where: { proProfileId: cleanProProfile.id },
      });
      expect(leaves.every((l) => l.status === LeaveStatus.CANCELLED)).toBe(true);
    });
  });
});
