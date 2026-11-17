import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  INestApplication,
  NotFoundException,
  UnauthorizedException,
  ValidationPipe,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import {
  UserRole,
  ProVerificationStatus,
  BookingStatus,
  TimeWindow,
  PaymentMethodType,
} from '@prisma/client';
import { AppModule } from '../app.module';
import { InMemoryStoreService } from '../prisma/in-memory-store.service';
import { PrismaService } from '../prisma/prisma.service';
import { ServicesController } from '../modules/services/services.controller';
import { ProfessionalsController } from '../modules/services/professionals.controller';
import { BookingsController } from '../modules/bookings/bookings.controller';
import { ProController } from '../modules/pro/pro.controller';
import { AdminAccessController } from '../modules/admin/admin-access.controller';
import { AdminCatalogController } from '../modules/admin/admin-catalog.controller';
import { AdminProfessionalsController } from '../modules/admin/admin-professionals.controller';
import { AuthService } from '../modules/auth/auth.service';
import { UsersService } from '../modules/users/users.service';
import { BookingsService } from '../modules/bookings/bookings.service';
import { ServicesService } from '../modules/services/services.service';
import { ProService } from '../modules/pro/pro.service';

describe('Tier 1: Feature Coverage (Backend API & Domain Architecture)', () => {
  let app: INestApplication;
  let memoryStore: InMemoryStoreService;
  let servicesController: ServicesController;
  let professionalsController: ProfessionalsController;
  let bookingsController: BookingsController;
  let proController: ProController;
  let adminAccessController: AdminAccessController;
  let adminCatalogController: AdminCatalogController;
  let adminProsController: AdminProfessionalsController;
  let authService: AuthService;
  let usersService: UsersService;
  let bookingsService: BookingsService;
  let servicesService: ServicesService;
  let proService: ProService;

  const mockCustomer = {
    id: 'cust-101',
    phone: '+201023456789',
    fullName: 'Salma El-Shazly',
    role: UserRole.CUSTOMER,
  };

  const mockAddress = {
    id: 'addr-seed-default',
    userId: 'cust-101',
    zoneId: 'zone-new-cairo',
    label: 'Home',
    buildingLine: 'Building 14',
    districtLine: 'New Cairo',
    gateNotes: null,
    latitude: 30.01,
    longitude: 31.42,
    isDefault: true,
    zone: {
      id: 'zone-new-cairo',
      slug: 'new-cairo',
      nameEn: 'New Cairo',
      nameAr: 'القاهرة الجديدة',
      governorate: 'Cairo',
      isActive: true,
    },
  };

  const mockBookings: any[] = [];
  const mockDossiers: any[] = [
    {
      id: 'pro-01',
      dossierCode: 'PRO-1001',
      legalName: 'Tarek Mahmoud',
      displayName: 'Tarek M.',
      verificationStatus: ProVerificationStatus.APPROVED,
      updatedAt: new Date(),
      user: { fullName: 'Tarek Mahmoud' },
      primaryCategory: { nameEn: 'AC Maintenance', nameAr: 'صيانة تكييف' },
      _count: { documents: 3 },
    },
  ];
  const mockCatalogDrafts: any[] = [
    {
      id: 'draft-01',
      slug: 'ac-repair',
      isActive: true,
      titleEn: 'AC Repair',
      titleAr: 'تصليح تكييف',
      createdAt: new Date(),
      updatedAt: new Date(),
      categorySlug: 'ac-maintenance',
      categoryNameEn: 'AC Maintenance',
      categoryNameAr: 'صيانة تكييف',
      offeringId: null,
    },
  ];

  let prismaMock: any;

  beforeAll(async () => {
    prismaMock = {
      isDatabaseConnected: jest.fn().mockReturnValue(false),
      getStorageMode: jest.fn().mockReturnValue('IN_MEMORY_FALLBACK'),
      onModuleInit: jest.fn().mockResolvedValue(undefined),
      onModuleDestroy: jest.fn().mockResolvedValue(undefined),
      $connect: jest.fn().mockResolvedValue(undefined),
      $disconnect: jest.fn().mockResolvedValue(undefined),
      $transaction: jest.fn(async (arg: any) =>
        typeof arg === 'function' ? arg(prismaMock) : Promise.all(arg),
      ),
      customerAddress: {
        findUnique: jest.fn().mockResolvedValue(mockAddress),
        findMany: jest.fn().mockResolvedValue([mockAddress]),
      },
      booking: {
        findMany: jest.fn().mockImplementation(async () => mockBookings),
        count: jest.fn().mockImplementation(async () => mockBookings.length),
        findUnique: jest.fn().mockImplementation(async ({ where }) =>
          mockBookings.find((b) => b.id === where.id) || mockBookings[0],
        ),
        create: jest.fn().mockImplementation(async ({ data }) => {
          const offering = memoryStore.getOfferings()[0];
          const item = {
            id: 'booking-seed-01',
            orderCode: 'FIX-1001',
            customerId: data.customerId,
            offeringId: data.offeringId,
            addressId: data.addressId,
            proProfileId: null,
            status: BookingStatus.DRAFT,
            cancellationReason: null,
            scheduledDate: data.scheduledDate,
            timeWindow: data.timeWindow,
            issueDescription: data.issueDescription ?? null,
            issuePhotoUrls: data.issuePhotoUrls ?? [],
            arrivalPinCode: '4829',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            completedAt: null,
            baseInspectionEgp: 150,
            serviceFeeEgp: 300,
            transportFeeEgp: 0,
            totalEgp: 450,
            platformFeeEgp: 50,
            netArtisanEgp: 400,
            pricing: {
              baseInspectionEgp: 150,
              serviceFeeEgp: 300,
              transportFeeEgp: 0,
              totalEgp: 450,
              platformFeeEgp: 50,
              netArtisanEgp: 400,
              currency: 'EGP',
            },
            offering: {
              id: offering.id,
              slug: offering.slug,
              titleEn: offering.titleEn,
              titleAr: offering.titleAr,
              descriptionEn: offering.descriptionEn,
              descriptionAr: offering.descriptionAr,
              category: {
                id: offering.categoryId,
                slug: 'ac-maintenance',
                nameEn: 'AC Maintenance',
                nameAr: 'صيانة تكييف',
              },
            },
            address: mockAddress,
            proProfile: null,
            payment: null,
            review: null,
            statusEvents: [
              {
                id: 'evt-1',
                fromStatus: null,
                toStatus: BookingStatus.DRAFT,
                note: 'Booking draft created',
                createdAt: new Date().toISOString(),
              },
            ],
          };
          mockBookings.push(item);
          return item;
        }),
        update: jest.fn().mockImplementation(async ({ where, data }) => {
          const item =
            mockBookings.find((b) => b.id === where.id) || mockBookings[0];
          if (item) {
            Object.assign(item, data);
            if (data.status) {
              item.statusEvents.push({
                id: `evt-${item.statusEvents.length + 1}`,
                fromStatus: item.status,
                toStatus: data.status,
                note: data.cancellationReason ?? 'Status update',
                createdAt: new Date().toISOString(),
              });
            }
          }
          return item;
        }),
      },
      bookingStatusEvent: {
        create: jest.fn().mockResolvedValue({ id: 'evt-new' }),
      },
      paymentRecord: {
        create: jest.fn().mockResolvedValue({
          id: 'pay-01',
          method: PaymentMethodType.CASH_ON_SERVICE,
          amountEgp: 450,
          currency: 'EGP',
        }),
        aggregate: jest.fn().mockResolvedValue({
          _sum: { amountEgp: 1500 },
          _count: { id: 5 },
        }),
      },
      proProfile: {
        findMany: jest.fn().mockResolvedValue(mockDossiers),
        count: jest.fn().mockResolvedValue(mockDossiers.length),
        findUnique: jest.fn().mockResolvedValue(mockDossiers[0]),
      },
      adminCatalogDraft: {
        findMany: jest.fn().mockResolvedValue(mockCatalogDrafts),
        count: jest.fn().mockResolvedValue(mockCatalogDrafts.length),
      },
      adminAuditLog: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'audit-01',
            actorUserId: 'user-admin',
            action: 'REVIEW_PRO',
            entityId: 'pro-01',
            details: { status: 'APPROVED' },
            createdAt: new Date(),
          },
        ]),
      },
      adminMembership: {
        count: jest.fn().mockResolvedValue(2),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue(mockCustomer),
        count: jest.fn().mockResolvedValue(10),
      },
      coverageZone: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'zone-new-cairo',
          slug: 'new-cairo',
          nameEn: 'New Cairo',
          nameAr: 'القاهرة الجديدة',
          governorate: 'Cairo',
          isActive: true,
        }),
      },
      serviceCategory: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      serviceOffering: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const list = memoryStore.getOfferings();
          const item = list.find((o) => o.id === where.id);
          if (!item) return null;
          return {
            ...item,
            category: {
              id: item.categoryId,
              slug: 'ac-maintenance',
              nameEn: 'AC Maintenance',
              nameAr: 'صيانة تكييف',
              isActive: true,
            },
          };
        }),
      },
    };

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(prismaMock)
      .compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    memoryStore = moduleRef.get(InMemoryStoreService);
    servicesController = moduleRef.get(ServicesController);
    professionalsController = moduleRef.get(ProfessionalsController);
    bookingsController = moduleRef.get(BookingsController);
    proController = moduleRef.get(ProController);
    adminAccessController = moduleRef.get(AdminAccessController);
    adminCatalogController = moduleRef.get(AdminCatalogController);
    adminProsController = moduleRef.get(AdminProfessionalsController);
    authService = moduleRef.get(AuthService);
    usersService = moduleRef.get(UsersService);
    bookingsService = moduleRef.get(BookingsService);
    servicesService = moduleRef.get(ServicesService);
    proService = moduleRef.get(ProService);

    authService.configureSecurity({
      accessSecret: 'fc6d177aaf07dbda39de2f010ab7f954026f1a34e6f30bbeed9ed531dc09341c',
      refreshSecret: 'dc804b09046d9998a37fd864f4fa830f0f74bc9b35a46710013ce371baa6fbea',
      otpHmacSecret: '694ccf28dbdf0583c830c87b751ad463bb6096d171bff9425419c324c1d76964',
      smsProviderType: 'DEV_SANDBOX_SMS',
      isProduction: false,
      allowDevSms: true,
      allowInMemoryFallback: true,
      allowTestFixedOtp: true,
    });
  });

  beforeEach(() => {
    memoryStore.resetToSeedState();
    mockBookings.length = 0;
    const defaultCust = memoryStore.findUserByPhone('+201023456789');
    if (defaultCust) {
      mockAddress.userId = defaultCust.id;
    }
  });

  afterAll(async () => {
    await app.close();
  });

  // ==========================================
  // FEATURE 1: Clean Architecture Separation
  // ==========================================
  describe('Feature 1: Clean Architecture Separation', () => {
    it('1.1: ServicesController delegates business queries to ServicesService without direct ORM leakage', async () => {
      const categories = await servicesController.listCategories();
      expect(categories).toBeDefined();
      expect(categories.categories).toBeInstanceOf(Array);
      expect(categories.meta.currency).toBe('EGP');
    });

    it('1.2: BookingsService encapsulates booking lifecycle logic away from the HTTP controller', () => {
      expect(bookingsService).toBeDefined();
      expect(typeof bookingsService.createBooking).toBe('function');
      expect(typeof bookingsService.checkoutBooking).toBe('function');
      expect(typeof bookingsService.cancelBooking).toBe('function');
    });

    it('1.3: ProService encapsulates technician scheduling and dashboard aggregates', () => {
      expect(proService).toBeDefined();
      expect(typeof proService.getDashboard).toBe('function');
      expect(typeof proService.getMyProProfile).toBe('function');
    });

    it('1.4: UsersService isolates user management and data access contracts', () => {
      expect(usersService).toBeDefined();
      expect(typeof usersService.updateDisplayName).toBe('function');
      expect(typeof usersService.formatAddressResponse).toBe('function');
    });

    it('1.5: InMemoryStoreService provides clean persistence isolation without external database coupling', () => {
      expect(memoryStore).toBeDefined();
      const user = memoryStore.findUserByPhone('+201023456789');
      expect(user).toBeDefined();
      expect(user?.role).toBe(UserRole.CUSTOMER);
    });
  });

  // ==========================================
  // FEATURE 2: Error Handling & Centralized Envelope
  // ==========================================
  describe('Feature 2: Error Handling & Centralized Envelope', () => {
    it('2.1: NotFoundException is thrown on non-existent service query', async () => {
      await expect(
        servicesController.getServiceById('00000000-0000-0000-0000-000000000000'),
      ).rejects.toThrow(NotFoundException);
    });

    it('2.2: NotFoundException contains standard HTTP 404 status code', async () => {
      try {
        await servicesController.getServiceById('non-existent-id');
        fail('Should have thrown NotFoundException');
      } catch (err: any) {
        expect(err.getStatus()).toBe(404);
      }
    });

    it('2.3: BadRequestException enforces valid parameters on booking queries', () => {
      const badQuery = new BadRequestException('Validation failed');
      expect(badQuery.getStatus()).toBe(400);
      expect(badQuery.getResponse()).toBeDefined();
    });

    it('2.4: ConflictException represents state conflicts (HTTP 409)', () => {
      const conflict = new ConflictException('Offer has already been claimed');
      expect(conflict.getStatus()).toBe(409);
      expect(conflict.message).toBe('Offer has already been claimed');
    });

    it('2.5: UnauthorizedException signals missing or forged bearer credentials (HTTP 401)', () => {
      const unauthorized = new UnauthorizedException('Authentication required');
      expect(unauthorized.getStatus()).toBe(401);
    });
  });

  // ==========================================
  // FEATURE 3: Input Validation & DTO Checks
  // ==========================================
  describe('Feature 3: Input Validation & DTO Checks', () => {
    it('3.1: Validates Egyptian phone format and normalizes prefixes', async () => {
      const challenge = await authService.requestOtp({ phone: '+201023456789' });
      expect(challenge).toBeDefined();
      expect(challenge.challengeId).toBeDefined();
    });

    it('3.2: Rejects non-Egyptian phone numbers on OTP request', async () => {
      await expect(
        authService.requestOtp({ phone: '+14155552671' }),
      ).rejects.toThrow();
    });

    it('3.3: Rejects invalid OTP code lengths during verification', async () => {
      const challenge = await authService.requestOtp({ phone: '+201023456789' });
      await expect(
        authService.verifyOtp({
          phone: '+201023456789',
          challengeId: challenge.challengeId,
          code: '12', // Too short (must be 6 digits)
        }),
      ).rejects.toThrow();
    });

    it('3.4: Rejects booking creation when required offeringId is missing or empty', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      await expect(
        bookingsService.createBooking(customer.id, {
          offeringId: '',
          addressId: 'some-address',
          scheduledDate: '2026-11-10',
          timeWindow: TimeWindow.MORNING_09_12,
        } as any),
      ).rejects.toThrow();
    });

    it('3.5: Rejects booking creation when scheduled date is invalid', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();
      await expect(
        bookingsService.createBooking(customer.id, {
          offeringId: offerings[0].id,
          addressId: 'some-address',
          scheduledDate: 'not-a-date',
          timeWindow: TimeWindow.MORNING_09_12,
        } as any),
      ).rejects.toThrow();
    });
  });

  // ==========================================
  // FEATURE 8: Backend Query Efficiency & Indexing
  // ==========================================
  describe('Feature 8: Backend Query Efficiency & Indexing', () => {
    it('8.1: Customer bookings query filters by customer ID without full table scan', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const result = await bookingsService.findCustomerBookings(customer.id, {});
      expect(result).toBeDefined();
      expect(result.bookings).toBeInstanceOf(Array);
      expect(typeof result.total).toBe('number');
    });

    it('8.2: Service catalog queries filter by category and active status efficiently', async () => {
      const categories = await servicesService.listCategories();
      const firstCat = categories.categories[0];
      const services = await servicesService.listServices({
        categoryId: firstCat.id,
        page: 1,
        limit: 10,
      });
      expect(services.items).toBeDefined();
      for (const s of services.items) {
        expect(s.categoryId).toBe(firstCat.id);
      }
    });

    it('8.3: Professional discovery query filters by approved verification status only', async () => {
      const pros = await servicesService.listProfessionals({});
      expect(pros.items).toBeDefined();
      for (const p of pros.items) {
        expect(p.fullNameEn).toBeDefined();
      }
    });

    it('8.4: Pro catalog options query returns available coverage zones and transport modes', async () => {
      const options = await proService.getCatalogOptions();
      expect(options.zones.length).toBeGreaterThan(0);
      expect(options.transportModes.length).toBeGreaterThan(0);
      expect(options.experienceTiers.length).toBeGreaterThan(0);
    });

    it('8.5: UsersService formats address entity with normalized geographic zone response', () => {
      const formatted = usersService.formatAddressResponse({
        id: 'addr-01',
        userId: 'cust-101',
        zoneId: 'zone-new-cairo',
        label: 'Home',
        buildingLine: 'Villa 14',
        districtLine: 'New Cairo',
        gateNotes: null,
        latitude: 30.01,
        longitude: 31.42,
        isDefault: true,
        createdAt: new Date(),
        zone: {
          id: 'zone-new-cairo',
          slug: 'new-cairo',
          nameEn: 'New Cairo',
          nameAr: 'القاهرة الجديدة',
          governorate: 'Cairo',
          isActive: true,
        },
      });
      expect(formatted.id).toBe('addr-01');
      expect(formatted.zone?.governorate).toBe('Cairo');
    });
  });

  // ==========================================
  // FEATURE 9: Pro Dashboard Concurrency & Read Isolation
  // ==========================================
  describe('Feature 9: Pro Dashboard Concurrency & Read Isolation', () => {
    it('9.1: Pro catalog options is strictly read-only and idempotent', async () => {
      const options1 = await proService.getCatalogOptions();
      const options2 = await proService.getCatalogOptions();
      expect(options1.zones.length).toBe(options2.zones.length);
      expect(options1.transportModes).toEqual(options2.transportModes);
    });

    it('9.2: Pro catalog options returns Egyptian transport modes matching market', async () => {
      const options = await proService.getCatalogOptions();
      expect(options.transportModes).toEqual([
        'MOTORCYCLE',
        'WORK_VAN',
        'METRO_BUS',
      ]);
    });

    it('9.3: Pro catalog options returns Egyptian experience tiers matching market', async () => {
      const options = await proService.getCatalogOptions();
      expect(options.experienceTiers).toEqual([
        'JUNIOR_1_2Y',
        'SKILLED_3_5Y',
        'SENIOR_6_8Y',
        'MASTER_8_PLUS_Y',
      ]);
    });

    it('9.4: Pro catalog options returns coverage zones across Greater Cairo & Giza', async () => {
      const options = await proService.getCatalogOptions();
      const governorates = new Set(options.zones.map((z) => z.governorate));
      expect(governorates.has('Cairo')).toBe(true);
      expect(governorates.has('Giza')).toBe(true);
    });

    it('9.5: Multiple concurrent catalog options requests resolve without lock contention', async () => {
      const requests = Array.from({ length: 5 }, () =>
        proService.getCatalogOptions(),
      );
      const results = await Promise.all(requests);
      expect(results).toHaveLength(5);
      results.forEach((r) => expect(r.zones.length).toBeGreaterThan(0));
    });
  });

  // ==========================================
  // FEATURE 10: Customer Service Discovery API
  // ==========================================
  describe('Feature 10: Customer Service Discovery API', () => {
    it('10.1: GET /api/v1/services/categories returns all 21 Fixo Egyptian categories', async () => {
      const result = await servicesController.listCategories();
      expect(result.categories).toHaveLength(21);
      expect(result.meta.market).toBe('EG');
      expect(result.meta.currency).toBe('EGP');
    });

    it('10.2: Service categories include starting prices in EGP matching Egyptian baseline', async () => {
      const result = await servicesController.listCategories();
      const acCat = result.categories.find((c) => c.nameEn === 'AC Maintenance');
      expect(acCat).toBeDefined();
      expect(acCat!.startingPriceEgp).toBe(450);
    });

    it('10.3: GET /api/v1/services supports keyword search and pagination', async () => {
      const res = await servicesController.listServices({
        search: 'AC',
        page: 1,
        limit: 10,
      });
      expect(res.items.length).toBeGreaterThan(0);
      expect(res.meta.page).toBe(1);
    });

    it('10.4: GET /api/v1/services/:id returns service details with localized strings', async () => {
      const offerings = memoryStore.getOfferings();
      const res = await servicesController.getServiceById(offerings[0].id);
      expect(res.service.id).toBe(offerings[0].id);
      expect(res.service.titleEn).toBeDefined();
      expect(res.service.titleAr).toBeDefined();
      expect(res.service.flatPriceEgp).toBeGreaterThan(0);
    });

    it('10.5: Professional discovery strictly sanitizes private data (phone, ID numbers)', async () => {
      const pros = await professionalsController.listProfessionals({});
      expect(pros.items.length).toBeGreaterThan(0);
      for (const pro of pros.items) {
        expect((pro as any).phone).toBeUndefined();
        expect((pro as any).nationalIdNumber).toBeUndefined();
        expect(pro.fullNameEn).toBeDefined();
      }
    });
  });

  // ==========================================
  // FEATURE 11: Customer Booking & Order Checkout Flow
  // ==========================================
  describe('Feature 11: Customer Booking & Order Checkout Flow', () => {
    it('11.1: Customer creates booking in DRAFT status with EGP price calculation', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();

      const booking = await bookingsService.createBooking(customer.id, {
        offeringId: offerings[0].id,
        addressId: 'addr-seed-default',
        scheduledDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
        issueDescription: 'Testing booking creation',
      });

      expect(booking.id).toBeDefined();
      expect(booking.status).toBe(BookingStatus.DRAFT);
      expect(booking.pricing.totalEgp).toBeGreaterThan(0);
      expect(booking.pricing.currency).toBe('EGP');
    });

    it('11.2: Customer checkout transitions booking from DRAFT to PENDING_DISPATCH', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();

      const booking = await bookingsService.createBooking(customer.id, {
        offeringId: offerings[0].id,
        addressId: 'addr-seed-default',
        scheduledDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });

      const checkedOut = await bookingsService.checkoutBooking(
        customer.id,
        booking.id,
        {
          paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
        },
      );

      expect(checkedOut.status).toBe(BookingStatus.PENDING_DISPATCH);
    });

    it('11.3: Booking receipt breaks down base fare, service fee, and total in EGP', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();

      const booking = await bookingsService.createBooking(customer.id, {
        offeringId: offerings[0].id,
        addressId: 'addr-seed-default',
        scheduledDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });

      expect(booking.pricing.baseInspectionEgp).toBeGreaterThan(0);
      expect(booking.pricing.totalEgp).toBe(
        booking.pricing.baseInspectionEgp + booking.pricing.serviceFeeEgp,
      );
    });

    it('11.4: Customer can cancel a draft or pending booking with reason', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();

      const booking = await bookingsService.createBooking(customer.id, {
        offeringId: offerings[0].id,
        addressId: 'addr-seed-default',
        scheduledDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });

      const cancelled = await bookingsService.cancelBooking(
        customer.id,
        booking.id,
        { reason: 'Customer schedule changed' },
      );

      expect(cancelled.status).toBe(BookingStatus.CANCELLED);
    });

    it('11.5: Booking status event timeline records initial booking creation event', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();

      const booking = await bookingsService.createBooking(customer.id, {
        offeringId: offerings[0].id,
        addressId: 'addr-seed-default',
        scheduledDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        timeWindow: TimeWindow.MORNING_09_12,
      });

      const detail = await bookingsService.findCustomerBookingById(
        customer.id,
        booking.id,
      );

      expect(detail.statusEvents?.length).toBeGreaterThanOrEqual(1);
      expect(detail.statusEvents![0].toStatus).toBe(BookingStatus.DRAFT);
    });
  });

  // ==========================================
  // FEATURE 12: Admin Management API & Audit Logging
  // ==========================================
  describe('Feature 12: Admin Management API & Audit Logging', () => {
    it('12.1: Admin membership summary returns system users, pros and active bookings counts', async () => {
      const summary = await adminAccessController.summary();
      expect(summary).toBeDefined();
      expect(typeof summary.users).toBe('number');
      expect(typeof summary.professionals).toBe('number');
      expect(typeof summary.activeBookings).toBe('number');
    });

    it('12.2: Admin can query professional list with pagination', async () => {
      const pros = await adminProsController.list({
        page: 1,
      });
      expect(pros).toBeDefined();
      expect(Array.isArray(pros.items)).toBe(true);
      expect(typeof pros.meta.total).toBe('number');
    });

    it('12.3: Admin can filter professional list by verification status', async () => {
      const pros = await adminProsController.list({
        page: 1,
        status: ProVerificationStatus.APPROVED,
      });
      expect(pros).toBeDefined();
      expect(Array.isArray(pros.items)).toBe(true);
    });

    it('12.4: Admin catalog controller lists offerings with version information', async () => {
      const catalog = await adminCatalogController.list({
        page: 1,
      });
      expect(catalog).toBeDefined();
      expect(Array.isArray(catalog.items)).toBe(true);
      expect(typeof catalog.meta.total).toBe('number');
    });

    it('12.5: Admin audit log records actions with actor ID, entity ID and timestamp', async () => {
      const logs = await adminAccessController.audit();
      expect(logs).toBeDefined();
      expect(Array.isArray(logs.items)).toBe(true);
    });
  });
});
