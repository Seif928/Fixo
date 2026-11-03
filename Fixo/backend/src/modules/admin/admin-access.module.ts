import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminAccessService } from './admin-access.service';
import { AdminAccessGuard } from './admin-access.guard';
import { AdminAccessController } from './admin-access.controller';
@Module({
  imports: [AuthModule],
  controllers: [AdminAccessController],
  providers: [AdminAccessService, AdminAccessGuard],
  exports: [AdminAccessService, AdminAccessGuard],
})
export class AdminAccessModule {}
