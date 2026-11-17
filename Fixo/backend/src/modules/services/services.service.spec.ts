import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { ProVerificationStatus } from '@prisma/client';
import { InMemoryStoreService } from '../../prisma/in-memory-store.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import { ProfessionalsController } from './professionals.controller';
import { ServicesController } from './services.controller';
import { ServicesModule } from './services.module';

describe('ServicesController & ProfessionalsController (Phase 2 Marketplace API)', () => {
  let servicesController: ServicesController;
  let professionalsController: ProfessionalsController;
  let memoryStore: InMemoryStoreService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [PrismaModule, ServicesModule],
    }).compile();

    servicesController = moduleRef.get(ServicesController);
    professionalsController = moduleRef.get(ProfessionalsController);
    memoryStore = moduleRef.get(InMemoryStoreService);
    prisma = moduleRef.get(PrismaService);
    memoryStore.resetToSeedState();
  });

  it('GET /api/v1/services/categories returns all 21 Fixo categories in EGP', async () => {
    const result = await servicesController.listCategories();
    expect(result.meta.currency).toBe('EGP');
    expect(result.meta.market).toBe('EG');
    expect(result.categories).toHaveLength(21);

    const names = result.categories.slice(0, 6).map((c) => c.nameEn);
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
    expect(featuredRes.items[0].titleEn).toBe(
      'Summer AC Deep Clean & Gas Refill',
    );
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

  describe('Database-Connected Catalog Isolation (Regression Tests)', () => {
    let getCategoriesSpy: jest.SpyInstance;
    let getZonesSpy: jest.SpyInstance;
    let getOfferingsSpy: jest.SpyInstance;
    let getProfessionalsSpy: jest.SpyInstance;

    beforeEach(() => {
      jest.spyOn(prisma, 'isDatabaseConnected').mockReturnValue(true);
      jest.spyOn(prisma, 'getStorageMode').mockReturnValue('POSTGRESQL_PRISMA');

      jest.spyOn(prisma.serviceCategory, 'findMany').mockResolvedValue([]);
      jest.spyOn(prisma.coverageZone, 'findMany').mockResolvedValue([]);
      jest.spyOn(prisma.serviceOffering, 'findMany').mockResolvedValue([]);
      jest.spyOn(prisma.serviceOffering, 'count').mockResolvedValue(0);
      jest.spyOn(prisma.proProfile, 'findMany').mockResolvedValue([]);

      getCategoriesSpy = jest.spyOn(memoryStore, 'getCategories');
      getZonesSpy = jest.spyOn(memoryStore, 'getZones');
      getOfferingsSpy = jest.spyOn(memoryStore, 'getOfferings');
      getProfessionalsSpy = jest.spyOn(memoryStore, 'getProfessionals');
    });

    it('filters by actual coverage relations, never profile marketing text', async () => {
      const row = (id: string, covered: string[]) => ({
        id,
        user: { fullName: 'Technician' },
        primaryCategoryId: 'cat-plumbing',
        primaryCategory: { slug: 'plumbing' },
        primaryZone: null,
        coverageZones: covered.map((slug) => ({
          slug,
          governorate: slug === 'giza' ? 'Giza' : 'Cairo',
        })),
        zonesLabelEn: 'Everywhere in Egypt, Alexandria',
        ratingAvg: 5,
        reviewsCount: 0,
        completedJobsCount: 0,
        acceptanceRatePct: 0,
        estimatedPriceEgp: 200,
        isOnline: false,
      });
      jest
        .spyOn(prisma.proProfile, 'findMany')
        .mockResolvedValue([
          row('real-giza', ['giza']),
          row('misleading-label', ['cairo']),
        ] as any);
      jest
        .spyOn(prisma.coverageZone, 'findUnique')
        .mockResolvedValue({ slug: 'giza', governorate: 'Giza' } as any);
      const result = await professionalsController.listProfessionals({
        zone: 'giza',
      });
      expect(result.items.map((p) => p.id)).toEqual(['real-giza']);
      expect(result.items[0].specialtyEn).not.toContain('Certified');
      expect(result.items[0].primaryZoneSlug).toBe('');
      expect(result.items[0]).toHaveProperty(
        'primaryCategoryId',
        'cat-plumbing',
      );
      expect(result.items[0].ratingAvg).toBe(0);
      expect(
        (
          await professionalsController.listProfessionals({
            categoryId: 'cat-plumbing',
          })
        ).items,
      ).toHaveLength(2);
    });

    it('does not turn district-only approval into whole-governorate coverage', async () => {
      jest
        .spyOn(prisma.coverageZone, 'findUnique')
        .mockResolvedValue({
          slug: 'giza',
          governorate: 'Giza',
          isActive: true,
        } as any);
      jest.spyOn(prisma.proProfile, 'findMany').mockResolvedValue([
        {
          id: 'district-only',
          user: { fullName: 'Technician' },
          primaryCategory: { slug: 'plumbing' },
          primaryZone: null,
          coverageZones: [
            { slug: 'sheikh-zayed', governorate: 'Giza', isActive: true },
          ],
          reviewsCount: 0,
          ratingAvg: 0,
        },
      ] as any);
      expect(
        (await professionalsController.listProfessionals({ zone: 'giza' }))
          .items,
      ).toEqual([]);
    });

    it('returns empty categories and zones exclusively from DB without reading demo data', async () => {
      const result = await servicesController.listCategories();

      expect(result.categories).toEqual([]);
      expect(result.zones).toEqual([]);
      expect(result.meta.total).toBe(0);
      expect(result.meta.databaseConnected).toBe(true);
      expect(result.meta.storageMode).toBe('POSTGRESQL_PRISMA');

      expect(getCategoriesSpy).not.toHaveBeenCalled();
      expect(getZonesSpy).not.toHaveBeenCalled();
      expect(prisma.serviceCategory.findMany).toHaveBeenCalledTimes(1);
      expect(prisma.coverageZone.findMany).toHaveBeenCalledTimes(1);
    });

    it('returns empty services list exclusively from DB without reading demo data', async () => {
      const result = await servicesController.listServices({
        page: 1,
        limit: 20,
      });

      expect(result.items).toEqual([]);
      expect(result.meta.total).toBe(0);
      expect(result.meta.totalPages).toBe(1);
      expect(result.meta.databaseConnected).toBe(true);
      expect(result.meta.storageMode).toBe('POSTGRESQL_PRISMA');

      expect(getOfferingsSpy).not.toHaveBeenCalled();
      expect(prisma.serviceOffering.findMany).toHaveBeenCalledTimes(1);
    });

    it('throws NotFoundException on getServiceById when DB has no matching record without falling back to demo data', async () => {
      await expect(
        servicesController.getServiceById('off-ac-deep-clean'),
      ).rejects.toThrow(NotFoundException);

      expect(getOfferingsSpy).not.toHaveBeenCalled();
      expect(prisma.serviceOffering.findMany).toHaveBeenCalledTimes(1);
    });

    it('returns empty professionals list exclusively from DB without reading demo data', async () => {
      const result = await professionalsController.listProfessionals({
        page: 1,
        limit: 20,
      });

      expect(result.items).toEqual([]);
      expect(result.meta.total).toBe(0);
      expect(result.meta.totalPages).toBe(1);
      expect(result.meta.databaseConnected).toBe(true);
      expect(result.meta.storageMode).toBe('POSTGRESQL_PRISMA');

      expect(getProfessionalsSpy).not.toHaveBeenCalled();
      expect(prisma.proProfile.findMany).toHaveBeenCalledTimes(1);
    });

    it('never reads demo data when Prisma is connected, even when ENABLE_DEMO_SEED=true', async () => {
      const originalEnv = process.env.ENABLE_DEMO_SEED;
      try {
        process.env.ENABLE_DEMO_SEED = 'true';

        const catRes = await servicesController.listCategories();
        expect(catRes.categories).toEqual([]);
        expect(catRes.zones).toEqual([]);
        expect(getCategoriesSpy).not.toHaveBeenCalled();

        const servRes = await servicesController.listServices({
          page: 1,
          limit: 10,
        });
        expect(servRes.items).toEqual([]);
        expect(getOfferingsSpy).not.toHaveBeenCalled();

        const proRes = await professionalsController.listProfessionals({
          page: 1,
          limit: 10,
        });
        expect(proRes.items).toEqual([]);
        expect(getProfessionalsSpy).not.toHaveBeenCalled();
      } finally {
        process.env.ENABLE_DEMO_SEED = originalEnv;
      }
    });

    it('returns empty results when Prisma is connected and ENABLE_DEMO_SEED=false', async () => {
      const originalEnv = process.env.ENABLE_DEMO_SEED;
      try {
        process.env.ENABLE_DEMO_SEED = 'false';

        const catRes = await servicesController.listCategories();
        expect(catRes.categories).toEqual([]);
        expect(catRes.zones).toEqual([]);

        const servRes = await servicesController.listServices({
          page: 1,
          limit: 10,
        });
        expect(servRes.items).toEqual([]);

        const proRes = await professionalsController.listProfessionals({
          page: 1,
          limit: 10,
        });
        expect(proRes.items).toEqual([]);

        expect(getCategoriesSpy).not.toHaveBeenCalled();
        expect(getOfferingsSpy).not.toHaveBeenCalled();
        expect(getProfessionalsSpy).not.toHaveBeenCalled();
      } finally {
        process.env.ENABLE_DEMO_SEED = originalEnv;
      }
    });
  });
});
