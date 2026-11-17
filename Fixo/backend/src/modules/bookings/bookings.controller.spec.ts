import { Test, TestingModule } from '@nestjs/testing';
import {
  BookingStatus,
  PaymentMethodType,
  TimeWindow,
  UserRole,
} from '@prisma/client';
import { AuthService } from '../auth/auth.service';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';
import { BookingQueryDto } from './dto/booking-query.dto';
import { CheckoutBookingDto } from './dto/checkout-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';

describe('BookingsController (Unit Tests)', () => {
  let controller: BookingsController;
  let serviceMock: Partial<Record<keyof BookingsService, jest.Mock>>;

  const mockCustomerJwt: FixoJwtPayload = {
    sub: 'user-cust-1',
    phone: '+201012345678',
    role: UserRole.CUSTOMER,
    type: 'access',
    jti: 'jti-1',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 900,
  };

  const mockAdminJwt: FixoJwtPayload = {
    sub: 'user-admin-1',
    phone: '+201099999999',
    role: UserRole.ADMIN,
    type: 'access',
    jti: 'jti-2',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 900,
  };

  beforeEach(async () => {
    serviceMock = {
      createBooking: jest.fn(),
      findCustomerBookings: jest.fn(),
      findCustomerBookingById: jest.fn(),
      checkoutBooking: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [BookingsController],
      providers: [
        {
          provide: BookingsService,
          useValue: serviceMock,
        },
        {
          provide: AuthService,
          useValue: {},
        },
      ],
    }).compile();

    controller = module.get<BookingsController>(BookingsController);
  });

  it('POST / forwards customer ID and DTO to bookingsService.createBooking', async () => {
    const dto: CreateBookingDto = {
      offeringId: 'off-1',
      addressId: 'addr-1',
      scheduledDate: '2026-11-10',
      timeWindow: TimeWindow.AFTERNOON_13_16,
    };

    const expectedResponse: any = {
      id: 'bk-1',
      orderCode: 'FX-8842',
      status: BookingStatus.DRAFT,
    };
    serviceMock.createBooking!.mockResolvedValue(expectedResponse);

    const res = await controller.createBooking(mockCustomerJwt, dto);

    expect(serviceMock.createBooking).toHaveBeenCalledWith(
      mockCustomerJwt.sub,
      dto,
    );
    expect(res).toEqual(expectedResponse);
  });

  it('GET / forwards customer ID and query to bookingsService.findCustomerBookings', async () => {
    const query: BookingQueryDto = {
      tab: 'active',
      limit: 10,
      offset: 0,
    };

    const expectedResponse: any = {
      bookings: [],
      total: 0,
      limit: 10,
      offset: 0,
    };
    serviceMock.findCustomerBookings!.mockResolvedValue(expectedResponse);

    const res = await controller.getCustomerBookings(mockCustomerJwt, query);

    expect(serviceMock.findCustomerBookings).toHaveBeenCalledWith(
      mockCustomerJwt.sub,
      query,
    );
    expect(res).toEqual(expectedResponse);
  });

  it('GET /:id forwards the customer identity and booking ID', async () => {
    const bookingId = 'bk-target-123';
    const expectedResponse: any = { id: bookingId };
    serviceMock.findCustomerBookingById!.mockResolvedValue(expectedResponse);

    const res = await controller.getBookingById(mockCustomerJwt, bookingId);

    expect(serviceMock.findCustomerBookingById).toHaveBeenCalledWith(
      mockCustomerJwt.sub,
      bookingId,
    );
    expect(res).toEqual(expectedResponse);
  });

  it('GET /:id never forwards an app ADMIN ownership override', async () => {
    const bookingId = 'bk-target-123';
    const expectedResponse: any = { id: bookingId };
    serviceMock.findCustomerBookingById!.mockResolvedValue(expectedResponse);

    const res = await controller.getBookingById(mockAdminJwt, bookingId);

    expect(serviceMock.findCustomerBookingById).toHaveBeenCalledWith(
      mockAdminJwt.sub,
      bookingId,
    );
    expect(res).toEqual(expectedResponse);
  });

  describe('POST /:bookingId/checkout', () => {
    it('forwards customer identity and checkout data', async () => {
      const bookingId = 'bk-target-123';
      const dto: CheckoutBookingDto = {
        paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
      };
      const expectedResponse: any = {
        id: bookingId,
        status: BookingStatus.PENDING_DISPATCH,
      };
      serviceMock.checkoutBooking!.mockResolvedValue(expectedResponse);

      const res = await controller.checkoutBooking(
        mockCustomerJwt,
        bookingId,
        dto,
      );

      expect(serviceMock.checkoutBooking).toHaveBeenCalledWith(
        mockCustomerJwt.sub,
        bookingId,
        dto,
      );
      expect(res).toEqual(expectedResponse);
    });

    it('never grants an app ADMIN checkout override', async () => {
      const bookingId = 'bk-target-123';
      const dto: CheckoutBookingDto = {
        paymentMethod: PaymentMethodType.CASH_ON_SERVICE,
      };
      const expectedResponse: any = {
        id: bookingId,
        status: BookingStatus.PENDING_DISPATCH,
      };
      serviceMock.checkoutBooking!.mockResolvedValue(expectedResponse);

      const res = await controller.checkoutBooking(
        mockAdminJwt,
        bookingId,
        dto,
      );

      expect(serviceMock.checkoutBooking).toHaveBeenCalledWith(
        mockAdminJwt.sub,
        bookingId,
        dto,
      );
      expect(res).toEqual(expectedResponse);
    });
  });
});
