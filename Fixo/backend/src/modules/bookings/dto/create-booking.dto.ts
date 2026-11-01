import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { TimeWindow } from '@prisma/client';
import {
  IsArray,
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreateBookingDto {
  @ApiProperty({
    description: 'UUID of the service offering being booked',
    example: 'off-ac-deep-clean',
  })
  @IsNotEmpty()
  @IsString()
  offeringId: string;

  @ApiProperty({
    description: 'UUID of the customer address where service takes place',
    example: 'addr-palm-hills-14',
  })
  @IsNotEmpty()
  @IsString()
  addressId: string;

  @ApiPropertyOptional({
    description: 'Optional UUID of customer preferred professional',
    example: 'pro-hassan-01',
  })
  @IsOptional()
  @IsString()
  preferredProId?: string;

  @ApiProperty({
    description: 'Scheduled date for the service (YYYY-MM-DD or ISO 8601 string)',
    example: '2026-11-05',
  })
  @IsNotEmpty()
  @IsDateString()
  scheduledDate: string;

  @ApiProperty({
    description: 'Selected 3-hour time slot window',
    enum: TimeWindow,
    example: TimeWindow.AFTERNOON_13_16,
  })
  @IsNotEmpty()
  @IsEnum(TimeWindow, {
    message:
      'timeWindow must be one of: MORNING_09_12, AFTERNOON_13_16, EVENING_17_20',
  })
  timeWindow: TimeWindow;

  @ApiPropertyOptional({
    description: 'Optional customer notes or diagnostics about the issue',
    example: 'AC in living room is leaking water and not cooling efficiently.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  issueDescription?: string;

  @ApiPropertyOptional({
    description: 'Optional photo attachment URLs',
    type: [String],
    example: [],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  issuePhotoUrls?: string[];
}

