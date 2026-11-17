import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Transform, Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminAccessGuard, AdminRequest } from './admin-access.guard';
import { AdminCatalogService } from './admin-catalog.service';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;
export class CatalogVersionDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
}
export class CatalogUpdateDto extends CatalogVersionDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  titleEn?: string;
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  titleAr?: string;
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(1600)
  descriptionEn?: string;
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(1600)
  descriptionAr?: string;
  @IsOptional() @IsInt() @Min(0) @Max(1000000) baseInspectionEgp?:
    | number
    | null;
  @IsOptional() @IsInt() @Min(0) @Max(1000000) serviceFeeEgp?: number | null;
  @IsOptional() @IsInt() @Min(5) @Max(1440) estimatedDurationMins?:
    | number
    | null;
}
export class CatalogQueryDto {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(10000) page = 1;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(100) search?: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(100) category?: string;
}

export class CreateCatalogDraftDto {
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  titleEn!: string;

  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  titleAr!: string;

  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(1600)
  descriptionEn!: string;

  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(1600)
  descriptionAr!: string;

  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  categorySlug!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(100)
  categoryNameEn?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(100)
  categoryNameAr?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(100)
  categoryIcon?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  slug?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1000000)
  baseInspectionEgp?: number | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1000000)
  serviceFeeEgp?: number | null;

  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(1440)
  estimatedDurationMins?: number | null;
}

@Controller('admin/catalog')
@UseGuards(JwtAuthGuard, AdminAccessGuard)
export class AdminCatalogController {
  constructor(private readonly catalog: AdminCatalogService) {}
  @Get()
  @Header('Cache-Control', 'private, no-store')
  list(@Query() query: CatalogQueryDto) {
    return this.catalog.list(query);
  }

  @Post()
  @Header('Cache-Control', 'private, no-store')
  createDraft(
    @Req() request: AdminRequest,
    @Body() dto: CreateCatalogDraftDto,
  ) {
    return this.catalog.createDraft(request.adminActor!, dto);
  }

  @Put(':id')
  @Header('Cache-Control', 'private, no-store')
  update(
    @Req() request: AdminRequest,
    @Param('id') id: string,
    @Body() dto: CatalogUpdateDto,
  ) {
    return this.catalog.update(request.adminActor!, id, dto);
  }

  @Post(':id/publish')
  @Header('Cache-Control', 'private, no-store')
  publish(
    @Req() request: AdminRequest,
    @Param('id') id: string,
    @Body() dto: CatalogVersionDto,
  ) {
    return this.catalog.publish(request.adminActor!, id, dto.version);
  }

  @Post(':id/deactivate')
  @Header('Cache-Control', 'private, no-store')
  deactivate(
    @Req() request: AdminRequest,
    @Param('id') id: string,
    @Body() dto: CatalogVersionDto,
  ) {
    return this.catalog.deactivate(request.adminActor!, id, dto.version);
  }

  @Post(':id/reactivate')
  @Header('Cache-Control', 'private, no-store')
  reactivate(
    @Req() request: AdminRequest,
    @Param('id') id: string,
    @Body() dto: CatalogVersionDto,
  ) {
    return this.catalog.reactivate(request.adminActor!, id, dto.version);
  }
}
