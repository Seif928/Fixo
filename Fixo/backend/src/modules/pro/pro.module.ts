import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CommunicationsModule } from '../communications/communications.module';
import { ProController } from './pro.controller';
import { MediaModule } from '../media/media.module';
import { ProService } from './pro.service';

@Module({
  imports: [AuthModule, CommunicationsModule, MediaModule],
  controllers: [ProController],
  providers: [ProService],
  exports: [ProService],
})
export class ProModule {}
