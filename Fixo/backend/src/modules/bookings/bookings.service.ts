import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import {
  BookingStatus,
  JobOfferStatus,
  PaymentMethodType,
  PaymentStatus,
  Prisma,
  ProVerificationStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { PushService } from '../communications/push.service';
import { BookingQueryDto } from './dto/booking-query.dto';
import {
  BookingDetailResponse,
  BookingListResponse,
  BookingReceiptLineItem,
  BookingReceiptResponse,
  BookingReviewSummary,
  BookingTrackingMilestone,
  BookingTrackingResponse,
} from './dto/booking-response.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { CheckoutBookingDto } from './dto/checkout-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CreateReviewDto } from './dto/create-review.dto';
import { professionalCoverageWhere } from '../services/coverage-policy';
import { ensureDispatchOffer } from '../pro/dispatch-offers';
import { PrivateUploadDto } from './dto/private-upload.dto';
import {
  signPrivateUploadAccessToken,
  validatePrivateUploadPayload,
  verifyPrivateUploadAccessToken,
} from './private-upload.util';

const ACTIVE_BOOKING_STATUSES: BookingStatus[] = [
  BookingStatus.DRAFT,
  BookingStatus.PENDING_DISPATCH,
  BookingStatus.OFFERED_TO_PRO,
  BookingStatus.CONFIRMED,
  BookingStatus.PRO_EN_ROUTE,
  BookingStatus.ARRIVED,
  BookingStatus.IN_PROGRESS,
];

const CANCELLABLE_BOOKING_STATUSES: BookingStatus[] = [
  BookingStatus.DRAFT,
  BookingStatus.PENDING_DISPATCH,
  BookingStatus.OFFERED_TO_PRO,
  BookingStatus.CONFIRMED,
];

export const INTERNAL_FAILED_PIN_EVENT_NOTE = 'ARRIVAL_PIN_FAILED_ATTEMPT';

