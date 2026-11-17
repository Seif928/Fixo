import { ApiPropertyOptional } from '@nestjs/swagger';
import { BookingStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';

export class BookingQueryDto {
  @ApiPropertyOptional({
    description: 'Filter bookings by exact status',
    enum: BookingStatus,
  })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @ApiPropertyOptional({
    description: 'Filter orders by Screen 08 tab: active, completed, or cancelled',
    enum: ['active', 'completed', 'cancelled'],
  })
  @IsOptional()
  @IsIn(['active', 'completed', 'cancelled'])
  tab?: 'active' | 'completed' | 'cancelled';

  @ApiPropertyOptional({
    description: 'Page size limit (default 20, max 50)',
    default: 20,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({
    description: 'Pagination offset (default 0)',
    default: 0,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;
}

