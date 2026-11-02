import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { FirebaseIdentityController } from './firebase-identity.controller';
import { FirebaseIdentityService, FirebaseTokenVerifier } from './firebase-identity.service';
import { PhonePasswordController } from './phone-password.controller';
import { FirebasePasswordGateway, PhonePasswordService } from './phone-password.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import {
  DevSmsProvider,
  ProductionTelecomSmsProvider,
  SMS_PROVIDER,
} from './sms/sms.provider';

@Module({
  controllers: [AuthController, FirebaseIdentityController, PhonePasswordController],
  providers: [
    AuthService,
    FirebaseIdentityService,
    FirebaseTokenVerifier,
    FirebasePasswordGateway,
    PhonePasswordService,
    DevSmsProvider,
    ProductionTelecomSmsProvider,
    {
      provide: SMS_PROVIDER,
      useFactory: (
        devProvider: DevSmsProvider,
        prodProvider: ProductionTelecomSmsProvider,
      ) => {
        if (process.env.NODE_ENV === 'production' || process.env.SMS_PROVIDER_TYPE === 'DISABLED') {
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
