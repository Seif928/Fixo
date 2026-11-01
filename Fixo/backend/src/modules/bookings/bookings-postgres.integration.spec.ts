import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import {
  BookingStatus,
  PaymentMethodType,
  PaymentStatus,
  PrismaClient,
  ProVerificationStatus,
  TimeWindow,
  UserRole,
} from '@prisma/client';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import { seedCatalog } from '../../prisma/seed-catalog';
import {
  assertCurrentDatabaseIsTest,
  safeCleanupBookingTestTables,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { BookingsModule } from './bookings.module';
import { BookingsService } from './bookings.service';
import { CheckoutBookingDto } from './dto/checkout-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';

// Load .env configuration
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

/**
 * Real PostgreSQL Integration Test Suite for Phase 3.1 Customer Booking Backend.
 *
 * Runs strictly against the dedicated local `fixo_test` database on localhost:5432.
 * Validates:
 * - Fail-closed safety guards (only fixo_test allowed)
 * - Atomic transactional creation of Booking and initial BookingStatusEvent
 * - Initial state invariant: strictly DRAFT
 * - Deterministic EGP pricing calculation with 10% platform fee
 * - Address ownership validation and access isolation between customers
 * - Querying by customer ID and tab filtering (active, completed, cancelled)
 * - Administrative access overrides
 */
describe('Bookings PostgreSQL Real Database Integration Suite (fixo_test)', () => {
  let moduleRef: TestingModule;
  let prisma: PrismaService;
  let bookingsService: BookingsService;
  let testDbUrl: string;

  let customerUserA: any;
  let customerUserB: any;
  let adminUser: any;
  let proUser: any;
  let proProfile: any;
  let zoneCairo: any;
  let addressA: any;
  let addressB: any;
  let offeringAc: any;

  beforeAll(async () => {
    // 1. Fail-closed safety validation: target MUST be local fixo_test on port 5432
    testDbUrl =
      process.env.TEST_DATABASE_URL ??
      'postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public';

    validateTestDatabaseTarget(testDbUrl);

    process.env.TEST_DATABASE_URL = testDbUrl;
    process.env.DATABASE_URL = testDbUrl;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    moduleRef = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule, BookingsModule],
    }).compile();

    await moduleRef.init();

    prisma = moduleRef.get(PrismaService);
    bookingsService = moduleRef.get(BookingsService);

    // Verify real PostgreSQL connection was established
    expect(prisma.isDatabaseConnected()).toBe(true);
    expect(prisma.getStorageMode()).toBe('POSTGRESQL_PRISMA');

    // Fail-closed verification: runtime database must report fixo_test
    await assertCurrentDatabaseIsTest(prisma);

    // Clean up test tables and seed catalog
    await safeCleanupBookingTestTables(prisma, { testDatabaseUrl: testDbUrl });
    await seedCatalog(prisma as unknown as PrismaClient);

    // Seed common test entities
    zoneCairo = await prisma.coverageZone.findFirst({
      where: { slug: 'new-cairo' },
    });
    expect(zoneCairo).toBeDefined();

    offeringAc = await prisma.serviceOffering.findFirst({
      where: { slug: 'summer-ac-deep-clean-gas-refill' },
      include: { category: true },
    });
    expect(offeringAc).toBeDefined();

    customerUserA = await prisma.user.create({
      data: {
        phone: '+201011110001',
        fullName: 'Ahmed Zaki',
        role: UserRole.CUSTOMER,
      },
    });

    customerUserB = await prisma.user.create({
      data: {
        phone: '+201022220002',
        fullName: 'Mona Mahmoud',
        role: UserRole.CUSTOMER,
      },
    });

    adminUser = await prisma.user.create({
      data: {
        phone: '+201099990003',
        fullName: 'Admin System',
        role: UserRole.ADMIN,
      },
    });

    proUser = await prisma.user.create({
      data: {
        phone: '+201055550004',
        fullName: 'Hassan HVAC Pro',
        role: UserRole.PRO,
      },
    });

    proProfile = await prisma.proProfile.create({
      data: {
        userId: proUser.id,
        dossierCode: 'PRO-TEST-901',
        nationalIdSynthetic: '29001011234567',
        primaryCategoryId: offeringAc.categoryId,
        primaryZoneId: zoneCairo.id,
        specialtyEn: 'Master AC Technician',
        specialtyAr: 'فني تكييف خبير',
        verificationStatus: ProVerificationStatus.APPROVED,
        isOnline: true,
      },
    });

    addressA = await prisma.customerAddress.create({
      data: {
        userId: customerUserA.id,
        zoneId: zoneCairo.id,
        label: 'Home Apartment',
        buildingLine: 'Building 12, Street 9',
        districtLine: 'New Cairo, First Settlement',
        gateNotes: 'Apt 4B',
        isDefault: true,
      },
    });

    addressB = await prisma.customerAddress.create({
      data: {
        userId: customerUserB.id,
        zoneId: zoneCairo.id,
        label: 'Mona Residence',
        buildingLine: 'Tower 3, Road 90',
        districtLine: 'New Cairo, Fifth Settlement',
        isDefault: true,
      },
    });
  });

  afterAll(async () => {
    if (prisma && prisma.isDatabaseConnected()) {
      await safeCleanupBookingTestTables(prisma, { testDatabaseUrl: testDbUrl });
    }
    if (moduleRef) {
      await moduleRef.close();
    }
  });

  describe('Database Safety & Configuration', () => {
    it('strictly verifies connected runtime database is fixo_test', async () => {
      const currentDb = await assertCurrentDatabaseIsTest(prisma);
      expect(currentDb).toBe('fixo_test');
    });

    it('rejects unsafe non-fixo_test connection targets', () => {
      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:secret@localhost:5432/fixo_dev',
        ),
      ).toThrow(/Refusing to target database "fixo_dev"/);

      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:secret@remote-host.com:5432/fixo_test',
        ),
      ).toThrow(/Unsafe test database host/);
    });
  });

  describe('POST /api/v1/bookings — Real DB Persistence', () => {
    it('creates a booking in DRAFT status and records initial BookingStatusEvent in PostgreSQL', async () => {
      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
      const dto: CreateBookingDto = {
        offeringId: offeringAc.id,
        addressId: addressA.id,
        preferredProId: proProfile.id,
        scheduledDate: tomorrow,
        timeWindow: TimeWindow.AFTERNOON_13_16,
        issueDescription: 'Split AC indoor unit is dripping water.',
        issuePhotoUrls: ['https://storage.fixo.app/photos/leak-1.jpg'],
      };

      const response = await bookingsService.createBooking(customerUserA.id, dto);

      // Verify returned DTO
      expect(response.id).toBeDefined();
      expect(response.orderCode).toMatch(/^FX-\d{4}$/);
      expect(response.status).toBe(BookingStatus.DRAFT);
      expect(response.customerId).toBe(customerUserA.id);
      expect(response.proProfileId).toBe(proProfile.id);
      expect(response.arrivalPinCode).toMatch(/^\d{4}$/);
      expect(response.issueDescription).toBe('Split AC indoor unit is dripping water.');
      expect(response.issuePhotoUrls).toEqual(['https://storage.fixo.app/photos/leak-1.jpg']);

      // Verify deterministic EGP pricing breakdown
      const expectedTotal =
        offeringAc.flatPriceEgp ??
        offeringAc.baseInspectionEgp + offeringAc.serviceFeeEgp;
      const expectedPlatformFee = Math.round(expectedTotal * 0.1);
      const expectedNetArtisan = expectedTotal - expectedPlatformFee;

      expect(response.pricing).toEqual({
        baseInspectionEgp: offeringAc.baseInspectionEgp,
        serviceFeeEgp: offeringAc.serviceFeeEgp,
        transportFeeEgp: 0,
        totalEgp: expectedTotal,
        platformFeeEgp: expectedPlatformFee,
        netArtisanEgp: expectedNetArtisan,
        currency: 'EGP',
      });

      // Verify status event in response
      expect(response.statusEvents).toHaveLength(1);
      expect(response.statusEvents![0].fromStatus).toBeNull();
      expect(response.statusEvents![0].toStatus).toBe(BookingStatus.DRAFT);

      // Verify direct PostgreSQL state using Prisma raw query
      const dbRows = await prisma.$queryRaw<
        Array<{
          id: string;
          orderCode: string;
          status: string;
          totalEgp: number;
          platformFeeEgp: number;
          netArtisanEgp: number;
          customerId: string;
        }>
      >`
        SELECT id, "orderCode", status::text, "totalEgp", "platformFeeEgp", "netArtisanEgp", "customerId"
        FROM "Booking"
        WHERE id = ${response.id};
      `;

      expect(dbRows).toHaveLength(1);
      expect(dbRows[0].orderCode).toBe(response.orderCode);
      expect(dbRows[0].status).toBe('DRAFT');
      expect(dbRows[0].totalEgp).toBe(expectedTotal);
      expect(dbRows[0].platformFeeEgp).toBe(expectedPlatformFee);
      expect(dbRows[0].netArtisanEgp).toBe(expectedNetArtisan);
      expect(dbRows[0].customerId).toBe(customerUserA.id);

      // Verify BookingStatusEvent in real PostgreSQL table
      const eventRows = await prisma.$queryRaw<
        Array<{
          id: string;
          bookingId: string;
          fromStatus: string | null;
          toStatus: string;
          actorUserId: string | null;
        }>
      >`
        SELECT id, "bookingId", "fromStatus"::text, "toStatus"::text, "actorUserId"
        FROM "BookingStatusEvent"
        WHERE "bookingId" = ${response.id};
      `;

      expect(eventRows).toHaveLength(1);
      expect(eventRows[0].fromStatus).toBeNull();
      expect(eventRows[0].toStatus).toBe('DRAFT');
      expect(eventRows[0].actorUserId).toBe(customerUserA.id);
    });

    it('enforces address ownership: Customer B cannot book with Customer As address', async () => {
      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
      const dto: CreateBookingDto = {
        offeringId: offeringAc.id,
        addressId: addressA.id, // Belongs to Customer A!
        scheduledDate: tomorrow,
        timeWindow: TimeWindow.MORNING_09_12,
      };

      const bookingCountBefore = await prisma.booking.count();

      await expect(
        bookingsService.createBooking(customerUserB.id, dto),
      ).rejects.toThrow(new ForbiddenException('You do not own this address.'));

      // Confirm no database record was created
      const bookingCountAfter = await prisma.booking.count();
      expect(bookingCountAfter).toBe(bookingCountBefore);
    });

    it('rejects booking with unverified or non-approved preferred pro', async () => {
      // Create a draft (unapproved) pro
      const unapprovedProUser = await prisma.user.create({
        data: {
          phone: '+201088880005',
          fullName: 'Draft Pro',
          role: UserRole.PRO,
        },
      });

      const unapprovedPro = await prisma.proProfile.create({
        data: {
          userId: unapprovedProUser.id,
          dossierCode: 'PRO-DRAFT-999',
          nationalIdSynthetic: '29001019999999',
          verificationStatus: ProVerificationStatus.DRAFT,
        },
      });

      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
      const dto: CreateBookingDto = {
        offeringId: offeringAc.id,
        addressId: addressA.id,
        preferredProId: unapprovedPro.id,
        scheduledDate: tomorrow,
        timeWindow: TimeWindow.MORNING_09_12,
      };

      await expect(
        bookingsService.createBooking(customerUserA.id, dto),
      ).rejects.toThrow(
        new BadRequestException(
          'Preferred professional is not verified and available for bookings.',
        ),
      );
    });
  });

  describe('GET /api/v1/bookings — Tab Filtering & Customer Isolation', () => {
    let activeBookingId: string;
    let completedBookingId: string;
    let cancelledBookingId: string;

    beforeAll(async () => {
      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];

      // Create an active booking for Customer A
      const activeRes = await bookingsService.createBooking(customerUserA.id, {
        offeringId: offeringAc.id,
        addressId: addressA.id,
        scheduledDate: tomorrow,
        timeWindow: TimeWindow.MORNING_09_12,
      });
      activeBookingId = activeRes.id;

      // Create a completed booking for Customer A
      const completedBooking = await prisma.booking.create({
        data: {
          orderCode: 'FX-COMP-01',
          customerId: customerUserA.id,
          offeringId: offeringAc.id,
          addressId: addressA.id,
          status: BookingStatus.COMPLETED,
          scheduledDate: new Date('2026-10-25'),
          timeWindow: TimeWindow.MORNING_09_12,
          baseInspectionEgp: 150,
          serviceFeeEgp: 200,
          totalEgp: 350,
          platformFeeEgp: 35,
          netArtisanEgp: 315,
          arrivalPinCode: '7711',
          completedAt: new Date('2026-10-25T11:00:00Z'),
        },
      });
      completedBookingId = completedBooking.id;

      // Create a cancelled booking for Customer A
      const cancelledBooking = await prisma.booking.create({
        data: {
          orderCode: 'FX-CANC-01',
          customerId: customerUserA.id,
          offeringId: offeringAc.id,
          addressId: addressA.id,
          status: BookingStatus.CANCELLED,
          cancellationReason: 'Customer requested reschedule',
          scheduledDate: new Date('2026-10-20'),
          timeWindow: TimeWindow.EVENING_17_20,
          baseInspectionEgp: 150,
          serviceFeeEgp: 200,
          totalEgp: 350,
          platformFeeEgp: 35,
          netArtisanEgp: 315,
          arrivalPinCode: '9922',
        },
      });
      cancelledBookingId = cancelledBooking.id;
    });

    it('filters customer orders by tab: active', async () => {
      const result = await bookingsService.findCustomerBookings(
        customerUserA.id,
        { tab: 'active' },
      );

      expect(result.total).toBeGreaterThanOrEqual(1);
      const statuses = result.bookings.map((b) => b.status);
      expect(statuses.every((s) => s === BookingStatus.DRAFT)).toBe(true);
      expect(result.bookings.some((b) => b.id === activeBookingId)).toBe(true);
      expect(result.bookings.some((b) => b.id === completedBookingId)).toBe(false);
      expect(result.bookings.some((b) => b.id === cancelledBookingId)).toBe(false);
    });

    it('filters customer orders by tab: completed', async () => {
      const result = await bookingsService.findCustomerBookings(
        customerUserA.id,
        { tab: 'completed' },
      );

      expect(result.total).toBe(1);
      expect(result.bookings[0].id).toBe(completedBookingId);
      expect(result.bookings[0].status).toBe(BookingStatus.COMPLETED);
    });

    it('filters customer orders by tab: cancelled', async () => {
      const result = await bookingsService.findCustomerBookings(
        customerUserA.id,
        { tab: 'cancelled' },
      );

      expect(result.total).toBe(1);
      expect(result.bookings[0].id).toBe(cancelledBookingId);
      expect(result.bookings[0].status).toBe(BookingStatus.CANCELLED);
    });

    it('guarantees customer data isolation: Customer B sees zero orders from Customer A', async () => {
      const result = await bookingsService.findCustomerBookings(
        customerUserB.id,
        {},
      );
      expect(result.total).toBe(0);
      expect(result.bookings).toHaveLength(0);
    });
  });

  describe('GET /api/v1/bookings/:id — Detail Retrieval & Access Control', () => {
    let bookingId: string;

    beforeAll(async () => {
      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
      const res = await bookingsService.createBooking(customerUserA.id, {
        offeringId: offeringAc.id,
        addressId: addressA.id,
        scheduledDate: tomorrow,
        timeWindow: TimeWindow.AFTERNOON_13_16,
      });
      bookingId = res.id;
    });

    it('allows owner customer to retrieve booking detail with populated relations', async () => {
      const detail = await bookingsService.findCustomerBookingById(
        customerUserA.id,
        bookingId,
        false,
      );

      expect(detail.id).toBe(bookingId);
      expect(detail.customerId).toBe(customerUserA.id);
      expect(detail.offering.slug).toBe(offeringAc.slug);
      expect(detail.offering.category.nameEn).toBe('AC Maintenance');
      expect(detail.address.label).toBe('Home Apartment');
      expect(detail.address.zone?.nameEn).toBe('New Cairo, 5th Settlement');
    });

    it('forbids another customer from accessing booking detail (HTTP 403)', async () => {
      await expect(
        bookingsService.findCustomerBookingById(
          customerUserB.id,
          bookingId,
          false,
        ),
      ).rejects.toThrow(
        new ForbiddenException('You do not have access to this booking.'),
      );
    });

    it('permits administrator to access any customer booking detail', async () => {
      const detail = await bookingsService.findCustomerBookingById(
        adminUser.id,
        bookingId,
        true, // isAdmin
      );

      expect(detail.id).toBe(bookingId);
      expect(detail.customerId).toBe(customerUserA.id);
    });

    it('returns NotFoundException (HTTP 404) for non-existent booking ID', async () => {
      await expect(
        bookingsService.findCustomerBookingById(
          customerUserA.id,
          'non-existent-uuid-0000',
          false,
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('POST /api/v1/bookings/:bookingId/checkout — Phase 4A Cash on Service Checkout', () => {
    let draftBooking: any;
    const tomorrowStr = new Date(Date.now() + 86400000).toISOString().split('T')[0];

    beforeEach(async () => {
      // Create a fresh DRAFT booking for Customer A before each test in this suite
      draftBooking = await bookingsService.createBooking(customerUserA.id, {
        offeringId: offeringAc.id,
        addressId: addressA.id,
        scheduledDate: tomorrowStr,
        timeWindow: TimeWindow.MORNING_09_12,
        issueDescription: 'AC blowing warm air in living room',
      });
    });

    it('rejects unsupported digital payment methods (INSTAPAY_SANDBOX) with BadRequestException', async () => {
      await expect(
        bookingsService.checkoutBooking(
          customerUserA.id,
          draftBooking.id,
          { paymentMethod: PaymentMethodType.INSTAPAY_SANDBOX },
        ),
      ).rejects.toThrow(BadRequestException);

      // Verify booking status was not altered in PostgreSQL
      const dbBooking = await prisma.booking.findUnique({
        where: { id: draftBooking.id },
      });
      expect(dbBooking?.status).toBe(BookingStatus.DRAFT);
    });

    it('throws NotFoundException for non-existent booking ID', async () => {
      await expect(
        bookingsService.checkoutBooking(
          customerUserA.id,
          '00000000-0000-0000-0000-000000000000',
          { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('forbids another customer from checking out booking (HTTP 403)', async () => {
      await expect(
        bookingsService.checkoutBooking(
          customerUserB.id,
          draftBooking.id,
          { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
          false,
        ),
      ).rejects.toThrow(ForbiddenException);

      // Verify no payment record created in PostgreSQL
      const paymentCount = await prisma.paymentRecord.count({
        where: { bookingId: draftBooking.id },
      });
      expect(paymentCount).toBe(0);
    });

    it('rejects checkout when booking is in invalid lifecycle state (CANCELLED)', async () => {
      // Update booking directly to CANCELLED in DB
      await prisma.booking.update({
        where: { id: draftBooking.id },
        data: { status: BookingStatus.CANCELLED },
      });

      await expect(
        bookingsService.checkoutBooking(
          customerUserA.id,
          draftBooking.id,
          { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
        ),
      ).rejects.toThrow(BadRequestException);

      const dbBooking = await prisma.booking.findUnique({
        where: { id: draftBooking.id },
      });
      expect(dbBooking?.status).toBe(BookingStatus.CANCELLED);
    });

    it('atomically transitions DRAFT booking to PENDING_DISPATCH with PENDING cash payment record in PostgreSQL', async () => {
      const result = await bookingsService.checkoutBooking(
        customerUserA.id,
        draftBooking.id,
        { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
      );

      // 1. Verify returned response structure
      expect(result.id).toBe(draftBooking.id);
      expect(result.status).toBe(BookingStatus.PENDING_DISPATCH);
      expect(result.payment).toBeDefined();
      expect(result.payment?.method).toBe(PaymentMethodType.CASH_ON_SERVICE);
      expect(result.payment?.status).toBe(PaymentStatus.PENDING);
      expect(result.payment?.amountEgp).toBe(draftBooking.pricing.totalEgp);
      expect(result.payment?.tipEgp).toBe(0);
      expect(result.payment?.paidAt).toBeNull();
      expect(result.payment?.externalReference).toBeNull();

      // 2. Verify Booking table directly in PostgreSQL
      const dbBooking = await prisma.booking.findUnique({
        where: { id: draftBooking.id },
      });
      expect(dbBooking?.status).toBe(BookingStatus.PENDING_DISPATCH);
      expect(dbBooking?.proProfileId).toBeNull(); // No pro assigned at checkout

      // 3. Verify PaymentRecord table directly in PostgreSQL
      const dbPayment = await prisma.paymentRecord.findUnique({
        where: { bookingId: draftBooking.id },
      });
      expect(dbPayment).not.toBeNull();
      expect(dbPayment?.method).toBe(PaymentMethodType.CASH_ON_SERVICE);
      expect(dbPayment?.status).toBe(PaymentStatus.PENDING);
      expect(dbPayment?.amountEgp).toBe(draftBooking.pricing.totalEgp);
      expect(dbPayment?.paidAt).toBeNull();
      expect(dbPayment?.externalReference).toBeNull();

      // 4. Verify BookingStatusEvent table directly in PostgreSQL
      const statusEvents = await prisma.bookingStatusEvent.findMany({
        where: { bookingId: draftBooking.id },
        orderBy: { createdAt: 'asc' },
      });
      expect(statusEvents.length).toBe(2);
      expect(statusEvents[0].toStatus).toBe(BookingStatus.DRAFT);
      expect(statusEvents[1].fromStatus).toBe(BookingStatus.DRAFT);
      expect(statusEvents[1].toStatus).toBe(BookingStatus.PENDING_DISPATCH);
      expect(statusEvents[1].actorUserId).toBe(customerUserA.id);
      expect(statusEvents[1].note).toBe('Customer confirmed Cash on Service checkout');
    });

    it('is idempotent and retry-safe: duplicate sequential checkout calls return identical data without duplicating records', async () => {
      // First checkout call
      const firstResult = await bookingsService.checkoutBooking(
        customerUserA.id,
        draftBooking.id,
        { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
      );
      expect(firstResult.status).toBe(BookingStatus.PENDING_DISPATCH);

      // Second checkout call (retry / double-submit)
      const secondResult = await bookingsService.checkoutBooking(
        customerUserA.id,
        draftBooking.id,
        { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
      );
      expect(secondResult.status).toBe(BookingStatus.PENDING_DISPATCH);
      expect(secondResult.id).toBe(firstResult.id);
      expect(secondResult.payment?.id).toBe(firstResult.payment?.id);

      // Verify PostgreSQL counts: strictly 1 PaymentRecord and strictly 1 PENDING_DISPATCH event
      const paymentRecordsCount = await prisma.paymentRecord.count({
        where: { bookingId: draftBooking.id },
      });
      expect(paymentRecordsCount).toBe(1);

      const dispatchEventsCount = await prisma.bookingStatusEvent.count({
        where: {
          bookingId: draftBooking.id,
          toStatus: BookingStatus.PENDING_DISPATCH,
        },
      });
      expect(dispatchEventsCount).toBe(1);
    });

    it('handles concurrent checkout requests safely with PostgreSQL row locking', async () => {
      // Fire 5 concurrent requests on the exact same DRAFT booking
      const concurrentAttempts = [1, 2, 3, 4, 5].map(() =>
        bookingsService.checkoutBooking(
          customerUserA.id,
          draftBooking.id,
          { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
        ),
      );

      const results = await Promise.all(concurrentAttempts);

      // All 5 requests must succeed idempotently with PENDING_DISPATCH status
      for (const res of results) {
        expect(res.status).toBe(BookingStatus.PENDING_DISPATCH);
        expect(res.payment?.method).toBe(PaymentMethodType.CASH_ON_SERVICE);
        expect(res.payment?.status).toBe(PaymentStatus.PENDING);
      }

      // Verify PostgreSQL database integrity: exactly 1 payment record was created
      const payments = await prisma.paymentRecord.findMany({
        where: { bookingId: draftBooking.id },
      });
      expect(payments.length).toBe(1);

      // Verify status events: exactly 1 PENDING_DISPATCH transition was recorded
      const dispatchEvents = await prisma.bookingStatusEvent.findMany({
        where: {
          bookingId: draftBooking.id,
          toStatus: BookingStatus.PENDING_DISPATCH,
        },
      });
      expect(dispatchEvents.length).toBe(1);
    });

    it('aborts and rolls back entire transaction if any failure occurs during checkout: booking remains DRAFT', async () => {
      const realTransaction = prisma.$transaction.bind(prisma);

      // Spy on $transaction to simulate a mid-transaction database crash during payment creation
      const txSpy = jest
        .spyOn(prisma, '$transaction')
        .mockImplementationOnce(async (callback: any) => {
          return realTransaction(async (tx: any) => {
            // Override tx.paymentRecord.create to simulate unexpected failure
            tx.paymentRecord.create = jest
              .fn()
              .mockRejectedValueOnce(
                new Error('SIMULATED_POSTGRES_PAYMENT_INSERT_FAILURE'),
              );
            return callback(tx);
          });
        });

      await expect(
        bookingsService.checkoutBooking(
          customerUserA.id,
          draftBooking.id,
          { paymentMethod: PaymentMethodType.CASH_ON_SERVICE },
        ),
      ).rejects.toThrow('SIMULATED_POSTGRES_PAYMENT_INSERT_FAILURE');

      txSpy.mockRestore();

      // Inspect PostgreSQL directly: verify that Booking status rolled back to DRAFT!
      const dbBooking = await prisma.booking.findUnique({
        where: { id: draftBooking.id },
      });
      expect(dbBooking?.status).toBe(BookingStatus.DRAFT);

      // Verify no payment record was committed
      const paymentCount = await prisma.paymentRecord.count({
        where: { bookingId: draftBooking.id },
      });
      expect(paymentCount).toBe(0);

      // Verify no PENDING_DISPATCH status event was committed
      const dispatchEvents = await prisma.bookingStatusEvent.findMany({
        where: {
          bookingId: draftBooking.id,
          toStatus: BookingStatus.PENDING_DISPATCH,
        },
      });
      expect(dispatchEvents.length).toBe(0);
    });
  });
});
