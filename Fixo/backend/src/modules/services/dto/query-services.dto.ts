import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

function parseOptionalBoolean(value: unknown): boolean | undefined {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') {
      return true;
    }
    if (normalized === 'false' || normalized === '0') {
      return false;
    }
  }
  return Boolean(value);
}

export class QueryServicesDto {
  @ApiPropertyOptional({
    example: 'AC',
    description: 'Search query across English/Arabic service titles and descriptions',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @ApiPropertyOptional({
    example: 'ac-maintenance',
    description: 'Filter by category ID or category slug',
  })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({
    example: true,
    description: 'Filter featured seasonal promotional services',
  })
  @IsOptional()
  @Transform(({ value }) => parseOptionalBoolean(value))
  @IsBoolean()
  featured?: boolean;

  @ApiPropertyOptional({
    example: false,
    description: 'Filter bundle offers (e.g. Home Safety Inspection)',
  })
  @IsOptional()
  @Transform(({ value }) => parseOptionalBoolean(value))
  @IsBoolean()
  bundle?: boolean;

  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}

export class QueryProfessionalsDto {
  @ApiPropertyOptional({
    example: 'Tarek',
    description: 'Search query across professional names, specialties, or Cairo/Giza zones',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @ApiPropertyOptional({
    example: 'electrical-lighting',
    description: 'Filter by primary category ID or slug',
  })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({
    example: 'sheikh-zayed',
    description: 'Filter by Cairo/Giza coverage zone slug or label',
  })
  @IsOptional()
  @IsString()
  zone?: string;

  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}

