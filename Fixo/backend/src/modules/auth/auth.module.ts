import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { DevSmsProvider, SMS_PROVIDER } from './sms/sms.provider';

@Module({
  controllers: [AuthController],
  providers: [
    AuthService,
    DevSmsProvider,
    {
      provide: SMS_PROVIDER,
      useExisting: DevSmsProvider,
    },
    JwtAuthGuard,
    RolesGuard,
  ],
  exports: [AuthService, JwtAuthGuard, RolesGuard, SMS_PROVIDER],
})
export class AuthModule {}

