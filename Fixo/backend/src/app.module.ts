import { Module } from '@nestjs/common';
import { AuthModule } from './modules/auth/auth.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { CommunicationsModule } from './modules/communications/communications.module';
import { HealthModule } from './modules/health/health.module';
import { ServicesModule } from './modules/services/services.module';
import { UsersModule } from './modules/users/users.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    HealthModule,
    AuthModule,
    UsersModule,
    ServicesModule,
    BookingsModule,
    CommunicationsModule,
  ],
})
export class AppModule {}
