import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DayOfWeek, LeaveReason } from '@prisma/client';

export class DayScheduleItemDto {
  @ApiProperty({ enum: DayOfWeek })
  @IsEnum(DayOfWeek)
  dayOfWeek!: DayOfWeek;

  @ApiProperty({ example: 540, description: 'Shift start minute from midnight (09:00 = 540)' })
  @IsInt()
  @Min(0)
  @Max(1440)
  startMinute!: number;

  @ApiProperty({ example: 1080, description: 'Shift end minute from midnight (18:00 = 1080)' })
  @IsInt()
  @Min(0)
  @Max(1440)
  endMinute!: number;

  @ApiProperty({ example: true })
  @IsBoolean()
  isActive!: boolean;
}

export class UpdateWeeklyScheduleDto {
  @ApiProperty({ type: [DayScheduleItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DayScheduleItemDto)
  days!: DayScheduleItemDto[];
}

export class CreateLeaveDto {
  @ApiProperty({ example: '2026-06-01T00:00:00.000Z' })
  @IsNotEmpty()
  @IsDateString()
  startDate!: string;

  @ApiProperty({ example: '2026-06-03T23:59:59.000Z' })
  @IsNotEmpty()
  @IsDateString()
  endDate!: string;

  @ApiPropertyOptional({ enum: LeaveReason, default: LeaveReason.PERSONAL })
  @IsOptional()
  @IsEnum(LeaveReason)
  reason?: LeaveReason;

  @ApiPropertyOptional({ example: 'Family commitments' })
  @IsOptional()
  @IsString()
  notes?: string;
}

