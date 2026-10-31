import { Global, Module } from '@nestjs/common';
import { InMemoryStoreService } from './in-memory-store.service';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService, InMemoryStoreService],
  exports: [PrismaService, InMemoryStoreService],
})
export class PrismaModule {}

