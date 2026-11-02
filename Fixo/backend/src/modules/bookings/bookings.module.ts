import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CommunicationsModule } from '../communications/communications.module';
import { BookingsController, PrivateUploadsController } from './bookings.controller';
import { BookingsService } from './bookings.service';

@Module({
  imports: [AuthModule, CommunicationsModule],
  controllers: [BookingsController, PrivateUploadsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
