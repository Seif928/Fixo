import {
  Controller,
  Get,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import {
  PrismaService,
  StoragePersistenceMode,
} from '../../prisma/prisma.service';

export interface HealthLivenessResponse {
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

export interface HealthReadinessResponse {
  status: 'ready';
  service: 'fixo-backend';
  database: {
    ready: boolean;
    storageMode: StoragePersistenceMode;
  };
  timestamp: string;
}

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Liveness check: Verify API service process is up' })
  @ApiResponse({ status: 200, description: 'Service process is alive' })
  getHealth(): HealthLivenessResponse {
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

  @Get('ready')
  @ApiOperation({
    summary: 'Readiness check: Live verification of database and storage layer',
  })
  @ApiResponse({ status: 200, description: 'Database and storage are ready' })
  @ApiResponse({
    status: 503,
    description: 'Storage backend is not reachable or unready',
  })
  async getReadiness(): Promise<HealthReadinessResponse> {
    const readiness = await this.prisma.checkReadiness();

    if (!readiness.ready) {
      throw new HttpException(
        {
          status: 'not_ready',
          service: 'fixo-backend',
          database: {
            ready: false,
            storageMode: readiness.storageMode,
            reason: readiness.reason ?? 'Storage backend unready',
          },
          timestamp: new Date().toISOString(),
        },
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }

    return {
      status: 'ready',
      service: 'fixo-backend',
      database: {
        ready: true,
        storageMode: readiness.storageMode,
      },
      timestamp: new Date().toISOString(),
    };
  }
}
