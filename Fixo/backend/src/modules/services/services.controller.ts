import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';
import { QueryServicesDto } from './dto/query-services.dto';
import { ServicesService } from './services.service';

@ApiTags('services')
@Controller('services')
export class ServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get('categories')
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
  @ApiOperation({
    summary: 'Search and filter home services in EGP (supports search, categoryId, featured, bundle, pagination)',
  })
  @ApiResponse({ status: 200, description: 'Paginated list of services in EGP' })
  async listServices(@Query() query: QueryServicesDto) {
    return this.servicesService.listServices(query);
  }

  @Get(':id')
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

