import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Publicly exposed professional profile response.
 *
 * Security & Privacy Invariants:
 * - Omits internal dossier identifiers (`dossierCode`, regulatory dossier codes).
 * - Omits personal telephone numbers (`user.phone`) to prevent harvesting.
 * - Omits internal reviewer notes (`reviewerNote`).
 * - Never fabricates verification badges or ratings if not explicitly set.
 */
export class PublicProfessionalDto {
  @ApiProperty({
    example: 'pro-tarek-01',
    description: 'Public professional ID',
  })
  id!: string;

  @ApiProperty({ example: 'Eng. Tarek Mansour' })
  fullNameEn!: string;

  @ApiProperty({ example: 'م/ طارق منصور' })
  fullNameAr!: string;

  @ApiProperty({ example: 'Certified HVAC & Gas Specialist' })
  specialtyEn!: string;

  @ApiProperty({ example: 'مهندس تبريد وفريون معتمد' })
  specialtyAr!: string;

  @ApiProperty({ example: 'ac-maintenance' })
  primaryCategorySlug!: string;

  @ApiProperty({
    description: 'Actual service category ID for booking selection',
  })
  primaryCategoryId!: string;

  @ApiProperty({ example: 'sheikh-zayed' })
  primaryZoneSlug!: string;

  @ApiProperty({ example: 'Sheikh Zayed & 6th of October' })
  zonesLabelEn!: string;

  @ApiProperty({ example: 'الشيخ زايد وأكتوبر' })
  zonesLabelAr!: string;

  @ApiProperty({ example: 4.9 })
  ratingAvg!: number;

  @ApiProperty({ example: 87 })
  reviewsCount!: number;

  @ApiProperty({ example: 342 })
  completedJobsCount!: number;

  @ApiProperty({ example: 98 })
  acceptanceRatePct!: number;

  @ApiProperty({ example: 250, description: 'Inspection / Hourly rate in EGP' })
  estimatedPriceEgp!: number;

  @ApiPropertyOptional({ example: 'Verified Master Pro', nullable: true })
  badgeEn!: string | null;

  @ApiPropertyOptional({ example: 'فني خبير معتمد', nullable: true })
  badgeAr!: string | null;

  @ApiPropertyOptional({
    example: 'verified_master',
    enum: ['fast_responder', 'verified_master', null],
    nullable: true,
  })
  badgeVariant!: 'fast_responder' | 'verified_master' | null;

  @ApiProperty({ example: true })
  isOnline!: boolean;
}
