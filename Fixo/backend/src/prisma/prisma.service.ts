import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

export type StoragePersistenceMode =
  | 'POSTGRESQL_PRISMA'
  | 'IN_MEMORY_FALLBACK';

export interface PersistenceDiagnostics {
  connected: boolean;
  storageMode: StoragePersistenceMode;
  fallbackAllowed: boolean;
  environment: string;
  connectionFailureReason: string | null;
}

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);
  private connected = false;
  private connectionFailureReason: string | null = null;

  async onModuleInit(): Promise<void> {
    const isProd = process.env.NODE_ENV === 'production';
    const isTest = process.env.NODE_ENV === 'test';
    const allowFallback = process.env.ALLOW_IN_MEMORY_FALLBACK === 'true';

    // Invariant: Production must never allow in-memory fallback
    if (isProd && allowFallback) {
      throw new Error(
        'FATAL CONFIGURATION ERROR: ALLOW_IN_MEMORY_FALLBACK is strictly forbidden in production mode.',
      );
    }

    // Isolated unit test execution without external daemon
    if (isTest && process.env.FIXO_TEST_FORCE_PRISMA !== 'true') {
      this.connected = false;
      this.connectionFailureReason =
        'Running in isolated automated test mode without external PostgreSQL daemon.';
      return;
    }

    try {
      await Promise.race([
        this.$connect(),
        new Promise<never>((_, reject) =>
          setTimeout(
            () => reject(new Error('PostgreSQL connection timeout (1500ms)')),
            1500,
          ),
        ),
      ]);
      await this.$queryRaw`SELECT 1`;
      this.connected = true;
      this.connectionFailureReason = null;
      this.logger.log('Connected to PostgreSQL database via Prisma ORM.');
    } catch (error) {
      this.connected = false;
      this.connectionFailureReason =
        error instanceof Error ? error.message : 'PostgreSQL connection failed';

      if (isProd) {
        throw new Error(
          `FATAL DATABASE ERROR: Failed to connect to PostgreSQL database in production environment: ${this.connectionFailureReason}. Silently activating in-memory persistence is strictly forbidden.`,
        );
      }

      if (!allowFallback) {
        throw new Error(
          `FATAL DATABASE ERROR: PostgreSQL is not reachable (${this.connectionFailureReason}) and ALLOW_IN_MEMORY_FALLBACK is not set to 'true'. Refusing to start without verified persistence. For offline local development, explicitly set ALLOW_IN_MEMORY_FALLBACK='true' in .env.`,
        );
      }

      this.logger.warn(
        `[PrismaService] PostgreSQL is not reachable (${this.connectionFailureReason}). Explicit ALLOW_IN_MEMORY_FALLBACK=true active. Operating in IN_MEMORY_FALLBACK mode for local development only.`,
      );
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (this.connected) {
      await this.$disconnect();
    }
  }

  isDatabaseConnected(): boolean {
    return this.connected;
  }

  getStorageMode(): StoragePersistenceMode {
    return this.connected ? 'POSTGRESQL_PRISMA' : 'IN_MEMORY_FALLBACK';
  }

  getConnectionFailureReason(): string | null {
    return this.connectionFailureReason;
  }

  getPersistenceDiagnostics(): PersistenceDiagnostics {
    return {
      connected: this.connected,
      storageMode: this.getStorageMode(),
      fallbackAllowed: process.env.ALLOW_IN_MEMORY_FALLBACK === 'true',
      environment: process.env.NODE_ENV ?? 'development',
      connectionFailureReason: this.connected
        ? null
        : this.connectionFailureReason,
    };
  }
}
