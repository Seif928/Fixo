import { Controller, Get, Header, Query } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PublicProfessionalDto } from './dto/public-professional.dto';
import { QueryProfessionalsDto } from './dto/query-services.dto';
import { PaginatedResponse, ServicesService } from './services.service';

@ApiTags('professionals')
@Controller('professionals')
export class ProfessionalsController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get()
  @Header(
    'Cache-Control',
    'public, max-age=30, s-maxage=120, stale-while-revalidate=300',
  )
  @ApiOperation({
    summary: 'List and search verified Cairo & Giza professionals in EGP',
  })
  @ApiResponse({
    status: 200,
    description:
      'Paginated list of approved professionals (private PII, phone, and dossier codes excluded)',
    type: PublicProfessionalDto,
  })
  async listProfessionals(
    @Query() query: QueryProfessionalsDto,
  ): Promise<PaginatedResponse<PublicProfessionalDto>> {
    return this.servicesService.listProfessionals(query);
  }
}
