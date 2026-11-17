import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RepeatBookingController } from './repeat-booking.controller';
import { RepeatBookingService } from './repeat-booking.service';

@Module({
  imports: [AuthModule],
  controllers: [RepeatBookingController],
  providers: [RepeatBookingService],
  exports: [RepeatBookingService],
})
export class RepeatBookingModule {}
