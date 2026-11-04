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
import { LocationModule } from './modules/location/location.module';
import { AdminAccessModule } from './modules/admin/admin-access.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { RepeatBookingModule } from './modules/repeat-booking/repeat-booking.module';
import { ComplaintsModule } from './modules/complaints/complaints.module';
import { ProScheduleModule } from './modules/pro-schedule/pro-schedule.module';

@Module({
  imports: [
    PrismaModule,
    MediaModule,
    LocationModule,
    HealthModule,
    AuthModule,
    UsersModule,
    ServicesModule,
    BookingsModule,
    ProModule,
    CommunicationsModule,
    AdminAccessModule,
    FavoritesModule,
    RepeatBookingModule,
    ComplaintsModule,
    ProScheduleModule,
  ],
})
export class AppModule {}
