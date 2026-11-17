import { Controller, Get, Header, Param, Query } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';
import { QueryServicesDto } from './dto/query-services.dto';
import { ServicesService } from './services.service';

const PUBLIC_CATALOG_CACHE_CONTROL =
  'public, max-age=60, s-maxage=300, stale-while-revalidate=600';

@ApiTags('services')
@Controller('services')
export class ServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get('categories')
  @Header('Cache-Control', PUBLIC_CATALOG_CACHE_CONTROL)
  @ApiOperation({
    summary: 'List all 6 Egyptian home service categories and Greater Cairo/Giza zones',
  })
  @ApiResponse({
    status: 200,
    description: 'Service categories with EGP starting prices',
  })
  async listCategories() {
    return this.servicesService.listCategories();
  }

  @Get()
  @Header('Cache-Control', PUBLIC_CATALOG_CACHE_CONTROL)
  @ApiOperation({
    summary: 'Search and filter home services in EGP (supports search, categoryId, featured, bundle, pagination)',
  })
  @ApiResponse({ status: 200, description: 'Paginated list of services in EGP' })
  async listServices(@Query() query: QueryServicesDto) {
    return this.servicesService.listServices(query);
  }

  @Get(':id')
  @Header('Cache-Control', PUBLIC_CATALOG_CACHE_CONTROL)
  @ApiOperation({
    summary: 'Retrieve a specific service offering by ID or slug',
  })
  @ApiParam({ name: 'id', example: 'off-ac-deep-clean' })
  @ApiResponse({ status: 200, description: 'Service offering details in EGP' })
  @ApiResponse({ status: 404, description: 'Service not found' })
  async getServiceById(@Param('id') id: string) {
    return this.servicesService.getServiceById(id);
  }
}

