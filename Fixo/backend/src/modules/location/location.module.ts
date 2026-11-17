import { Body, Controller, Module, Post, UseGuards } from '@nestjs/common';
import { IsLatitude, IsLongitude } from 'class-validator';
import { AuthModule } from '../auth/auth.module';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { PrismaModule } from '../../prisma/prisma.module';
import { LocationService } from './location.service';

class ReverseAreaDto {
  @IsLatitude() latitude!: number;
  @IsLongitude() longitude!: number;
}

@Controller('locations')
@UseGuards(JwtAuthGuard)
class LocationController {
  constructor(private readonly service: LocationService) {}
  @Post('reverse')
  reverse(@CurrentUser() user: FixoJwtPayload, @Body() body: ReverseAreaDto) {
    return this.service.reverse(user.sub, body.latitude, body.longitude);
  }
}
@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [LocationController],
  providers: [LocationService],
})
export class LocationModule {}
