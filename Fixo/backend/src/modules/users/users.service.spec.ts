import { BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UsersService } from './users.service';

describe('UsersService (Unit Tests)', () => {
  let service: UsersService;
  let prismaMock: any;

  const mockCustomerId = 'cust-101';

  const mockUser = {
    id: mockCustomerId,
    phone: '+201012345678',
    fullName: 'Salma El-Shazly',
    role: 'CUSTOMER',
  };

  const mockActiveZone = {
    id: 'zone-sheikh-zayed',
    slug: 'sheikh-zayed',
    nameEn: 'Sheikh Zayed, Dist. 9',
    nameAr: 'الشيخ زايد، الحي التاسع',
    governorate: 'Giza',
    isActive: true,
  };

  const mockInactiveZone = {
    id: 'zone-inactive-aswan',
    slug: 'aswan-city',
    nameEn: 'Aswan City',
    nameAr: 'مدينة أسوان',
    governorate: 'Aswan',
    isActive: false,
  };

  const sampleDbAddress = {
    id: 'addr-01',
    userId: mockCustomerId,
    zoneId: 'zone-sheikh-zayed',
    label: 'Palm Hills Villa 14',
    buildingLine: 'Apartment 4B, Building 14',
    districtLine: 'Palm Hills, 6th of October / Sheikh Zayed, Giza',
    gateNotes: 'Private Gate 3',
    latitude: 30.0131,
    longitude: 30.9854,
    isDefault: true,
    createdAt: new Date('2026-11-01T04:00:00.000Z'),
    zone: mockActiveZone,
  };

  beforeEach(() => {
    prismaMock = {
      user: {
        findUnique: jest.fn(),
      },
      coverageZone: {
        findFirst: jest.fn(),
      },
      customerAddress: {
        findMany: jest.fn(),
        create: jest.fn(),
        updateMany: jest.fn(),
      },
      $queryRaw: jest.fn().mockResolvedValue([{ id: mockCustomerId }]),
      $transaction: jest.fn().mockImplementation(async (callback) => {
        return callback(prismaMock);
      }),
      isDatabaseConnected: jest.fn().mockReturnValue(true),
      getStorageMode: jest.fn().mockReturnValue('POSTGRESQL_PRISMA'),
    };

    service = new UsersService(prismaMock as unknown as PrismaService);
  });

  describe('createAddress', () => {
    const validDto: CreateAddressDto = {
      zoneId: 'zone-sheikh-zayed',
      label: 'Palm Hills Villa 14',
      buildingLine: 'Apartment 4B, Building 14',
      districtLine: 'Palm Hills, 6th of October / Sheikh Zayed, Giza',
      gateNotes: 'Private Gate 3',
      latitude: 30.0131,
      longitude: 30.9854,
      isDefault: true,
    };

    it('throws NotFoundException when customer account is not found in database', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(
        service.createAddress(mockCustomerId, validDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws NotFoundException when coverage zone is not found', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(null);

      await expect(
        service.createAddress(mockCustomerId, {
          ...validDto,
          zoneId: 'non-existent-zone',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws BadRequestException when coverage zone is inactive', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(mockInactiveZone);

      await expect(
        service.createAddress(mockCustomerId, {
          ...validDto,
          zoneId: 'zone-inactive-aswan',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws BadRequestException when label is whitespace only', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(mockActiveZone);

      await expect(
        service.createAddress(mockCustomerId, {
          ...validDto,
          label: '   ',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws BadRequestException when buildingLine is whitespace only', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(mockActiveZone);

      await expect(
        service.createAddress(mockCustomerId, {
          ...validDto,
          buildingLine: '   ',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws BadRequestException when districtLine is whitespace only', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(mockActiveZone);

      await expect(
        service.createAddress(mockCustomerId, {
          ...validDto,
          districtLine: '   ',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('creates address with isDefault: true, clears previous default in transaction, and returns formatted response', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(mockActiveZone);
      prismaMock.customerAddress.updateMany.mockResolvedValue({ count: 1 });
      prismaMock.customerAddress.create.mockResolvedValue(sampleDbAddress);

      const res = await service.createAddress(mockCustomerId, validDto);

      // Verify transaction was utilized
      expect(prismaMock.$transaction).toHaveBeenCalledTimes(1);

      // Verify previous default was cleared specifically for this customer
      expect(prismaMock.customerAddress.updateMany).toHaveBeenCalledWith({
        where: {
          userId: mockCustomerId,
          isDefault: true,
        },
        data: {
          isDefault: false,
        },
      });

      // Verify address created with customerId derived from auth
      expect(prismaMock.customerAddress.create).toHaveBeenCalledWith({
        data: {
          userId: mockCustomerId,
          zoneId: 'zone-sheikh-zayed',
          label: 'Palm Hills Villa 14',
          buildingLine: 'Apartment 4B, Building 14',
          districtLine: 'Palm Hills, 6th of October / Sheikh Zayed, Giza',
          gateNotes: 'Private Gate 3',
          latitude: 30.0131,
          longitude: 30.9854,
          isDefault: true,
        },
        include: {
          zone: true,
        },
      });

      expect(res.id).toBe('addr-01');
      expect(res.isDefault).toBe(true);
      expect(res.zone?.slug).toBe('sheikh-zayed');
    });

    it('creates address with isDefault: false without clearing existing default addresses', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(mockActiveZone);
      prismaMock.customerAddress.create.mockResolvedValue({
        ...sampleDbAddress,
        id: 'addr-02',
        isDefault: false,
      });

      const res = await service.createAddress(mockCustomerId, {
        ...validDto,
        isDefault: false,
      });

      expect(prismaMock.customerAddress.updateMany).not.toHaveBeenCalled();
      expect(res.id).toBe('addr-02');
      expect(res.isDefault).toBe(false);
    });

    it('resolves zone when passed by slug instead of UUID', async () => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.coverageZone.findFirst.mockResolvedValue(mockActiveZone);
      prismaMock.customerAddress.create.mockResolvedValue({
        ...sampleDbAddress,
        isDefault: false,
      });

      await service.createAddress(mockCustomerId, {
        ...validDto,
        zoneId: 'sheikh-zayed', // slug passed
        isDefault: false,
      });

      expect(prismaMock.coverageZone.findFirst).toHaveBeenCalledWith({
        where: {
          OR: [{ id: 'sheikh-zayed' }, { slug: 'sheikh-zayed' }],
        },
      });
    });
  });

  describe('findUserAddresses', () => {
    it('returns empty array when database is not connected', async () => {
      prismaMock.isDatabaseConnected.mockReturnValue(false);

      const res = await service.findUserAddresses(mockCustomerId);

      expect(res).toEqual([]);
      expect(prismaMock.customerAddress.findMany).not.toHaveBeenCalled();
    });

    it('returns formatted addresses ordered by isDefault and createdAt descending', async () => {
      prismaMock.isDatabaseConnected.mockReturnValue(true);
      prismaMock.customerAddress.findMany.mockResolvedValue([sampleDbAddress]);

      const res = await service.findUserAddresses(mockCustomerId);

      expect(prismaMock.customerAddress.findMany).toHaveBeenCalledWith({
        where: { userId: mockCustomerId },
        include: { zone: true },
        orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
      });
      expect(res).toHaveLength(1);
      expect(res[0].id).toBe('addr-01');
      expect(res[0].createdAt).toBe('2026-11-01T04:00:00.000Z');
    });
  });
});

