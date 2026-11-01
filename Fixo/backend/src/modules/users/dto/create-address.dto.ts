import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateAddressDto {
  @ApiProperty({
    description: 'Coverage zone UUID or slug in Greater Cairo / Giza',
    example: 'zone-sheikh-zayed',
  })
  @IsString()
  @IsNotEmpty()
  zoneId: string;

  @ApiProperty({
    description: 'Human-readable label for the address (e.g. Home, Villa 14, Office)',
    example: 'Palm Hills Villa 14',
    maxLength: 50,
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(50)
  label: string;

  @ApiProperty({
    description: 'Building, apartment, villa, or floor details',
    example: 'Apartment 4B, Building 14',
    maxLength: 150,
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(150)
  buildingLine: string;

  @ApiProperty({
    description: 'Street, compound, district, and governorate',
    example: 'Palm Hills, 6th of October / Sheikh Zayed, Giza',
    maxLength: 150,
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(150)
  districtLine: string;

  @ApiPropertyOptional({
    description: 'Optional compound access, gate notes, or security instructions',
    example: 'Private Gate 3 pre-cleared with security',
    maxLength: 250,
  })
  @IsOptional()
  @IsString()
  @MaxLength(250)
  gateNotes?: string;

  @ApiPropertyOptional({
    description: 'Optional GPS Latitude coordinate in Egypt',
    example: 30.0131,
  })
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({
    description: 'Optional GPS Longitude coordinate in Egypt',
    example: 30.9854,
  })
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({
    description: 'Whether this address should be the default delivery address',
    example: true,
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

