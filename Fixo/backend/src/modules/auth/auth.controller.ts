import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { RateLimit, RateLimitGuard } from '../../common/guards/rate-limit.guard';
import {
  AuthService,
  AuthTokensResponse,
  OtpRequestResponse,
} from './auth.service';
import {
  LogoutDto,
  RefreshTokenDto,
  RequestOtpDto,
  VerifyOtpDto,
} from './dto/auth.dto';

@ApiTags('auth')
@UseGuards(RateLimitGuard)
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('otp/request')
  @RateLimit({ max: 20, windowMs: 60_000, keyBy: 'ip' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Request a 6-digit SMS OTP challenge for an Egyptian (+20) mobile number',
  })
  @ApiResponse({ status: 200, description: 'OTP challenge created and dispatched' })
  @ApiResponse({ status: 400, description: 'Invalid Egyptian mobile number' })
  @ApiResponse({ status: 429, description: 'Rate limit exceeded' })
  async requestOtp(@Body() dto: RequestOtpDto): Promise<OtpRequestResponse> {
    return this.authService.requestOtp(dto);
  }

  @Post('otp/verify')
  @RateLimit({ max: 15, windowMs: 60_000, keyBy: 'ip' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Verify a 6-digit OTP code and issue JWT access + refresh tokens',
  })
  @ApiResponse({ status: 200, description: 'OTP verified and JWT tokens issued' })
  @ApiResponse({ status: 401, description: 'Invalid or expired OTP code' })
  @ApiResponse({ status: 429, description: 'Max verification attempts exceeded' })
  async verifyOtp(@Body() dto: VerifyOtpDto): Promise<AuthTokensResponse> {
    return this.authService.verifyOtp(dto);
  }

  @Post('refresh')
  @RateLimit({ max: 30, windowMs: 60_000, keyBy: 'ip' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Rotate refresh token and issue a fresh JWT access + refresh token pair',
  })
  @ApiResponse({ status: 200, description: 'Refresh token rotated' })
  @ApiResponse({ status: 401, description: 'Invalid, expired, or revoked refresh token' })
  async refresh(@Body() dto: RefreshTokenDto): Promise<AuthTokensResponse> {
    return this.authService.refreshTokens(dto);
  }

  @Post('logout')
  @RateLimit({ max: 30, windowMs: 60_000, keyBy: 'ip' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Revoke active refresh token and terminate session',
  })
  @ApiResponse({ status: 200, description: 'Refresh token revoked' })
  async logout(@Body() dto: LogoutDto) {
    return this.authService.logout(dto);
  }
}

