import {
  Controller,
  Get,
  Header,
  Param,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { RepeatBookingService } from './repeat-booking.service';

@Controller('bookings')
@UseGuards(JwtAuthGuard)
export class RepeatBookingController {
  constructor(private readonly repeatService: RepeatBookingService) {}

  @Get(':id/repeat-quote')
  @Header('Cache-Control', 'private, no-store')
  getRepeatQuote(
    @CurrentUser() user: FixoJwtPayload,
    @Param('id') id: string,
  ) {
    return this.repeatService.getRepeatQuote(user.sub, id);
  }
}
