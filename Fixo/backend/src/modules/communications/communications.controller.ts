import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { CommunicationsService } from './communications.service';
import { MessageQueryDto, NotificationPreferenceDto, SendMessageDto } from './dto/communication.dto';
import { Header, StreamableFile, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiConsumes } from '@nestjs/swagger';

@ApiTags('communications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class CommunicationsController {
  constructor(private readonly service: CommunicationsService) {}

  @Post('bookings/:bookingId/messages/photo')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('photo', { limits: { fileSize: 2 * 1024 * 1024, files: 1, fields: 0, parts: 1 } }))
  photo(@CurrentUser() user: FixoJwtPayload, @Param('bookingId') bookingId: string, @UploadedFile() file?: { buffer: Buffer; mimetype: string }) {
    return this.service.sendPhoto(user.sub, bookingId, file);
  }

  @Get('bookings/:bookingId/messages/:messageId/photo')
  @Header('Cache-Control', 'private, no-store')
  @Header('X-Content-Type-Options', 'nosniff')
  async photoBytes(@CurrentUser() user: FixoJwtPayload, @Param('bookingId') bookingId: string, @Param('messageId') messageId: string) {
    return new StreamableFile(await this.service.readPhoto(user.sub, bookingId, messageId), { type: 'image/webp', disposition: 'inline' });
  }

  @Get('bookings/:bookingId/messages')
  list(@CurrentUser() user: FixoJwtPayload, @Param('bookingId') bookingId: string, @Query() query: MessageQueryDto) {
    return this.service.listMessages(user.sub, bookingId, query);
  }

  @Post('bookings/:bookingId/messages')
  send(@CurrentUser() user: FixoJwtPayload, @Param('bookingId') bookingId: string, @Body() dto: SendMessageDto) {
    return this.service.sendMessage(user.sub, bookingId, dto);
  }

  @Patch('bookings/:bookingId/messages/:messageId/read')
  read(@CurrentUser() user: FixoJwtPayload, @Param('bookingId') bookingId: string, @Param('messageId') messageId: string) {
    return this.service.markMessageRead(user.sub, bookingId, messageId);
  }

  @Get('users/me/notifications')
  notifications(@CurrentUser() user: FixoJwtPayload) {
    return this.service.notificationFeed(user.sub);
  }

  @Patch('users/me/notification-preferences')
  preferences(@CurrentUser() user: FixoJwtPayload, @Body() dto: NotificationPreferenceDto) {
    return this.service.updateNotificationPreference(user.sub, dto.arrivalAlertsEnabled);
  }
}
