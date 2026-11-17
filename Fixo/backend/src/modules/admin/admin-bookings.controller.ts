import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { BookingStatus } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminAccessGuard, AdminRequest } from './admin-access.guard';
import { AdminBookingsService } from './admin-bookings.service';
export class AdminBookingQueryDto {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(10000) page = 1;
  @IsOptional() @IsEnum(BookingStatus) status?: BookingStatus;
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(100)
  search?: string;
}
class VersionDto {
  @IsString() @Matches(/^[a-f0-9]{64}$/) version!: string;
}
export class AdminCancelBookingDto extends VersionDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
export class AdminOfferBookingDto extends VersionDto {
  @IsString() @MinLength(1) @MaxLength(100) proProfileId!: string;
}
@Controller('admin/bookings')
@UseGuards(JwtAuthGuard, AdminAccessGuard)
export class AdminBookingsController {
  constructor(private readonly bookings: AdminBookingsService) {}
  @Get() @Header('Cache-Control', 'private, no-store') list(
    @Query() query: AdminBookingQueryDto,
  ) {
    return this.bookings.list(query);
  }
  @Get(':id') @Header('Cache-Control', 'private, no-store') detail(
    @Req() req: AdminRequest,
    @Param('id') id: string,
  ) {
    return this.bookings.detail(req.adminActor!, id);
  }
  @Get(':id/candidates')
  @Header('Cache-Control', 'private, no-store')
  candidates(@Param('id') id: string, @Query() query: AdminBookingQueryDto) {
    return this.bookings.candidates(id, query.page);
  }
  @Post(':id/cancel')
  @HttpCode(200)
  @Header('Cache-Control', 'private, no-store')
  cancel(
    @Req() req: AdminRequest,
    @Param('id') id: string,
    @Body() dto: AdminCancelBookingDto,
  ) {
    return this.bookings.cancel(req.adminActor!, id, dto);
  }
  @Post(':id/offer')
  @HttpCode(200)
  @Header('Cache-Control', 'private, no-store')
  offer(
    @Req() req: AdminRequest,
    @Param('id') id: string,
    @Body() dto: AdminOfferBookingDto,
  ) {
    return this.bookings.offer(req.adminActor!, id, dto);
  }
}
