import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class PrivateUploadDto {
  @ApiProperty({
    description: 'Upload purpose context',
    enum: ['BOOKING_ISSUE', 'REVIEW_PHOTO', 'PRO_DOCUMENT'],
    example: 'BOOKING_ISSUE',
  })
  @IsNotEmpty()
  @IsIn(['BOOKING_ISSUE', 'REVIEW_PHOTO', 'PRO_DOCUMENT'])
  purpose: 'BOOKING_ISSUE' | 'REVIEW_PHOTO' | 'PRO_DOCUMENT';

  @ApiProperty({
    description: 'Original file name',
    example: 'ac-unit-leak.jpg',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(180)
  fileName: string;

  @ApiProperty({
    description: 'Allowed MIME type',
    enum: ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
    example: 'image/jpeg',
  })
  @IsNotEmpty()
  @IsIn(['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
  mimeType: 'image/jpeg' | 'image/png' | 'image/webp' | 'application/pdf';

  @ApiProperty({
    description: 'Base64-encoded file bytes (maximum 2 MB decoded)',
  })
  @IsNotEmpty()
  @IsString()
  contentBase64: string;

  @ApiPropertyOptional({
    description: 'Optional related booking ID for participant authorization',
  })
  @IsOptional()
  @IsString()
  bookingId?: string;
}
