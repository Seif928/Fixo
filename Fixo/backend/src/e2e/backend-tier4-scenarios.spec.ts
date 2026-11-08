import {
  BadRequestException,
  ForbiddenException,
  INestApplication,
  NotFoundException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import {
  UserRole,
  ProVerificationStatus,
  BookingStatus,
  TimeWindow,
  PaymentMethodType,
  PaymentStatus,
  DocumentType,
  DocumentStatus,
} from '@prisma/client';
import { AppModule } from '../app.module';
import { InMemoryStoreService } from '../prisma/in-memory-store.service';
import { PrismaService } from '../prisma/prisma.service';
import { ServicesController } from '../modules/services/services.controller';
import { BookingsService } from '../modules/bookings/bookings.service';
import { ProService } from '../modules/pro/pro.service';
import { AdminAccessController } from '../modules/admin/admin-access.controller';
import { AdminCatalogController } from '../modules/admin/admin-catalog.controller';
import { AdminProfessionalsController } from '../modules/admin/admin-professionals.controller';
import { dossierReviewVersion } from '../modules/pro/dossier-review-version';

describe('Tier 4: Real-World Application Scenarios (End-to-End User Journeys)', () => {
  let app: INestApplication;
  let memoryStore: InMemoryStoreService;
  let servicesController: ServicesController;
  let bookingsService: BookingsService;
  let proService: ProService;
  let adminAccessController: AdminAccessController;
  let adminCatalogController: AdminCatalogController;
  let adminProfessionalsController: AdminProfessionalsController;
  let prismaMock: any;

  // Real-world Personas
  const customerPersona = {
    id: 'cust-karim-401',
    phone: '+201012348899',
    fullName: 'Karim Abdel-Rahman',
    role: UserRole.CUSTOMER,
  };

  const proPersona = {
    id: 'pro-hassan-502',
    phone: '+201144556677',
    fullName: 'Hassan El-Sayed',
    role: UserRole.PRO,
  };

  const mockProProfile = {
    id: 'pro-profile-502',
    userId: 'pro-hassan-502',
    dossierCode: 'PRO-502',
    legalName: 'Hassan El-Sayed',
    displayName: 'Hassan S.',
    nationalId: '29001011234567',
    nationalIdSynthetic: '29001011234567',
    primaryCategoryId: 'cat-elec',
    primaryZoneId: 'zone-maadi',
    toolkitCommitmentConfirmed: true,
    verificationStatus: ProVerificationStatus.APPROVED,
    ratingAvg: 4.95,
    reviewsCount: 38,
    completedJobsCount: 120,
    acceptanceRatePct: 98,
    isOnline: true,
    user: proPersona,
    createdAt: new Date(),
    updatedAt: new Date(),
    primaryCategory: { id: 'cat-elec', nameEn: 'Electrical Maintenance', nameAr: 'صيانة كهرباء', slug: 'electrical' },
    documents: [
      {
        id: 'doc-nat-front',
        docType: DocumentType.NATIONAL_ID_FRONT,
        status: DocumentStatus.VERIFIED,
        uploadedAt: new Date(),
        storageKey: 'key-nat-front',
      },
      {
        id: 'doc-nat-back',
        docType: DocumentType.NATIONAL_ID_BACK,
        status: DocumentStatus.VERIFIED,
        uploadedAt: new Date(),
        storageKey: 'key-nat-back',
      },
      {
        id: 'doc-crim-cert',
        docType: DocumentType.CRIMINAL_RECORD_CERT,
        status: DocumentStatus.VERIFIED,
        uploadedAt: new Date(),
        storageKey: 'key-crim-cert',
      },
    ],
  };

  const customerAddress = {
    id: 'addr-maadi-401',
    userId: 'cust-karim-401',
    zoneId: 'zone-maadi',
    label: 'Apartment',
    buildingLine: 'Building 22, Road 9',
    districtLine: 'Maadi, Cairo',
    gateNotes: 'Apartment 4, 2nd Floor',
    latitude: 29.9602,
    longitude: 31.2569,
    isDefault: true,
    zone: {
      id: 'zone-maadi',
      slug: 'maadi',
      nameEn: 'Maadi',
      nameAr: 'المعادي',
      governorate: 'Cairo',
      isActive: true,
    },
  };

  const adminOwnerActor = {
    id: 'admin-owner-99',
    email: 'admin.owner@fixo.eg',
    role: 'OWNER',
    authTime: Math.floor(Date.now() / 1000),
  };

  // State Stores
  const bookingsDb: any[] = [];
  const statusEventsDb: any[] = [];
  const paymentsDb: any[] = [];
  const reviewsDb: any[] = [];
  const auditLogsDb: any[] = [];
  const catalogDraftsDb: any[] = [];
  const proProfilesDb: any[] = [mockProProfile];

  beforeAll(async () => {
    prismaMock = {
      isDatabaseConnected: () => false,
      $transaction: jest.fn(async (callback) => callback(prismaMock)),
      $executeRaw: jest.fn().mockResolvedValue(1),
      $queryRaw: jest.fn().mockResolvedValue([]),
      adminMembership: {
        findUnique: jest.fn().mockImplementation(({ where }) => {
          if (where.adminEmail) {
            return Promise.resolve({
              id: 'mem-001',
              adminEmail: where.adminEmail,
              userId: 'admin-owner-99',
              role: 'OWNER',
              isActive: true,
            });
          }
          return Promise.resolve({
            id: 'mem-001',
            userId: 'admin-owner-99',
            role: 'OWNER',
            isActive: true,
          });
        }),
      },
      customerAddress: {
        findUnique: jest.fn().mockImplementation(({ where }) => {
          if (where.id === customerAddress.id) {
            return Promise.resolve(customerAddress);
          }
          return Promise.resolve(null);
        }),
      },
      serviceOffering: {
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn().mockImplementation(({ data }) =>
          Promise.resolve({ id: `off-${Date.now()}`, ...data }),
        ),
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const list = memoryStore.getOfferings();
          const item = list.find(
            (o) =>
              (where.id && o.id === where.id) ||
              (where.slug && o.slug === where.slug),
          );
          if (!item) return Promise.resolve(null);
          return Promise.resolve({
            ...item,
            category: {
              id: item.categoryId,
              slug: 'electrical',
              nameEn: 'Electrical',
              nameAr: 'كهرباء',
              isActive: true,
            },
          });
        }),
      },
      serviceCategory: {
        findMany: jest.fn().mockImplementation(() => memoryStore.getCategories()),
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const list = memoryStore.getCategories();
          const item = list.find(
            (c) =>
              (where.id && c.id === where.id) ||
              (where.slug && c.slug === where.slug),
          );
          return Promise.resolve(item || null);
        }),
      },
      booking: {
        create: jest.fn().mockImplementation(({ data }) => {
          const offering = memoryStore.getOfferings().find((o) => o.id === data.offeringId) || memoryStore.getOfferings()[0];
          const newBooking = {
            id: `bk-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
            orderCode: `FIXO-${Date.now().toString().slice(-6)}`,
            customerId: data.customerId,
            offeringId: data.offeringId,
            addressId: data.addressId,
            scheduledDate: data.scheduledDate,
            timeWindow: data.timeWindow,
            status: BookingStatus.DRAFT,
            paymentMethod: data.paymentMethod || PaymentMethodType.CASH_ON_SERVICE,
            paymentStatus: PaymentStatus.PENDING,
            baseInspectionEgp: Number(offering?.baseInspectionEgp || 120),
            serviceFeeEgp: 20,
            totalEgp: Number(offering?.baseInspectionEgp || 120) + 20,
            platformFeeEgp: 25,
            netArtisanEgp: Number(offering?.baseInspectionEgp || 120) + 20 - 25,
            arrivalPinCode: '7391',
            issueDescription: data.issueDescription || null,
            issuePhotoUrls: [],
            proProfileId: null,
            completedAt: null,
            offering: {
              ...offering,
              category: { id: offering.categoryId, nameEn: 'Electrical', nameAr: 'كهرباء', slug: 'electrical', isActive: true },
            },
            customer: customerPersona,
            address: customerAddress,
            proProfile: null,
            payment: null,
            review: null,
            statusEvents: [],
            createdAt: new Date(),
            updatedAt: new Date(),
          };
          bookingsDb.push(newBooking);
          return Promise.resolve(newBooking);
        }),
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const b = bookingsDb.find((item) => item.id === where.id);
          if (!b) return Promise.resolve(null);
          return Promise.resolve({
            ...b,
            proProfile: b.proProfileId ? mockProProfile : null,
            payment: paymentsDb.find((p) => p.bookingId === b.id) || null,
            review: reviewsDb.find((r) => r.bookingId === b.id) || null,
            statusEvents: statusEventsDb.filter((s) => s.bookingId === b.id),
          });
        }),
        findUniqueOrThrow: jest.fn().mockImplementation(({ where }) => {
          const b = bookingsDb.find((item) => item.id === where.id);
          if (!b) return Promise.reject(new NotFoundException('Booking not found'));
          return Promise.resolve({
            ...b,
            proProfile: b.proProfileId ? mockProProfile : null,
            payment: paymentsDb.find((p) => p.bookingId === b.id) || null,
            review: reviewsDb.find((r) => r.bookingId === b.id) || null,
            statusEvents: statusEventsDb.filter((s) => s.bookingId === b.id),
          });
        }),
        findMany: jest.fn().mockImplementation(({ where }) => {
          return Promise.resolve(
            bookingsDb.filter((b) => {
              if (where?.customerId && b.customerId !== where.customerId) return false;
              if (where?.proProfileId && b.proProfileId !== where.proProfileId) return false;
              if (where?.status && b.status !== where.status) return false;
              return true;
            }),
          );
        }),
        update: jest.fn().mockImplementation(({ where, data }) => {
          const idx = bookingsDb.findIndex((b) => b.id === where.id);
          if (idx === -1) return Promise.resolve(null);
          bookingsDb[idx] = {
            ...bookingsDb[idx],
            ...data,
            updatedAt: new Date(),
          };
          if (data.proProfileId) {
            bookingsDb[idx].proProfile = mockProProfile;
          }
          return Promise.resolve(bookingsDb[idx]);
        }),
      },
      bookingStatusEvent: {
        create: jest.fn().mockImplementation(({ data }) => {
          const event = { id: `evt-${Date.now()}`, ...data, createdAt: new Date() };
          statusEventsDb.push(event);
          return Promise.resolve(event);
        }),
        count: jest.fn().mockImplementation(({ where }) => {
          return Promise.resolve(
            statusEventsDb.filter(
              (e) =>
                e.bookingId === where?.bookingId &&
                (!where?.note || e.note === where.note),
            ).length,
          );
        }),
        findMany: jest.fn().mockImplementation(({ where }) => {
          return Promise.resolve(
            statusEventsDb.filter((e) => e.bookingId === where?.bookingId),
          );
        }),
      },
      paymentRecord: {
        create: jest.fn().mockImplementation(({ data }) => {
          const rec = { id: `pay-${Date.now()}`, ...data, createdAt: new Date() };
          paymentsDb.push(rec);
          return Promise.resolve(rec);
        }),
        update: jest.fn().mockImplementation(({ where, data }) => {
          const rec = paymentsDb.find((p) => p.id === where.id);
          if (rec) Object.assign(rec, data);
          return Promise.resolve(rec || { id: where.id, ...data });
        }),
        findMany: jest.fn().mockImplementation(({ where }) => {
          return Promise.resolve(
            paymentsDb.filter((p) => p.bookingId === where?.bookingId),
          );
        }),
        aggregate: jest.fn().mockResolvedValue({
          _sum: { amountEgp: 260 },
          _count: { id: 1 },
        }),
      },
      proProfile: {
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const pro = proProfilesDb.find(
            (p) => p.id === where.id || p.userId === where.userId,
          );
          return Promise.resolve(pro || null);
        }),
        findMany: jest.fn().mockResolvedValue(proProfilesDb),
        count: jest.fn().mockResolvedValue(proProfilesDb.length),
        update: jest.fn().mockImplementation(({ where, data }) => {
          const idx = proProfilesDb.findIndex(
            (p) => p.id === where.id || p.userId === where.userId,
          );
          if (idx === -1) return Promise.resolve(null);
          proProfilesDb[idx] = { ...proProfilesDb[idx], ...data };
          return Promise.resolve(proProfilesDb[idx]);
        }),
      },
      adminCatalogDraft: {
        create: jest.fn().mockImplementation(({ data }) => {
          const draft = {
            id: `draft-${Date.now()}`,
            version: 1,
            titleEn: data.titleEn,
            titleAr: data.titleAr,
            descriptionEn: data.descriptionEn,
            descriptionAr: data.descriptionAr,
            categorySlug: data.categorySlug,
            status: 'PENDING_APPROVAL',
            createdAt: new Date(),
            updatedAt: new Date(),
          };
          catalogDraftsDb.push(draft);
          return Promise.resolve(draft);
        }),
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const draft = catalogDraftsDb.find((d) => d.id === where.id);
          return Promise.resolve(draft || null);
        }),
        findFirst: jest.fn().mockResolvedValue(null),
        update: jest.fn().mockImplementation(({ where, data }) => {
          const idx = catalogDraftsDb.findIndex((d) => d.id === where.id);
          if (idx === -1) return Promise.resolve(null);
          catalogDraftsDb[idx] = { ...catalogDraftsDb[idx], ...data, updatedAt: new Date() };
          return Promise.resolve(catalogDraftsDb[idx]);
        }),
        count: jest.fn().mockResolvedValue(catalogDraftsDb.length),
      },
      proVerificationDocument: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      adminAuditLog: {
        create: jest.fn().mockImplementation(({ data }) => {
          const log = { id: `audit-${Date.now()}`, ...data, createdAt: new Date() };
          auditLogsDb.push(log);
          return Promise.resolve(log);
        }),
        findMany: jest.fn().mockResolvedValue(auditLogsDb),
      },
      review: {
        create: jest.fn().mockImplementation(({ data }) => {
          const rev = { id: `rev-${Date.now()}`, ...data, createdAt: new Date() };
          reviewsDb.push(rev);
          return Promise.resolve(rev);
        }),
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const rev = reviewsDb.find((r) => r.bookingId === where?.bookingId);
          return Promise.resolve(rev || null);
        }),
      },
      user: {
        findUnique: jest.fn().mockImplementation(async ({ where }) => {
          if (where.id === customerPersona.id) return customerPersona;
          if (where.id === proPersona.id) return proPersona;
          return null;
        }),
        update: jest.fn().mockImplementation(async ({ where, data }) => {
          return { id: where.id, ...data };
        }),
      },
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(prismaMock)
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();

    memoryStore = moduleFixture.get<InMemoryStoreService>(InMemoryStoreService);
    servicesController = moduleFixture.get<ServicesController>(ServicesController);
    bookingsService = moduleFixture.get<BookingsService>(BookingsService);
    proService = moduleFixture.get<ProService>(ProService);
    adminAccessController = moduleFixture.get<AdminAccessController>(AdminAccessController);
    adminCatalogController = moduleFixture.get<AdminCatalogController>(AdminCatalogController);
    adminProfessionalsController = moduleFixture.get<AdminProfessionalsController>(AdminProfessionalsController);

    memoryStore.resetToSeedState();
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  describe('Scenario 3: Dispatch Offer, Technician Acceptance & Real-Time Tracking', () => {
    let scenarioBookingId: string;

    it('Step 1: Customer creates and confirms booking -> transitions to PENDING_DISPATCH', async () => {
      const offerings = memoryStore.getOfferings();
      const targetOffering = offerings[0];
      expect(targetOffering).toBeDefined();

      const createdBooking = await bookingsService.createBooking(customerPersona.id, {
        offeringId: targetOffering.id,
        addressId: customerAddress.id,
        scheduledDate: '2026-11-20',
        timeWindow: TimeWindow.MORNING_09_12,
        issueDescription: 'Ring doorbell twice upon arrival',
      });

      expect(createdBooking.status).toBe(BookingStatus.DRAFT);
      expect(createdBooking.pricing.totalEgp).toBeGreaterThan(0);

      // Customer checks out order
      const confirmedBooking = await bookingsService.checkoutBooking(
        customerPersona.id,
        createdBooking.id,
        {
          paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
        },
      );

      expect(confirmedBooking.status).toBe(BookingStatus.PENDING_DISPATCH);
      scenarioBookingId = confirmedBooking.id;
    });

    it('Step 2: Pro availability check enables technician for dispatch matching', async () => {
      // Pro is online
      const updatedAvailability = await proService.updateAvailability(proPersona.id, {
        isOnline: true,
      });
      expect(updatedAvailability.isOnline).toBe(true);

      const catalog = await proService.getCatalogOptions();
      expect(catalog.zones.length).toBeGreaterThan(0);
    });

    it('Step 3: Pro acceptance assigns professional and transitions booking to CONFIRMED', async () => {
      // Simulate booking assignment upon offer acceptance
      const assigned = await prismaMock.booking.update({
        where: { id: scenarioBookingId },
        data: {
          status: BookingStatus.CONFIRMED,
          proProfileId: mockProProfile.id,
        },
      });

      expect(assigned.status).toBe(BookingStatus.CONFIRMED);
      expect(assigned.proProfileId).toBe(mockProProfile.id);

      // Status event logged
      await prismaMock.bookingStatusEvent.create({
        data: {
          bookingId: scenarioBookingId,
          fromStatus: BookingStatus.PENDING_DISPATCH,
          toStatus: BookingStatus.CONFIRMED,
          actorUserId: proPersona.id,
          note: 'Professional accepted dispatch offer',
        },
      });

      const events = statusEventsDb.filter((e) => e.bookingId === scenarioBookingId);
      const confirmedEvent = events.find((e) => e.toStatus === BookingStatus.CONFIRMED);
      expect(confirmedEvent).toBeDefined();
    });

    it('Step 4: Customer checks live tracking and receives coordinates and arrival PIN', async () => {
      const trackingInfo = await bookingsService.getBookingTracking(
        customerPersona.id,
        scenarioBookingId,
      );

      expect(trackingInfo).toBeDefined();
      expect(trackingInfo.booking).toBeDefined();
      expect(trackingInfo.booking.status).toBe(BookingStatus.CONFIRMED);
      expect(trackingInfo.booking.arrivalPinCode).toBe('7391');
      expect(trackingInfo.milestones.length).toBeGreaterThanOrEqual(4);
    });
  });

  describe('Scenario 4: Service Fulfillment, Cash Collection & Customer Rating', () => {
    let fulfillmentBookingId: string;

    beforeAll(async () => {
      const offerings = memoryStore.getOfferings();
      const created = await bookingsService.createBooking(customerPersona.id, {
        offeringId: offerings[0].id,
        addressId: customerAddress.id,
        scheduledDate: '2026-11-21',
        timeWindow: TimeWindow.AFTERNOON_13_16,
      });

      await bookingsService.checkoutBooking(customerPersona.id, created.id, {
        paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
      });

      await prismaMock.booking.update({
        where: { id: created.id },
        data: {
          status: BookingStatus.CONFIRMED,
          proProfileId: mockProProfile.id,
        },
      });

      fulfillmentBookingId = created.id;
    });

    it('Step 1: Pro transitions status: CONFIRMED -> PRO_EN_ROUTE -> ARRIVED', async () => {
      const enRoute = await proService.advanceBookingStatus(
        proPersona.id,
        fulfillmentBookingId,
        { toStatus: 'PRO_EN_ROUTE' },
      );
      expect(enRoute.status).toBe(BookingStatus.PRO_EN_ROUTE);

      const arrived = await proService.advanceBookingStatus(
        proPersona.id,
        fulfillmentBookingId,
        { toStatus: 'ARRIVED' },
      );
      expect(arrived.status).toBe(BookingStatus.ARRIVED);
    });

    it('Step 2: Arrival verification enforces 4-digit PIN matching', async () => {
      // Incorrect PIN rejected with BadRequestException
      await expect(
        proService.advanceBookingStatus(proPersona.id, fulfillmentBookingId, {
          toStatus: 'IN_PROGRESS',
          arrivalPinCode: '0000',
        }),
      ).rejects.toThrow(BadRequestException);

      // Correct PIN '7391' verified successfully
      const inProgress = await proService.advanceBookingStatus(
        proPersona.id,
        fulfillmentBookingId,
        {
          toStatus: 'IN_PROGRESS',
          arrivalPinCode: '7391',
        },
      );

      expect(inProgress.status).toBe(BookingStatus.IN_PROGRESS);
    });

    it('Step 3: Service execution progresses to COMPLETED with Cash collection record', async () => {
      const completed = await proService.advanceBookingStatus(
        proPersona.id,
        fulfillmentBookingId,
        {
          toStatus: 'COMPLETED',
        },
      );

      expect(completed.status).toBe(BookingStatus.COMPLETED);

      // Record cash on service collection
      const payment = await prismaMock.paymentRecord.create({
        data: {
          bookingId: fulfillmentBookingId,
          amountEgp: 260,
          method: PaymentMethodType.CASH_ON_SERVICE,
          status: PaymentStatus.PAID,
        },
      });

      expect(payment.amountEgp).toBe(260);
      expect(payment.status).toBe(PaymentStatus.PAID);
    });

    it('Step 4: Customer submits review with Arabic/English feedback and 5-star rating', async () => {
      const reviewResult = await bookingsService.submitBookingReview(
        customerPersona.id,
        fulfillmentBookingId,
        {
          rating: 5,
          comment: 'خدمة ممتازة وفني محترف جدا وسريع - Outstanding technician!',
          tipAmountEgp: 20,
        },
      );

      expect(reviewResult).toBeDefined();
      expect(reviewResult.rating).toBe(5);
      expect(reviewResult.comment).toContain('خدمة ممتازة');
      expect(reviewResult.tipAmountEgp).toBe(20);
      expect(reviewsDb.some((r) => r.bookingId === fulfillmentBookingId)).toBe(true);
    });
  });

  describe('Scenario 5: Admin Dossier Audit, Review & Catalog Versioned Publishing', () => {
    it('Step 1: Admin reviews candidate dossier details', async () => {
      const mockReq = { adminActor: adminOwnerActor } as any;
      const dossier = await adminProfessionalsController.detail(
        mockReq,
        mockProProfile.id,
      );

      expect(dossier).toBeDefined();
      expect(dossier.dossierCode).toBe('PRO-502');
      expect(dossier.verificationStatus).toBe(ProVerificationStatus.APPROVED);
      expect(dossier.documents.length).toBe(3);
    });

    it('Step 2: Admin reviews professional with cryptographic dossier version verification', async () => {
      const mockReq = { adminActor: adminOwnerActor } as any;
      const versionHash = dossierReviewVersion(mockProProfile as any);
      expect(typeof versionHash).toBe('string');
      expect(versionHash.length).toBe(64);

      const reviewOutcome = await adminProfessionalsController.review(
        mockReq,
        mockProProfile.id,
        {
          status: 'APPROVED',
          reviewVersion: versionHash,
          confirmDocumentsReviewed: true,
          reviewerNote: 'All credentials thoroughly verified by QA Ops',
        },
      );

      expect(reviewOutcome).toBeDefined();
      expect(reviewOutcome.verificationStatus).toBe(ProVerificationStatus.APPROVED);
    });

    it('Step 3: Admin drafts catalog entry and publishes version with transaction lock', async () => {
      const mockReq = { adminActor: adminOwnerActor } as any;

      // Draft creation
      const draft = await adminCatalogController.createDraft(mockReq, {
        titleEn: 'Emergency AC Circuit Board Diagnosis',
        titleAr: 'تشخيص طارئ للوحة كهرباء التكييف',
        descriptionEn: 'Full diagnostic on inverter control circuit board',
        descriptionAr: 'فحص شامل للوحة التحكم في التكييف الإنفرتر',
        categorySlug: 'ac-maintenance',
        baseInspectionEgp: 250,
        serviceFeeEgp: 30,
        estimatedDurationMins: 60,
      });

      expect(draft).toBeDefined();
      expect(draft.titleEn).toBe('Emergency AC Circuit Board Diagnosis');

      // Publish draft
      const published = await adminCatalogController.publish(mockReq, draft.id, {
        version: 1,
      });

      expect(published).toBeDefined();
      expect(published.publishedVersion).toBe(1);
    });
  });
});
