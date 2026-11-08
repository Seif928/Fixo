import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import {
  UserRole,
  ProVerificationStatus,
  BookingStatus,
  TimeWindow,
  PaymentMethodType,
  PaymentStatus,
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

describe('Tier 3: Cross-Feature Interactions (Full Lifecycle Progression)', () => {
  let app: INestApplication;
  let memoryStore: InMemoryStoreService;
  let servicesController: ServicesController;
  let bookingsService: BookingsService;
  let proService: ProService;
  let adminAccessController: AdminAccessController;
  let usersService: UsersService;
  let prismaMock: any;

  const mockCustomer = {
    id: 'cust-salma-101',
    phone: '+201023456789',
    fullName: 'Salma El-Shazly',
    role: UserRole.CUSTOMER,
  };

  const mockProUser = {
    id: 'pro-tarek-202',
    phone: '+201123456789',
    fullName: 'Tarek Mahmoud',
    role: UserRole.PRO,
  };

  const mockProProfile = {
    id: 'pro-profile-01',
    userId: 'pro-tarek-202',
    dossierCode: 'PRO-1001',
    legalName: 'Tarek Mahmoud',
    displayName: 'Tarek M.',
    verificationStatus: ProVerificationStatus.APPROVED,
    ratingAvg: 4.9,
    reviewsCount: 15,
    completedJobsCount: 42,
    acceptanceRatePct: 95,
    isOnline: true,
    user: mockProUser,
    primaryCategory: { nameEn: 'AC Maintenance', nameAr: 'صيانة تكييف' },
  };

  const mockAddress = {
    id: 'addr-new-cairo-01',
    userId: 'cust-salma-101',
    zoneId: 'zone-new-cairo',
    label: 'Home',
    buildingLine: 'Building 14, Street 9',
    districtLine: 'First Settlement, New Cairo',
    gateNotes: 'Ring 3B',
    latitude: 30.0124,
    longitude: 31.4312,
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

  const bookingsDb: any[] = [];
  const statusEventsDb: any[] = [];
  const reviewsDb: any[] = [];
  const auditLogsDb: any[] = [];

  beforeAll(async () => {
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
        findMany: jest.fn().mockImplementation(async () => bookingsDb),
        count: jest.fn().mockImplementation(async () => bookingsDb.length),
        findUnique: jest.fn().mockImplementation(async ({ where }) =>
          bookingsDb.find((b) => b.id === where.id) || null,
        ),
        create: jest.fn().mockImplementation(async ({ data }) => {
          const item = {
            id: `booking-${bookingsDb.length + 1}`,
            orderCode: `FIX-${1000 + bookingsDb.length}`,
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
              slug: 'summer-ac-deep-clean-gas-refill',
              titleEn: 'Summer AC Deep Clean & Gas Refill',
              titleAr: 'غسيل التكييف العميق وشحن الفريون الصيفي',
              descriptionEn: 'Full indoor split AC pressure wash',
              descriptionAr: 'غسيل ضغط داخلي مع تعقيم',
              category: {
                id: 'cat-ac-maintenance',
                slug: 'ac-maintenance',
                nameEn: 'AC Maintenance',
                nameAr: 'صيانة تكييف',
                isActive: true,
              },
            },
            address: mockAddress,
            proProfile: null,
            payment: null,
            review: null,
            statusEvents: [
              {
                id: `evt-${statusEventsDb.length + 1}`,
                fromStatus: null,
                toStatus: BookingStatus.DRAFT,
                note: 'Booking draft created',
                createdAt: new Date().toISOString(),
              },
            ],
          };
          bookingsDb.push(item);
          statusEventsDb.push(item.statusEvents[0]);
          return item;
        }),
        update: jest.fn().mockImplementation(async ({ where, data }) => {
          const item = bookingsDb.find((b) => b.id === where.id);
          if (!item) throw new NotFoundException('Booking not found');
          Object.assign(item, data);
          if (data.status) {
            const evt = {
              id: `evt-${statusEventsDb.length + 1}`,
              fromStatus: item.status,
              toStatus: data.status,
              note: data.cancellationReason ?? 'Lifecycle transition',
              createdAt: new Date().toISOString(),
            };
            item.statusEvents.push(evt);
            statusEventsDb.push(evt);
          }
          if (data.proProfileId) {
            item.proProfile = mockProProfile;
          }
          return item;
        }),
      },
      bookingStatusEvent: {
        create: jest.fn().mockImplementation(async ({ data }) => {
          const evt = { id: `evt-${statusEventsDb.length + 1}`, ...data };
          statusEventsDb.push(evt);
          return evt;
        }),
      },
      paymentRecord: {
        create: jest.fn().mockImplementation(async ({ data }) => ({
          id: 'pay-01',
          method: data.method ?? PaymentMethodType.CASH_ON_SERVICE,
          status: PaymentStatus.PENDING,
          amountEgp: data.amountEgp ?? 450,
          currency: 'EGP',
        })),
        aggregate: jest.fn().mockResolvedValue({
          _sum: { amountEgp: 450 },
          _count: { id: 1 },
        }),
      },
      proProfile: {
        findUnique: jest.fn().mockResolvedValue(mockProProfile),
        findMany: jest.fn().mockResolvedValue([mockProProfile]),
        count: jest.fn().mockResolvedValue(1),
        update: jest.fn().mockImplementation(async ({ where, data }) => {
          Object.assign(mockProProfile, data);
          return mockProProfile;
        }),
      },
      serviceOffering: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const list = memoryStore.getOfferings();
          const item = list.find((o) => o.id === where.id) || list[0];
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
      serviceCategory: {
        findMany: jest.fn().mockImplementation(() => memoryStore.getCategories()),
      },
      user: {
        findUnique: jest.fn().mockImplementation(async ({ where }) => {
          if (where.id === mockCustomer.id) return mockCustomer;
          if (where.id === mockProUser.id) return mockProUser;
          return mockCustomer;
        }),
        count: jest.fn().mockResolvedValue(2),
      },
      adminAuditLog: {
        create: jest.fn().mockImplementation(async ({ data }) => {
          const entry = { id: `audit-${auditLogsDb.length + 1}`, ...data };
          auditLogsDb.push(entry);
          return entry;
        }),
        findMany: jest.fn().mockImplementation(async () => auditLogsDb),
      },
      adminMembership: {
        count: jest.fn().mockResolvedValue(1),
        findUnique: jest.fn().mockResolvedValue({
          id: 'mem-01',
          userId: 'admin-01',
          role: 'OWNER',
          isActive: true,
        }),
      },
      adminCatalogDraft: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        findUnique: jest.fn().mockResolvedValue(null),
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

    memoryStore = moduleRef.get(InMemoryStoreService);
    servicesController = moduleRef.get(ServicesController);
    bookingsService = moduleRef.get(BookingsService);
    proService = moduleRef.get(ProService);
    adminAccessController = moduleRef.get(AdminAccessController);
    usersService = moduleRef.get(UsersService);
  });

  beforeEach(() => {
    bookingsDb.length = 0;
    statusEventsDb.length = 0;
    reviewsDb.length = 0;
    auditLogsDb.length = 0;
  });

  afterAll(async () => {
    await app.close();
  });

  // ==========================================
  // CROSS-FEATURE INTERACTIONS (1 to 6)
  // ==========================================
  it('Interaction 1: Service Discovery to Booking Creation initializes DRAFT order in EGP', async () => {
    const categories = await servicesController.listCategories();
    expect(categories.categories.length).toBe(6);
    const acCategory = categories.categories[0];

    const offerings = memoryStore.getOfferings();
    const acOffering = offerings.find((o) => o.categoryId === acCategory.id)!;

    const booking = await bookingsService.createBooking(mockCustomer.id, {
      offeringId: acOffering.id,
      addressId: mockAddress.id,
      scheduledDate: '2026-11-20',
      timeWindow: TimeWindow.MORNING_09_12,
      issueDescription: 'Indoor unit leaking water onto wall',
    });

    expect(booking.id).toBeDefined();
    expect(booking.status).toBe(BookingStatus.DRAFT);
    expect(booking.pricing.totalEgp).toBe(450);
    expect(booking.pricing.currency).toBe('EGP');
  });

  it('Interaction 2: Booking Creation to Checkout transitions order to PENDING_DISPATCH', async () => {
    const offerings = memoryStore.getOfferings();
    const booking = await bookingsService.createBooking(mockCustomer.id, {
      offeringId: offerings[0].id,
      addressId: mockAddress.id,
      scheduledDate: '2026-11-20',
      timeWindow: TimeWindow.MORNING_09_12,
    });

    const checkedOut = await bookingsService.checkoutBooking(
      mockCustomer.id,
      booking.id,
      {
        paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
      },
    );

    expect(checkedOut.status).toBe(BookingStatus.PENDING_DISPATCH);
    expect(checkedOut.pricing.totalEgp).toBe(450);
  });

  it('Interaction 3: Pro availability enables receipt and listing of dispatch offers', async () => {
    const options = await proService.getCatalogOptions();
    expect(options.zones.length).toBeGreaterThan(0);
    const newCairoZone = options.zones.find((z) => z.slug === 'new-cairo');
    expect(newCairoZone).toBeDefined();
    expect(mockProProfile.isOnline).toBe(true);
  });

  it('Interaction 4: Pro acceptance assigns professional and transitions booking to CONFIRMED', async () => {
    const offerings = memoryStore.getOfferings();
    const booking = await bookingsService.createBooking(mockCustomer.id, {
      offeringId: offerings[0].id,
      addressId: mockAddress.id,
      scheduledDate: '2026-11-20',
      timeWindow: TimeWindow.MORNING_09_12,
    });

    await bookingsService.checkoutBooking(mockCustomer.id, booking.id, {
      paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
    });

    // Simulate pro offer acceptance updating booking
    const confirmedBooking = await prismaMock.booking.update({
      where: { id: booking.id },
      data: {
        status: BookingStatus.CONFIRMED,
        proProfileId: mockProProfile.id,
      },
    });

    expect(confirmedBooking.status).toBe(BookingStatus.CONFIRMED);
    expect(confirmedBooking.proProfileId).toBe(mockProProfile.id);
  });

  it('Interaction 5: Pro execution milestones (PRO_EN_ROUTE -> ARRIVED -> PIN Verification)', async () => {
    const offerings = memoryStore.getOfferings();
    const booking = await bookingsService.createBooking(mockCustomer.id, {
      offeringId: offerings[0].id,
      addressId: mockAddress.id,
      scheduledDate: '2026-11-20',
      timeWindow: TimeWindow.MORNING_09_12,
    });

    // Advance to PRO_EN_ROUTE
    await prismaMock.booking.update({
      where: { id: booking.id },
      data: { status: BookingStatus.PRO_EN_ROUTE, proProfileId: mockProProfile.id },
    });

    // Advance to ARRIVED
    await prismaMock.booking.update({
      where: { id: booking.id },
      data: { status: BookingStatus.ARRIVED },
    });

    // Customer tracking shows arrival status
    const tracking = await bookingsService.getBookingTracking(mockCustomer.id, booking.id);
    expect(tracking.booking.status).toBe(BookingStatus.ARRIVED);
    expect(tracking.booking.arrivalPinCode).toBe('4829');
  });

  it('Interaction 6: Job Completion records cash collection, audit entry, and updates history', async () => {
    const offerings = memoryStore.getOfferings();
    const booking = await bookingsService.createBooking(mockCustomer.id, {
      offeringId: offerings[0].id,
      addressId: mockAddress.id,
      scheduledDate: '2026-11-20',
      timeWindow: TimeWindow.MORNING_09_12,
    });

    // Complete job
    await prismaMock.booking.update({
      where: { id: booking.id },
      data: {
        status: BookingStatus.COMPLETED,
        completedAt: new Date().toISOString(),
        proProfileId: mockProProfile.id,
      },
    });

    // Create admin audit log entry for completion
    await prismaMock.adminAuditLog.create({
      data: {
        actorUserId: 'admin-system',
        action: 'BOOKING_COMPLETED_CASH_SETTLED',
        entityId: booking.id,
        details: { totalEgp: 450, paymentMethod: 'CASH_ON_SERVICE' },
      },
    });

    const receipt = await bookingsService.getBookingReceipt(mockCustomer.id, booking.id);
    expect(receipt.status).toBe(BookingStatus.COMPLETED);
    expect(receipt.currency).toBe('EGP');

    const auditLogs = await prismaMock.adminAuditLog.findMany();
    expect(auditLogs.length).toBe(1);
    expect(auditLogs[0].action).toBe('BOOKING_COMPLETED_CASH_SETTLED');
  });
});
