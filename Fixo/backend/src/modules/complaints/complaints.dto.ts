import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ComplaintCategory, ComplaintStatus } from '@prisma/client';
import { IsSafePhotoUrl } from '../../common/validators/safe-photo-url.validator';

export class CreateComplaintDto {
  @IsString()
  @IsNotEmpty()
  bookingId!: string;

  @IsEnum(ComplaintCategory)
  category!: ComplaintCategory;

  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  @MaxLength(2000)
  description!: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(5)
  @MaxLength(500, { each: true })
  @IsSafePhotoUrl({ maxHttpLength: 500, each: true })
  photoUrls?: string[];
}

export class ComplaintsQueryDto {
  @IsOptional()
  @Transform(({ value }) => {
    const num = parseInt(value, 10);
    return isNaN(num) || num < 1 ? 1 : num;
  })
  @IsInt()
  page: number = 1;

  @IsOptional()
  @Transform(({ value }) => {
    const num = parseInt(value, 10);
    if (isNaN(num) || num < 1) return 20;
    if (num > 50) return 50;
    return num;
  })
  @IsInt()
  limit: number = 20;

  @IsOptional()
  @IsEnum(ComplaintStatus)
  status?: ComplaintStatus;
}

export class UpdateComplaintStatusDto {
  @IsEnum(ComplaintStatus)
  status!: ComplaintStatus;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  adminNotes?: string;
}

