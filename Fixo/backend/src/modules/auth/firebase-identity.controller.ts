import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { FirebaseIdentityService } from './firebase-identity.service';

class FirebaseSessionDto {
  @ApiProperty({ description: 'Signed Firebase ID token for a verified email; never an app-supplied user ID or role.' })
  @IsString()
  @MinLength(20)
  @MaxLength(10000)
  idToken!: string;
}

@ApiTags('auth')
@Controller('auth/firebase')
export class FirebaseIdentityController {
  constructor(private readonly service: FirebaseIdentityService) {}
  @Post('session')
  @HttpCode(200)
  exchange(@Body() dto: FirebaseSessionDto) { return this.service.exchange(dto.idToken); }
}
