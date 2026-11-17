import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { PushService } from './push.service';

export class RegisterPushDeviceDto {
  @IsString() @MinLength(20) @MaxLength(4096) token!: string;
  @IsIn(['ANDROID', 'IOS', 'WEB']) platform!: string;
}

@UseGuards(JwtAuthGuard)
@Controller('users/me')
export class PushController {
  constructor(private readonly service: PushService) {}
  @Get('push-status') status() { return this.service.status(); }
  @Post('push-devices') register(@CurrentUser() user: FixoJwtPayload, @Body() dto: RegisterPushDeviceDto) {
    return this.service.register(user.sub, dto);
  }
  @Delete('push-devices/:id') unregister(@CurrentUser() user: FixoJwtPayload, @Param('id') id: string) {
    return this.service.unregister(user.sub, id);
  }
}
