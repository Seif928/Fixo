import {
  Controller,
  Get,
  NotFoundException,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService, AuthenticatedUserProfile } from '../auth/auth.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(
    private readonly authService: AuthService,
    private readonly prisma: PrismaService,
  ) {}

  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CUSTOMER, UserRole.PRO, UserRole.ADMIN)
  @ApiOperation({
    summary: 'Get authenticated user profile (protected by JWT + RBAC)',
  })
  @ApiResponse({ status: 200, description: 'Authenticated user profile' })
  @ApiResponse({ status: 401, description: 'Missing or invalid Bearer token' })
  async getMe(@CurrentUser() currentUser: FixoJwtPayload): Promise<{
    user: AuthenticatedUserProfile;
    storageMode: string;
  }> {
    const profile = await this.authService.findUserById(currentUser.sub);
    if (!profile) {
      throw new NotFoundException('Authenticated user profile not found.');
    }
    const addresses = this.prisma.isDatabaseConnected()
      ? await this.prisma.customerAddress.findMany({
          where: { userId: currentUser.sub },
          include: { zone: true },
          orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
        })
      : [];

    return {
      user: {
        ...profile,
        addresses,
      },
      storageMode: this.prisma.getStorageMode(),
    };
  }
}

