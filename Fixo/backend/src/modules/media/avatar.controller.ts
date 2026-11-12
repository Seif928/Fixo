import { Controller, Get, Header, HttpCode, Post, StreamableFile, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { RateLimit, RateLimitGuard } from '../../common/guards/rate-limit.guard';
import { AvatarService, AvatarUpload } from './avatar.service';

@ApiTags('Profile photo')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RateLimitGuard)
@Controller('users/me/avatar')
export class AvatarController {
  constructor(private readonly avatars: AvatarService) {}

  @Post()
  @RateLimit({ max: 10, windowMs: 60_000, keyBy: 'userOrIp' })
  @HttpCode(200)
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { photo: { type: 'string', format: 'binary' } }, required: ['photo'] } })
  @UseInterceptors(FileInterceptor('photo', { limits: { fileSize: 2 * 1024 * 1024, files: 1, fields: 0, parts: 1 } }))
  save(@CurrentUser() user: FixoJwtPayload, @UploadedFile() file: AvatarUpload) {
    return this.avatars.save(user.sub, file);
  }

  @Get()
  @Header('Cache-Control', 'private, no-store')
  @Header('X-Content-Type-Options', 'nosniff')
  async read(@CurrentUser() user: FixoJwtPayload) {
    return new StreamableFile(await this.avatars.read(user.sub), { type: 'image/webp', disposition: 'inline' });
  }
}
