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
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { BookingsService } from './bookings.service';
import { BookingQueryDto } from './dto/booking-query.dto';
import {
  BookingDetailResponse,
  BookingListResponse,
} from './dto/booking-response.dto';
import { CreateBookingDto } from './dto/create-booking.dto';

@ApiTags('bookings')
@ApiBearerAuth()
@Controller('bookings')
@UseGuards(JwtAuthGuard, RolesGuard)
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @Roles(UserRole.CUSTOMER, UserRole.ADMIN)
  @ApiOperation({
    summary:
      'Create a customer booking in DRAFT status with calculated EGP pricing breakdown',
  })
  @ApiResponse({
    status: 201,
    description: 'Booking draft created successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Validation failed or date in the past',
  })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid Bearer token',
  })
  @ApiResponse({
    status: 403,
    description: 'Address ownership validation failed',
  })
  @ApiResponse({
    status: 404,
    description: 'Service offering, address, or preferred pro not found',
  })
  async createBooking(
    @CurrentUser() currentUser: FixoJwtPayload,
    @Body() dto: CreateBookingDto,
  ): Promise<BookingDetailResponse> {
    return this.bookingsService.createBooking(currentUser.sub, dto);
  }

  @Get()
  @Roles(UserRole.CUSTOMER, UserRole.ADMIN)
  @ApiOperation({
    summary:
      'List bookings for the authenticated customer filtered by status or tab',
  })
  @ApiResponse({
    status: 200,
    description: 'List of customer bookings',
  })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid Bearer token',
  })
  async getCustomerBookings(
    @CurrentUser() currentUser: FixoJwtPayload,
    @Query() query: BookingQueryDto,
  ): Promise<BookingListResponse> {
    return this.bookingsService.findCustomerBookings(currentUser.sub, query);
  }

  @Get(':id')
  @Roles(UserRole.CUSTOMER, UserRole.ADMIN)
  @ApiOperation({
    summary: 'Get details for a specific booking by ID',
  })
  @ApiResponse({
    status: 200,
    description: 'Booking details',
  })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid Bearer token',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden: booking belongs to another customer',
  })
  @ApiResponse({
    status: 404,
    description: 'Booking not found',
  })
  async getBookingById(
    @CurrentUser() currentUser: FixoJwtPayload,
    @Param('id') id: string,
  ): Promise<BookingDetailResponse> {
    const isAdmin = currentUser.role === UserRole.ADMIN;
    return this.bookingsService.findCustomerBookingById(
      currentUser.sub,
      id,
      isAdmin,
    );
  }
}

