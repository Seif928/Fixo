import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { ProVerificationStatus, TransportMode, UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { ProService } from './pro.service';

describe('ProService (Unit Tests)', () => {
  let service: ProService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      isDatabaseConnected: jest.fn().mockReturnValue(false),
      coverageZone: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
      },
      serviceCategory: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
      },
      serviceSubSkill: {
        findMany: jest.fn(),
        count: jest.fn().mockResolvedValue(18),
        upsert: jest.fn().mockResolvedValue({ id: 'existing-skill' }),
      },
      user: {
        update: jest.fn(),
      },
      proProfile: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        update: jest.fn(),
      },
      proVerificationDocument: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      jobOffer: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
        count: jest.fn(),
      },
      booking: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
      },
      bookingStatusEvent: {
        count: jest.fn(),
        create: jest.fn(),
      },
      paymentRecord: {
        update: jest.fn(),
      },
      $transaction: jest.fn(async (cb) => cb(prismaMock)),
    };

    service = new ProService(prismaMock as unknown as PrismaService);
  });

  it('returns fallback catalog options when database is disconnected', async () => {
    const options = await service.getCatalogOptions();
    expect(options.categories.length).toBeGreaterThanOrEqual(6);
    expect(options.zones.length).toBeGreaterThan(0);
    expect(options.transportModes).toContain(TransportMode.MOTORCYCLE);
  });

  it('reads the catalog without overwriting an administrator custom skill', async () => {
    prismaMock.isDatabaseConnected.mockReturnValue(true);
    prismaMock.serviceSubSkill.count.mockResolvedValue(0);
    prismaMock.serviceCategory.findUnique.mockResolvedValue({
      id: 'custom-category',
    });
    prismaMock.serviceCategory.findMany.mockResolvedValue([
      {
        id: 'custom-category',
        subSkills: [{ id: 'custom-skill', nameEn: 'Owner custom label' }],
      },
    ]);
    prismaMock.coverageZone.findMany.mockResolvedValue([]);
    const result = await service.getCatalogOptions();
    expect(result.categories[0].subSkills[0].nameEn).toBe('Owner custom label');
    expect(prismaMock.serviceSubSkill.upsert).not.toHaveBeenCalled();
  });

  it('rejects non-14-digit synthetic National ID on Screen 11', async () => {
    await expect(
      service.upsertPersonalDetails('user-1', {
        nationalIdSynthetic: '12345',
        primaryZoneId: 'zone-new-cairo',
        transportMode: TransportMode.MOTORCYCLE,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects adminReviewProProfile when caller role is not ADMIN', async () => {
    await expect(
      service.adminReviewProProfile('user-1', UserRole.PRO, 'pro-1', {
        status: 'APPROVED',
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('cannot approve a dossier that lacks the three required documents', async () => {
    const profile = {
      id: 'pro-1',
      userId: 'user-1',
      documents: [],
      coverageZones: [],
      verificationStatus: ProVerificationStatus.PENDING_REVIEW,
    };
    prismaMock.proProfile.findUnique.mockResolvedValue(profile);
    prismaMock.proProfile.update.mockResolvedValue({
      ...profile,
      verificationStatus: ProVerificationStatus.APPROVED,
    });
    await expect(
      service.adminReviewProProfile('reviewer-1', UserRole.ADMIN, 'pro-1', {
        status: 'APPROVED',
      }),
    ).rejects.toThrow(BadRequestException);
    expect(prismaMock.proProfile.update).not.toHaveBeenCalled();
  });

  it('locks reviewed identity fields until a reviewer requests corrections', async () => {
    prismaMock.coverageZone.findUnique.mockResolvedValue({
      id: 'zone-1',
      isActive: true,
    });
    prismaMock.proProfile.findUnique.mockResolvedValue({
      id: 'pro-1',
      userId: 'user-1',
      verificationStatus: ProVerificationStatus.APPROVED,
    });
    await expect(
      service.upsertPersonalDetails('user-1', {
        fullName: 'Changed name',
        nationalIdSynthetic: '12345678901234',
        primaryZoneId: 'zone-1',
        transportMode: TransportMode.MOTORCYCLE,
      }),
    ).rejects.toThrow(ForbiddenException);
    expect(prismaMock.user.update).not.toHaveBeenCalled();
    expect(prismaMock.proProfile.upsert).not.toHaveBeenCalled();
  });

  it('rejects availability toggle when ProProfile is not APPROVED', async () => {
    prismaMock.proProfile.findUnique.mockResolvedValue({
      id: 'pro-1',
      userId: 'user-1',
      verificationStatus: ProVerificationStatus.PENDING_REVIEW,
    });

    await expect(
      service.updateAvailability('user-1', { isOnline: true }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('throws NotFoundException when getting status for non-existent ProProfile', async () => {
    prismaMock.proProfile.findUnique.mockResolvedValue(null);

    await expect(service.getVerificationStatus('user-1')).rejects.toThrow(
      NotFoundException,
    );
  });
});
