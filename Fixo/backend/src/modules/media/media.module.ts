import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AvatarController } from './avatar.controller';
import { AvatarService } from './avatar.service';
import { PrivateStorageService } from './private-storage.service';

@Module({ imports: [AuthModule], controllers: [AvatarController], providers: [PrivateStorageService, AvatarService], exports: [PrivateStorageService] })
export class MediaModule {}
