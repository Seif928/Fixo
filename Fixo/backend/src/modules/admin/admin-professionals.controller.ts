import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  Patch,
  Query,
  Req,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ProVerificationStatus } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ProAdminReviewDto } from '../pro/dto/pro.dto';
import { ProService } from '../pro/pro.service';
import { AdminAccessGuard, AdminRequest } from './admin-access.guard';
import { AdminProfessionalsService } from './admin-professionals.service';

export class ProfessionalQueryDto {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(10000) page = 1;
  @IsOptional() @IsEnum(ProVerificationStatus) status?: ProVerificationStatus;
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(100)
  search?: string;
}
@Controller('admin/professionals')
@UseGuards(JwtAuthGuard, AdminAccessGuard)
export class AdminProfessionalsController {
  constructor(
    private readonly professionals: AdminProfessionalsService,
    private readonly pro: ProService,
  ) {}
  @Get()
  @Header('Cache-Control', 'private, no-store')
  list(@Query() query: ProfessionalQueryDto) {
    return this.professionals.list(query);
  }
  @Get(':id')
  @Header('Cache-Control', 'private, no-store')
  detail(@Req() request: AdminRequest, @Param('id') id: string) {
    return this.professionals.detail(request.adminActor!, id);
  }
  @Patch(':id/review')
  @Header('Cache-Control', 'private, no-store')
  review(
    @Req() request: AdminRequest,
    @Param('id') id: string,
    @Body() dto: ProAdminReviewDto,
  ) {
    return this.pro.adminReviewProProfile(request.adminActor!, id, dto);
  }
  @Get(':id/documents/:docId/content')
  @Header('Cache-Control', 'private, no-store')
  @Header('X-Content-Type-Options', 'nosniff')
  @Header('Content-Security-Policy', "default-src 'none'; sandbox")
  async document(
    @Req() request: AdminRequest,
    @Param('id') id: string,
    @Param('docId') docId: string,
  ) {
    const content = await this.pro.getReviewDocumentContent(
      request.adminActor!,
      id,
      docId,
    );
    return new StreamableFile(content.bytes, {
      type: content.mimeType,
      disposition: 'attachment; filename="verification-document"',
    });
  }
}
