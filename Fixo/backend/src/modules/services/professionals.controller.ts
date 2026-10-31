import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { QueryProfessionalsDto } from './dto/query-services.dto';
import { ServicesService } from './services.service';

@ApiTags('professionals')
@Controller('professionals')
export class ProfessionalsController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get()
  @ApiOperation({
    summary: 'List and search recommended Cairo & Giza professionals in EGP',
  })
  @ApiResponse({
    status: 200,
    description: 'Paginated list of recommended professionals with ratings and EGP estimates',
  })
  async listProfessionals(@Query() query: QueryProfessionalsDto) {
    return this.servicesService.listProfessionals(query);
  }
}

