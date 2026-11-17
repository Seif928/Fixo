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
import { PrivateStorageService } from '../media/private-storage.service';
import { dossierReviewVersion } from './dossier-review-version';
const sharp: typeof import('sharp').default = require('sharp');

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

// Minimal valid PNG binary header for synthetic specimen tests
let VALID_PNG_BASE64: string;

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
  const privateObjects = new Map<string, Buffer>();

  beforeAll(async () => {
    VALID_PNG_BASE64 = (
      await sharp({
        create: { width: 32, height: 32, channels: 3, background: '#173f35' },
      })
        .png()
        .toBuffer()
    ).toString('base64');
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    testDbUrl = process.env.TEST_DATABASE_URL!;

    process.env.TEST_DATABASE_URL = testDbUrl;
    process.env.DATABASE_URL = testDbUrl;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    moduleRef = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule, BookingsModule, ProModule],
    })
      .overrideProvider(PrivateStorageService)
      .useValue({
        put: async (key: string, bytes: Buffer) => {
          privateObjects.set(key, bytes);
          return key;
        },
        get: async (key: string) => privateObjects.get(key),
        remove: async (key: string) => {
          privateObjects.delete(key);
        },
      })
      .compile();

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
        email: 'pro-reviewer-fixture@example.test',
        role: UserRole.ADMIN,
      },
    });

    await prisma.adminMembership.create({
      data: {
        slot: 2,
        email: adminReviewerUser.email,
        userId: adminReviewerUser.id,
        role: 'ADMIN',
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
      await safeCleanupBookingTestTables(prisma, {
        testDatabaseUrl: testDbUrl,
      });
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
        },
      );

      expect(step1.dossierCode).toMatch(/^FX-PRO-\d{4}$/);
      expect(step1.verificationStatus).toBe(ProVerificationStatus.DRAFT);
      expect(step1.step1Complete).toBe(true);
      expect(step1.primaryZoneId).toBeNull();
      expect(step1.transportMode).toBeNull();
      expect(step1.vehicleDescription).toBeNull();
      expect(step1.coverageZones).toHaveLength(0);
      expect(step1.fullName).toBe('Karim HVAC Master');
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
      expect(step2.primaryZoneId).toBe(zoneCairo.id);
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
        ),
      ).rejects.toThrow(ForbiddenException);

      // Owner CAN access short-lived signed document
      const ownerAccess = await proService.getVerificationDocumentAccess(
        proApplicantUser.id,
        uploadedDocId,
      );
      expect(ownerAccess.downloadPath).toBe(
        `/api/v1/pro/onboarding/documents/${uploadedDocId}/content`,
      );
      expect(JSON.stringify(ownerAccess)).not.toContain('base64');
      const stored = await prisma.proVerificationDocument.findUniqueOrThrow({
        where: { id: uploadedDocId },
      });
      expect(stored.storageKey).toMatch(
        /^obj::[a-f0-9]+::image\/webp::documents\//,
      );
      expect(privateObjects.size).toBe(3);

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
          {
            userId: proApplicantUser.id,
            role: 'ADMIN',
            authTime: Math.floor(Date.now() / 1000),
          },
          applicantProfileId,
          { status: 'APPROVED' },
        ),
      ).rejects.toThrow(ForbiddenException);

      // Authorized ADMIN reviewer approves the dossier
      const approved = await proService.adminReviewProProfile(
        {
          userId: adminReviewerUser.id,
          role: 'ADMIN',
          authTime: Math.floor(Date.now() / 1000),
        },
        applicantProfileId,
        {
          status: 'APPROVED',
          reviewVersion: dossierReviewVersion(
            await prisma.proProfile.findUniqueOrThrow({
              where: { id: applicantProfileId },
              include: { documents: true },
            }),
          ),
          confirmDocumentsReviewed: true,
          reviewerNote: 'Verified synthetic dossier for dispatch.',
        },
      );

      expect(approved.verificationStatus).toBe(ProVerificationStatus.APPROVED);
      expect(
        approved.documents.every(
          (d: any) => d.status === DocumentStatus.VERIFIED,
        ),
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
      ).rejects.toThrow(
        /Invalid 4-digit Arrival PIN code\. 4 attempt\(s\) remaining/,
      );

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
      const completions = await Promise.all(
        Array.from({ length: 3 }, () =>
          proService.advanceBookingStatus(proApplicantUser.id, bookingId, {
            toStatus: 'COMPLETED',
          }),
        ),
      );
      const completed = completions[0];
      expect(
        completions.every(
          (result) => result.status === BookingStatus.COMPLETED,
        ),
      ).toBe(true);
      expect(completed.status).toBe(BookingStatus.COMPLETED);
      expect(completed.completedAt).not.toBeNull();
      expect(
        await prisma.bookingStatusEvent.count({
          where: { bookingId, toStatus: BookingStatus.COMPLETED },
        }),
      ).toBe(1);

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
      const attempts = await Promise.allSettled(
        Array.from({ length: 8 }, () =>
          proService.advanceBookingStatus(proApplicantUser.id, bk.id, {
            toStatus: 'IN_PROGRESS',
            arrivalPinCode: wrongPin,
          }),
        ),
      );
      expect(attempts.every((attempt) => attempt.status === 'rejected')).toBe(
        true,
      );
      expect(
        await prisma.bookingStatusEvent.count({
          where: {
            bookingId: bk.id,
            fromStatus: BookingStatus.ARRIVED,
            toStatus: BookingStatus.ARRIVED,
          },
        }),
      ).toBe(5);

      // 6th attempt even with the CORRECT PIN must be blocked with ForbiddenException
      await expect(
        proService.advanceBookingStatus(proApplicantUser.id, bk.id, {
          toStatus: 'IN_PROGRESS',
          arrivalPinCode: bk.arrivalPinCode,
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('Approval revocation at the final decision', () => {
    it('includes an eligible preferred professional before applying the five-offer limit', async () => {
      const suffix = Date.now().toString();
      const users: string[] = [];
      try {
        for (let index = 0; index < 6; index++) {
          const user = await prisma.user.create({
            data: { fullName: 'Local preferred-pro fixture' },
          });
          users.push(user.id);
          await prisma.proProfile.create({
            data: {
              id: `z-pref-${suffix}-${index}`,
              userId: user.id,
              dossierCode: `TEST-PREF-${suffix}-${index}`,
              nationalIdSynthetic: '90000000000000',
              primaryCategoryId: categoryAc.id,
              primaryZoneId: zoneCairo.id,
              verificationStatus: ProVerificationStatus.APPROVED,
              isOnline: true,
            },
          });
          expect(
            (
              await prisma.proProfile.findUniqueOrThrow({
                where: { userId: user.id },
              })
            ).ratingAvg,
          ).toBe(0);
        }
        const preferred = `z-pref-${suffix}-5`;
        const draft = await bookingsService.createBooking(customerUser.id, {
          offeringId: offeringAc.id,
          addressId: customerAddress.id,
          preferredProId: preferred,
          scheduledDate: new Date(Date.now() + 86400000)
            .toISOString()
            .slice(0, 10),
          timeWindow: TimeWindow.MORNING_09_12,
        });
        await bookingsService.checkoutBooking(customerUser.id, draft.id, {
          paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
        });
        const offers = await prisma.jobOffer.findMany({
          where: { bookingId: draft.id },
        });
        expect(offers).toHaveLength(5);
        expect(offers.some((offer) => offer.proProfileId === preferred)).toBe(
          true,
        );
      } finally {
        await prisma.user.deleteMany({ where: { id: { in: users } } });
      }
    });
    it('database rejects duplicate pending invitations while preserving offer history', async () => {
      const profile = await prisma.proProfile.findUniqueOrThrow({
        where: { userId: proCompetingUser.id },
      });
      const draft = await bookingsService.createBooking(customerUser.id, {
        offeringId: offeringAc.id,
        addressId: customerAddress.id,
        scheduledDate: new Date(Date.now() + 86400000)
          .toISOString()
          .slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });
      const data = {
        bookingId: draft.id,
        proProfileId: profile.id,
        expiresAt: new Date(Date.now() + 300000),
        status: JobOfferStatus.PENDING,
      };
      const original = await prisma.jobOffer.create({ data });
      await expect(prisma.jobOffer.create({ data })).rejects.toMatchObject({
        code: 'P2002',
      });
      await prisma.jobOffer.update({
        where: { id: original.id },
        data: { status: JobOfferStatus.EXPIRED },
      });
      await prisma.jobOffer.create({ data });
      expect(
        await prisma.jobOffer.count({ where: { bookingId: draft.id } }),
      ).toBe(2);
    });
    it('counts every completion in the period even when there are more than fifty', async () => {
      const profile = await prisma.proProfile.findUniqueOrThrow({
        where: { userId: proCompetingUser.id },
      });
      const before = await proService.getDashboard(proCompetingUser.id);
      const now = new Date();
      const created = await prisma.booking.createMany({
        data: Array.from({ length: 60 }, (_, i) => ({
          orderCode: `EARN-${now.getTime()}-${i}`,
          customerId: customerUser.id,
          proProfileId: profile.id,
          offeringId: offeringAc.id,
          addressId: customerAddress.id,
          status: BookingStatus.COMPLETED,
          scheduledDate: now,
          timeWindow: TimeWindow.MORNING_09_12,
          completedAt: now,
          arrivalPinCode: '1234',
          baseInspectionEgp: 100,
          serviceFeeEgp: 0,
          transportFeeEgp: 0,
          totalEgp: 100,
          platformFeeEgp: 10,
          netArtisanEgp: 90,
        })),
      });
      expect(created.count).toBe(60);
      try {
        const after = await proService.getDashboard(proCompetingUser.id);
        expect(
          after.earningsSummary.todayCompletedCount -
            before.earningsSummary.todayCompletedCount,
        ).toBe(60);
        expect(
          after.earningsSummary.weeklyNetEarningsEgp -
            before.earningsSummary.weeklyNetEarningsEgp,
        ).toBe(5400);
        expect(after.recentCompletedJobs).toHaveLength(10);
      } finally {
        await prisma.booking.deleteMany({
          where: { orderCode: { startsWith: `EARN-${now.getTime()}-` } },
        });
      }
    });
    it('does not decline a job accepted after a stale offer read', async () => {
      const profile = await prisma.proProfile.findUniqueOrThrow({
        where: { userId: proCompetingUser.id },
      });
      const draft = await bookingsService.createBooking(customerUser.id, {
        offeringId: offeringAc.id,
        addressId: customerAddress.id,
        scheduledDate: new Date(Date.now() + 86400000)
          .toISOString()
          .slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });
      const offer = await prisma.jobOffer.create({
        data: {
          bookingId: draft.id,
          proProfileId: profile.id,
          status: JobOfferStatus.PENDING,
          expiresAt: new Date(Date.now() + 300000),
        },
      });
      const spy = jest
        .spyOn(prisma.jobOffer as any, 'findUnique')
        .mockImplementationOnce(async () => {
          await prisma.jobOffer.update({
            where: { id: offer.id },
            data: { status: JobOfferStatus.ACCEPTED, respondedAt: new Date() },
          });
          return offer;
        });
      try {
        await expect(
          proService.declineJobOffer(proCompetingUser.id, offer.id, {}),
        ).rejects.toThrow();
        expect(
          (await prisma.jobOffer.findUniqueOrThrow({ where: { id: offer.id } }))
            .status,
        ).toBe(JobOfferStatus.ACCEPTED);
      } finally {
        spy.mockRestore();
      }
    });
    it('dispatches governorate coverage to a child district without broadening district-only pros', async () => {
      const profile = await prisma.proProfile.findUniqueOrThrow({
        where: { userId: proCompetingUser.id },
      });
      const governorate = await prisma.coverageZone.findUniqueOrThrow({
        where: { slug: 'cairo' },
      });
      const maadi = await prisma.coverageZone.findUniqueOrThrow({
        where: { slug: 'maadi' },
      });
      await prisma.proProfile.update({
        where: { id: profile.id },
        data: {
          isOnline: true,
          coverageZones: { connect: { id: governorate.id } },
        },
      });
      try {
        const address = await prisma.customerAddress.create({
          data: {
            userId: customerUser.id,
            zoneId: maadi.id,
            label: 'Test',
            buildingLine: 'Test building',
            districtLine: 'Maadi',
          },
        });
        const draft = await bookingsService.createBooking(customerUser.id, {
          offeringId: offeringAc.id,
          addressId: address.id,
          scheduledDate: new Date(Date.now() + 86400000)
            .toISOString()
            .slice(0, 10),
          timeWindow: TimeWindow.MORNING_09_12,
        });
        await bookingsService.checkoutBooking(customerUser.id, draft.id, {
          paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
        });
        const offers = await prisma.jobOffer.findMany({
          where: { bookingId: draft.id },
        });
        expect(offers.map((o) => o.proProfileId)).toEqual([profile.id]);
      } finally {
        await prisma.proProfile.update({
          where: { id: profile.id },
          data: { coverageZones: { disconnect: { id: governorate.id } } },
        });
      }
    });
    it('keeps a decided offer when a stale detail response tries to expire it', async () => {
      const profile = await prisma.proProfile.findUniqueOrThrow({
        where: { userId: proCompetingUser.id },
      });
      const draft = await bookingsService.createBooking(customerUser.id, {
        offeringId: offeringAc.id,
        addressId: customerAddress.id,
        scheduledDate: new Date(Date.now() + 86400000)
          .toISOString()
          .slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });
      const offer = await prisma.jobOffer.create({
        data: {
          bookingId: draft.id,
          proProfileId: profile.id,
          expiresAt: new Date(Date.now() - 1000),
          status: JobOfferStatus.PENDING,
        },
      });
      const stale = await prisma.jobOffer.findUniqueOrThrow({
        where: { id: offer.id },
        include: {
          booking: {
            include: {
              offering: { include: { category: true } },
              address: { include: { zone: true } },
              customer: true,
            },
          },
        },
      });
      const spy = jest
        .spyOn(prisma.jobOffer as any, 'findUnique')
        .mockImplementationOnce(async () => {
          await prisma.$transaction([
            prisma.booking.update({
              where: { id: draft.id },
              data: {
                status: BookingStatus.CONFIRMED,
                proProfileId: profile.id,
              },
            }),
            prisma.jobOffer.update({
              where: { id: offer.id },
              data: {
                status: JobOfferStatus.ACCEPTED,
                respondedAt: new Date(),
              },
            }),
          ]);
          return stale;
        });
      try {
        const result = await proService.getJobOfferById(
          proCompetingUser.id,
          offer.id,
        );
        expect(result.status).toBe(JobOfferStatus.ACCEPTED);
        expect(
          (await prisma.jobOffer.findUniqueOrThrow({ where: { id: offer.id } }))
            .status,
        ).toBe(JobOfferStatus.ACCEPTED);
      } finally {
        spy.mockRestore();
      }
    });

    it('creates one offer per technician under concurrent checkout and dashboard polls', async () => {
      await prisma.proProfile.update({
        where: { userId: proCompetingUser.id },
        data: { verificationStatus: 'APPROVED', isOnline: true },
      });
      const draft = await bookingsService.createBooking(customerUser.id, {
        offeringId: offeringAc.id,
        addressId: customerAddress.id,
        scheduledDate: new Date(Date.now() + 86400000)
          .toISOString()
          .slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });
      await Promise.all(
        Array.from({ length: 6 }, () =>
          bookingsService.checkoutBooking(customerUser.id, draft.id, {
            paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
          }),
        ),
      );
      await Promise.all(
        Array.from({ length: 6 }, () =>
          proService.getDashboard(proCompetingUser.id),
        ),
      );
      const pairs = await prisma.jobOffer.groupBy({
        by: ['bookingId', 'proProfileId'],
        where: { bookingId: draft.id },
        _count: { id: true },
      });
      expect(pairs.length).toBeGreaterThan(0);
      expect(pairs.every((pair) => pair._count.id === 1)).toBe(true);
    });
    for (const action of ['online', 'accept'] as const) {
      it(`rejects ${action} when approval changes after the initial profile read`, async () => {
        const profile = await prisma.proProfile.findUniqueOrThrow({
          where: { userId: proCompetingUser.id },
        });
        await prisma.proProfile.update({
          where: { id: profile.id },
          data: { verificationStatus: 'APPROVED', isOnline: true },
        });
        let offerId = 'unused';
        if (action === 'accept') {
          const draft = await bookingsService.createBooking(customerUser.id, {
            offeringId: offeringAc.id,
            addressId: customerAddress.id,
            scheduledDate: new Date(Date.now() + 86400000)
              .toISOString()
              .slice(0, 10),
            timeWindow: TimeWindow.MORNING_09_12,
          });
          await bookingsService.checkoutBooking(customerUser.id, draft.id, {
            paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
          });
          offerId = (
            await prisma.jobOffer.findFirstOrThrow({
              where: { bookingId: draft.id, proProfileId: profile.id },
            })
          ).id;
        }
        const stale = await prisma.proProfile.findUniqueOrThrow({
          where: { id: profile.id },
        });
        const spy = jest
          .spyOn(prisma.proProfile as any, 'findUnique')
          .mockImplementationOnce(async () => {
            await prisma.proProfile.update({
              where: { id: profile.id },
              data: { verificationStatus: 'SUSPENDED', isOnline: false },
            });
            return stale;
          });
        try {
          await expect(
            action === 'online'
              ? proService.updateAvailability(proCompetingUser.id, {
                  isOnline: true,
                })
              : proService.acceptJobOffer(proCompetingUser.id, offerId),
          ).rejects.toThrow(ForbiddenException);
          expect(
            (
              await prisma.proProfile.findUniqueOrThrow({
                where: { id: profile.id },
              })
            ).isOnline,
          ).toBe(false);
        } finally {
          spy.mockRestore();
          await prisma.proProfile.update({
            where: { id: profile.id },
            data: { verificationStatus: 'APPROVED', isOnline: false },
          });
        }
      });
    }
  });
});
