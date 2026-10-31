import { Test, TestingModule } from '@nestjs/testing';
import { PrismaModule } from '../../prisma/prisma.module';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  let controller: HealthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [PrismaModule],
      controllers: [HealthController],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('returns ok status with Egyptian market (EG) and EGP currency', () => {
    const result = controller.getHealth();
    expect(result.status).toBe('ok');
    expect(result.service).toBe('fixo-backend');
    expect(result.market).toBe('EG');
    expect(result.currency).toBe('EGP');
    expect(result.persistence).toBeDefined();
    expect(typeof result.timestamp).toBe('string');
  });
});
