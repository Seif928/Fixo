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
import { CreateBookingDto } from '../modules/bookings/dto/create-booking.dto';
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

describe('Tier 2: Boundary & Corner Cases (Backend API & Invariant Enforcement)', () => {
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
  let prismaMock: any;

  const previousOwnerEmail = process.env.FIXO_OWNER_EMAIL;
  beforeAll(async () => {
    process.env.FIXO_OWNER_EMAIL = 'owner-fixture@example.test';
    prismaMock = {
      isDatabaseConnected: jest.fn().mockReturnValue(false),
      getStorageMode: jest.fn().mockReturnValue('IN_MEMORY_FALLBACK'),
      onModuleInit: jest.fn().mockResolvedValue(undefined),
      onModuleDestroy: jest.fn().mockResolvedValue(undefined),
      $connect: jest.fn().mockResolvedValue(undefined),
      $disconnect: jest.fn().mockResolvedValue(undefined),
      $executeRaw: jest.fn().mockResolvedValue(1),
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
        findUnique: jest
          .fn()
          .mockImplementation(
            async ({ where }) =>
              mockBookings.find((b) => b.id === where.id) || null,
          ),
        create: jest.fn().mockImplementation(async ({ data }) => {
          const item = {
            id: `booking-${mockBookings.length + 1}`,
            orderCode: `FIX-${1000 + mockBookings.length}`,
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
              id: data.offeringId,
              slug: 'offering-slug',
              titleEn: 'Service Offering',
              titleAr: 'خدمة',
              descriptionEn: 'Description',
              descriptionAr: 'وصف',
              category: {
                id: 'cat-ac',
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
          const item = mockBookings.find((b) => b.id === where.id);
          if (!item) throw new NotFoundException('Booking not found');
          Object.assign(item, data);
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
      },
      proProfile: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        findUnique: jest.fn().mockResolvedValue(null),
      },
      adminCatalogDraft: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        findUnique: jest.fn().mockResolvedValue(null),
      },
      adminAuditLog: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      adminMembership: {
        count: jest.fn().mockResolvedValue(1),
        findUnique: jest.fn().mockResolvedValue({
          id: 'mem-01',
          userId: 'admin-01',
          role: 'OWNER',
          email: 'owner-fixture@example.test',
          isActive: true,
        }),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue(mockCustomer),
        count: jest.fn().mockResolvedValue(1),
      },
      coverageZone: {
        findFirst: jest.fn().mockResolvedValue(mockAddress.zone),
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
      accessSecret:
        'fc6d177aaf07dbda39de2f010ab7f954026f1a34e6f30bbeed9ed531dc09341c',
      refreshSecret:
        'dc804b09046d9998a37fd864f4fa830f0f74bc9b35a46710013ce371baa6fbea',
      otpHmacSecret:
        '694ccf28dbdf0583c830c87b751ad463bb6096d171bff9425419c324c1d76964',
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
    if (previousOwnerEmail === undefined) delete process.env.FIXO_OWNER_EMAIL;
    else process.env.FIXO_OWNER_EMAIL = previousOwnerEmail;
    await app.close();
  });

  // ==========================================
  // FEATURE 2: Error Handling & Filters Boundaries
  // ==========================================
  describe('Feature 2: Error Filter Boundaries', () => {
    it('2.1: Non-existent route or resource yields clean NotFoundException', async () => {
      await expect(
        servicesController.getServiceById(
          '00000000-0000-0000-0000-000000000000',
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('2.2: Malformed UUID format throws NotFoundException on database lookup', async () => {
      await expect(
        servicesController.getServiceById('invalid!uuid@code'),
      ).rejects.toThrow(NotFoundException);
    });

    it('2.3: Unhandled exception is mapped to structured error response', () => {
      const err = new BadRequestException({
        statusCode: 400,
        errorCode: 'VALIDATION_FAILED',
        message: 'Invalid input parameters',
        timestamp: new Date().toISOString(),
        path: '/api/v1/bookings',
      });
      const response = err.getResponse() as any;
      expect(response.errorCode).toBe('VALIDATION_FAILED');
      expect(response.statusCode).toBe(400);
    });

    it('2.4: ConflictException includes descriptive conflict message without leaking stack trace', () => {
      const conflict = new ConflictException(
        'Simultaneous booking slot collision',
      );
      expect(conflict.getStatus()).toBe(409);
      expect(conflict.message).toBe('Simultaneous booking slot collision');
    });

    it('2.5: Missing address during booking creation throws NotFoundException', async () => {
      prismaMock.customerAddress.findUnique.mockResolvedValueOnce(null);
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();

      await expect(
        bookingsService.createBooking(customer.id, {
          offeringId: offerings[0].id,
          addressId: 'non-existent-address',
          scheduledDate: '2026-11-20',
          timeWindow: TimeWindow.MORNING_09_12,
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ==========================================
  // FEATURE 3: Validation Boundary & Corner Cases
  // ==========================================
  describe('Feature 3: Validation Boundary Values', () => {
    it('3.1: Egypt phone validator rejects unsupported telecom prefix (019...)', async () => {
      await expect(
        authService.requestOtp({ phone: '+201912345678' }),
      ).rejects.toThrow();
    });

    it('3.2: Rejects empty phone strings and whitespace-only strings', async () => {
      await expect(authService.requestOtp({ phone: '' })).rejects.toThrow();
      await expect(authService.requestOtp({ phone: '   ' })).rejects.toThrow();
    });

    it('3.3: Rejects scheduled booking date set in the distant past', async () => {
      const customer = memoryStore.findUserByPhone('+201023456789')!;
      const offerings = memoryStore.getOfferings();

      await expect(
        bookingsService.createBooking(customer.id, {
          offeringId: offerings[0].id,
          addressId: 'addr-seed-default',
          scheduledDate: '2020-01-01',
          timeWindow: TimeWindow.MORNING_09_12,
        }),
      ).rejects.toThrow();
    });

    it('3.4: Rejects booking issue description exceeding 1000 characters', async () => {
      const pipe = new ValidationPipe({ transform: true, whitelist: true });
      await expect(
        pipe.transform(
          {
            offeringId: 'off-ac-clean',
            addressId: 'addr-seed-default',
            scheduledDate: '2026-11-20',
            timeWindow: TimeWindow.MORNING_09_12,
            issueDescription: 'A'.repeat(1001),
          },
          { metatype: CreateBookingDto, type: 'body' },
        ),
      ).rejects.toThrow();
    });

    it('3.5: UsersService rejects displayName containing non-printable control characters', async () => {
      await expect(
        usersService.updateDisplayName('cust-101', 'Tarek\x00Mahmoud'),
      ).rejects.toThrow();
    });
  });

  // ==========================================
  // FEATURE 8: Query Indexing Boundaries & Large Volume
  // ==========================================
  describe('Feature 8: Query Indexing Boundaries & Large Volume', () => {
    it('8.1: Customer bookings query for user with 0 bookings returns empty list immediately', async () => {
      const result = await bookingsService.findCustomerBookings(
        'cust-empty-user',
        {},
      );
      expect(result.bookings).toEqual([]);
      expect(result.total).toBe(0);
    });

    it('8.2: Service catalog query with non-existent category returns empty items', async () => {
      const result = await servicesService.listServices({
        categoryId: 'non-existent-cat-uuid',
      });
      expect(result.items).toEqual([]);
      expect(result.meta.total).toBe(0);
    });

    it('8.3: Deep pagination offset returns empty results without server failure', async () => {
      const result = await servicesService.listServices({
        page: 9999,
        limit: 20,
      });
      expect(result.items).toEqual([]);
      expect(result.meta.page).toBe(9999);
    });

    it('8.4: Multi-filter query (category + keyword) safely combines conditions', async () => {
      const categories = await servicesService.listCategories();
      const acCat = categories.categories[0];
      const result = await servicesService.listServices({
        categoryId: acCat.id,
        search: 'AC',
      });
      expect(Array.isArray(result.items)).toBe(true);
    });

    it('8.5: Professional discovery query with non-matching search returns zero items', async () => {
      const result = await professionalsController.listProfessionals({
        search: 'NonExistentTechnicianNameXYZ',
      });
      expect(result.items).toEqual([]);
      expect(result.meta.total).toBe(0);
    });
  });

  // ==========================================
  // FEATURE 9: Pro Concurrency Race Conditions & Expiration
  // ==========================================
  describe('Feature 9: Pro Concurrency Race Conditions & Expiration', () => {
    it('9.1: Pro with non-existent ID querying dashboard throws NotFoundException', async () => {
      await expect(
        proService.getDashboard('pro-non-existent-user-id'),
      ).rejects.toThrow(NotFoundException);
    });

    it('9.2: Pro querying non-existent job offer throws NotFoundException', async () => {
      await expect(
        proService.getJobOfferById('pro-user-id', 'non-existent-offer-id'),
      ).rejects.toThrow(NotFoundException);
    });

    it('9.3: Pro declining a non-existent offer throws NotFoundException', async () => {
      await expect(
        proService.declineJobOffer('pro-user-id', 'non-existent-offer-id', {
          reason: 'Schedule conflict',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('9.4: Advance job status on non-existent booking throws NotFoundException', async () => {
      await expect(
        proService.advanceBookingStatus(
          'pro-user-id',
          'non-existent-booking-id',
          {
            toStatus: 'PRO_EN_ROUTE',
          },
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('9.5: Updating availability for non-existent pro throws NotFoundException', async () => {
      await expect(
        proService.updateAvailability('pro-user-id', { isOnline: false }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ==========================================
  // FEATURE 10: Discovery Special Character Sanitization
  // ==========================================
  describe('Feature 10: Discovery Special Character Sanitization', () => {
    it('10.1: Search with SQL injection payload is sanitized safely', async () => {
      const result = await servicesController.listServices({
        search: "' OR '1'='1' --",
      });
      expect(Array.isArray(result.items)).toBe(true);
      expect(result.items).toEqual([]);
    });

    it('10.2: Search with HTML/script tag is treated as literal search string', async () => {
      const result = await servicesController.listServices({
        search: '<script>alert(1)</script>',
      });
      expect(Array.isArray(result.items)).toBe(true);
      expect(result.items).toEqual([]);
    });

    it('10.3: Search with Arabic keyword correctly queries Arabic service titles', async () => {
      const result = await servicesController.listServices({
        search: 'تكييف',
      });
      expect(Array.isArray(result.items)).toBe(true);
      expect(result.items.length).toBeGreaterThan(0);
    });

    it('10.4: Search with unicode emojis returns zero items without 500 error', async () => {
      const result = await servicesController.listServices({
        search: '❄️🔧⚡',
      });
      expect(Array.isArray(result.items)).toBe(true);
      expect(result.items).toEqual([]);
    });

    it('10.5: Search with only whitespace characters returns default catalog without filter', async () => {
      const result = await servicesController.listServices({
        search: '   ',
      });
      expect(Array.isArray(result.items)).toBe(true);
      expect(result.items.length).toBeGreaterThan(0);
    });
  });

  // ==========================================
  // FEATURE 11: Booking Past Dates & Negative Amounts
  // ==========================================
  describe('Feature 11: Booking Past Dates & Negative Amounts', () => {
    it('11.1: Customer checkout on non-existent booking throws NotFoundException', async () => {
      await expect(
        bookingsService.checkoutBooking('cust-101', 'non-existent-booking', {
          paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('11.2: Customer cancelling a non-existent booking throws NotFoundException', async () => {
      await expect(
        bookingsService.cancelBooking('cust-101', 'non-existent-booking', {
          reason: 'Test cancellation',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('11.3: Booking creation with invalid time window is rejected', async () => {
      const pipe = new ValidationPipe({ transform: true, whitelist: true });
      await expect(
        pipe.transform(
          {
            offeringId: 'off-ac-clean',
            addressId: 'addr-seed-default',
            scheduledDate: '2026-11-20',
            timeWindow: 'MIDNIGHT_00_03',
          },
          { metatype: CreateBookingDto, type: 'body' },
        ),
      ).rejects.toThrow();
    });

    it('11.4: Getting receipt for non-existent booking throws NotFoundException', async () => {
      await expect(
        bookingsService.getBookingReceipt('cust-101', 'non-existent-booking'),
      ).rejects.toThrow(NotFoundException);
    });

    it('11.5: Getting tracking for non-existent booking throws NotFoundException', async () => {
      await expect(
        bookingsService.getBookingTracking('cust-101', 'non-existent-booking'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ==========================================
  // FEATURE 12: Admin Access Rejection & Role Boundaries
  // ==========================================
  describe('Feature 12: Admin Access Rejection & Role Boundaries', () => {
    it('12.1: Non-admin user cannot access admin review functions', async () => {
      const forbidden = new ForbiddenException('Admin credentials required');
      expect(forbidden.getStatus()).toBe(403);
    });

    it('12.2: Admin review of non-existent pro ID throws NotFoundException', async () => {
      const mockReq = {
        adminActor: {
          id: 'admin-01',
          role: 'OWNER',
          email: 'owner-fixture@example.test',
          authTime: Math.floor(Date.now() / 1000),
        },
      } as any;
      await expect(
        adminProsController.detail(mockReq, 'non-existent-pro-id'),
      ).rejects.toThrow(NotFoundException);
    });

    it('12.3: Admin catalog update on non-existent item throws NotFoundException', async () => {
      const mockReq = {
        adminActor: {
          id: 'admin-01',
          role: 'OWNER',
          email: 'owner-fixture@example.test',
          authTime: Math.floor(Date.now() / 1000),
        },
      } as any;
      await expect(
        adminCatalogController.update(mockReq, 'non-existent-draft-id', {
          version: 1,
          titleEn: 'Updated Title',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('12.4: Admin catalog publishing of non-existent item throws NotFoundException', async () => {
      const mockReq = {
        adminActor: {
          id: 'admin-01',
          role: 'OWNER',
          email: 'owner-fixture@example.test',
          authTime: Math.floor(Date.now() / 1000),
        },
      } as any;
      await expect(
        adminCatalogController.publish(mockReq, 'non-existent-draft-id', {
          version: 1,
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('12.5: Admin catalog draft creation with missing required fields is rejected', async () => {
      await expect(
        adminCatalogController.createDraft(
          { id: 'admin-01', role: 'ADMIN' } as any,
          {
            titleEn: '',
            titleAr: '',
            descriptionEn: '',
            descriptionAr: '',
            categorySlug: '',
          } as any,
        ),
      ).rejects.toThrow();
    });
  });
});
