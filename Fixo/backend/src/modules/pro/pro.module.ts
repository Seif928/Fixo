import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CommunicationsModule } from '../communications/communications.module';
import { ProController } from './pro.controller';
import { MediaModule } from '../media/media.module';
import { ProService } from './pro.service';
import { AdminAccessModule } from '../admin/admin-access.module';
import { AdminProfessionalsController } from '../admin/admin-professionals.controller';
import { AdminProfessionalsService } from '../admin/admin-professionals.service';

@Module({
  imports: [AuthModule, CommunicationsModule, MediaModule, AdminAccessModule],
  controllers: [ProController, AdminProfessionalsController],
  providers: [ProService, AdminProfessionalsService],
  exports: [ProService],
})
export class ProModule {}
