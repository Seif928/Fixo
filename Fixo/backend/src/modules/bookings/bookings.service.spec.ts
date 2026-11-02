import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingStatus,
  PaymentMethodType,
  PaymentStatus,
  ProVerificationStatus,
  TimeWindow,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { BookingsService } from './bookings.service';
import { CheckoutBookingDto } from './dto/checkout-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';

describe('BookingsService (Unit Tests)', () => {
  let service: BookingsService;
  let prismaMock: any;

  const mockCustomerId = 'cust-101';
  const mockOtherCustomerId = 'cust-999';

  const mockAddress = {
    id: 'addr-01',
    userId: mockCustomerId,
    zoneId: 'zone-new-cairo',
    label: 'Home',
    buildingLine: 'Villa 14, Street 9',
    districtLine: 'New Cairo, First Settlement',
    gateNotes: 'Ring 3B',
    isDefault: true,
    zone: {
      id: 'zone-new-cairo',
      slug: 'new-cairo',
      nameEn: 'New Cairo & Tagamoa',
      nameAr: 'القاهرة الجديدة والتجمع',
      governorate: 'Cairo',
    },
  };

  const mockOffering = {
    id: 'off-ac-clean',
    categoryId: 'cat-ac',
    slug: 'ac-cleaning-split',
    titleEn: 'AC Deep Clean & Filter Sanitization',
    titleAr: 'تنظيف عميق وتعقيم فلاتر التكييف',
    descriptionEn: 'Full indoor split AC pressure wash',
    descriptionAr: 'غسيل ضغط داخلي مع تعقيم',
    baseInspectionEgp: 150,
    serviceFeeEgp: 250,
    flatPriceEgp: null, // Total will be 150 + 250 = 400
    category: {
      id: 'cat-ac',
      slug: 'ac-maintenance',
      nameEn: 'AC Maintenance',
      nameAr: 'صيانة تكييف',
      isActive: true,
    },
  };

  const mockPro = {
    id: 'pro-hassan-01',
    userId: 'user-hassan',
    dossierCode: 'PRO-1001',
    specialtyEn: 'HVAC Certified Specialist',
    specialtyAr: 'فني تكييف معتمد',
    ratingAvg: 4.9,
    verificationStatus: ProVerificationStatus.APPROVED,
    user: {
      fullName: 'Hassan El-Sayed',
      avatarUrl: 'https://example.com/hassan.jpg',
    },
  };

  beforeEach(() => {
    prismaMock = {
      customerAddress: {
        findUnique: jest.fn(),
      },
      serviceOffering: {
        findUnique: jest.fn(),
      },
      proProfile: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      booking: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      paymentRecord: {
        create: jest.fn(),
        update: jest.fn(),
      },
      bookingStatusEvent: {
        create: jest.fn(),
      },
      review: {
        findUnique: jest.fn(),
        create: jest.fn(),
        aggregate: jest.fn(),
      },
      jobOffer: {
        updateMany: jest.fn(),
      },
      user: {
        update: jest.fn(),
      },
      $queryRaw: jest.fn().mockResolvedValue([{ id: 'mock-id' }]),
      isDatabaseConnected: jest.fn().mockReturnValue(false),
      $transaction: jest.fn(async (callback) => {
        return callback(prismaMock);
      }),
    };

    service = new BookingsService(prismaMock as unknown as PrismaService);
  });

  describe('createBooking Validations', () => {
    const validDto: CreateBookingDto = {
      offeringId: 'off-ac-clean',
      addressId: 'addr-01',
      scheduledDate: new Date(Date.now() + 86400000).toISOString().split('T')[0], // Tomorrow
      timeWindow: TimeWindow.AFTERNOON_13_16,
      issueDescription: 'Unit is leaking condensation water',
    };

    it('rejects invalid scheduled date strings', async () => {
      const invalidDto = { ...validDto, scheduledDate: 'not-a-date' };
      await expect(service.createBooking(mockCustomerId, invalidDto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('rejects past scheduled dates', async () => {
      const pastDto = { ...validDto, scheduledDate: '2020-01-01' };
      await expect(service.createBooking(mockCustomerId, pastDto)).rejects.toThrow(
        new BadRequestException('Scheduled date cannot be in the past.'),
      );
    });

    it('throws NotFoundException when customer address does not exist', async () => {
      prismaMock.customerAddress.findUnique.mockResolvedValue(null);

      await expect(service.createBooking(mockCustomerId, validDto)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('throws ForbiddenException when customer attempts to use someone elses address', async () => {
      prismaMock.customerAddress.findUnique.mockResolvedValue({
        ...mockAddress,
        userId: mockOtherCustomerId,
      });

      await expect(service.createBooking(mockCustomerId, validDto)).rejects.toThrow(
        new ForbiddenException('You do not own this address.'),
      );
    });

    it('throws NotFoundException when service offering does not exist', async () => {
      prismaMock.customerAddress.findUnique.mockResolvedValue(mockAddress);
      prismaMock.serviceOffering.findUnique.mockResolvedValue(null);

      await expect(service.createBooking(mockCustomerId, validDto)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('throws BadRequestException when service offering category is inactive', async () => {
      prismaMock.customerAddress.findUnique.mockResolvedValue(mockAddress);
      prismaMock.serviceOffering.findUnique.mockResolvedValue({
        ...mockOffering,
        category: { ...mockOffering.category, isActive: false },
      });

      await expect(service.createBooking(mockCustomerId, validDto)).rejects.toThrow(
        new BadRequestException(
          'Selected service offering category is not currently active.',
        ),
      );
    });

    it('throws NotFoundException when preferred pro does not exist', async () => {
      prismaMock.customerAddress.findUnique.mockResolvedValue(mockAddress);
      prismaMock.serviceOffering.findUnique.mockResolvedValue(mockOffering);
      prismaMock.proProfile.findUnique.mockResolvedValue(null);

      const dtoWithPro = { ...validDto, preferredProId: 'non-existent-pro' };
      await expect(service.createBooking(mockCustomerId, dtoWithPro)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('throws BadRequestException when preferred pro is not APPROVED', async () => {
      prismaMock.customerAddress.findUnique.mockResolvedValue(mockAddress);
      prismaMock.serviceOffering.findUnique.mockResolvedValue(mockOffering);
      prismaMock.proProfile.findUnique.mockResolvedValue({
        ...mockPro,
        verificationStatus: ProVerificationStatus.PENDING_REVIEW,
      });

      const dtoWithPro = { ...validDto, preferredProId: 'pro-hassan-01' };
      await expect(service.createBooking(mockCustomerId, dtoWithPro)).rejects.toThrow(
        new BadRequestException(
          'Preferred professional is not verified and available for bookings.',
        ),
      );
    });
  });

  describe('createBooking Execution & Pricing Breakdown', () => {
    it('creates booking in DRAFT status with accurate EGP pricing, 10% platform fee, and audit event', async () => {
      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
      const validDto: CreateBookingDto = {
        offeringId: 'off-ac-clean',
        addressId: 'addr-01',
        preferredProId: 'pro-hassan-01',
        scheduledDate: tomorrow,
        timeWindow: TimeWindow.AFTERNOON_13_16,
        issueDescription: 'AC leaking water',
        issuePhotoUrls: ['https://example.com/ac.jpg'],
      };

      prismaMock.customerAddress.findUnique.mockResolvedValue(mockAddress);
      prismaMock.serviceOffering.findUnique.mockResolvedValue(mockOffering);
      prismaMock.proProfile.findUnique.mockResolvedValue(mockPro);
      prismaMock.booking.findUnique.mockResolvedValue(null); // No collision on orderCode

      const createdBookingRecord = {
        id: 'bk-new-1',
        orderCode: 'FX-7721',
        customerId: mockCustomerId,
        proProfileId: 'pro-hassan-01',
        offeringId: 'off-ac-clean',
        addressId: 'addr-01',
        status: BookingStatus.DRAFT,
        scheduledDate: new Date(tomorrow),
        timeWindow: TimeWindow.AFTERNOON_13_16,
        issueDescription: 'AC leaking water',
        issuePhotoUrls: ['https://example.com/ac.jpg'],
        baseInspectionEgp: 150,
        serviceFeeEgp: 250,
        transportFeeEgp: 0,
        totalEgp: 400,
        platformFeeEgp: 40,
        netArtisanEgp: 360,
        arrivalPinCode: '8832',
        offering: mockOffering,
        address: mockAddress,
        proProfile: mockPro,
        statusEvents: [
          {
            id: 'evt-01',
            fromStatus: null,
            toStatus: BookingStatus.DRAFT,
            note: 'Customer created booking draft',
            createdAt: new Date(),
          },
        ],
        createdAt: new Date(),
        updatedAt: new Date(),
        completedAt: null,
      };

      prismaMock.booking.create.mockResolvedValue(createdBookingRecord);

      const result = await service.createBooking(mockCustomerId, validDto);

      expect(prismaMock.booking.create).toHaveBeenCalledTimes(1);
      const createCallData = prismaMock.booking.create.mock.calls[0][0].data;

      // Verify strict invariants
      expect(createCallData.status).toBe(BookingStatus.DRAFT);
      expect(createCallData.baseInspectionEgp).toBe(150);
      expect(createCallData.serviceFeeEgp).toBe(250);
      expect(createCallData.transportFeeEgp).toBe(0);
      expect(createCallData.totalEgp).toBe(400);
      expect(createCallData.platformFeeEgp).toBe(40); // 10% of 400
      expect(createCallData.netArtisanEgp).toBe(360); // 400 - 40
      expect(createCallData.orderCode).toMatch(/^FX-\d{4}$/);
      expect(createCallData.arrivalPinCode).toMatch(/^\d{4}$/);
      expect(createCallData.statusEvents.create).toEqual({
        fromStatus: null,
        toStatus: BookingStatus.DRAFT,
        actorUserId: mockCustomerId,
        note: 'Customer created booking draft',
      });

      // Verify formatted response
      expect(result.id).toBe('bk-new-1');
      expect(result.status).toBe(BookingStatus.DRAFT);
      expect(result.pricing.currency).toBe('EGP');
      expect(result.pricing.totalEgp).toBe(400);
      expect(result.pricing.platformFeeEgp).toBe(40);
      expect(result.pricing.netArtisanEgp).toBe(360);
      expect(result.offering.titleEn).toBe('AC Deep Clean & Filter Sanitization');
      expect(result.address.districtLine).toBe('New Cairo, First Settlement');
      expect(result.statusEvents).toHaveLength(1);
      expect(result.statusEvents![0].toStatus).toBe(BookingStatus.DRAFT);
    });

    it('uses flatPriceEgp when defined on service offering', async () => {
      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
      const flatOffering = {
        ...mockOffering,
        flatPriceEgp: 350,
      };

      prismaMock.customerAddress.findUnique.mockResolvedValue(mockAddress);
      prismaMock.serviceOffering.findUnique.mockResolvedValue(flatOffering);
      prismaMock.booking.findUnique.mockResolvedValue(null);

      prismaMock.booking.create.mockImplementation((args: any) => ({
        ...args.data,
        id: 'bk-flat-1',
        offering: flatOffering,
        address: mockAddress,
        statusEvents: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      }));

      const result = await service.createBooking(mockCustomerId, {
        offeringId: 'off-ac-clean',
        addressId: 'addr-01',
        scheduledDate: tomorrow,
        timeWindow: TimeWindow.MORNING_09_12,
      });

      expect(result.pricing.totalEgp).toBe(350);
      expect(result.pricing.platformFeeEgp).toBe(35); // 10% of 350
      expect(result.pricing.netArtisanEgp).toBe(315);
    });
  });

  describe('findCustomerBookings', () => {
    it('queries only authenticated customer bookings with tab filtering', async () => {
      prismaMock.booking.findMany.mockResolvedValue([]);
      prismaMock.booking.count.mockResolvedValue(0);

      // Active tab
      await service.findCustomerBookings(mockCustomerId, { tab: 'active' });
      expect(prismaMock.booking.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            customerId: mockCustomerId,
            status: {
              in: [
                BookingStatus.DRAFT,
                BookingStatus.PENDING_DISPATCH,
                BookingStatus.OFFERED_TO_PRO,
                BookingStatus.CONFIRMED,
                BookingStatus.PRO_EN_ROUTE,
                BookingStatus.ARRIVED,
                BookingStatus.IN_PROGRESS,
              ],
            },
          },
          take: 20,
          skip: 0,
        }),
      );

      // Completed tab
      await service.findCustomerBookings(mockCustomerId, { tab: 'completed' });
      expect(prismaMock.booking.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            customerId: mockCustomerId,
            status: BookingStatus.COMPLETED,
          },
        }),
      );

      // Cancelled tab
      await service.findCustomerBookings(mockCustomerId, { tab: 'cancelled' });
      expect(prismaMock.booking.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            customerId: mockCustomerId,
            status: BookingStatus.CANCELLED,
          },
        }),
      );
    });
  });

  describe('findCustomerBookingById & Access Isolation', () => {
    const mockDetailRecord = {
      id: 'bk-target-1',
      orderCode: 'FX-1122',
      customerId: mockCustomerId,
      proProfileId: null,
      offeringId: 'off-ac-clean',
      addressId: 'addr-01',
      status: BookingStatus.DRAFT,
      scheduledDate: new Date('2026-11-10'),
      timeWindow: TimeWindow.MORNING_09_12,
      issueDescription: null,
      issuePhotoUrls: [],
      baseInspectionEgp: 150,
      serviceFeeEgp: 250,
      transportFeeEgp: 0,
      totalEgp: 400,
      platformFeeEgp: 40,
      netArtisanEgp: 360,
      arrivalPinCode: '1234',
      offering: mockOffering,
      address: mockAddress,
      proProfile: null,
      statusEvents: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    it('throws NotFoundException when booking does not exist', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(null);

      await expect(
        service.findCustomerBookingById(mockCustomerId, 'non-existent'),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ForbiddenException when a customer attempts to access another customers booking', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(mockDetailRecord);

      // Other customer requesting booking belonging to mockCustomerId
      await expect(
        service.findCustomerBookingById(mockOtherCustomerId, 'bk-target-1', false),
      ).rejects.toThrow(new ForbiddenException('You do not have access to this booking.'));
    });

    it('returns booking details to the legitimate owner customer', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(mockDetailRecord);

      const result = await service.findCustomerBookingById(
        mockCustomerId,
        'bk-target-1',
        false,
      );
      expect(result.id).toBe('bk-target-1');
      expect(result.orderCode).toBe('FX-1122');
      expect(result.customerId).toBe(mockCustomerId);
    });

    it('permits administrator to access any customer booking', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(mockDetailRecord);

      // Admin with different user ID can access
      const result = await service.findCustomerBookingById(
        'admin-user-01',
        'bk-target-1',
        true,
      );
      expect(result.id).toBe('bk-target-1');
      expect(result.customerId).toBe(mockCustomerId);
    });
  });

  describe('checkoutBooking (Phase 4A Cash on Service)', () => {
    const mockDraftBooking: any = {
      id: 'bk-checkout-1',
      orderCode: 'FX-7788',
      customerId: mockCustomerId,
      proProfileId: null,
      offeringId: 'off-ac-clean',
      addressId: 'addr-01',
      status: BookingStatus.DRAFT,
      scheduledDate: new Date('2026-11-15T00:00:00.000Z'),
      timeWindow: TimeWindow.AFTERNOON_13_16,
      issueDescription: 'Need AC maintenance',
      issuePhotoUrls: [],
      baseInspectionEgp: 150,
      serviceFeeEgp: 250,
      transportFeeEgp: 0,
      totalEgp: 400,
      platformFeeEgp: 40,
      netArtisanEgp: 360,
      arrivalPinCode: '4321',
      offering: mockOffering,
      address: mockAddress,
      proProfile: null,
      payment: null,
      statusEvents: [
        {
          id: 'evt-1',
          fromStatus: null,
          toStatus: BookingStatus.DRAFT,
          note: 'Initial draft',
          createdAt: new Date(),
        },
      ],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const cashCheckoutDto: CheckoutBookingDto = {
      paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
    };

    it('rejects unsupported digital payment methods with BadRequestException', async () => {
      const unsupportedDto: CheckoutBookingDto = {
        paymentMethod: PaymentMethodType.INSTAPAY_SANDBOX,
      };

      await expect(
        service.checkoutBooking(mockCustomerId, 'bk-checkout-1', unsupportedDto),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.checkoutBooking(mockCustomerId, 'bk-checkout-1', unsupportedDto),
      ).rejects.toThrow(/not supported yet/);
    });

    it('throws NotFoundException when booking does not exist', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(null);

      await expect(
        service.checkoutBooking(mockCustomerId, 'non-existent', cashCheckoutDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ForbiddenException when another customer attempts checkout', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(mockDraftBooking);

      await expect(
        service.checkoutBooking(mockOtherCustomerId, 'bk-checkout-1', cashCheckoutDto, false),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws BadRequestException when booking is not in DRAFT status', async () => {
      const cancelledBooking = {
        ...mockDraftBooking,
        status: BookingStatus.CANCELLED,
      };
      prismaMock.booking.findUnique.mockResolvedValue(cancelledBooking);

      await expect(
        service.checkoutBooking(mockCustomerId, 'bk-checkout-1', cashCheckoutDto),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.checkoutBooking(mockCustomerId, 'bk-checkout-1', cashCheckoutDto),
      ).rejects.toThrow(/Only bookings in DRAFT status can be checked out/);
    });

    it('atomically transitions DRAFT booking to PENDING_DISPATCH and creates pending cash payment', async () => {
      prismaMock.booking.findUnique
        .mockResolvedValueOnce(mockDraftBooking) // initial check
        .mockResolvedValueOnce(mockDraftBooking) // inside transaction check
        .mockResolvedValueOnce({                 // final findCustomerBookingById reload
          ...mockDraftBooking,
          status: BookingStatus.PENDING_DISPATCH,
          payment: {
            id: 'pay-001',
            bookingId: 'bk-checkout-1',
            method: PaymentMethodType.CASH_ON_SERVICE,
            status: PaymentStatus.PENDING,
            amountEgp: 400,
            tipEgp: 0,
            externalReference: null,
            paidAt: null,
            createdAt: new Date(),
          },
          statusEvents: [
            {
              id: 'evt-2',
              fromStatus: BookingStatus.DRAFT,
              toStatus: BookingStatus.PENDING_DISPATCH,
              note: 'Customer confirmed Cash on Service checkout',
              createdAt: new Date(),
            },
          ],
        });

      prismaMock.booking.update.mockResolvedValue({
        ...mockDraftBooking,
        status: BookingStatus.PENDING_DISPATCH,
      });

      prismaMock.paymentRecord.create.mockResolvedValue({
        id: 'pay-001',
        bookingId: 'bk-checkout-1',
        method: PaymentMethodType.CASH_ON_SERVICE,
        status: PaymentStatus.PENDING,
        amountEgp: 400,
        tipEgp: 0,
        externalReference: null,
        paidAt: null,
      });

      prismaMock.bookingStatusEvent.create.mockResolvedValue({
        id: 'evt-2',
        bookingId: 'bk-checkout-1',
        fromStatus: BookingStatus.DRAFT,
        toStatus: BookingStatus.PENDING_DISPATCH,
        actorUserId: mockCustomerId,
      });

      const result = await service.checkoutBooking(
        mockCustomerId,
        'bk-checkout-1',
        cashCheckoutDto,
      );

      expect(prismaMock.booking.update).toHaveBeenCalledWith({
        where: { id: 'bk-checkout-1' },
        data: { status: BookingStatus.PENDING_DISPATCH },
      });

      expect(prismaMock.paymentRecord.create).toHaveBeenCalledWith({
        data: {
          bookingId: 'bk-checkout-1',
          method: PaymentMethodType.CASH_ON_SERVICE,
          status: PaymentStatus.PENDING,
          amountEgp: 400,
          tipEgp: 0,
          externalReference: null,
          paidAt: null,
        },
      });

      expect(prismaMock.bookingStatusEvent.create).toHaveBeenCalledWith({
        data: {
          bookingId: 'bk-checkout-1',
          fromStatus: BookingStatus.DRAFT,
          toStatus: BookingStatus.PENDING_DISPATCH,
          actorUserId: mockCustomerId,
          note: 'Customer confirmed Cash on Service checkout',
        },
      });

      expect(result.status).toBe(BookingStatus.PENDING_DISPATCH);
      expect(result.payment).toBeDefined();
      expect(result.payment?.method).toBe(PaymentMethodType.CASH_ON_SERVICE);
      expect(result.payment?.status).toBe(PaymentStatus.PENDING);
      expect(result.payment?.amountEgp).toBe(400);
      expect(result.payment?.paidAt).toBeNull();
      expect(result.payment?.externalReference).toBeNull();
    });

    it('returns idempotent response without duplicate update when already PENDING_DISPATCH with cash payment', async () => {
      const alreadyCheckedOutBooking: any = {
        ...mockDraftBooking,
        status: BookingStatus.PENDING_DISPATCH,
        payment: {
          id: 'pay-001',
          bookingId: 'bk-checkout-1',
          method: PaymentMethodType.CASH_ON_SERVICE,
          status: PaymentStatus.PENDING,
          amountEgp: 400,
          tipEgp: 0,
          externalReference: null,
          paidAt: null,
          createdAt: new Date(),
        },
      };

      prismaMock.booking.findUnique.mockResolvedValue(alreadyCheckedOutBooking);

      const result = await service.checkoutBooking(
        mockCustomerId,
        'bk-checkout-1',
        cashCheckoutDto,
      );

      expect(prismaMock.booking.update).not.toHaveBeenCalled();
      expect(prismaMock.paymentRecord.create).not.toHaveBeenCalled();
      expect(prismaMock.bookingStatusEvent.create).not.toHaveBeenCalled();
      expect(result.status).toBe(BookingStatus.PENDING_DISPATCH);
      expect(result.payment?.method).toBe(PaymentMethodType.CASH_ON_SERVICE);
    });
  });

  describe('Tracking, Cancellation, Receipt, Reviews & Private Uploads', () => {
    const completedBookingWithPro: any = {
      id: 'bk-comp-100',
      orderCode: 'FX-9010',
      customerId: mockCustomerId,
      proProfileId: 'pro-hassan-01',
      offeringId: 'off-ac-clean',
      addressId: 'addr-01',
      status: BookingStatus.COMPLETED,
      scheduledDate: new Date('2026-11-15T00:00:00.000Z'),
      timeWindow: TimeWindow.MORNING_09_12,
      issueDescription: 'AC maintenance completed',
      issuePhotoUrls: [],
      baseInspectionEgp: 150,
      serviceFeeEgp: 250,
      transportFeeEgp: 0,
      totalEgp: 400,
      platformFeeEgp: 40,
      netArtisanEgp: 360,
      arrivalPinCode: '5824',
      offering: mockOffering,
      address: { ...mockAddress, latitude: 30.0254, longitude: 31.4902 },
      proProfile: {
        ...mockPro,
        user: { id: 'user-hassan', fullName: 'Hassan El-Sayed', avatarUrl: null },
      },
      customer: { id: mockCustomerId, fullName: 'Ahmed Customer' },
      payment: {
        id: 'pay-9010',
        bookingId: 'bk-comp-100',
        method: PaymentMethodType.CASH_ON_SERVICE,
        status: PaymentStatus.PAID,
        amountEgp: 400,
        tipEgp: 0,
        externalReference: null,
        paidAt: new Date('2026-11-15T11:30:00.000Z'),
        createdAt: new Date('2026-11-14T10:00:00.000Z'),
      },
      review: null,
      statusEvents: [
        {
          id: 'evt-1',
          fromStatus: null,
          toStatus: BookingStatus.DRAFT,
          note: 'Draft created',
          createdAt: new Date('2026-11-14T10:00:00.000Z'),
        },
        {
          id: 'evt-2',
          fromStatus: BookingStatus.DRAFT,
          toStatus: BookingStatus.CONFIRMED,
          note: 'Pro accepted',
          createdAt: new Date('2026-11-14T10:05:00.000Z'),
        },
        {
          id: 'evt-3',
          fromStatus: BookingStatus.IN_PROGRESS,
          toStatus: BookingStatus.COMPLETED,
          note: 'Completed',
          createdAt: new Date('2026-11-15T11:30:00.000Z'),
        },
      ],
      createdAt: new Date('2026-11-14T10:00:00.000Z'),
      updatedAt: new Date('2026-11-15T11:30:00.000Z'),
      completedAt: new Date('2026-11-15T11:30:00.000Z'),
    };

    it('builds 5 tracking milestones and masks arrivalPinCode when accessed by assigned Pro', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(completedBookingWithPro);

      // Customer sees real arrivalPinCode
      const customerTracking = await service.getBookingTracking(
        mockCustomerId,
        'bk-comp-100',
      );
      expect(customerTracking.booking.arrivalPinCode).toBe('5824');
      expect(customerTracking.milestones).toHaveLength(5);
      expect(
        customerTracking.milestones.every((m) => m.state === 'COMPLETED'),
      ).toBe(true);
      expect(customerTracking.canReview).toBe(true);
      expect(customerTracking.canCancel).toBe(false);

      // Assigned pro sees masked arrivalPinCode ('****')
      const proTracking = await service.getBookingTracking(
        'user-hassan',
        'bk-comp-100',
      );
      expect(proTracking.booking.arrivalPinCode).toBe('****');
      expect(proTracking.canReview).toBe(false);
    });

    it('rejects review when booking is not COMPLETED or has duplicate review', async () => {
      prismaMock.booking.findUnique.mockResolvedValue({
        ...completedBookingWithPro,
        status: BookingStatus.CONFIRMED,
      });

      await expect(
        service.submitBookingReview(mockCustomerId, 'bk-comp-100', {
          rating: 5,
          tags: ['On Time'],
          comment: 'Great service',
        }),
      ).rejects.toThrow(BadRequestException);

      // Duplicate review check
      prismaMock.booking.findUnique.mockResolvedValue({
        ...completedBookingWithPro,
        review: { id: 'rev-existing', rating: 5 },
      });

      await expect(
        service.submitBookingReview(mockCustomerId, 'bk-comp-100', {
          rating: 5,
        }),
      ).rejects.toThrow(/already been submitted/);
    });

    it('submits review for COMPLETED booking, updates tipEgp, and recalculates Pro ratingAvg', async () => {
      prismaMock.booking.findUnique.mockResolvedValue(completedBookingWithPro);
      prismaMock.review.findUnique.mockResolvedValue(null);
      prismaMock.review.create.mockResolvedValue({
        id: 'rev-new-1',
        bookingId: 'bk-comp-100',
        customerId: mockCustomerId,
        proProfileId: 'pro-hassan-01',
        rating: 5,
        tags: ['On Time', 'Clean Work'],
        comment: 'Fixed the AC leak quickly!',
        photoUrls: [],
        tipAmountEgp: 50,
        createdAt: new Date('2026-11-15T12:00:00.000Z'),
      });
      prismaMock.review.aggregate.mockResolvedValue({
        _avg: { rating: 4.92 },
        _count: { id: 12 },
      });

      const res = await service.submitBookingReview(mockCustomerId, 'bk-comp-100', {
        rating: 5,
        tags: ['On Time', 'Clean Work'],
        comment: 'Fixed the AC leak quickly!',
        tipAmountEgp: 50,
      });

      expect(res.rating).toBe(5);
      expect(res.tipAmountEgp).toBe(50);
      expect(prismaMock.paymentRecord.update).toHaveBeenCalledWith({
        where: { id: 'pay-9010' },
        data: { tipEgp: 50 },
      });
      expect(prismaMock.proProfile.update).toHaveBeenCalledWith({
        where: { id: 'pro-hassan-01' },
        data: { ratingAvg: 4.92, reviewsCount: 12 },
      });
    });

    it('validates and signs private image uploads and rejects spoofed magic bytes', async () => {
      // Valid PNG magic header: 89 50 4E 47 0D 0A 1A 0A
      const pngBytes = Buffer.from([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
      ]);
      const uploadRes = await service.createPrivateUpload(mockCustomerId, {
        purpose: 'BOOKING_ISSUE',
        fileName: 'ac-leak.png',
        mimeType: 'image/png',
        contentBase64: pngBytes.toString('base64'),
      });

      expect(uploadRes.mimeType).toBe('image/png');
      expect(uploadRes.accessToken).toBeDefined();

      const claims = service.verifyPrivateUploadToken(
        mockCustomerId,
        uploadRes.accessToken,
      );
      expect(claims.ownerUserId).toBe(mockCustomerId);
      expect(claims.fileName).toBe('ac-leak.png');

      // Other user cannot verify token
      expect(() =>
        service.verifyPrivateUploadToken(
          mockOtherCustomerId,
          uploadRes.accessToken,
        ),
      ).toThrow(ForbiddenException);

      // Spoofed magic bytes (text claiming to be image/jpeg)
      await expect(
        service.createPrivateUpload(mockCustomerId, {
          purpose: 'BOOKING_ISSUE',
          fileName: 'fake.jpg',
          mimeType: 'image/jpeg',
          contentBase64: Buffer.from('hello world not a jpeg').toString('base64'),
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});


