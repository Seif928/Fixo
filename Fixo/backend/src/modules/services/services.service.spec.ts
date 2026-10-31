import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaModule } from '../../prisma/prisma.module';
import { ProfessionalsController } from './professionals.controller';
import { ServicesController } from './services.controller';
import { ServicesModule } from './services.module';

describe('ServicesController & ProfessionalsController (Phase 2 Marketplace API)', () => {
  let servicesController: ServicesController;
  let professionalsController: ProfessionalsController;

  beforeEach(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [PrismaModule, ServicesModule],
    }).compile();

    servicesController = moduleRef.get(ServicesController);
    professionalsController = moduleRef.get(ProfessionalsController);
  });

  it('GET /api/v1/services/categories returns all 6 Fixo categories in EGP', async () => {
    const result = await servicesController.listCategories();
    expect(result.meta.currency).toBe('EGP');
    expect(result.meta.market).toBe('EG');
    expect(result.categories).toHaveLength(6);

    const names = result.categories.map((c) => c.nameEn);
    expect(names).toEqual([
      'AC Maintenance',
      'Plumbing & Leaks',
      'Electrical & Lighting',
      'Deep Home Cleaning',
      'Carpentry & Repairs',
      'Painting & Finishing',
    ]);
    expect(result.categories[0].startingPriceEgp).toBe(450);
    expect(result.categories[1].startingPriceEgp).toBe(280);
    expect(result.categories[2].startingPriceEgp).toBe(250);
  });

  it('GET /api/v1/services supports search, featured, bundle, categoryId, and pagination', async () => {
    const featuredRes = await servicesController.listServices({
      featured: true,
      page: 1,
      limit: 10,
    });
    expect(featuredRes.items).toHaveLength(1);
    expect(featuredRes.items[0].titleEn).toBe('Summer AC Deep Clean & Gas Refill');
    expect(featuredRes.items[0].flatPriceEgp).toBe(350);

    const bundleRes = await servicesController.listServices({
      bundle: true,
      page: 1,
      limit: 10,
    });
    expect(bundleRes.items).toHaveLength(1);
    expect(bundleRes.items[0].titleEn).toBe('Home Safety Inspection');
    expect(bundleRes.items[0].flatPriceEgp).toBe(450);

    const searchRes = await servicesController.listServices({
      search: 'Jotun',
      page: 1,
      limit: 10,
    });
    expect(searchRes.items).toHaveLength(1);
    expect(searchRes.items[0].categorySlug).toBe('painting-finishing');
  });

  it('GET /api/v1/services/:id returns service details or throws 404 NotFoundException', async () => {
    const found = await servicesController.getServiceById('off-ac-deep-clean');
    expect(found.service.flatPriceEgp).toBe(350);
    expect(found.meta.currency).toBe('EGP');

    await expect(
      servicesController.getServiceById('non-existent-service'),
    ).rejects.toThrow(NotFoundException);
  });

  describe('STEP 7: Protected Professional Discovery & Privacy Sanitization', () => {
    it('returns recommended Cairo/Giza pros in EGP with search and zone filters', async () => {
      const allPros = await professionalsController.listProfessionals({
        page: 1,
        limit: 10,
      });
      expect(allPros.items.length).toBeGreaterThanOrEqual(2);
      expect(allPros.items[0].fullNameEn).toBe('Eng. Tarek Mansour');
      expect(allPros.items[0].estimatedPriceEgp).toBe(250);
      expect(allPros.items[1].fullNameEn).toBe('Hassan El-Sayed');
      expect(allPros.items[1].estimatedPriceEgp).toBe(350);

      const searchTarek = await professionalsController.listProfessionals({
        search: 'Electrician',
        page: 1,
        limit: 10,
      });
      expect(searchTarek.items).toHaveLength(1);
      expect(searchTarek.items[0].id).toBe('pro-tarek-01');
    });

    it('strictly omits phone numbers, dossier codes, and synthetic ID numbers from public response', async () => {
      const response = await professionalsController.listProfessionals({
        page: 1,
        limit: 10,
      });

      for (const pro of response.items) {
        const rawPro = pro as unknown as Record<string, unknown>;
        expect(rawPro['phone']).toBeUndefined();
        expect(rawPro['dossierCode']).toBeUndefined();
        expect(rawPro['nationalIdSynthetic']).toBeUndefined();
        expect(rawPro['reviewerNote']).toBeUndefined();
      }
    });

    it('returns genuine empty list when in production or when demo seed is disabled', async () => {
      const originalEnv = process.env.ENABLE_DEMO_SEED;
      try {
        process.env.ENABLE_DEMO_SEED = 'false';
        const emptyResponse = await professionalsController.listProfessionals({
          page: 1,
          limit: 10,
        });
        expect(emptyResponse.items).toEqual([]);
        expect(emptyResponse.meta.total).toBe(0);
      } finally {
        process.env.ENABLE_DEMO_SEED = originalEnv;
      }
    });
  });
});
