import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

export interface HealthStatusResponse {
  status: 'ok';
  service: 'fixo-backend';
  market: 'EG';
  currency: 'EGP';
  timestamp: string;
}

@ApiTags('health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Check API service health and market configuration' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  getHealth(): HealthStatusResponse {
    return {
      status: 'ok',
      service: 'fixo-backend',
      market: 'EG',
      currency: 'EGP',
      timestamp: new Date().toISOString(),
    };
  }
}

