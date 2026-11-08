import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { ExecutionContext } from '@nestjs/common';
import { RolesGuard } from '../auth/guards/roles.guard';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { CreateAddressDto } from './dto/create-address.dto';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

describe('UsersController (Unit Tests)', () => {
  it('lets a verified professional manage their own customer addresses', () => {
    const guard = new RolesGuard(new Reflector());
    for (const handler of [UsersController.prototype.createAddress, UsersController.prototype.getAddresses]) {
      const context = {
        getClass: () => UsersController, getHandler: () => handler,
        switchToHttp: () => ({ getRequest: () => ({ user: { role: UserRole.PRO } }) }),
      } as unknown as ExecutionContext;
      expect(guard.canActivate(context)).toBe(true);
    }
  });
  let controller: UsersController;
  let authServiceMock: Partial<Record<keyof AuthService, jest.Mock>>;
  let usersServiceMock: Partial<Record<keyof UsersService, jest.Mock>>;
  let prismaMock: Partial<Record<keyof PrismaService, jest.Mock>>;

  const mockCustomerJwt: FixoJwtPayload = {
    sub: 'user-cust-101',
    phone: '+201012345678',
    role: UserRole.CUSTOMER,
    type: 'access',
    jti: 'jti-cust-1',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 900,
  };

  const sampleAddress = {
    id: 'addr-01',
    userId: 'user-cust-101',
    zoneId: 'zone-sheikh-zayed',
    label: 'Palm Hills Villa 14',
    buildingLine: 'Apartment 4B, Building 14',
    districtLine: 'Palm Hills, 6th of October / Sheikh Zayed, Giza',
    gateNotes: 'Private Gate 3',
    latitude: 30.0131,
    longitude: 30.9854,
    isDefault: true,
    createdAt: '2026-11-01T04:00:00.000Z',
    zone: {
      id: 'zone-sheikh-zayed',
      slug: 'sheikh-zayed',
      nameEn: 'Sheikh Zayed, Dist. 9',
      nameAr: 'الشيخ زايد، الحي التاسع',
      governorate: 'Giza',
      isActive: true,
    },
  };

  beforeEach(async () => {
    authServiceMock = {
      findUserById: jest.fn(),
    };

    usersServiceMock = {
      createAddress: jest.fn(),
      findUserAddresses: jest.fn(),
      formatAddressResponse: jest.fn(),
      getStorageMode: jest.fn().mockReturnValue('POSTGRESQL_PRISMA'),
    };

    prismaMock = {
      getStorageMode: jest.fn().mockReturnValue('POSTGRESQL_PRISMA'),
      isDatabaseConnected: jest.fn().mockReturnValue(true),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: AuthService,
          useValue: authServiceMock,
        },
        {
          provide: UsersService,
          useValue: usersServiceMock,
        },
        {
          provide: PrismaService,
          useValue: prismaMock,
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
  });

  describe('GET /users/me', () => {
    it('returns authenticated customer profile with formatted addresses', async () => {
      authServiceMock.findUserById!.mockResolvedValue({
        id: 'user-cust-101',
        phone: '+201012345678',
        fullName: 'Salma El-Shazly',
        role: UserRole.CUSTOMER,
        preferredLocale: 'en',
      });
      usersServiceMock.findUserAddresses!.mockResolvedValue([sampleAddress]);

      const res = await controller.getMe(mockCustomerJwt);

      expect(authServiceMock.findUserById).toHaveBeenCalledWith('user-cust-101');
      expect(usersServiceMock.findUserAddresses).toHaveBeenCalledWith(
        'user-cust-101',
      );
      expect(res.user.id).toBe('user-cust-101');
      expect(res.user.addresses).toEqual([sampleAddress]);
      expect(res.storageMode).toBe('POSTGRESQL_PRISMA');
    });

    it('throws NotFoundException when authenticated user profile does not exist', async () => {
      authServiceMock.findUserById!.mockResolvedValue(null);

      await expect(controller.getMe(mockCustomerJwt)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('POST /users/me/addresses', () => {
    it('derives userId exclusively from JWT sub and forwards DTO to usersService.createAddress', async () => {
      const dto: CreateAddressDto = {
        zoneId: 'zone-sheikh-zayed',
        label: 'Palm Hills Villa 14',
        buildingLine: 'Apartment 4B, Building 14',
        districtLine: 'Palm Hills, 6th of October / Sheikh Zayed, Giza',
        gateNotes: 'Private Gate 3',
        isDefault: true,
      };

      usersServiceMock.createAddress!.mockResolvedValue(sampleAddress);

      const res = await controller.createAddress(mockCustomerJwt, dto);

      // Verify that currentUser.sub ('user-cust-101') was passed as the owner ID
      expect(usersServiceMock.createAddress).toHaveBeenCalledWith(
        'user-cust-101',
        dto,
      );
      expect(res).toEqual(sampleAddress);
    });

    it('ignores client-supplied rogue userId and enforces authenticated sub', async () => {
      const rogueDto: any = {
        userId: 'rogue-attacker-user-id',
        zoneId: 'zone-sheikh-zayed',
        label: 'Attacker Address',
        buildingLine: 'Bldg 1',
        districtLine: 'Dist 1',
        isDefault: true,
      };

      usersServiceMock.createAddress!.mockResolvedValue(sampleAddress);

      await controller.createAddress(mockCustomerJwt, rogueDto);

      // Must be called with mockCustomerJwt.sub, NOT rogue-attacker-user-id
      expect(usersServiceMock.createAddress).toHaveBeenCalledWith(
        'user-cust-101',
        rogueDto,
      );
      expect(usersServiceMock.createAddress).not.toHaveBeenCalledWith(
        'rogue-attacker-user-id',
        expect.anything(),
      );
    });
  });

  describe('GET /users/me/addresses', () => {
    it('returns address list and total count for authenticated user', async () => {
      usersServiceMock.findUserAddresses!.mockResolvedValue([sampleAddress]);

      const res = await controller.getAddresses(mockCustomerJwt);

      expect(usersServiceMock.findUserAddresses).toHaveBeenCalledWith(
        'user-cust-101',
      );
      expect(res.addresses).toEqual([sampleAddress]);
      expect(res.total).toBe(1);
    });
  });
});

