import { HttpException, HttpStatus } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  let controller: HealthController;
  let prismaService: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [PrismaModule],
      controllers: [HealthController],
    }).compile();

    controller = module.get<HealthController>(HealthController);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  it('returns ok status on liveness check (/health)', () => {
    const result = controller.getHealth();
    expect(result.status).toBe('ok');
    expect(result.service).toBe('fixo-backend');
    expect(result.market).toBe('EG');
    expect(result.currency).toBe('EGP');
    expect(result.persistence).toBeDefined();
    expect(typeof result.timestamp).toBe('string');
  });

  it('returns ready on live storage readiness check (/health/ready)', async () => {
    const result = await controller.getReadiness();
    expect(result.status).toBe('ready');
    expect(result.database.ready).toBe(true);
    expect(result.database.storageMode).toBeDefined();
  });

  it('throws HTTP 503 Service Unavailable when storage readiness fails', async () => {
    jest.spyOn(prismaService, 'checkReadiness').mockResolvedValueOnce({
      ready: false,
      storageMode: 'POSTGRESQL_PRISMA',
      reason: 'Database connection check failed',
    });

    await expect(controller.getReadiness()).rejects.toThrow(HttpException);

    try {
      await controller.getReadiness();
    } catch (err) {
      const httpErr = err as HttpException;
      expect(httpErr.getStatus()).toBe(HttpStatus.SERVICE_UNAVAILABLE);
      const res = httpErr.getResponse() as Record<string, unknown>;
      expect(res['status']).toBe('not_ready');
      expect((res['database'] as any)['reason']).toBe('Database connection check failed');
    }
  });
});
