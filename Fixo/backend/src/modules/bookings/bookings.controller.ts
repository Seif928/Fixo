import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { BookingsService } from './bookings.service';
import { BookingQueryDto } from './dto/booking-query.dto';
import {
  BookingDetailResponse,
  BookingListResponse,
  BookingReceiptResponse,
  BookingReviewSummary,
  BookingTrackingResponse,
} from './dto/booking-response.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { CheckoutBookingDto } from './dto/checkout-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CreateReviewDto } from './dto/create-review.dto';
import { PrivateUploadDto } from './dto/private-upload.dto';

@ApiTags('Customer Bookings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Create a new service booking in DRAFT status with EGP pricing breakdown (Screen 04)',
  })
  async createBooking(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: CreateBookingDto,
  ): Promise<BookingDetailResponse> {
    return this.bookingsService.createBooking(user.sub, dto);
  }

  @Get()
  @ApiOperation({
    summary:
      'List authenticated customer bookings with optional tab filter (Screen 08)',
  })
  async getCustomerBookings(
    @CurrentUser() user: FixoJwtPayload,
    @Query() query: BookingQueryDto,
  ): Promise<BookingListResponse> {
    return this.bookingsService.findCustomerBookings(user.sub, query);
  }

  @Get(':id')
  @ApiParam({ name: 'id', description: 'Booking UUID' })
  @ApiOperation({
    summary:
      'Get single booking detail (enforces strict customer ownership isolation)',
  })
  async getBookingById(
    @CurrentUser() user: FixoJwtPayload,
    @Param('id') bookingId: string,
  ): Promise<BookingDetailResponse> {
    const isAdmin = user.role === UserRole.ADMIN;
    return this.bookingsService.findCustomerBookingById(
      user.sub,
      bookingId,
      isAdmin,
    );
  }

  @Post(':bookingId/checkout')
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: 'bookingId', description: 'Booking UUID' })
  @ApiOperation({
    summary:
      'Confirm booking checkout with Cash on Service (Screen 05 -> PENDING_DISPATCH)',
  })
  async checkoutBooking(
    @CurrentUser() user: FixoJwtPayload,
    @Param('bookingId') bookingId: string,
    @Body() dto: CheckoutBookingDto,
  ): Promise<BookingDetailResponse> {
    const isAdmin = user.role === UserRole.ADMIN;
    return this.bookingsService.checkoutBooking(
      user.sub,
      bookingId,
      dto,
      isAdmin,
    );
  }

  @Get(':bookingId/tracking')
  @ApiParam({ name: 'bookingId', description: 'Booking UUID' })
  @ApiOperation({
    summary:
      'Get live order tracking status, milestone timeline, and assigned pro info (Screen 06)',
  })
  async getBookingTracking(
    @CurrentUser() user: FixoJwtPayload,
    @Param('bookingId') bookingId: string,
  ): Promise<BookingTrackingResponse> {
    const isAdmin = user.role === UserRole.ADMIN;
    return this.bookingsService.getBookingTracking(user.sub, bookingId, isAdmin);
  }

  @Post(':bookingId/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: 'bookingId', description: 'Booking UUID' })
  @ApiOperation({
    summary:
      'Cancel a customer booking prior to service execution (Screens 06 / 08)',
  })
  async cancelBooking(
    @CurrentUser() user: FixoJwtPayload,
    @Param('bookingId') bookingId: string,
    @Body() dto: CancelBookingDto,
  ): Promise<BookingDetailResponse> {
    const isAdmin = user.role === UserRole.ADMIN;
    return this.bookingsService.cancelBooking(
      user.sub,
      bookingId,
      dto,
      isAdmin,
    );
  }

  @Get(':bookingId/receipt')
  @ApiParam({ name: 'bookingId', description: 'Booking UUID' })
  @ApiOperation({
    summary:
      'Generate structured booking & payment receipt from actual records (Screens 08 / 09)',
  })
  async getBookingReceipt(
    @CurrentUser() user: FixoJwtPayload,
    @Param('bookingId') bookingId: string,
  ): Promise<BookingReceiptResponse> {
    const isAdmin = user.role === UserRole.ADMIN;
    return this.bookingsService.getBookingReceipt(user.sub, bookingId, isAdmin);
  }

  @Get(':bookingId/review')
  @ApiParam({ name: 'bookingId', description: 'Booking UUID' })
  @ApiOperation({
    summary: 'Get the customer review submitted for a booking (Screen 09)',
  })
  async getBookingReview(
    @CurrentUser() user: FixoJwtPayload,
    @Param('bookingId') bookingId: string,
  ): Promise<{ review: BookingReviewSummary | null }> {
    const isAdmin = user.role === UserRole.ADMIN;
    const review = await this.bookingsService.getBookingReview(
      user.sub,
      bookingId,
      isAdmin,
    );
    return { review };
  }

  @Post(':bookingId/review')
  @HttpCode(HttpStatus.CREATED)
  @ApiParam({ name: 'bookingId', description: 'Booking UUID' })
  @ApiOperation({
    summary:
      'Submit a customer rating, compliment tags, comment, and optional tip for a COMPLETED booking (Screen 09)',
  })
  async submitBookingReview(
    @CurrentUser() user: FixoJwtPayload,
    @Param('bookingId') bookingId: string,
    @Body() dto: CreateReviewDto,
  ): Promise<BookingReviewSummary> {
    return this.bookingsService.submitBookingReview(user.sub, bookingId, dto);
  }
}

@ApiTags('Private Media Uploads')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('uploads/private')
export class PrivateUploadsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Upload and validate private media (issue photos, review photos, or pro verification docs)',
  })
  async uploadPrivateMedia(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: PrivateUploadDto,
  ) {
    return this.bookingsService.createPrivateUpload(user.sub, dto);
  }

  @Get('verify')
  @ApiOperation({
    summary: 'Verify a short-lived private upload access token',
  })
  async verifyAccess(
    @CurrentUser() user: FixoJwtPayload,
    @Query('token') token: string,
  ) {
    const isAdmin = user.role === UserRole.ADMIN;
    return this.bookingsService.verifyPrivateUploadToken(
      user.sub,
      token,
      isAdmin,
    );
  }
}
