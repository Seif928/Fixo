import { Module } from '@nestjs/common';
import { AuthModule } from './modules/auth/auth.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { CommunicationsModule } from './modules/communications/communications.module';
import { HealthModule } from './modules/health/health.module';
import { ProModule } from './modules/pro/pro.module';
import { ServicesModule } from './modules/services/services.module';
import { UsersModule } from './modules/users/users.module';
import { PrismaModule } from './prisma/prisma.module';
import { MediaModule } from './modules/media/media.module';

@Module({
  imports: [
    PrismaModule,
    MediaModule,
    HealthModule,
    AuthModule,
    UsersModule,
    ServicesModule,
    BookingsModule,
    ProModule,
    CommunicationsModule,
  ],
})
export class AppModule {}
