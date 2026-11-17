import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, Matches } from 'class-validator';

export class RequestOtpDto {
  @ApiProperty({
    example: '+201023456789',
    description: 'Egyptian mobile number (+20 10/11/12/15 followed by 8 digits)',
  })
  @IsString()
  @IsNotEmpty({ message: 'Egyptian mobile number is required.' })
  @Matches(/^(\+?20|0020|0)?\s*1[0125][\d\s\-]{8,11}$/, {
    message:
      'Invalid Egyptian mobile number. Must begin with +20 (or 010, 011, 012, 015) and have 10 digits.',
  })
  phone!: string;
}

export class VerifyOtpDto {
  @ApiProperty({
    example: '+201023456789',
    description: 'Egyptian mobile number used to request the OTP challenge',
  })
  @IsString()
  @IsNotEmpty({ message: 'Egyptian mobile number is required.' })
  @Matches(/^(\+?20|0020|0)?\s*1[0125][\d\s\-]{8,11}$/, {
    message:
      'Invalid Egyptian mobile number. Must begin with +20 (or 010, 011, 012, 015) and have 10 digits.',
  })
  phone!: string;

  @ApiProperty({
    example: '482910',
    description: 'Six-digit SMS verification code',
  })
  @IsString()
  @IsNotEmpty({ message: '6-digit verification code is required.' })
  @Matches(/^\d{6}$/, {
    message: 'OTP verification code must be exactly 6 numeric digits.',
  })
  code!: string;

  @ApiPropertyOptional({
    example: 'c72e71f2-1d6b-4a8e-9b1c-8477d0b3e111',
    description: 'Optional OTP challenge identifier returned from /auth/otp/request',
  })
  @IsOptional()
  @IsString()
  challengeId?: string;
}

export class RefreshTokenDto {
  @ApiProperty({
    description: 'Active refresh token to rotate',
  })
  @IsString()
  @IsNotEmpty({ message: 'Refresh token is required.' })
  refreshToken!: string;
}

export class LogoutDto {
  @ApiProperty({
    description: 'Refresh token to revoke',
  })
  @IsString()
  @IsNotEmpty({ message: 'Refresh token is required.' })
  refreshToken!: string;
}

