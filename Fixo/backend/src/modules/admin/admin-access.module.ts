import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminAccessService } from './admin-access.service';
import { AdminAccessGuard } from './admin-access.guard';
import { AdminAccessController } from './admin-access.controller';
import { AdminCatalogController } from './admin-catalog.controller';
import { AdminCatalogService } from './admin-catalog.service';
@Module({
  imports: [AuthModule],
  controllers: [AdminAccessController, AdminCatalogController],
  providers: [AdminAccessService, AdminAccessGuard, AdminCatalogService],
  exports: [AdminAccessService, AdminAccessGuard],
})
export class AdminAccessModule {}
