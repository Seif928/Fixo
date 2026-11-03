import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Transform } from 'class-transformer';
import { IsEmail, MaxLength } from 'class-validator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminAccessGuard, AdminRequest } from './admin-access.guard';
import { AdminAccessService } from './admin-access.service';
class InviteAdminDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail()
  @MaxLength(254)
  email!: string;
}
@Controller('admin')
@UseGuards(JwtAuthGuard, AdminAccessGuard)
export class AdminAccessController {
  constructor(private readonly access: AdminAccessService) {}
  @Get('me')
  @Header('Cache-Control', 'private, no-store')
  me(@Req() request: AdminRequest) {
    const actor = request.adminActor!;
    return {
      role: actor.role,
      canManageMembers: actor.role === 'OWNER',
      canManageOperations: true,
      needsConfirmation: Date.now() / 1000 - actor.authTime > 900,
    };
  }
  @Get('members')
  @Header('Cache-Control', 'private, no-store')
  members(@Req() request: AdminRequest) {
    return this.access.members(request.adminActor!);
  }
  @Get('summary')
  @Header('Cache-Control', 'private, no-store')
  summary() {
    return this.access.summary();
  }
  @Put('member')
  invite(@Req() request: AdminRequest, @Body() dto: InviteAdminDto) {
    return this.access.invite(request.adminActor!, dto.email);
  }
  @Delete('member')
  revoke(@Req() request: AdminRequest) {
    return this.access.revoke(request.adminActor!);
  }
  @Get('audit')
  @Header('Cache-Control', 'private, no-store')
  audit() {
    return this.access.audit();
  }
}
