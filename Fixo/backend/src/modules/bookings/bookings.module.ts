import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CommunicationsModule } from '../communications/communications.module';
import {
  BookingsController,
  PrivateUploadsController,
} from './bookings.controller';
import { BookingsService } from './bookings.service';
import { AdminAccessModule } from '../admin/admin-access.module';
import { AdminBookingsController } from '../admin/admin-bookings.controller';
import { AdminBookingsService } from '../admin/admin-bookings.service';

@Module({
  imports: [AuthModule, CommunicationsModule, AdminAccessModule],
  controllers: [
    BookingsController,
    PrivateUploadsController,
    AdminBookingsController,
  ],
  providers: [BookingsService, AdminBookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
