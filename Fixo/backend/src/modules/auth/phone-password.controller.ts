import {
  Body,
  Controller,
  HttpCode,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Transform } from 'class-transformer';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { RateLimit, RateLimitGuard } from '../../common/guards/rate-limit.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { FixoJwtPayload } from './utils/jwt-token.util';
import { PhonePasswordService } from './phone-password.service';

class PhoneAliasDto {
  @IsString() @MinLength(10) @MaxLength(24) phone!: string;
}
export class PhonePasswordDto extends PhoneAliasDto {
  @IsString() @MinLength(1) @MaxLength(128) password!: string;
}
export class FirstProfileDto extends PhoneAliasDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  @Matches(/^[^\x00-\x1f\x7f]+$/)
  fullName!: string;
}
@Controller('auth')
export class PhonePasswordController {
  constructor(private readonly service: PhonePasswordService) {}
  @Post('phone-password')
  @UseGuards(RateLimitGuard)
  @RateLimit({
    max: 15,
    windowMs: 60_000,
    keyBy: 'phoneAndIp',
    phoneMax: 12,
    phoneWindowMs: 15 * 60_000,
  })
  @HttpCode(200)
  signIn(@Body() dto: PhonePasswordDto) {
    return this.service.signIn(dto);
  }
  @Patch('phone-alias')
  @UseGuards(JwtAuthGuard, RateLimitGuard)
  @RateLimit({ max: 10, windowMs: 15 * 60_000, keyBy: 'userOrIp' })
  changePhone(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: PhonePasswordDto,
  ) {
    return this.service.changePhone(user.sub, dto);
  }
  @Post('first-profile')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard, RateLimitGuard)
  @RateLimit({ max: 10, windowMs: 60_000, keyBy: 'userOrIp' })
  complete(@CurrentUser() user: FixoJwtPayload, @Body() dto: FirstProfileDto) {
    return this.service.completeProfile(user.sub, dto);
  }
}
