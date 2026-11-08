import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { FirebaseIdentityService } from './firebase-identity.service';

class FirebaseSessionDto {
  @ApiProperty({ description: 'Signed Firebase ID token for a verified email; never an app-supplied user ID or role.' })
  @IsString()
  @MinLength(20)
  @MaxLength(10000)
  idToken!: string;
}

class AppleIdentitySessionDto {
  @ApiPropertyOptional({ description: 'Optional Firebase Apple OAuth ID token' })
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  idToken?: string;

  @ApiPropertyOptional({ description: 'Apple ID email or Private Relay email' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  email?: string;

  @ApiPropertyOptional({ description: 'Apple ID display name' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  fullName?: string;

  @ApiPropertyOptional({ description: 'Use Apple Private Relay (Hide My Email)' })
  @IsOptional()
  @IsBoolean()
  hideEmail?: boolean;
}

@ApiTags('auth')
@Controller('auth/firebase')
export class FirebaseIdentityController {
  constructor(private readonly service: FirebaseIdentityService) {}
  @Post('session')
  @HttpCode(200)
  exchange(@Body() dto: FirebaseSessionDto) { return this.service.exchange(dto.idToken); }

  @Post('apple')
  @HttpCode(200)
  exchangeApple(@Body() dto: AppleIdentitySessionDto) {
    return this.service.exchangeApple(dto);
  }
}
