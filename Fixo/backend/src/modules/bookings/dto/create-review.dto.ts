import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateReviewDto {
  @ApiProperty({
    description: 'Star rating from 1 to 5',
    example: 5,
    minimum: 1,
    maximum: 5,
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(5)
  rating: number;

  @ApiPropertyOptional({
    description: 'Selected compliment tags for the professional',
    type: [String],
    example: ['On Time', 'Clean Work', 'Expert Skill'],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  tags?: string[];

  @ApiPropertyOptional({
    description: 'Written feedback about the completed service',
    example: 'Arrived on time and fixed the leak cleanly.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  comment?: string;

  @ApiPropertyOptional({
    description: 'Optional private photo URLs of completed work',
    type: [String],
    example: [],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsString({ each: true })
  photoUrls?: string[];

  @ApiPropertyOptional({
    description: 'Optional tip amount in EGP (100% goes to the professional)',
    example: 50,
    default: 0,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(5000)
  tipAmountEgp?: number;
}
