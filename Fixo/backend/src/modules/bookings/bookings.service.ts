import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingStatus,
  PaymentMethodType,
  PaymentStatus,
  ProVerificationStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { BookingQueryDto } from './dto/booking-query.dto';
import {
  BookingDetailResponse,
  BookingListResponse,
} from './dto/booking-response.dto';
import { CheckoutBookingDto } from './dto/checkout-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';

const ACTIVE_BOOKING_STATUSES: BookingStatus[] = [
  BookingStatus.DRAFT,
  BookingStatus.PENDING_DISPATCH,
  BookingStatus.OFFERED_TO_PRO,
  BookingStatus.CONFIRMED,
  BookingStatus.PRO_EN_ROUTE,
  BookingStatus.ARRIVED,
  BookingStatus.IN_PROGRESS,
];

@Injectable()
export class BookingsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generates a unique human-readable order code: e.g. "FX-8842".
   */
  private async generateUniqueOrderCode(): Promise<string> {
    for (let attempt = 0; attempt < 5; attempt++) {
      const randomDigits = Math.floor(1000 + Math.random() * 9000);
      const code = `FX-${randomDigits}`;
      const existing = await this.prisma.booking.findUnique({
        where: { orderCode: code },
        select: { id: true },
      });
      if (!existing) {
        return code;
      }
    }
    const fallbackDigits = Math.floor(1000 + Math.random() * 9000);
    return `FX-${fallbackDigits}-${Date.now().toString().slice(-4)}`;
  }

  /**
   * Generates a 4-digit numeric arrival PIN code: e.g. "5841".
   */
  private generateArrivalPinCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  /**
   * Validates scheduled date string and ensures it is not in the past.
   */
  private validateScheduledDate(dateStr: string): Date {
    const parsedDate = new Date(dateStr);
    if (isNaN(parsedDate.getTime())) {
      throw new BadRequestException('Invalid scheduledDate format.');
    }

    const todayUtc = new Date();
    todayUtc.setUTCHours(0, 0, 0, 0);

    const scheduledUtc = new Date(parsedDate);
    scheduledUtc.setUTCHours(0, 0, 0, 0);

    if (scheduledUtc.getTime() < todayUtc.getTime()) {
      throw new BadRequestException('Scheduled date cannot be in the past.');
    }

    return parsedDate;
  }

  /**
   * Maps internal Prisma Booking entity to standard BookingDetailResponse.
   */
  formatBookingResponse(booking: any): BookingDetailResponse {
    return {
      id: booking.id,
      orderCode: booking.orderCode,
      customerId: booking.customerId,
      proProfileId: booking.proProfileId ?? null,
      offeringId: booking.offeringId,
      addressId: booking.addressId,
      status: booking.status,
      scheduledDate:
        booking.scheduledDate instanceof Date
          ? booking.scheduledDate.toISOString().split('T')[0]
          : String(booking.scheduledDate),
      timeWindow: booking.timeWindow,
      issueDescription: booking.issueDescription ?? null,
      issuePhotoUrls: Array.isArray(booking.issuePhotoUrls)
        ? booking.issuePhotoUrls
        : [],
      pricing: {
        baseInspectionEgp: booking.baseInspectionEgp,
        serviceFeeEgp: booking.serviceFeeEgp,
        transportFeeEgp: booking.transportFeeEgp ?? 0,
        totalEgp: booking.totalEgp,
        platformFeeEgp: booking.platformFeeEgp,
        netArtisanEgp: booking.netArtisanEgp,
        currency: 'EGP',
      },
      arrivalPinCode: booking.arrivalPinCode,
      offering: {
        id: booking.offering.id,
        slug: booking.offering.slug,
        titleEn: booking.offering.titleEn,
        titleAr: booking.offering.titleAr,
        descriptionEn: booking.offering.descriptionEn,
        descriptionAr: booking.offering.descriptionAr,
        category: {
          id: booking.offering.category.id,
          slug: booking.offering.category.slug,
          nameEn: booking.offering.category.nameEn,
          nameAr: booking.offering.category.nameAr,
        },
      },
      address: {
        id: booking.address.id,
        label: booking.address.label,
        buildingLine: booking.address.buildingLine,
        districtLine: booking.address.districtLine,
        gateNotes: booking.address.gateNotes ?? null,
        zone: booking.address.zone
          ? {
              id: booking.address.zone.id,
              slug: booking.address.zone.slug,
              nameEn: booking.address.zone.nameEn,
              nameAr: booking.address.zone.nameAr,
              governorate: booking.address.zone.governorate,
            }
          : null,
      },
      proProfile: booking.proProfile
        ? {
            id: booking.proProfile.id,
            dossierCode: booking.proProfile.dossierCode,
            specialtyEn: booking.proProfile.specialtyEn ?? null,
            specialtyAr: booking.proProfile.specialtyAr ?? null,
            ratingAvg: booking.proProfile.ratingAvg,
            user: booking.proProfile.user
              ? {
                  fullName: booking.proProfile.user.fullName ?? null,
                  avatarUrl: booking.proProfile.user.avatarUrl ?? null,
                }
              : null,
          }
        : null,
      payment: booking.payment
        ? {
            id: booking.payment.id,
            bookingId: booking.payment.bookingId,
            method: booking.payment.method,
            status: booking.payment.status,
            amountEgp: booking.payment.amountEgp,
            tipEgp: booking.payment.tipEgp ?? 0,
            externalReference: booking.payment.externalReference ?? null,
            paidAt: booking.payment.paidAt
              ? booking.payment.paidAt instanceof Date
                ? booking.payment.paidAt.toISOString()
                : String(booking.payment.paidAt)
              : null,
            createdAt:
              booking.payment.createdAt instanceof Date
                ? booking.payment.createdAt.toISOString()
                : String(booking.payment.createdAt),
          }
        : null,
      statusEvents: Array.isArray(booking.statusEvents)
        ? booking.statusEvents.map((evt: any) => ({
            id: evt.id,
            fromStatus: evt.fromStatus ?? null,
            toStatus: evt.toStatus,
            note: evt.note ?? null,
            createdAt:
              evt.createdAt instanceof Date
                ? evt.createdAt.toISOString()
                : String(evt.createdAt),
          }))
        : [],
      createdAt:
        booking.createdAt instanceof Date
          ? booking.createdAt.toISOString()
          : String(booking.createdAt),
      updatedAt:
        booking.updatedAt instanceof Date
          ? booking.updatedAt.toISOString()
          : String(booking.updatedAt),
      completedAt: booking.completedAt
        ? booking.completedAt instanceof Date
          ? booking.completedAt.toISOString()
          : String(booking.completedAt)
        : null,
    };
  }

  /**
   * Creates a customer booking in DRAFT status.
   *
   * Validations:
   * 1. Customer address exists and belongs to the authenticated customer.
   * 2. Service offering exists and its parent category is active.
   * 3. Optional preferred pro exists and is APPROVED.
   * 4. Scheduled date is valid and not in the past.
   * 5. Fare breakdown is computed deterministically in EGP.
   * 6. Transaction creates the Booking and the initial BookingStatusEvent.
   */
  async createBooking(
    customerId: string,
    dto: CreateBookingDto,
  ): Promise<BookingDetailResponse> {
    const scheduledDate = this.validateScheduledDate(dto.scheduledDate);

    // 1. Validate Address Ownership
    const address = await this.prisma.customerAddress.findUnique({
      where: { id: dto.addressId },
    });
    if (!address) {
      throw new NotFoundException(`Address with ID "${dto.addressId}" not found.`);
    }
    if (address.userId !== customerId) {
      throw new ForbiddenException('You do not own this address.');
    }

    // 2. Validate Service Offering Availability
    const offering = await this.prisma.serviceOffering.findUnique({
      where: { id: dto.offeringId },
      include: { category: true },
    });
    if (!offering) {
      throw new NotFoundException(
        `Service offering with ID "${dto.offeringId}" not found.`,
      );
    }
    if (!offering.category.isActive) {
      throw new BadRequestException(
        'Selected service offering category is not currently active.',
      );
    }

    // 3. Validate Optional Preferred Professional
    if (dto.preferredProId) {
      const pro = await this.prisma.proProfile.findUnique({
        where: { id: dto.preferredProId },
      });
      if (!pro) {
        throw new NotFoundException(
          `Preferred professional with ID "${dto.preferredProId}" not found.`,
        );
      }
      if (pro.verificationStatus !== ProVerificationStatus.APPROVED) {
        throw new BadRequestException(
          'Preferred professional is not verified and available for bookings.',
        );
      }
    }

    // 4. Compute EGP Pricing Breakdown
    const baseInspectionEgp = offering.baseInspectionEgp;
    const serviceFeeEgp = offering.serviceFeeEgp;
    const transportFeeEgp = 0; // Waived in Cairo & Giza per design
    const totalEgp =
      offering.flatPriceEgp ?? baseInspectionEgp + serviceFeeEgp;
    const platformFeeEgp = Math.round(totalEgp * 0.1);
    const netArtisanEgp = totalEgp - platformFeeEgp;

    // 5. Generate Codes
    const orderCode = await this.generateUniqueOrderCode();
    const arrivalPinCode = this.generateArrivalPinCode();

    // 6. Execute Atomic Transaction (Booking + Initial Status Event)
    const booking = await this.prisma.$transaction(async (tx) => {
      const createdBooking = await tx.booking.create({
        data: {
          orderCode,
          customerId,
          proProfileId: dto.preferredProId ?? null,
          offeringId: dto.offeringId,
          addressId: dto.addressId,
          status: BookingStatus.DRAFT,
          scheduledDate,
          timeWindow: dto.timeWindow,
          issueDescription: dto.issueDescription ?? null,
          issuePhotoUrls: dto.issuePhotoUrls ?? [],
          baseInspectionEgp,
          serviceFeeEgp,
          transportFeeEgp,
          totalEgp,
          platformFeeEgp,
          netArtisanEgp,
          arrivalPinCode,
          statusEvents: {
            create: {
              fromStatus: null,
              toStatus: BookingStatus.DRAFT,
              actorUserId: customerId,
              note: 'Customer created booking draft',
            },
          },
        },
        include: {
          offering: {
            include: {
              category: true,
            },
          },
          address: {
            include: {
              zone: true,
            },
          },
          proProfile: {
            include: {
              user: true,
            },
          },
          payment: true,
          statusEvents: {
            orderBy: { createdAt: 'desc' },
          },
        },
      });

      return createdBooking;
    });

    return this.formatBookingResponse(booking);
  }

  /**
   * Retrieves bookings for the authenticated customer, filtered by status or tab.
   */
  async findCustomerBookings(
    customerId: string,
    query: BookingQueryDto,
  ): Promise<BookingListResponse> {
    const limit = query.limit ?? 20;
    const offset = query.offset ?? 0;

    const where: any = { customerId };

    if (query.status) {
      where.status = query.status;
    } else if (query.tab) {
      if (query.tab === 'active') {
        where.status = { in: ACTIVE_BOOKING_STATUSES };
      } else if (query.tab === 'completed') {
        where.status = BookingStatus.COMPLETED;
      } else if (query.tab === 'cancelled') {
        where.status = BookingStatus.CANCELLED;
      }
    }

    const [records, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        take: limit,
        skip: offset,
        orderBy: { createdAt: 'desc' },
        include: {
          offering: {
            include: {
              category: true,
            },
          },
          address: {
            include: {
              zone: true,
            },
          },
          proProfile: {
            include: {
              user: true,
            },
          },
          payment: true,
          statusEvents: {
            orderBy: { createdAt: 'desc' },
          },
        },
      }),
      this.prisma.booking.count({ where }),
    ]);

    return {
      bookings: records.map((b) => this.formatBookingResponse(b)),
      total,
      limit,
      offset,
    };
  }

  /**
   * Retrieves a single booking by ID.
   * Enforces customer ownership (or admin privileges).
   */
  async findCustomerBookingById(
    userId: string,
    bookingId: string,
    isAdmin = false,
  ): Promise<BookingDetailResponse> {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        offering: {
          include: {
            category: true,
          },
        },
        address: {
          include: {
            zone: true,
          },
        },
        proProfile: {
          include: {
            user: true,
          },
        },
        payment: true,
        statusEvents: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!booking) {
      throw new NotFoundException(`Booking with ID "${bookingId}" not found.`);
    }

    if (booking.customerId !== userId && !isAdmin) {
      throw new ForbiddenException('You do not have access to this booking.');
    }

    return this.formatBookingResponse(booking);
  }

  /**
   * Confirms payment method and atomically transitions booking from DRAFT to PENDING_DISPATCH.
   *
   * Business & Security Rules:
   * 1. Only CASH_ON_SERVICE is accepted in MVP. Unsupported digital payment methods are rejected.
   * 2. Validates that the booking exists and is owned by the authenticated customer (or admin).
   * 3. Idempotent & retry-safe: if already PENDING_DISPATCH with a matching payment record, returns the booking.
   * 4. Enforces lifecycle state: only DRAFT bookings can transition to checkout.
   * 5. Atomically transitions Booking status to PENDING_DISPATCH, creates PaymentRecord (PENDING),
   *    and creates BookingStatusEvent.
   * 6. Uses PostgreSQL row-level locking (FOR UPDATE) to guarantee concurrency safety against
   *    race conditions, double submissions, and duplicate payment records.
   * 7. Leaves paidAt and externalReference null; no technician is assigned or dispatched.
   */
  async checkoutBooking(
    customerId: string,
    bookingId: string,
    dto: CheckoutBookingDto,
    isAdmin = false,
  ): Promise<BookingDetailResponse> {
    // 1. Initially accept only CASH_ON_SERVICE
    if (dto.paymentMethod !== PaymentMethodType.CASH_ON_SERVICE) {
      throw new BadRequestException(
        `Payment method "${dto.paymentMethod}" is not supported yet. Only "${PaymentMethodType.CASH_ON_SERVICE}" is currently accepted.`,
      );
    }

    // 2. Fetch booking and validate existence
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        payment: true,
      },
    });

    if (!booking) {
      throw new NotFoundException(`Booking with ID "${bookingId}" not found.`);
    }

    // 3. Ownership validation: reject if belongs to another customer
    if (booking.customerId !== customerId && !isAdmin) {
      throw new ForbiddenException('You do not have access to this booking.');
    }

    // 4. Idempotency fast path: if already in PENDING_DISPATCH with matching payment record
    if (
      booking.status === BookingStatus.PENDING_DISPATCH &&
      booking.payment &&
      booking.payment.method === dto.paymentMethod
    ) {
      return this.findCustomerBookingById(customerId, bookingId, isAdmin);
    }

    // 5. Reject invalid lifecycle states: only DRAFT bookings can transition to checkout
    if (booking.status !== BookingStatus.DRAFT) {
      throw new BadRequestException(
        `Cannot checkout booking with status "${booking.status}". Only bookings in DRAFT status can be checked out.`,
      );
    }

    // 6. Atomic State Transition with Concurrency Protection
    await this.prisma.$transaction(async (tx) => {
      // Row-level lock: serialize concurrent checkout transactions for this booking
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`
          SELECT "id" FROM "Booking" WHERE "id" = ${bookingId} FOR UPDATE;
        `;
      }

      // Re-read booking state within the locked transaction
      const current = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { payment: true },
      });

      if (!current) {
        throw new NotFoundException(`Booking with ID "${bookingId}" not found.`);
      }

      // If a concurrent transaction already transitioned this booking to PENDING_DISPATCH
      if (current.status === BookingStatus.PENDING_DISPATCH && current.payment) {
        return;
      }

      if (current.status !== BookingStatus.DRAFT) {
        throw new BadRequestException(
          `Cannot checkout booking with status "${current.status}". Only bookings in DRAFT status can be checked out.`,
        );
      }

      // A. Transition status to PENDING_DISPATCH
      await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: BookingStatus.PENDING_DISPATCH,
        },
      });

      // B. Create PaymentRecord with status: PENDING and amountEgp from booking total
      await tx.paymentRecord.create({
        data: {
          bookingId,
          method: dto.paymentMethod,
          status: PaymentStatus.PENDING,
          amountEgp: current.totalEgp,
          tipEgp: 0,
          externalReference: null,
          paidAt: null,
        },
      });

      // C. Create BookingStatusEvent
      await tx.bookingStatusEvent.create({
        data: {
          bookingId,
          fromStatus: BookingStatus.DRAFT,
          toStatus: BookingStatus.PENDING_DISPATCH,
          actorUserId: customerId,
          note: 'Customer confirmed Cash on Service checkout',
        },
      });
    });

    // 7. Return complete booking detail with payment and updated status
    return this.findCustomerBookingById(customerId, bookingId, isAdmin);
  }
}