@Injectable()
export class BookingsService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly pushService?: PushService,
  ) {}

  private readonly bookingInclude = {
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
        user: {
          select: {
            id: true,
            fullName: true,
            avatarUrl: true,
          },
        },
      },
    },
    customer: {
      select: {
        id: true,
        fullName: true,
      },
    },
    payment: true,
    review: true,
    statusEvents: {
      orderBy: { createdAt: 'asc' as const },
    },
  };

  /**
   * Creates a new customer booking in initial `DRAFT` status.
   * Performs ownership checks on address, validates service offering and optional pro,
   * calculates deterministic EGP pricing (10% platform fee, 90% net artisan),
   * and atomically persists the booking + initial BookingStatusEvent.
   */
  async createBooking(
    customerId: string,
    dto: CreateBookingDto,
  ): Promise<BookingDetailResponse> {
    // 1. Validate scheduledDate format and ensure it is not in the past
    const parsedDate = new Date(dto.scheduledDate);
    if (Number.isNaN(parsedDate.getTime())) {
      throw new BadRequestException('Invalid scheduledDate format.');
    }

    const todayStart = new Date();
    todayStart.setUTCHours(0, 0, 0, 0);
    if (parsedDate < todayStart) {
      throw new BadRequestException('Scheduled date cannot be in the past.');
    }

    // 2. Verify CustomerAddress exists and belongs to the authenticated customer
    const address = await this.prisma.customerAddress.findUnique({
      where: { id: dto.addressId },
      include: { zone: true },
    });

    if (!address) {
      throw new NotFoundException(
        `Customer address with ID "${dto.addressId}" was not found.`,
      );
    }

    if (address.userId !== customerId) {
      throw new ForbiddenException('You do not own this address.');
    }

    // 3. Verify ServiceOffering exists and its category is active
    const offering = await this.prisma.serviceOffering.findUnique({
      where: { id: dto.offeringId },
      include: { category: true },
    });

    if (!offering) {
      throw new NotFoundException(
        `Service offering with ID "${dto.offeringId}" was not found.`,
      );
    }

    if (offering.isActive === false) {
      throw new BadRequestException(
        'Selected service offering is not currently active.',
      );
    }

    if (!offering.category.isActive) {
      throw new BadRequestException(
        'Selected service offering category is not currently active.',
      );
    }

    // 4. Optional: Validate preferredProId if provided
    if (dto.preferredProId) {
      const pro = await this.prisma.proProfile.findUnique({
        where: { id: dto.preferredProId },
      });

      if (!pro) {
        throw new NotFoundException(
          `Preferred professional with ID "${dto.preferredProId}" was not found.`,
        );
      }

      if (pro.verificationStatus !== ProVerificationStatus.APPROVED) {
        throw new BadRequestException(
          'Preferred professional is not verified and available for bookings.',
        );
      }
    }

    // 5. Calculate deterministic EGP pricing breakdown
    const baseInspectionEgp = offering.baseInspectionEgp;
    const serviceFeeEgp = offering.serviceFeeEgp;
    const transportFeeEgp = 0;
    const totalEgp =
      offering.flatPriceEgp ??
      baseInspectionEgp + serviceFeeEgp + transportFeeEgp;
    const platformFeeEgp = Math.round(totalEgp * 0.1);
    const netArtisanEgp = totalEgp - platformFeeEgp;

    // 6. Generate unique orderCode (FX-XXXX) and 4-digit arrivalPinCode
    const orderCode = await this.generateUniqueOrderCode();
    const arrivalPinCode = this.generateArrivalPinCode();

    // 7. Persist Booking in DRAFT status + initial BookingStatusEvent atomically
    const createdBooking = await this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.create({
        data: {
          orderCode,
          customerId,
          proProfileId: dto.preferredProId ?? null,
          offeringId: offering.id,
          addressId: address.id,
          status: BookingStatus.DRAFT,
          scheduledDate: parsedDate,
          timeWindow: dto.timeWindow,
          issueDescription: dto.issueDescription?.trim() || null,
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
        include: this.bookingInclude,
      });

      return booking;
    });

    return this.mapBookingDetail(createdBooking, customerId);
  }

  /**
   * Lists bookings belonging to the authenticated customer, with optional
   * Screen 08 tab filtering (`active`, `completed`, `cancelled`) or exact status.
   */
  async findCustomerBookings(
    customerId: string,
    query: BookingQueryDto,
  ): Promise<BookingListResponse> {
    const limit = query.limit ?? 20;
    const offset = query.offset ?? 0;

    const where: Prisma.BookingWhereInput = {
      customerId,
    };

    if (query.status) {
      where.status = query.status;
    } else if (query.tab === 'active') {
      where.status = { in: ACTIVE_BOOKING_STATUSES };
    } else if (query.tab === 'completed') {
      where.status = BookingStatus.COMPLETED;
    } else if (query.tab === 'cancelled') {
      where.status = BookingStatus.CANCELLED;
    }

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: this.bookingInclude,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return {
      bookings: bookings.map((b) =>
        this.mapBookingDetail(b, customerId),
      ),
      total,
      limit,
      offset,
    };
  }

  /**
   * Retrieves a single booking by ID.
   * Allows only the customer or the assigned professional. Administration has
   * separate membership-guarded endpoints and never receives the arrival PIN.
   */
  async findCustomerBookingById(
    userId: string,
    bookingId: string,
  ): Promise<BookingDetailResponse> {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: this.bookingInclude,
    });

    if (!booking) {
      throw new NotFoundException(
        `Booking with ID "${bookingId}" was not found.`,
      );
    }

    const isAssignedPro = booking.proProfile?.user?.id === userId;
    if (booking.customerId !== userId && !isAssignedPro) {
      throw new ForbiddenException('You do not have access to this booking.');
    }

    return this.mapBookingDetail(booking, userId);
  }

  /**
   * Phase 4A: Confirms booking checkout using Cash on Service (`CASH_ON_SERVICE`).
   *
   * Rules enforced:
   * 1. Rejects unsupported digital methods (`INSTAPAY_SANDBOX`, `VODAFONE_CASH_SANDBOX`, `CARD_SANDBOX`) with 400.
   * 2. Verifies booking exists (404) and caller is the owning customer (403).
   * 3. Uses row-level lock (`SELECT ... FOR UPDATE`) inside a single Prisma transaction to guarantee
   *    race-safe idempotency:
   *    - If already `PENDING_DISPATCH` with a `CASH_ON_SERVICE` `PaymentRecord`, returns existing state without duplicating rows or status events.
   *    - If in `DRAFT` status, atomically updates `Booking.status` to `PENDING_DISPATCH`, creates `PaymentRecord` (`status: PENDING, paidAt: null`), and appends `BookingStatusEvent` (`DRAFT -> PENDING_DISPATCH`).
   *    - Otherwise rejects invalid lifecycle state with 400.
   */
  async checkoutBooking(
    userId: string,
    bookingId: string,
    dto: CheckoutBookingDto,
  ): Promise<BookingDetailResponse> {
    // 1. Strictly enforce Cash on Service only in Phase 4A
    if (dto.paymentMethod !== PaymentMethodType.CASH_ON_SERVICE) {
      throw new BadRequestException(
        `Payment method "${dto.paymentMethod}" is not supported yet. Only CASH_ON_SERVICE is currently enabled.`,
      );
    }

    // 2. Verify booking exists and belongs to the customer.
    const initialBooking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: this.bookingInclude,
    });

    if (!initialBooking) {
      throw new NotFoundException(
        `Booking with ID "${bookingId}" was not found.`,
      );
    }

    if (initialBooking.customerId !== userId) {
      throw new ForbiddenException('You do not have access to this booking.');
    }

    // Fast-path idempotent check if already checked out with CASH_ON_SERVICE
    if (
      initialBooking.status === BookingStatus.PENDING_DISPATCH &&
      initialBooking.payment &&
      initialBooking.payment.method === PaymentMethodType.CASH_ON_SERVICE
    ) {
      return this.mapBookingDetail(initialBooking, userId);
    }

    if (initialBooking.status !== BookingStatus.DRAFT) {
      throw new BadRequestException(
        `Booking cannot be checked out from current status "${initialBooking.status}". Only bookings in DRAFT status can be checked out.`,
      );
    }

    // 3. Execute atomic transaction with row lock for concurrent retry safety
    await this.prisma.$transaction(async (tx) => {
      // Acquire row-level lock on Booking in PostgreSQL when connected
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`
          SELECT id, status::text
          FROM "Booking"
          WHERE id = ${bookingId}
          FOR UPDATE;
        `;
      }

      const lockedBooking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { payment: true },
      });

      if (!lockedBooking) {
        throw new NotFoundException(
          `Booking with ID "${bookingId}" was not found.`,
        );
      }

      // Re-check idempotency after acquiring lock (handles concurrent double-taps)
      if (
        lockedBooking.status === BookingStatus.PENDING_DISPATCH &&
        lockedBooking.payment &&
        lockedBooking.payment.method === PaymentMethodType.CASH_ON_SERVICE
      ) {
        return;
      }

      if (lockedBooking.status !== BookingStatus.DRAFT) {
        throw new BadRequestException(
          `Booking cannot be checked out from current status "${lockedBooking.status}". Only bookings in DRAFT status can be checked out.`,
        );
      }

      // Clear any preferred pro assignment at checkout so dispatch starts unassigned
      await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: BookingStatus.PENDING_DISPATCH,
          ...(lockedBooking.proProfileId ? { proProfileId: null } : {}),
        },
      });

      // Create PENDING Cash on Service payment record (paidAt MUST be null)
      await tx.paymentRecord.create({
        data: {
          bookingId: lockedBooking.id,
          method: PaymentMethodType.CASH_ON_SERVICE,
          status: PaymentStatus.PENDING,
          amountEgp: lockedBooking.totalEgp,
          tipEgp: 0,
          externalReference: null,
          paidAt: null,
        },
      });

      // Record audit trail status transition DRAFT -> PENDING_DISPATCH
      await tx.bookingStatusEvent.create({
        data: {
          bookingId: lockedBooking.id,
          fromStatus: BookingStatus.DRAFT,
          toStatus: BookingStatus.PENDING_DISPATCH,
          actorUserId: userId,
          note: 'Customer confirmed Cash on Service checkout',
        },
      });
    });

    // Best-effort dispatch of job offers to eligible online pros without altering PENDING_DISPATCH
    await this.createInitialOffersForCheckedOutBooking(
      bookingId,
      initialBooking.proProfileId,
    );

    return this.findCustomerBookingById(userId, bookingId);
  }

  /**
   * Screen 06: Live Order Tracking & Status Timeline (`GET /bookings/:bookingId/tracking`).
   * Returns actual booking state, assigned professional (if any), saved address coordinates,
   * and chronological 5-step milestone progression derived strictly from database records.
   */
  async getBookingTracking(
    userId: string,
    bookingId: string,
  ): Promise<BookingTrackingResponse> {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: this.bookingInclude,
    });

    if (!booking) {
      throw new NotFoundException(
        `Booking with ID "${bookingId}" was not found.`,
      );
    }

    const isAssignedPro = booking.proProfile?.user?.id === userId;
    if (booking.customerId !== userId && !isAssignedPro) {
      throw new ForbiddenException('You do not have access to this booking.');
    }

    const mappedBooking = this.mapBookingDetail(booking, userId);
    const milestones = this.buildTrackingMilestones(mappedBooking);

    const canCancel =
      booking.customerId === userId &&
      CANCELLABLE_BOOKING_STATUSES.includes(booking.status);
    const canChat = Boolean(booking.proProfileId);
    const canReview =
      booking.customerId === userId &&
      booking.status === BookingStatus.COMPLETED &&
      Boolean(booking.proProfileId) &&
      !booking.review;

    return {
      booking: mappedBooking,
      milestones,
      canCancel,
      canChat,
      canReview,
      trackingAccuracyNoteEn:
        'Map displays your saved service address. Status milestones update as your assigned professional confirms each step.',
      trackingAccuracyNoteAr:
        'تعرض الخريطة عنوان الخدمة المحفوظ. تتحدث مراحل الطلب فور تأكيد الفني المختص لكل خطوة.',
    };
  }

  /**
   * Cancels a customer booking before service execution starts (`POST /bookings/:bookingId/cancel`).
   */
  async cancelBooking(
    userId: string,
    bookingId: string,
    dto: CancelBookingDto,
  ): Promise<BookingDetailResponse> {
    const existing = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: this.bookingInclude,
    });

    if (!existing) {
      throw new NotFoundException(
        `Booking with ID "${bookingId}" was not found.`,
      );
    }

    if (existing.customerId !== userId) {
      throw new ForbiddenException(
        'You do not have access to cancel this booking.',
      );
    }

    if (existing.status === BookingStatus.CANCELLED) {
      return this.mapBookingDetail(existing, userId);
    }

    if (!CANCELLABLE_BOOKING_STATUSES.includes(existing.status)) {
      throw new BadRequestException(
        `Booking cannot be cancelled once it is in "${existing.status}" status.`,
      );
    }

    const reason =
      dto.reason?.trim() || 'Cancelled by customer prior to service start';

    await this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`
          SELECT id, status::text
          FROM "Booking"
          WHERE id = ${bookingId}
          FOR UPDATE;
        `;
      }

      const locked = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { payment: true },
      });

      if (!locked) {
        throw new NotFoundException(
          `Booking with ID "${bookingId}" was not found.`,
        );
      }

      if (locked.status === BookingStatus.CANCELLED) {
        return;
      }

      if (!CANCELLABLE_BOOKING_STATUSES.includes(locked.status)) {
        throw new BadRequestException(
          `Booking cannot be cancelled once it is in "${locked.status}" status.`,
        );
      }

      await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: BookingStatus.CANCELLED,
          cancellationReason: reason,
        },
      });

      if (tx.jobOffer) {
        await tx.jobOffer.updateMany({
          where: {
            bookingId,
            status: JobOfferStatus.PENDING,
          },
          data: {
            status: JobOfferStatus.EXPIRED,
            respondedAt: new Date(),
          },
        });
      }

      if (locked.payment && locked.payment.status === PaymentStatus.PENDING) {
        await tx.paymentRecord.update({
          where: { id: locked.payment.id },
          data: {
            status: PaymentStatus.FAILED,
          },
        });
      }

      await tx.bookingStatusEvent.create({
        data: {
          bookingId,
          fromStatus: locked.status,
          toStatus: BookingStatus.CANCELLED,
          actorUserId: userId,
          note: reason,
        },
      });
    });

    if (existing.proProfile?.user?.id && this.pushService) {
      await this.pushService.notify(existing.proProfile.user.id, bookingId);
    }

    return this.findCustomerBookingById(userId, bookingId);
  }

  /**
   * Generates a structured receipt from actual Booking, PaymentRecord, and Review records.
   */
  async getBookingReceipt(
    userId: string,
    bookingId: string,
  ): Promise<BookingReceiptResponse> {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: this.bookingInclude,
    });

    if (!booking) {
      throw new NotFoundException(
        `Booking with ID "${bookingId}" was not found.`,
      );
    }

    const isAssignedPro = booking.proProfile?.user?.id === userId;
    if (booking.customerId !== userId && !isAssignedPro) {
      throw new ForbiddenException(
        'You do not have access to this booking receipt.',
      );
    }

    const tipEgp = booking.payment?.tipEgp ?? booking.review?.tipAmountEgp ?? 0;

    const lineItems: BookingReceiptLineItem[] = [
      {
        key: 'BASE_INSPECTION',
        labelEn: 'Base Inspection & Assessment',
        labelAr: 'فحص ومعاينة أساسية',
        amountEgp: booking.baseInspectionEgp,
      },
      {
        key: 'SERVICE_FEE',
        labelEn: booking.offering.titleEn,
        labelAr: booking.offering.titleAr,
        amountEgp:
          booking.totalEgp -
          booking.baseInspectionEgp -
          booking.transportFeeEgp,
      },
    ];

    if (booking.transportFeeEgp > 0) {
      lineItems.push({
        key: 'TRANSPORT_FEE',
        labelEn: 'Transport & Dispatch Fee',
        labelAr: 'رسوم الانتقال',
        amountEgp: booking.transportFeeEgp,
      });
    }

    if (tipEgp > 0) {
      lineItems.push({
        key: 'ARTISAN_TIP',
        labelEn: 'Artisan Appreciation Tip (100% to Pro)',
        labelAr: 'إكرامية الفني (١٠٠٪ للفني)',
        amountEgp: tipEgp,
      });
    }

    const issuedAtDate =
      booking.completedAt ?? booking.payment?.paidAt ?? booking.updatedAt;

    return {
      receiptNumber: `RCP-${booking.orderCode}`,
      bookingId: booking.id,
      orderCode: booking.orderCode,
      status: booking.status,
      issuedAt:
        issuedAtDate instanceof Date
          ? issuedAtDate.toISOString()
          : String(issuedAtDate),
      scheduledDate:
        booking.scheduledDate instanceof Date
          ? booking.scheduledDate.toISOString()
          : String(booking.scheduledDate),
      timeWindow: booking.timeWindow,
      completedAt: booking.completedAt
        ? booking.completedAt instanceof Date
          ? booking.completedAt.toISOString()
          : String(booking.completedAt)
        : null,
      customerName: booking.customer?.fullName || 'FIXO Customer',
      serviceTitleEn: booking.offering.titleEn,
      serviceTitleAr: booking.offering.titleAr,
      categoryNameEn: booking.offering.category.nameEn,
      categoryNameAr: booking.offering.category.nameAr,
      proName: booking.proProfile?.user?.fullName ?? null,
      proDossierCode: booking.proProfile?.dossierCode ?? null,
      addressSummary: `${booking.address.label} — ${booking.address.buildingLine}, ${booking.address.districtLine}`,
      lineItems,
      subtotalEgp: booking.totalEgp,
      tipEgp,
      grandTotalEgp: booking.totalEgp + tipEgp,
      platformFeeEgp: booking.platformFeeEgp,
      netArtisanEgp: booking.netArtisanEgp + tipEgp,
      currency: 'EGP',
      paymentMethod:
        booking.payment?.method ?? PaymentMethodType.CASH_ON_SERVICE,
      paymentStatus: booking.payment?.status ?? PaymentStatus.PENDING,
      paidAt: booking.payment?.paidAt
        ? booking.payment.paidAt instanceof Date
          ? booking.payment.paidAt.toISOString()
          : String(booking.payment.paidAt)
        : null,
    };
  }

  /**
   * Retrieves the review submitted for a booking (if any).
   */
  async getBookingReview(
    userId: string,
    bookingId: string,
  ): Promise<BookingReviewSummary | null> {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        review: true,
        proProfile: { select: { userId: true } },
      },
    });

    if (!booking) {
      throw new NotFoundException(
        `Booking with ID "${bookingId}" was not found.`,
      );
    }

    const isAssignedPro = booking.proProfile?.userId === userId;
    if (booking.customerId !== userId && !isAssignedPro) {
      throw new ForbiddenException(
        'You do not have access to this booking review.',
      );
    }

    if (!booking.review) {
      return null;
    }

    return this.mapReviewSummary(booking.review);
  }

  /**
   * Screen 09: Rate & Review (`POST /bookings/:bookingId/review`).
   *
   * Rules enforced:
   * - Only the owning customer of the booking can submit a review.
   * - Booking MUST be in `COMPLETED` status and have an assigned professional.
   * - Duplicate reviews for the same booking are rejected with `ConflictException` (HTTP 409).
   * - Atomically creates the `Review`, updates `PaymentRecord.tipEgp` if a tip is included,
   *   and recalculates `ProProfile.ratingAvg` & `ProProfile.reviewsCount` from actual review rows.
   */
  async submitBookingReview(
    customerId: string,
    bookingId: string,
    dto: CreateReviewDto,
  ): Promise<BookingReviewSummary> {
    const initialBooking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { review: true, payment: true },
    });

    if (!initialBooking) {
      throw new NotFoundException(
        `Booking with ID "${bookingId}" was not found.`,
      );
    }

    if (initialBooking.customerId !== customerId) {
      throw new ForbiddenException(
        'Only the customer who placed this booking can submit a review.',
      );
    }

    if (initialBooking.status !== BookingStatus.COMPLETED) {
      throw new BadRequestException(
        `Reviews can only be submitted for COMPLETED bookings (current status: "${initialBooking.status}").`,
      );
    }

    if (!initialBooking.proProfileId) {
      throw new BadRequestException(
        'Cannot submit a review for a booking without an assigned professional.',
      );
    }

    if (initialBooking.review) {
      throw new ConflictException(
        'A review has already been submitted for this booking.',
      );
    }

    const tipAmountEgp = dto.tipAmountEgp ?? 0;

    const createdReview = await this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`
          SELECT id, status::text
          FROM "Booking"
          WHERE id = ${bookingId}
          FOR UPDATE;
        `;
      }

      const lockedBooking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { payment: true },
      });
      if (!lockedBooking || lockedBooking.customerId !== customerId) {
        throw new ForbiddenException(
          'Only the booking customer can submit this review.',
        );
      }
      if (
        lockedBooking.status !== BookingStatus.COMPLETED ||
        !lockedBooking.proProfileId
      ) {
        throw new BadRequestException(
          'A completed booking with an assigned professional is required.',
        );
      }
      const proProfileId = lockedBooking.proProfileId;
      if (this.prisma.isDatabaseConnected()) {
        // Different bookings share this aggregate: serialize before insert/read, not only the final update.
        await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE id = ${proProfileId} FOR UPDATE`;
      }
      const existingReview = await tx.review.findUnique({
        where: { bookingId },
      });

      if (existingReview) {
        throw new ConflictException(
          'A review has already been submitted for this booking.',
        );
      }

      const review = await tx.review.create({
        data: {
          bookingId,
          customerId,
          proProfileId,
          rating: dto.rating,
          tags: dto.tags ?? [],
          comment: dto.comment?.trim() || null,
          photoUrls: dto.photoUrls ?? [],
          tipAmountEgp,
        },
      });

      if (
        tipAmountEgp > 0 &&
        lockedBooking.payment &&
        tx.paymentRecord?.update
      ) {
        await tx.paymentRecord.update({
          where: { id: lockedBooking.payment.id },
          data: { tipEgp: tipAmountEgp },
        });
      }

      // Recalculate ProProfile ratingAvg and reviewsCount from actual Review records
      if (tx.review?.aggregate && tx.proProfile?.update) {
        const stats = await tx.review.aggregate({
          where: { proProfileId },
          _avg: { rating: true },
          _count: { id: true },
        });

        const reviewsCount = stats._count.id || 1;
        const rawAvg = stats._avg.rating ?? dto.rating;
        const ratingAvg = Math.round(rawAvg * 100) / 100;

        await tx.proProfile.update({
          where: { id: proProfileId },
          data: {
            ratingAvg,
            reviewsCount,
          },
        });
      }

      if (tx.user?.update) {
        await tx.user.update({
          where: { id: customerId },
          data: {
            rewardPoints: { increment: 25 },
          },
        });
      }

      return review;
    });

    return this.mapReviewSummary(createdReview);
  }

  /**
   * Validates and signs a private photo/document upload so it can be attached
   * to a booking diagnostic, completed work review, or pro verification dossier
   * without exposing public storage buckets.
   */
  async createPrivateUpload(userId: string, dto: PrivateUploadDto) {
    if (dto.bookingId) {
      const booking = await this.prisma.booking.findUnique({
        where: { id: dto.bookingId },
        include: { proProfile: { select: { userId: true } } },
      });
      if (!booking) {
        throw new NotFoundException(
          `Booking with ID "${dto.bookingId}" was not found.`,
        );
      }
      const isParticipant =
        booking.customerId === userId || booking.proProfile?.userId === userId;
      if (!isParticipant) {
        throw new ForbiddenException(
          'You are not authorized to upload media for this booking.',
        );
      }
    }

    const validated = validatePrivateUploadPayload({
      purpose: dto.purpose,
      fileName: dto.fileName,
      mimeType: dto.mimeType,
      contentBase64: dto.contentBase64,
    });

    const signed = signPrivateUploadAccessToken({
      ownerUserId: userId,
      purpose: dto.purpose,
      sha256: validated.sha256,
      mimeType: validated.mimeType,
      fileName: validated.fileName,
    });

    const dataUri = `data:${validated.mimeType};base64,${validated.normalizedBase64}`;

    return {
      uploadId: `prv_${validated.sha256.slice(0, 16)}`,
      purpose: dto.purpose,
      fileName: validated.fileName,
      mimeType: validated.mimeType,
      fileSizeBytes: validated.fileSizeBytes,
      sha256: validated.sha256,
      accessToken: signed.token,
      expiresAt: signed.expiresAt,
      privateDataUri: dataUri,
    };
  }

  verifyPrivateUploadToken(userId: string, token: string) {
    const claims = verifyPrivateUploadAccessToken(token);
    if (claims.ownerUserId !== userId) {
      throw new ForbiddenException(
        'You do not have permission to access this private upload.',
      );
    }
    return claims;
  }

  private async createInitialOffersForCheckedOutBooking(
    bookingId: string,
    preferredProId?: string | null,
  ): Promise<void> {
    if (!this.prisma.isDatabaseConnected()) {
      return;
    }

    try {
      const booking = await this.prisma.booking.findUnique({
        where: { id: bookingId },
        include: {
          offering: true,
          address: { include: { zone: true } },
        },
      });

      if (!booking || booking.status !== BookingStatus.PENDING_DISPATCH) {
        return;
      }

      const eligibility = {
        verificationStatus: ProVerificationStatus.APPROVED,
        isOnline: true,
        userId: { not: booking.customerId },
        primaryCategoryId: booking.offering.categoryId,
        ...professionalCoverageWhere(booking.address.zone),
      };
      // Preference affects order only; it never bypasses category, coverage or approval.
      const preferred = preferredProId
        ? await this.prisma.proProfile.findFirst({
            where: { ...eligibility, id: preferredProId },
          })
        : null;
      const eligiblePros = await this.prisma.proProfile.findMany({
        where: {
          ...eligibility,
          ...(preferred ? { id: { not: preferred.id } } : {}),
        },
        orderBy: { id: 'asc' },
        take: preferred ? 4 : 5,
      });
      if (preferred) eligiblePros.unshift(preferred);

      if (!eligiblePros.length) {
        return;
      }

      for (const pro of eligiblePros) {
        const result = await ensureDispatchOffer(
          this.prisma,
          booking.id,
          pro.id,
        );
        if (result?.created && this.pushService) {
          await this.pushService.notify(result.userId, booking.id);
        }
      }
    } catch {
      // Non-blocking: Pro dashboard also synchronizes pending offers on poll
    }
  }

  private buildTrackingMilestones(
    booking: BookingDetailResponse,
  ): BookingTrackingMilestone[] {
    const events = booking.statusEvents ?? [];
    const findTimestamp = (...statuses: BookingStatus[]): string | null => {
      for (let i = events.length - 1; i >= 0; i--) {
        if (statuses.includes(events[i].toStatus)) {
          return events[i].createdAt;
        }
      }
      return null;
    };

    const statusOrder: Record<BookingStatus, number> = {
      [BookingStatus.DRAFT]: 0,
      [BookingStatus.PENDING_DISPATCH]: 0,
      [BookingStatus.OFFERED_TO_PRO]: 0,
      [BookingStatus.CONFIRMED]: 1,
      [BookingStatus.PRO_EN_ROUTE]: 2,
      [BookingStatus.ARRIVED]: 3,
      [BookingStatus.IN_PROGRESS]: 4,
      [BookingStatus.COMPLETED]: 5,
      [BookingStatus.CANCELLED]: -1,
    };

    const currentRank = statusOrder[booking.status];
    const isCancelled = booking.status === BookingStatus.CANCELLED;

    const resolveState = (
      stepIndex: number,
    ): 'COMPLETED' | 'CURRENT' | 'UPCOMING' | 'CANCELLED' => {
      if (isCancelled) {
        return stepIndex === 0 ? 'CANCELLED' : 'UPCOMING';
      }
      if (booking.status === BookingStatus.COMPLETED) {
        return 'COMPLETED';
      }
      if (stepIndex < currentRank) {
        return 'COMPLETED';
      }
      if (stepIndex === currentRank) {
        return 'CURRENT';
      }
      return 'UPCOMING';
    };

    const proNameEn = booking.proProfile?.user?.fullName || 'Verified FIXO Pro';
    const proNameAr = booking.proProfile?.user?.fullName || 'فني فيكسو المعتمد';

    return [
      {
        key: 'ORDER_PLACED',
        titleEn: 'Order Confirmed',
        titleAr: 'تم تأكيد الطلب',
        subtitleEn:
          booking.status === BookingStatus.DRAFT
            ? 'Draft created — awaiting checkout confirmation'
            : 'Service request registered for dispatch',
        subtitleAr:
          booking.status === BookingStatus.DRAFT
            ? 'تم إنشاء المسودة — بانتظار تأكيد الدفع'
            : 'تم تسجيل طلب الخدمة وجارٍ التوجيه للفنيين',
        state:
          booking.status === BookingStatus.CONFIRMED ||
          currentRank > 0 ||
          booking.status === BookingStatus.COMPLETED
            ? 'COMPLETED'
            : isCancelled
              ? 'CANCELLED'
              : 'CURRENT',
        timestamp:
          findTimestamp(
            BookingStatus.PENDING_DISPATCH,
            BookingStatus.OFFERED_TO_PRO,
            BookingStatus.DRAFT,
          ) ?? booking.createdAt,
      },
      {
        key: 'PRO_ASSIGNED',
        titleEn: booking.proProfile
          ? `Pro Assigned (${proNameEn})`
          : 'Awaiting Pro Assignment',
        titleAr: booking.proProfile
          ? `تم تعيين الفني (${proNameAr})`
          : 'بانتظار قبول أحد الفنيين',
        subtitleEn: booking.proProfile
          ? `Dossier ${booking.proProfile.dossierCode} confirmed your booking`
          : 'Matching with available verified professionals in your zone',
        subtitleAr: booking.proProfile
          ? `الفني (${booking.proProfile.dossierCode}) قام بتأكيد استلام طلبك`
          : 'جارٍ مطابقة الطلب مع الفنيين المعتمدين المتاحين في منطقتك',
        state: resolveState(1),
        timestamp: findTimestamp(BookingStatus.CONFIRMED),
      },
      {
        key: 'PRO_EN_ROUTE',
        titleEn: 'Pro En Route',
        titleAr: 'الفني في الطريق إليك',
        subtitleEn:
          currentRank >= 2
            ? 'Professional has departed toward your saved address'
            : 'Starts once the professional departs for your location',
        subtitleAr:
          currentRank >= 2
            ? 'انطلق الفني باتجاه عنوانك المحفوظ'
            : 'تبدأ عند تحرك الفني نحو موقعك',
        state: resolveState(2),
        timestamp: findTimestamp(BookingStatus.PRO_EN_ROUTE),
      },
      {
        key: 'ARRIVED_AT_LOCATION',
        titleEn: 'Arrived at Location',
        titleAr: 'وصل الفني إلى الموقع',
        subtitleEn:
          currentRank >= 3
            ? 'Professional arrived — share your 4-digit Arrival Code to start'
            : 'Share your 4-digit Arrival Code when the professional arrives',
        subtitleAr:
          currentRank >= 3
            ? 'وصل الفني — شارك كود الوصول المكون من ٤ أرقام لبدء العمل'
            : 'شارك كود الوصول المكون من ٤ أرقام عند وصول الفني',
        state: resolveState(3),
        timestamp: findTimestamp(BookingStatus.ARRIVED),
      },
      {
        key: 'IN_PROGRESS_AND_COMPLETION',
        titleEn:
          booking.status === BookingStatus.COMPLETED
            ? 'Service Completed'
            : 'In Progress & Completion',
        titleAr:
          booking.status === BookingStatus.COMPLETED
            ? 'اكتملت الخدمة بنجاح'
            : 'تنفيذ الخدمة والإتمام',
        subtitleEn:
          booking.status === BookingStatus.COMPLETED
            ? 'Service finished — you can now rate your experience and view receipt'
            : currentRank === 4
              ? 'Arrival PIN verified — service work is currently in progress'
              : 'Final inspection and cash settlement upon completion',
        subtitleAr:
          booking.status === BookingStatus.COMPLETED
            ? 'تم إنهاء الخدمة — يمكنك الآن تقييم التجربة وعرض الإيصال'
            : currentRank === 4
              ? 'تم التحقق من كود الوصول — يجري تنفيذ الخدمة حالياً'
              : 'المعاينة النهائية وتحصيل المبلغ نقداً بعد إتمام الخدمة',
        state: resolveState(4),
        timestamp:
          findTimestamp(BookingStatus.COMPLETED, BookingStatus.IN_PROGRESS) ??
          booking.completedAt ??
          null,
      },
    ];
  }

  private async generateUniqueOrderCode(): Promise<string> {
    for (let attempt = 0; attempt < 5; attempt++) {
      const randomNum = Math.floor(1000 + Math.random() * 9000);
      const code = `FX-${randomNum}`;
      const existing = await this.prisma.booking.findUnique({
        where: { orderCode: code },
        select: { id: true },
      });
      if (!existing) {
        return code;
      }
    }
    const fallbackSuffix = Date.now().toString().slice(-4);
    return `FX-${fallbackSuffix}`;
  }

  private generateArrivalPinCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  private mapReviewSummary(review: any): BookingReviewSummary {
    return {
      id: review.id,
      bookingId: review.bookingId,
      customerId: review.customerId,
      proProfileId: review.proProfileId,
      rating: review.rating,
      tags: review.tags ?? [],
      comment: review.comment ?? null,
      photoUrls: review.photoUrls ?? [],
      tipAmountEgp: review.tipAmountEgp ?? 0,
      createdAt:
        review.createdAt instanceof Date
          ? review.createdAt.toISOString()
          : String(review.createdAt),
    };
  }

  private mapBookingDetail(
    booking: any,
    viewerUserId?: string,
  ): BookingDetailResponse {
    const canSeeArrivalPin =
      !viewerUserId || booking.customerId === viewerUserId;

    const visibleEvents = Array.isArray(booking.statusEvents)
      ? booking.statusEvents.filter(
          (evt: any) => evt.note !== INTERNAL_FAILED_PIN_EVENT_NOTE,
        )
      : undefined;

    return {
      id: booking.id,
      orderCode: booking.orderCode,
      customerId: booking.customerId,
      proProfileId: booking.proProfileId ?? null,
      offeringId: booking.offeringId,
      addressId: booking.addressId,
      status: booking.status,
      cancellationReason: booking.cancellationReason ?? null,
      scheduledDate:
        booking.scheduledDate instanceof Date
          ? booking.scheduledDate.toISOString()
          : String(booking.scheduledDate),
      timeWindow: booking.timeWindow,
      issueDescription: booking.issueDescription ?? null,
      issuePhotoUrls: booking.issuePhotoUrls ?? [],
      pricing: {
        baseInspectionEgp: booking.baseInspectionEgp,
        serviceFeeEgp: booking.serviceFeeEgp,
        transportFeeEgp: booking.transportFeeEgp,
        totalEgp: booking.totalEgp,
        platformFeeEgp: booking.platformFeeEgp,
        netArtisanEgp: booking.netArtisanEgp,
        currency: 'EGP',
      },
      arrivalPinCode: canSeeArrivalPin ? booking.arrivalPinCode : '****',
      offering: {
        id: booking.offering.id,
        slug: booking.offering.slug,
        titleEn: booking.offering.titleEn,
        titleAr: booking.offering.titleAr,
        descriptionEn: booking.offering.descriptionEn,
        descriptionAr: booking.offering.descriptionAr,
        estimatedDurationMins: booking.offering.estimatedDurationMins,
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
        latitude: booking.address.latitude ?? null,
        longitude: booking.address.longitude ?? null,
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
            reviewsCount: booking.proProfile.reviewsCount,
            completedJobsCount: booking.proProfile.completedJobsCount,
            transportMode: booking.proProfile.transportMode,
            vehicleDescription: booking.proProfile.vehicleDescription ?? null,
            vehiclePlateAr: booking.proProfile.vehiclePlateAr ?? null,
            isOnline: booking.proProfile.isOnline,
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
            tipEgp: booking.payment.tipEgp,
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
      review: booking.review ? this.mapReviewSummary(booking.review) : null,
      statusEvents: visibleEvents
        ? visibleEvents.map((evt: any) => ({
            id: evt.id,
            fromStatus: evt.fromStatus ?? null,
            toStatus: evt.toStatus,
            note: evt.note ?? null,
            createdAt:
              evt.createdAt instanceof Date
                ? evt.createdAt.toISOString()
                : String(evt.createdAt),
          }))
        : undefined,
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
}
