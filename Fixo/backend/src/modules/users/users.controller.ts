import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  NotFoundException,
  Post,
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
import {
  CustomerAddressListResponse,
  CustomerAddressResponse,
} from './dto/address-response.dto';
import { CreateAddressDto } from './dto/create-address.dto';
import { UsersService } from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(
    private readonly authService: AuthService,
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
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
    const addresses = await this.usersService.findUserAddresses(currentUser.sub);

    return {
      user: {
        ...profile,
        addresses,
      },
      storageMode: this.prisma.getStorageMode(),
    };
  }

  @Post('me/addresses')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CUSTOMER, UserRole.PRO, UserRole.ADMIN)
  @ApiOperation({
    summary: 'Create a new delivery address for the authenticated customer',
  })
  @ApiResponse({
    status: 201,
    description: 'Address created successfully',
    type: CustomerAddressResponse,
  })
  @ApiResponse({
    status: 400,
    description: 'Validation failed or coverage zone is inactive',
  })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid Bearer token',
  })
  @ApiResponse({
    status: 404,
    description: 'Coverage zone or customer account not found',
  })
  async createAddress(
    @CurrentUser() currentUser: FixoJwtPayload,
    @Body() dto: CreateAddressDto,
  ): Promise<CustomerAddressResponse> {
    // userId is derived strictly from the authenticated JWT token (never trusted from body)
    return this.usersService.createAddress(currentUser.sub, dto);
  }

  @Get('me/addresses')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CUSTOMER, UserRole.PRO, UserRole.ADMIN)
  @ApiOperation({
    summary: 'List all saved addresses for the authenticated customer',
  })
  @ApiResponse({
    status: 200,
    description: 'List of customer saved delivery addresses',
    type: CustomerAddressListResponse,
  })
  @ApiResponse({
    status: 401,
    description: 'Missing or invalid Bearer token',
  })
  async getAddresses(
    @CurrentUser() currentUser: FixoJwtPayload,
  ): Promise<CustomerAddressListResponse> {
    const addresses = await this.usersService.findUserAddresses(currentUser.sub);
    return {
      addresses,
      total: addresses.length,
    };
  }
}

