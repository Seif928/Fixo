import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MediaModule } from '../media/media.module';
import { CommunicationsController } from './communications.controller';
import { CommunicationsService } from './communications.service';
import { PushController } from './push.controller';
import { PushSender, PushService } from './push.service';

@Module({
  imports: [AuthModule, MediaModule],
  controllers: [CommunicationsController, PushController],
  providers: [CommunicationsService, PushService, PushSender],
  exports: [PushService, PushSender],
})
export class CommunicationsModule {}
