import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  BookingStatus,
  DocumentStatus,
  DocumentType,
  ExperienceTier,
  ProVerificationStatus,
  TransportMode,
} from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMinSize,
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class ProPersonalDetailsDto {
  @ApiProperty({
    description: 'Full legal name matching the private identity photos',
    example: 'Mahmoud El-Masry',
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  @Matches(/^[^\x00-\x1f\x7f]+$/)
  fullName!: string;

  @ApiProperty({
    description:
      '14-digit Egyptian National ID number matching the private identity photos',
    example: '29205140102938',
  })
  @IsNotEmpty()
  @IsString()
  @Matches(/^\d{14}$/, {
    message: 'nationalIdSynthetic must be an exact 14-digit number.',
  })
  nationalIdSynthetic: string;

  @ApiPropertyOptional({
    description: 'Primary coverage zone ID',
    example: 'zone-new-cairo',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  primaryZoneId?: string;

  @ApiPropertyOptional({
    description: 'Primary transport mode for service calls',
    enum: TransportMode,
    example: TransportMode.MOTORCYCLE,
  })
  @IsOptional()
  @IsEnum(TransportMode)
  transportMode?: TransportMode;

  @ApiPropertyOptional({
    description:
      'Optional vehicle description shown to customers during dispatch',
    example: 'White Bajaj Boxer 150',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  vehicleDescription?: string;

  @ApiPropertyOptional({
    description: 'Optional vehicle license plate (Arabic/English)',
    example: 'أ ب ج ٤٩٢',
  })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  vehiclePlateAr?: string;
}

export class ProSkillsUpdateDto {
  @ApiProperty({
    description: 'Primary trade category ID',
    example: 'cat-plumbing-leaks',
  })
  @IsNotEmpty()
  @IsString()
  primaryCategoryId: string;

  @ApiPropertyOptional({
    description: 'Selected sub-skill IDs within the primary trade',
    type: [String],
    example: ['sub-pipe-leak', 'sub-water-heater', 'sub-bathroom-fixtures'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  subSkillIds?: string[];

  @ApiProperty({
    description: 'Professional experience tier',
    enum: ExperienceTier,
    example: ExperienceTier.SKILLED_3_5Y,
  })
  @IsNotEmpty()
  @IsEnum(ExperienceTier)
  experienceTier: ExperienceTier;

  @ApiProperty({
    description: 'Selected coverage zone IDs in Greater Cairo / Alexandria',
    type: [String],
    example: ['zone-new-cairo', 'zone-maadi'],
  })
  @IsArray()
  @ArrayMinSize(1, { message: 'Select at least one coverage zone.' })
  @IsString({ each: true })
  coverageZoneIds: string[];

  @ApiProperty({
    description: 'Accepts FIXO Standard Rate Card (150 EGP base inspection)',
    example: true,
  })
  @IsBoolean()
  acceptsStandardRateCard: boolean;

  @ApiProperty({
    description: 'Confirms ownership of professional toolkit and safety gear',
    example: true,
  })
  @IsBoolean()
  toolkitCommitmentConfirmed: boolean;

  @ApiPropertyOptional({
    description: 'Optional English specialty title',
    example: 'Master Plumbing & Heater Technician',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  specialtyEn?: string;

  @ApiPropertyOptional({
    description: 'Optional Arabic specialty title',
    example: 'فني سباكة وسخانات خبير',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  specialtyAr?: string;

  @ApiPropertyOptional({
    description: 'Estimated starting visit price in EGP',
    example: 280,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(100)
  @Max(5000)
  estimatedPriceEgp?: number;
}

export class ProDocumentUploadDto {
  @ApiProperty({
    description: 'Type of verification document',
    enum: DocumentType,
    example: DocumentType.NATIONAL_ID_FRONT,
  })
  @IsNotEmpty()
  @IsEnum(DocumentType)
  docType: DocumentType;

  @ApiProperty({
    description: 'Photo file name',
    example: 'document.png',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(160)
  fileName: string;

  @ApiProperty({
    description: 'Document MIME type (image/jpeg, image/png, image/webp)',
    enum: ['image/jpeg', 'image/png', 'image/webp'],
    example: 'image/png',
  })
  @IsNotEmpty()
  @IsIn(['image/jpeg', 'image/png', 'image/webp'])
  mimeType: 'image/jpeg' | 'image/png' | 'image/webp';

  @ApiProperty({
    description: 'Base64-encoded document photo (max 2 MB decoded)',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(2796204)
  contentBase64: string;
}

export class ProAdminDocDecisionDto {
  @ApiProperty({ enum: DocumentType })
  @IsEnum(DocumentType)
  docType: DocumentType;

  @ApiProperty({ enum: [DocumentStatus.VERIFIED, DocumentStatus.REJECTED] })
  @IsIn([DocumentStatus.VERIFIED, DocumentStatus.REJECTED])
  status: 'VERIFIED' | 'REJECTED';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(300)
  rejectionReason?: string;
}

export class ProAdminReviewDto {
  @IsString()
  @Matches(/^[a-f0-9]{64}$/)
  reviewVersion?: string;

  @IsOptional()
  @IsBoolean()
  confirmDocumentsReviewed?: boolean;
  @ApiProperty({
    description: 'Authorized reviewer decision',
    enum: [
      ProVerificationStatus.APPROVED,
      ProVerificationStatus.ACTION_REQUIRED,
      ProVerificationStatus.SUSPENDED,
    ],
    example: ProVerificationStatus.APPROVED,
  })
  @IsNotEmpty()
  @IsIn([
    ProVerificationStatus.APPROVED,
    ProVerificationStatus.ACTION_REQUIRED,
    ProVerificationStatus.SUSPENDED,
  ])
  status: 'APPROVED' | 'ACTION_REQUIRED' | 'SUSPENDED';

  @ApiPropertyOptional({
    description: 'Reviewer note shown to the professional on Screen 14',
    example: 'All synthetic verification documents verified.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(600)
  reviewerNote?: string;

  @ApiPropertyOptional({
    type: [ProAdminDocDecisionDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ProAdminDocDecisionDto)
  @ArrayMaxSize(4)
  documentDecisions?: ProAdminDocDecisionDto[];
}

export class ProAvailabilityDto {
  @ApiProperty({
    description:
      'Whether the approved professional is online for dispatch offers',
    example: true,
  })
  @IsBoolean()
  isOnline: boolean;
}

export class ProDeclineOfferDto {
  @ApiPropertyOptional({
    description: 'Reason for declining the incoming job offer',
    example: 'Currently in another district / traffic delay',
  })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

export class ProAdvanceJobStatusDto {
  @ApiProperty({
    description: 'Next booking status in the professional execution flow',
    enum: [
      BookingStatus.PRO_EN_ROUTE,
      BookingStatus.ARRIVED,
      BookingStatus.IN_PROGRESS,
      BookingStatus.COMPLETED,
    ],
    example: BookingStatus.PRO_EN_ROUTE,
  })
  @IsNotEmpty()
  @IsIn([
    BookingStatus.PRO_EN_ROUTE,
    BookingStatus.ARRIVED,
    BookingStatus.IN_PROGRESS,
    BookingStatus.COMPLETED,
  ])
  toStatus: 'PRO_EN_ROUTE' | 'ARRIVED' | 'IN_PROGRESS' | 'COMPLETED';

  @ApiPropertyOptional({
    description:
      '4-digit customer Arrival PIN code (strictly required when transitioning ARRIVED -> IN_PROGRESS)',
    example: '4829',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}$/, {
    message: 'arrivalPinCode must be an exact 4-digit code.',
  })
  arrivalPinCode?: string;

  @ApiPropertyOptional({
    description: 'Optional status transition note',
    example: 'Arrived at main gate',
  })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}
