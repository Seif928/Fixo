import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CoverageZoneSummaryResponse {
  @ApiProperty({ example: 'zone-sheikh-zayed' })
  id: string;

  @ApiProperty({ example: 'sheikh-zayed' })
  slug: string;

  @ApiProperty({ example: 'Sheikh Zayed, Dist. 9' })
  nameEn: string;

  @ApiProperty({ example: 'الشيخ زايد، الحي التاسع' })
  nameAr: string;

  @ApiProperty({ example: 'Giza' })
  governorate: string;

  @ApiProperty({ example: true })
  isActive: boolean;
}

export class CustomerAddressResponse {
  @ApiProperty({ example: 'addr-cairo-01' })
  id: string;

  @ApiProperty({ example: 'user-cust-1' })
  userId: string;

  @ApiProperty({ example: 'zone-sheikh-zayed' })
  zoneId: string;

  @ApiProperty({ example: 'Palm Hills Villa 14' })
  label: string;

  @ApiProperty({ example: 'Apartment 4B, Building 14' })
  buildingLine: string;

  @ApiProperty({ example: 'Palm Hills, 6th of October / Sheikh Zayed, Giza' })
  districtLine: string;

  @ApiPropertyOptional({ example: 'Private Gate 3' })
  gateNotes: string | null;

  @ApiPropertyOptional({ example: 30.0131 })
  latitude: number | null;

  @ApiPropertyOptional({ example: 30.9854 })
  longitude: number | null;

  @ApiProperty({ example: true })
  isDefault: boolean;

  @ApiProperty({ example: '2026-11-01T04:20:00.000Z' })
  createdAt: string;

  @ApiPropertyOptional({ type: () => CoverageZoneSummaryResponse })
  zone?: CoverageZoneSummaryResponse;
}

export class CustomerAddressListResponse {
  @ApiProperty({ type: () => [CustomerAddressResponse] })
  addresses: CustomerAddressResponse[];

  @ApiProperty({ example: 1 })
  total: number;
}

