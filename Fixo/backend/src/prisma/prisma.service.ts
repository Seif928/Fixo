import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

export type StoragePersistenceMode = 'POSTGRESQL_PRISMA' | 'IN_MEMORY_FALLBACK';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);
  private connected = false;
  private connectionFailureReason: string | null = null;

  async onModuleInit(): Promise<void> {
    if (process.env.NODE_ENV === 'test' && process.env.FIXO_TEST_FORCE_PRISMA !== 'true') {
      this.connected = false;
      this.connectionFailureReason =
        'Running in isolated automated test mode without external PostgreSQL daemon.';
      return;
    }

    try {
      await Promise.race([
        this.$connect(),
        new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error('PostgreSQL connection timeout (1500ms)')), 1500),
        ),
      ]);
      await this.$queryRaw`SELECT 1`;
      this.connected = true;
      this.connectionFailureReason = null;
      this.logger.log('Connected to PostgreSQL via Prisma ORM.');
    } catch (error) {
      this.connected = false;
      this.connectionFailureReason =
        error instanceof Error ? error.message : 'PostgreSQL connection failed';
      this.logger.warn(
        `PostgreSQL is not reachable (${this.connectionFailureReason}). Operating in explicitly separated IN_MEMORY_FALLBACK mode.`,
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
}

