import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { FirebaseSessionPolicy } from './firebase-session-policy.service';
import { FirebaseIdentityController } from './firebase-identity.controller';
import {
  FirebaseIdentityService,
  FirebaseTokenVerifier,
} from './firebase-identity.service';
import { PhonePasswordController } from './phone-password.controller';
import {
  FirebasePasswordGateway,
  PhonePasswordService,
} from './phone-password.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { ClerkSessionPolicy } from './clerk-session-policy.service';
import { ClerkIdentityService } from './clerk-identity.service';
import { ClerkIdentityController, ClerkTrialRateGuard } from './clerk-identity.controller';
import {
  DevSmsProvider,
  ProductionTelecomSmsProvider,
  SMS_PROVIDER,
} from './sms/sms.provider';

@Module({
  controllers: [
    AuthController,
    FirebaseIdentityController,
    PhonePasswordController,
    ClerkIdentityController,
  ],
  providers: [
    AuthService,
    { provide: ClerkSessionPolicy, useFactory: () => new ClerkSessionPolicy() },
    ClerkIdentityService,
    ClerkTrialRateGuard,
    FirebaseSessionPolicy,
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
        if (
          process.env.NODE_ENV === 'production' ||
          process.env.SMS_PROVIDER_TYPE === 'DISABLED'
        ) {
          return prodProvider;
        }
        return devProvider;
      },
      inject: [DevSmsProvider, ProductionTelecomSmsProvider],
    },
    JwtAuthGuard,
    RolesGuard,
  ],
  exports: [
    AuthService,
    FirebaseSessionPolicy,
    JwtAuthGuard,
    RolesGuard,
    SMS_PROVIDER,
  ],
})
export class AuthModule {}
