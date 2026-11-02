import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CommunicationsController } from './communications.controller';
import { CommunicationsService } from './communications.service';
import { PushController } from './push.controller';
import { PushSender, PushService } from './push.service';

@Module({ imports: [AuthModule], controllers: [CommunicationsController, PushController], providers: [CommunicationsService, PushService, PushSender] })
export class CommunicationsModule {}
