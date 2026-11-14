import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import {
  BookingStatus,
  ComplaintCategory,
  ComplaintStatus,
  TimeWindow,
} from '@prisma/client';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import {
  assertCurrentDatabaseIsTest,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { AuthModule } from '../auth/auth.module';
import { AuthService } from '../auth/auth.service';
import { FirebaseSessionPolicy } from '../auth/firebase-session-policy.service';
import { AdminAccessModule } from '../admin/admin-access.module';
import { BookingsModule } from '../bookings/bookings.module';
import { PushService } from '../communications/push.service';
import { ComplaintsModule } from './complaints.module';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Complaints System (Guarded PostgreSQL)', () => {
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

  let customerA: any;
  let customerB: any;
  let adminUser: any;
  let tokenA: string;
  let tokenB: string;
  let tokenAdmin: string;
  let completedBookingA: any;
  let draftBookingA: any;
  let bookingB: any;

  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    const module = await Test.createTestingModule({
      imports: [
        PrismaModule,
        AuthModule,
        AdminAccessModule,
        BookingsModule,
        ComplaintsModule,
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
      .useValue({ notify: jest.fn(async () => ({ accepted: false })) })
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

    const suffix = randomUUID().slice(0, 8);

    // 1. Seed Category and Offering
    const cat = await db.serviceCategory.create({
      data: {
        slug: `cat-complaints-${suffix}`,
        nameEn: 'Plumbing Service',
        nameAr: 'خدمات السباكة',
        subtitleEn: 'Fix leaks and pipes',
        subtitleAr: 'إصلاح التسريبات والمواسير',
        iconName: 'plumbing',
        startingPriceEgp: 150,
        isActive: true,
      },
    });
    categories.push(cat.id);

    const off = await db.serviceOffering.create({
      data: {
        slug: `pipe-fix-${suffix}`,
        titleEn: 'Pipe Leak Repair',
        titleAr: 'إصلاح تسريب المواسير',
        descriptionEn: 'Fast repair for broken or leaking pipes',
        descriptionAr: 'إصلاح سريع للمواسير المكسورة أو المسربة',
        categoryId: cat.id,
        baseInspectionEgp: 100,
        serviceFeeEgp: 100,
        flatPriceEgp: 200,
        estimatedDurationMins: 60,
        isActive: true,
      },
    });
    offerings.push(off.id);

    // 2. Zone & Address
    const z = await db.coverageZone.create({
      data: {
        slug: `zone-cmp-${suffix}`,
        nameEn: 'Maadi Zone',
        nameAr: 'منطقة المعادي',
        governorate: 'Cairo',
      },
    });
    zones.push(z.id);

    // Clean previous memberships to allow slot 1 initialization
    await db.adminMembership.deleteMany();

    // 3. Create Users
    customerA = await createUser('CUSTOMER');
    customerB = await createUser('CUSTOMER');
    adminUser = await createUser('ADMIN');

    process.env.FIXO_OWNER_EMAIL = adminUser.email;

    tokenA = await getAuthToken(customerA);
    tokenB = await getAuthToken(customerB);
    tokenAdmin = await getAuthToken(adminUser);

    // 4. Create Addresses
    const addrA = await db.customerAddress.create({
      data: {
        userId: customerA.id,
        label: 'Home A',
        buildingLine: '10 Street 9',
        districtLine: 'Maadi',
        zoneId: z.id,
      },
    });

    const addrB = await db.customerAddress.create({
      data: {
        userId: customerB.id,
        label: 'Home B',
        buildingLine: '12 Street 10',
        districtLine: 'Maadi',
        zoneId: z.id,
      },
    });

    // 5. Create Bookings
    completedBookingA = await db.booking.create({
      data: {
        orderCode: `FX-CMP-1-${suffix}`,
        customerId: customerA.id,
        offeringId: off.id,
        addressId: addrA.id,
        status: BookingStatus.COMPLETED,
        scheduledDate: new Date('2026-05-01T10:00:00Z'),
        timeWindow: TimeWindow.MORNING_09_12,
        baseInspectionEgp: 100,
        serviceFeeEgp: 100,
        transportFeeEgp: 0,
        totalEgp: 200,
        platformFeeEgp: 30,
        netArtisanEgp: 170,
        arrivalPinCode: '1234',
      },
    });
    bookings.push(completedBookingA.id);

    draftBookingA = await db.booking.create({
      data: {
        orderCode: `FX-CMP-2-${suffix}`,
        customerId: customerA.id,
        offeringId: off.id,
        addressId: addrA.id,
        status: BookingStatus.DRAFT,
        scheduledDate: new Date('2026-05-02T10:00:00Z'),
        timeWindow: TimeWindow.MORNING_09_12,
        baseInspectionEgp: 100,
        serviceFeeEgp: 100,
        transportFeeEgp: 0,
        totalEgp: 200,
        platformFeeEgp: 30,
        netArtisanEgp: 170,
        arrivalPinCode: '1235',
      },
    });
    bookings.push(draftBookingA.id);

    bookingB = await db.booking.create({
      data: {
        orderCode: `FX-CMP-3-${suffix}`,
        customerId: customerB.id,
        offeringId: off.id,
        addressId: addrB.id,
        status: BookingStatus.COMPLETED,
        scheduledDate: new Date('2026-05-03T10:00:00Z'),
        timeWindow: TimeWindow.MORNING_09_12,
        baseInspectionEgp: 100,
        serviceFeeEgp: 100,
        transportFeeEgp: 0,
        totalEgp: 200,
        platformFeeEgp: 30,
        netArtisanEgp: 170,
        arrivalPinCode: '1236',
      },
    });
    bookings.push(bookingB.id);
  });

  afterAll(async () => {
    if (db) {
      await assertCurrentDatabaseIsTest(db);
      await db.complaint.deleteMany({
        where: {
          OR: [
            { bookingId: { in: bookings } },
            { customerId: { in: users } },
          ],
        },
      });
      await db.adminMembership.deleteMany();
      await db.adminAuditLog.deleteMany({
        where: { actorUserId: adminUser?.id },
      });
      await db.booking.deleteMany({
        where: { id: { in: bookings } },
      });
      await db.proProfile.deleteMany({
        where: { userId: { in: users } },
      });
      await db.refreshToken.deleteMany({
        where: { userId: { in: users } },
      });
      await db.customerAddress.deleteMany({
        where: { userId: { in: users } },
      });
      await db.serviceOffering.deleteMany({
        where: { id: { in: offerings } },
      });
      await db.serviceCategory.deleteMany({
        where: { id: { in: categories } },
      });
      await db.coverageZone.deleteMany({
        where: { id: { in: zones } },
      });
      await db.user.deleteMany({
        where: { id: { in: users } },
      });
    }
    if (app) {
      await app.close();
    }
  });

  async function createUser(role: 'CUSTOMER' | 'ADMIN') {
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
  }

  async function getAuthToken(user: any) {
    const session = await auth.issueVerifiedUserSession(
      user.id,
      Math.floor(Date.now() / 1000),
    );
    return session.accessToken;
  }

  describe('Milestone 1: Complaints Creation & Ownership Invariants', () => {
    let createdComplaintId: string;

    it('customer creates complaint for own completed booking', async () => {
      const res = await fetch(`${url}/api/v1/complaints`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({
          bookingId: completedBookingA.id,
          category: ComplaintCategory.SERVICE_QUALITY,
          description: 'The pipe started leaking again two hours after technician left.',
          photoUrls: ['https://cdn.fixo.app/complaints/leak1.jpg'],
        }),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.id).toBeDefined();
      expect(data.status).toBe(ComplaintStatus.OPEN);
      expect(data.category).toBe(ComplaintCategory.SERVICE_QUALITY);
      expect(data.customerId).toBe(customerA.id);
      expect(data.bookingId).toBe(completedBookingA.id);
      expect(data.photoUrls).toEqual(['https://cdn.fixo.app/complaints/leak1.jpg']);
      createdComplaintId = data.id;
    });

    it('rejects complaint photo URLs pointing to blocked .local/internal hosts', async () => {
      const res = await fetch(`${url}/api/v1/complaints`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({
          bookingId: completedBookingA.id,
          category: ComplaintCategory.SERVICE_QUALITY,
          description: 'Attempted internal .local photo URL should be rejected.',
          photoUrls: ['https://storage.local/complaints/leak1.jpg'],
        }),
      });

      expect(res.status).toBe(400);
    });

    it('denies customer from filing complaint on another user booking', async () => {
      const res = await fetch(`${url}/api/v1/complaints`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({
          bookingId: bookingB.id, // belongs to Customer B
          category: ComplaintCategory.DELAY,
          description: 'Technician was late for appointment.',
        }),
      });

      expect(res.status).toBe(403);
      const data = await res.json();
      expect(data.message).toContain('You do not own this booking');
    });

    it('rejects complaint on a DRAFT booking', async () => {
      const res = await fetch(`${url}/api/v1/complaints`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({
          bookingId: draftBookingA.id,
          category: ComplaintCategory.OTHER,
          description: 'Testing draft booking rejection.',
        }),
      });

      expect(res.status).toBe(400);
      const data = await res.json();
      expect(data.message).toContain('Cannot file a complaint on an unconfirmed draft booking');
    });

    it('rejects duplicate active complaint on the same booking', async () => {
      const res = await fetch(`${url}/api/v1/complaints`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({
          bookingId: completedBookingA.id,
          category: ComplaintCategory.OVERCHARGING,
          description: 'Duplicate complaint attempt on active booking.',
        }),
      });

      expect(res.status).toBe(400);
      const data = await res.json();
      expect(data.message).toContain('An active complaint already exists for this booking');
    });

    it('lists customer complaints with strict isolation', async () => {
      // Customer A should see 1 complaint
      const resA = await fetch(`${url}/api/v1/complaints/my`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(resA.status).toBe(200);
      const dataA = await resA.json();
      expect(dataA.items.length).toBe(1);
      expect(dataA.items[0].id).toBe(createdComplaintId);
      expect(dataA.meta.total).toBe(1);

      // Customer B should see 0 complaints
      const resB = await fetch(`${url}/api/v1/complaints/my`, {
        headers: { Authorization: `Bearer ${tokenB}` },
      });
      expect(resB.status).toBe(200);
      const dataB = await resB.json();
      expect(dataB.items.length).toBe(0);
      expect(dataB.meta.total).toBe(0);
    });

    it('retrieves details for owner and denies non-owner', async () => {
      // Owner (Customer A) retrieves details
      const resOwner = await fetch(`${url}/api/v1/complaints/${createdComplaintId}`, {
        headers: { Authorization: `Bearer ${tokenA}` },
      });
      expect(resOwner.status).toBe(200);
      const dataOwner = await resOwner.json();
      expect(dataOwner.id).toBe(createdComplaintId);
      expect(dataOwner.booking.orderCode).toBeDefined();

      // Non-owner (Customer B) is denied
      const resNonOwner = await fetch(`${url}/api/v1/complaints/${createdComplaintId}`, {
        headers: { Authorization: `Bearer ${tokenB}` },
      });
      expect(resNonOwner.status).toBe(403);
    });

    it('admin lists all complaints and reviews details with customer contact info', async () => {
      const resList = await fetch(`${url}/api/v1/admin/complaints`, {
        headers: { Authorization: `Bearer ${tokenAdmin}` },
      });
      expect(resList.status).toBe(200);
      const dataList = await resList.json();
      expect(dataList.items.length).toBeGreaterThanOrEqual(1);

      const resDetails = await fetch(`${url}/api/v1/admin/complaints/${createdComplaintId}`, {
        headers: { Authorization: `Bearer ${tokenAdmin}` },
      });
      expect(resDetails.status).toBe(200);
      const dataDetails = await resDetails.json();
      expect(dataDetails.id).toBe(createdComplaintId);
      expect(dataDetails.customer.id).toBe(customerA.id);
      expect(dataDetails.customer.fullName).toBeDefined();
    });

    it('admin updates complaint status to RESOLVED with notes and records audit log', async () => {
      const res = await fetch(`${url}/api/v1/admin/complaints/${createdComplaintId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenAdmin}`,
        },
        body: JSON.stringify({
          status: ComplaintStatus.RESOLVED,
          adminNotes: 'Contacted customer, dispatched second technician for free warranty fix.',
        }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.status).toBe(ComplaintStatus.RESOLVED);
      expect(data.adminNotes).toBe(
        'Contacted customer, dispatched second technician for free warranty fix.',
      );
      expect(data.resolvedById).toBe(adminUser.id);
      expect(data.resolvedAt).toBeDefined();

      // Verify AdminAuditLog entry
      const audit = await db.adminAuditLog.findFirst({
        where: {
          entityId: createdComplaintId,
          action: 'COMPLAINT_STATUS_UPDATE',
        },
      });
      expect(audit).toBeDefined();
      expect(audit!.actorUserId).toBe(adminUser.id);
      expect((audit!.details as any).newStatus).toBe(ComplaintStatus.RESOLVED);
    });

    it('ordinary customer cannot update complaint status', async () => {
      const res = await fetch(`${url}/api/v1/admin/complaints/${createdComplaintId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokenA}`,
        },
        body: JSON.stringify({
          status: ComplaintStatus.REJECTED,
        }),
      });

      expect(res.status).toBe(403);
    });
  });
});
