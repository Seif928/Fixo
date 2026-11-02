import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import {
  BookingStatus,
  DocumentStatus,
  DocumentType,
  ExperienceTier,
  JobOfferStatus,
  PaymentMethodType,
  PaymentStatus,
  PrismaClient,
  ProVerificationStatus,
  TimeWindow,
  TransportMode,
  UserRole,
} from '@prisma/client';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import { seedCatalog } from '../../prisma/seed-catalog';
import {
  assertCurrentDatabaseIsTest,
  safeCleanupBookingTestTables,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { AuthModule } from '../auth/auth.module';
import { BookingsModule } from '../bookings/bookings.module';
import { BookingsService } from '../bookings/bookings.service';
import { ProModule } from './pro.module';
import { ProService } from './pro.service';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

// Minimal valid PNG binary header for synthetic specimen tests
const VALID_PNG_BASE64 = Buffer.from([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
]).toString('base64');

describe('Pro Workflows PostgreSQL Real Database Integration Suite (fixo_test)', () => {
  let moduleRef: TestingModule;
  let prisma: PrismaService;
  let proService: ProService;
  let bookingsService: BookingsService;
  let testDbUrl: string;

  let customerUser: any;
  let proApplicantUser: any;
  let proCompetingUser: any;
  let adminReviewerUser: any;
  let zoneCairo: any;
  let categoryAc: any;
  let offeringAc: any;
  let customerAddress: any;

  beforeAll(async () => {
    testDbUrl =
      process.env.TEST_DATABASE_URL ??
      'postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public';

    validateTestDatabaseTarget(testDbUrl);

    process.env.TEST_DATABASE_URL = testDbUrl;
    process.env.DATABASE_URL = testDbUrl;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    moduleRef = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule, BookingsModule, ProModule],
    }).compile();

    await moduleRef.init();

    prisma = moduleRef.get(PrismaService);
    proService = moduleRef.get(ProService);
    bookingsService = moduleRef.get(BookingsService);

    expect(prisma.isDatabaseConnected()).toBe(true);
    await assertCurrentDatabaseIsTest(prisma);

    await safeCleanupBookingTestTables(prisma, { testDatabaseUrl: testDbUrl });
    await seedCatalog(prisma as unknown as PrismaClient);

    zoneCairo = await prisma.coverageZone.findFirst({
      where: { slug: 'new-cairo' },
    });
    expect(zoneCairo).toBeDefined();

    offeringAc = await prisma.serviceOffering.findFirst({
      where: { slug: 'summer-ac-deep-clean-gas-refill' },
      include: { category: true },
    });
    expect(offeringAc).toBeDefined();
    categoryAc = offeringAc.category;

    customerUser = await prisma.user.create({
      data: {
        phone: '+201060001001',
        fullName: 'Salma Customer',
        role: UserRole.CUSTOMER,
      },
    });

    proApplicantUser = await prisma.user.create({
      data: {
        phone: '+201060001002',
        fullName: 'Karim Artisan',
        role: UserRole.CUSTOMER, // Starts as CUSTOMER before onboarding approval
      },
    });

    proCompetingUser = await prisma.user.create({
      data: {
        phone: '+201060001003',
        fullName: 'Tarek Competing Pro',
        role: UserRole.PRO,
      },
    });

    adminReviewerUser = await prisma.user.create({
      data: {
        phone: '+201060001099',
        fullName: 'FIXO Operations Admin',
        role: UserRole.ADMIN,
      },
    });

    customerAddress = await prisma.customerAddress.create({
      data: {
        userId: customerUser.id,
        zoneId: zoneCairo.id,
        label: 'New Cairo Villa',
        buildingLine: 'Villa 22, Narkes 3',
        districtLine: 'New Cairo, Fifth Settlement',
        latitude: 30.0155,
        longitude: 31.4567,
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

  describe('Screens 11–14: Pro Onboarding, Private Documents & Authorized Admin Approval', () => {
    let applicantProfileId: string;
    let uploadedDocId: string;

    it('completes Step 1 (Screen 11) and Step 2 (Screen 12) with real sub-skills and zones', async () => {
      const options = await proService.getCatalogOptions();
      expect(options.categories.length).toBeGreaterThanOrEqual(6);
      const acCatWithSubs = options.categories.find(
        (c: any) => c.id === categoryAc.id,
      );
      expect(acCatWithSubs?.subSkills.length).toBeGreaterThan(0);

      // Step 1: Personal details
      const step1 = await proService.upsertPersonalDetails(
        proApplicantUser.id,
        {
          fullName: 'Karim HVAC Master',
          nationalIdSynthetic: '29104150102345',
          primaryZoneId: zoneCairo.id,
          transportMode: TransportMode.WORK_VAN,
          vehicleDescription: 'Silver Chevrolet N300 Van',
          vehiclePlateAr: 'ق هـ ر ٨٤٢١',
        },
      );

      expect(step1.dossierCode).toMatch(/^FX-PRO-\d{4}$/);
      expect(step1.verificationStatus).toBe(ProVerificationStatus.DRAFT);
      expect(step1.step1Complete).toBe(true);
      expect(step1.step2Complete).toBe(false);
      applicantProfileId = step1.id;

      // Step 2: Skills & Coverage
      const subSkillIds = acCatWithSubs!.subSkills
        .slice(0, 2)
        .map((s: any) => s.id);
      const step2 = await proService.updateSkillsAndCoverage(
        proApplicantUser.id,
        {
          primaryCategoryId: categoryAc.id,
          subSkillIds,
          experienceTier: ExperienceTier.SENIOR_6_8Y,
          coverageZoneIds: [zoneCairo.id],
          acceptsStandardRateCard: true,
          toolkitCommitmentConfirmed: true,
          specialtyEn: 'Senior Split & Duct AC Specialist',
          specialtyAr: 'أخصائي تكييف سبليت ومركزي',
          estimatedPriceEgp: 350,
        },
      );

      expect(step2.step1Complete).toBe(true);
      expect(step2.step2Complete).toBe(true);
      expect(step2.step3Complete).toBe(false);
      expect(step2.subSkills).toHaveLength(2);
    });

    it('enforces required documents before submission and keeps uploaded documents private (Screen 13)', async () => {
      // Submitting before uploading all 3 required documents must fail
      await expect(
        proService.submitForVerification(proApplicantUser.id),
      ).rejects.toThrow(/Missing required verification documents/);

      // Upload required synthetic documents
      const frontDoc = await proService.uploadVerificationDocument(
        proApplicantUser.id,
        {
          docType: DocumentType.NATIONAL_ID_FRONT,
          fileName: 'synthetic-id-front.png',
          mimeType: 'image/png',
          contentBase64: VALID_PNG_BASE64,
        },
      );
      expect(frontDoc.status).toBe(DocumentStatus.PENDING);
      expect(frontDoc.hasPrivateContent).toBe(true);
      uploadedDocId = frontDoc.id;

      await proService.uploadVerificationDocument(proApplicantUser.id, {
        docType: DocumentType.NATIONAL_ID_BACK,
        fileName: 'synthetic-id-back.png',
        mimeType: 'image/png',
        contentBase64: VALID_PNG_BASE64,
      });

      await proService.uploadVerificationDocument(proApplicantUser.id, {
        docType: DocumentType.CRIMINAL_RECORD_CERT,
        fileName: 'synthetic-criminal-record.png',
        mimeType: 'image/png',
        contentBase64: VALID_PNG_BASE64,
      });

      // Another customer CANNOT access the private document
      await expect(
        proService.getVerificationDocumentAccess(
          customerUser.id,
          uploadedDocId,
          false,
        ),
      ).rejects.toThrow(ForbiddenException);

      // Owner CAN access short-lived signed document
      const ownerAccess = await proService.getVerificationDocumentAccess(
        proApplicantUser.id,
        uploadedDocId,
        false,
      );
      expect(ownerAccess.accessToken).toBeDefined();
      expect(ownerAccess.privateDataUri).toContain('data:image/png;base64,');

      // Submit for review -> transitions DRAFT -> PENDING_REVIEW
      const submittedStatus = await proService.submitForVerification(
        proApplicantUser.id,
      );
      expect(submittedStatus.verificationStatus).toBe(
        ProVerificationStatus.PENDING_REVIEW,
      );
    });

    it('forbids self-approval or going online while PENDING_REVIEW, and requires ADMIN reviewer approval (Screen 14)', async () => {
      // Unapproved pro cannot toggle online availability
      await expect(
        proService.updateAvailability(proApplicantUser.id, { isOnline: true }),
      ).rejects.toThrow(ForbiddenException);

      // Applicant cannot self-approve via admin review endpoint
      await expect(
        proService.adminReviewProProfile(
          proApplicantUser.id,
          UserRole.CUSTOMER,
          applicantProfileId,
          { status: 'APPROVED' },
        ),
      ).rejects.toThrow(ForbiddenException);

      // Authorized ADMIN reviewer approves the dossier
      const approved = await proService.adminReviewProProfile(
        adminReviewerUser.id,
        UserRole.ADMIN,
        applicantProfileId,
        {
          status: 'APPROVED',
          reviewerNote: 'Verified synthetic dossier for dispatch.',
        },
      );

      expect(approved.verificationStatus).toBe(ProVerificationStatus.APPROVED);
      expect(
        approved.documents.every((d: any) => d.status === DocumentStatus.VERIFIED),
      ).toBe(true);

      // Verify user role was promoted to PRO in PostgreSQL
      const updatedUser = await prisma.user.findUnique({
        where: { id: proApplicantUser.id },
      });
      expect(updatedUser?.role).toBe(UserRole.PRO);
    });
  });

  describe('Screens 15–16: Availability, Atomic Offer Acceptance, Arrival PIN Verification & Completion', () => {
    let competingProProfile: any;
    let bookingId: string;
    let customerArrivalPin: string;

    beforeAll(async () => {
      // Create a second APPROVED online pro in the same category and zone
      competingProProfile = await prisma.proProfile.create({
        data: {
          userId: proCompetingUser.id,
          dossierCode: 'FX-PRO-7702',
          nationalIdSynthetic: '28801010105555',
          primaryCategoryId: categoryAc.id,
          primaryZoneId: zoneCairo.id,
          verificationStatus: ProVerificationStatus.APPROVED,
          isOnline: true,
          coverageZones: {
            connect: [{ id: zoneCairo.id }],
          },
        },
      });
    });

    it('matches customer checkout to online pros and enforces atomic acceptance so two pros cannot accept the same job', async () => {
      // 1. Approved applicant pro goes online
      const onlineProfile = await proService.updateAvailability(
        proApplicantUser.id,
        { isOnline: true },
      );
      expect(onlineProfile.isOnline).toBe(true);

      // 2. Customer creates and checks out a booking in the same category & zone
      const tomorrowStr = new Date(Date.now() + 86400000)
        .toISOString()
        .split('T')[0];
      const draft = await bookingsService.createBooking(customerUser.id, {
        offeringId: offeringAc.id,
        addressId: customerAddress.id,
        scheduledDate: tomorrowStr,
        timeWindow: TimeWindow.AFTERNOON_13_16,
        issueDescription: 'AC compressor needs cleaning and gas check',
      });
      bookingId = draft.id;
      customerArrivalPin = draft.arrivalPinCode;

      await bookingsService.checkoutBooking(customerUser.id, bookingId, {
        paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
      });

      // 3. Both online pros fetch their dashboards and see a PENDING JobOffer for this booking
      const [dashApplicant, dashCompeting] = await Promise.all([
        proService.getDashboard(proApplicantUser.id),
        proService.getDashboard(proCompetingUser.id),
      ]);

      const offerApplicant = dashApplicant.activeOffers.find(
        (o: any) => o.bookingId === bookingId,
      );
      const offerCompeting = dashCompeting.activeOffers.find(
        (o: any) => o.bookingId === bookingId,
      );

      expect(offerApplicant).toBeDefined();
      expect(offerCompeting).toBeDefined();

      // 4. Concurrent race test: both pros try to accept their offer for the SAME booking simultaneously
      const raceResults = await Promise.allSettled([
        proService.acceptJobOffer(proApplicantUser.id, offerApplicant!.id),
        proService.acceptJobOffer(proCompetingUser.id, offerCompeting!.id),
      ]);

      const fulfilled = raceResults.filter((r) => r.status === 'fulfilled');
      const rejected = raceResults.filter((r) => r.status === 'rejected');

      // Strictly 1 pro must succeed and 1 pro must be rejected
      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(1);

      // Ensure our applicant pro is the assigned pro for the subsequent execution test
      const dbBooking = await prisma.booking.findUnique({
        where: { id: bookingId },
      });
      expect(dbBooking?.status).toBe(BookingStatus.CONFIRMED);
      expect(dbBooking?.proProfileId).not.toBeNull();

      if (dbBooking?.proProfileId === competingProProfile.id) {
        // Reassign to applicant pro for the step-by-step execution test below
        await prisma.booking.update({
          where: { id: bookingId },
          data: { proProfileId: onlineProfile.id },
        });
      }
    });

    it('enforces valid state transitions, server-side 4-digit arrival PIN verification with bounded attempts, and completion payout', async () => {
      // Cannot jump directly from CONFIRMED to IN_PROGRESS
      await expect(
        proService.advanceBookingStatus(proApplicantUser.id, bookingId, {
          toStatus: 'IN_PROGRESS',
          arrivalPinCode: customerArrivalPin,
        }),
      ).rejects.toThrow(BadRequestException);

      // 1. CONFIRMED -> PRO_EN_ROUTE
      const enRoute = await proService.advanceBookingStatus(
        proApplicantUser.id,
        bookingId,
        { toStatus: 'PRO_EN_ROUTE' },
      );
      expect(enRoute.status).toBe(BookingStatus.PRO_EN_ROUTE);
      expect(enRoute.arrivalPinCode).toBe('****'); // Pro never receives customer PIN

      // 2. PRO_EN_ROUTE -> ARRIVED
      const arrived = await proService.advanceBookingStatus(
        proApplicantUser.id,
        bookingId,
        { toStatus: 'ARRIVED' },
      );
      expect(arrived.status).toBe(BookingStatus.ARRIVED);

      // 3. Wrong Arrival PIN is rejected and decrements remaining attempts
      const wrongPin = customerArrivalPin === '0000' ? '9999' : '0000';
      await expect(
        proService.advanceBookingStatus(proApplicantUser.id, bookingId, {
          toStatus: 'IN_PROGRESS',
          arrivalPinCode: wrongPin,
        }),
      ).rejects.toThrow(/Invalid 4-digit Arrival PIN code\. 4 attempt\(s\) remaining/);

      // 4. Correct customer Arrival PIN transitions ARRIVED -> IN_PROGRESS
      const inProgress = await proService.advanceBookingStatus(
        proApplicantUser.id,
        bookingId,
        {
          toStatus: 'IN_PROGRESS',
          arrivalPinCode: customerArrivalPin,
        },
      );
      expect(inProgress.status).toBe(BookingStatus.IN_PROGRESS);

      // 5. IN_PROGRESS -> COMPLETED (marks CASH_ON_SERVICE PaymentRecord PAID and updates earnings)
      const completed = await proService.advanceBookingStatus(
        proApplicantUser.id,
        bookingId,
        { toStatus: 'COMPLETED' },
      );
      expect(completed.status).toBe(BookingStatus.COMPLETED);
      expect(completed.completedAt).not.toBeNull();

      const dbPayment = await prisma.paymentRecord.findUnique({
        where: { bookingId },
      });
      expect(dbPayment?.status).toBe(PaymentStatus.PAID);
      expect(dbPayment?.paidAt).not.toBeNull();

      // 6. Pro Dashboard reflects actual net earnings from the completed booking
      const dashAfter = await proService.getDashboard(proApplicantUser.id);
      expect(dashAfter.earningsSummary.todayNetEarningsEgp).toBe(
        completed.pricing.netArtisanEgp,
      );
      expect(dashAfter.earningsSummary.todayCompletedCount).toBe(1);
      expect(dashAfter.earningsSummary.totalCompletedJobsCount).toBe(1);
    });

    it('blocks ARRIVED -> IN_PROGRESS after 5 failed PIN attempts', async () => {
      const tomorrowStr = new Date(Date.now() + 86400000)
        .toISOString()
        .split('T')[0];
      const bk = await bookingsService.createBooking(customerUser.id, {
        offeringId: offeringAc.id,
        addressId: customerAddress.id,
        scheduledDate: tomorrowStr,
        timeWindow: TimeWindow.EVENING_17_20,
      });

      const applicantPro = await proService.getMyProProfile(
        proApplicantUser.id,
      );

      await prisma.booking.update({
        where: { id: bk.id },
        data: {
          proProfileId: applicantPro!.id,
          status: BookingStatus.ARRIVED,
        },
      });

      const wrongPin = bk.arrivalPinCode === '1111' ? '2222' : '1111';
      for (let i = 0; i < 5; i++) {
        await expect(
          proService.advanceBookingStatus(proApplicantUser.id, bk.id, {
            toStatus: 'IN_PROGRESS',
            arrivalPinCode: wrongPin,
          }),
        ).rejects.toThrow(BadRequestException);
      }

      // 6th attempt even with the CORRECT PIN must be blocked with ForbiddenException
      await expect(
        proService.advanceBookingStatus(proApplicantUser.id, bk.id, {
          toStatus: 'IN_PROGRESS',
          arrivalPinCode: bk.arrivalPinCode,
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
