import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { ProScheduleController } from './pro-schedule.controller';
import { ProScheduleService } from './pro-schedule.service';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [ProScheduleController],
  providers: [ProScheduleService],
  exports: [ProScheduleService],
})
export class ProScheduleModule {}
