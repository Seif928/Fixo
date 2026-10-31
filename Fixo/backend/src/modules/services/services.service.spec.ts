import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { ProVerificationStatus } from '@prisma/client';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { ProfessionalsController } from './professionals.controller';
import { ServicesController } from './services.controller';
import { ServicesModule } from './services.module';

describe('ServicesController & ProfessionalsController (Phase 2 Marketplace API)', () => {
  let servicesController: ServicesController;
  let professionalsController: ProfessionalsController;
  let memoryStore: InMemoryStoreService;

  beforeEach(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [PrismaModule, ServicesModule],
    }).compile();

    servicesController = moduleRef.get(ServicesController);
    professionalsController = moduleRef.get(ProfessionalsController);
    memoryStore = moduleRef.get(InMemoryStoreService);
    memoryStore.resetToSeedState();
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

    it('strictly excludes DRAFT, PENDING_REVIEW, ACTION_REQUIRED, and SUSPENDED pro profiles', async () => {
      // Inject unapproved negative fixtures into store
      (memoryStore as any).professionals.push(
        {
          id: 'pro-draft-test',
          userId: 'u-draft-test',
          fullNameEn: 'Unapproved Draft Tech',
          fullNameAr: 'فني مسودة',
          phone: '+20109990001',
          dossierCode: 'DOS-DRAFT-01',
          verificationStatus: ProVerificationStatus.DRAFT,
          primaryCategoryId: 'cat-ac-maintenance',
          primaryCategorySlug: 'ac-maintenance',
          primaryZoneSlug: 'sheikh-zayed',
          specialtyEn: 'Draft',
          specialtyAr: 'مسودة',
          zonesLabelEn: 'Cairo',
          zonesLabelAr: 'القاهرة',
          ratingAvg: 5.0,
          reviewsCount: 0,
          completedJobsCount: 0,
          acceptanceRatePct: 100,
          estimatedPriceEgp: 200,
          badgeEn: null,
          badgeAr: null,
          badgeVariant: null,
          transportMode: 'MOTORCYCLE',
          experienceTier: 'JUNIOR_1_2Y',
          isOnline: true,
        },
        {
          id: 'pro-pending-test',
          userId: 'u-pending-test',
          fullNameEn: 'Pending Review Tech',
          fullNameAr: 'فني قيد المراجعة',
          phone: '+20109990002',
          dossierCode: 'DOS-PENDING-02',
          verificationStatus: ProVerificationStatus.PENDING_REVIEW,
          primaryCategoryId: 'cat-ac-maintenance',
          primaryCategorySlug: 'ac-maintenance',
          primaryZoneSlug: 'sheikh-zayed',
          specialtyEn: 'Pending',
          specialtyAr: 'قيد المراجعة',
          zonesLabelEn: 'Cairo',
          zonesLabelAr: 'القاهرة',
          ratingAvg: 5.0,
          reviewsCount: 0,
          completedJobsCount: 0,
          acceptanceRatePct: 100,
          estimatedPriceEgp: 200,
          badgeEn: null,
          badgeAr: null,
          badgeVariant: null,
          transportMode: 'MOTORCYCLE',
          experienceTier: 'JUNIOR_1_2Y',
          isOnline: true,
        },
        {
          id: 'pro-suspended-test',
          userId: 'u-suspended-test',
          fullNameEn: 'Suspended Tech',
          fullNameAr: 'فني موقوف',
          phone: '+20109990003',
          dossierCode: 'DOS-SUSPENDED-03',
          verificationStatus: ProVerificationStatus.SUSPENDED,
          primaryCategoryId: 'cat-ac-maintenance',
          primaryCategorySlug: 'ac-maintenance',
          primaryZoneSlug: 'sheikh-zayed',
          specialtyEn: 'Suspended',
          specialtyAr: 'موقوف',
          zonesLabelEn: 'Cairo',
          zonesLabelAr: 'القاهرة',
          ratingAvg: 2.0,
          reviewsCount: 5,
          completedJobsCount: 2,
          acceptanceRatePct: 40,
          estimatedPriceEgp: 200,
          badgeEn: null,
          badgeAr: null,
          badgeVariant: null,
          transportMode: 'MOTORCYCLE',
          experienceTier: 'JUNIOR_1_2Y',
          isOnline: false,
        },
      );

      const response = await professionalsController.listProfessionals({
        page: 1,
        limit: 50,
      });

      const returnedIds = response.items.map((p) => p.id);
      expect(returnedIds).not.toContain('pro-draft-test');
      expect(returnedIds).not.toContain('pro-pending-test');
      expect(returnedIds).not.toContain('pro-suspended-test');
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
