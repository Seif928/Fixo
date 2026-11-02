import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CommunicationsModule } from '../communications/communications.module';
import { ProController } from './pro.controller';
import { ProService } from './pro.service';

@Module({
  imports: [AuthModule, CommunicationsModule],
  controllers: [ProController],
  providers: [ProService],
  exports: [ProService],
})
export class ProModule {}
