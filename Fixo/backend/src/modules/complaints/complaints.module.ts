import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { AdminAccessModule } from '../admin/admin-access.module';
import {
  AdminComplaintsController,
  ComplaintsController,
} from './complaints.controller';
import { ComplaintsService } from './complaints.service';

@Module({
  imports: [PrismaModule, AuthModule, AdminAccessModule],
  controllers: [ComplaintsController, AdminComplaintsController],
  providers: [ComplaintsService],
  exports: [ComplaintsService],
})
export class ComplaintsModule {}

