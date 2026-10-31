import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PrismaService, StoragePersistenceMode } from '../../prisma/prisma.service';

export interface HealthStatusResponse {
  status: 'ok';
  service: 'fixo-backend';
  market: 'EG';
  currency: 'EGP';
  timestamp: string;
  persistence: {
    storageMode: StoragePersistenceMode;
    databaseConnected: boolean;
  };
}

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

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
      persistence: {
        storageMode: this.prisma.getStorageMode(),
        databaseConnected: this.prisma.isDatabaseConnected(),
      },
    };
  }
}
