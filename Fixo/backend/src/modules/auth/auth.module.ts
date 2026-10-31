import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import {
  DevSmsProvider,
  ProductionTelecomSmsProvider,
  SMS_PROVIDER,
} from './sms/sms.provider';

@Module({
  controllers: [AuthController],
  providers: [
    AuthService,
    DevSmsProvider,
    ProductionTelecomSmsProvider,
    {
      provide: SMS_PROVIDER,
      useFactory: (
        devProvider: DevSmsProvider,
        prodProvider: ProductionTelecomSmsProvider,
      ) => {
        if (process.env.NODE_ENV === 'production') {
          return prodProvider;
        }
        return devProvider;
      },
      inject: [DevSmsProvider, ProductionTelecomSmsProvider],
    },
    JwtAuthGuard,
    RolesGuard,
  ],
  exports: [AuthService, JwtAuthGuard, RolesGuard, SMS_PROVIDER],
})
export class AuthModule {}
