import { PrismaClient, UserRole } from '@prisma/client';
import {
  DEFAULT_DEMO_CUSTOMER,
  EGYPT_COVERAGE_ZONES,
  EGYPT_PROFESSIONALS,
  EGYPT_SERVICE_CATEGORIES,
  EGYPT_SERVICE_OFFERINGS,
  EGYPT_SERVICE_SUB_SKILLS,
} from '../src/prisma/egypt-demo-seed.data';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  for (const zone of EGYPT_COVERAGE_ZONES) {
    await prisma.coverageZone.upsert({
      where: { slug: zone.slug },
      update: {
        nameEn: zone.nameEn,
        nameAr: zone.nameAr,
        governorate: zone.governorate,
        isActive: zone.isActive,
      },
      create: {
        id: zone.id,
        slug: zone.slug,
        nameEn: zone.nameEn,
        nameAr: zone.nameAr,
        governorate: zone.governorate,
        isActive: zone.isActive,
      },
    });
  }

  for (const category of EGYPT_SERVICE_CATEGORIES) {
    await prisma.serviceCategory.upsert({
      where: { slug: category.slug },
      update: {
        nameEn: category.nameEn,
        nameAr: category.nameAr,
        subtitleEn: category.subtitleEn,
        subtitleAr: category.subtitleAr,
        iconName: category.iconName,
        startingPriceEgp: category.startingPriceEgp,
        sortOrder: category.sortOrder,
        isActive: category.isActive,
      },
      create: {
        id: category.id,
        slug: category.slug,
        nameEn: category.nameEn,
        nameAr: category.nameAr,
        subtitleEn: category.subtitleEn,
        subtitleAr: category.subtitleAr,
        iconName: category.iconName,
        startingPriceEgp: category.startingPriceEgp,
        sortOrder: category.sortOrder,
        isActive: category.isActive,
      },
    });
  }

  for (const subSkill of EGYPT_SERVICE_SUB_SKILLS) {
    await prisma.serviceSubSkill.upsert({
      where: { slug: subSkill.slug },
      update: {
        categoryId: subSkill.categoryId,
        nameEn: subSkill.nameEn,
        nameAr: subSkill.nameAr,
      },
      create: {
        id: subSkill.id,
        categoryId: subSkill.categoryId,
        slug: subSkill.slug,
        nameEn: subSkill.nameEn,
        nameAr: subSkill.nameAr,
      },
    });
  }

  for (const offering of EGYPT_SERVICE_OFFERINGS) {
    await prisma.serviceOffering.upsert({
      where: { slug: offering.slug },
      update: {
        categoryId: offering.categoryId,
        titleEn: offering.titleEn,
        titleAr: offering.titleAr,
        descriptionEn: offering.descriptionEn,
        descriptionAr: offering.descriptionAr,
        badgeEn: offering.badgeEn,
        badgeAr: offering.badgeAr,
        providerTagEn: offering.providerTagEn,
        providerTagAr: offering.providerTagAr,
        baseInspectionEgp: offering.baseInspectionEgp,
        serviceFeeEgp: offering.serviceFeeEgp,
        flatPriceEgp: offering.flatPriceEgp,
        estimatedDurationMins: offering.estimatedDurationMins,
        isSeasonalPromo: offering.isSeasonalPromo,
        isBundle: offering.isBundle,
      },
      create: {
        id: offering.id,
        categoryId: offering.categoryId,
        slug: offering.slug,
        titleEn: offering.titleEn,
        titleAr: offering.titleAr,
        descriptionEn: offering.descriptionEn,
        descriptionAr: offering.descriptionAr,
        badgeEn: offering.badgeEn,
        badgeAr: offering.badgeAr,
        providerTagEn: offering.providerTagEn,
        providerTagAr: offering.providerTagAr,
        baseInspectionEgp: offering.baseInspectionEgp,
        serviceFeeEgp: offering.serviceFeeEgp,
        flatPriceEgp: offering.flatPriceEgp,
        estimatedDurationMins: offering.estimatedDurationMins,
        isSeasonalPromo: offering.isSeasonalPromo,
        isBundle: offering.isBundle,
      },
    });
  }

  await prisma.user.upsert({
    where: { phone: DEFAULT_DEMO_CUSTOMER.phone },
    update: {
      fullName: DEFAULT_DEMO_CUSTOMER.fullName,
      role: UserRole.CUSTOMER,
      rewardPoints: DEFAULT_DEMO_CUSTOMER.rewardPoints,
    },
    create: {
      id: DEFAULT_DEMO_CUSTOMER.id,
      phone: DEFAULT_DEMO_CUSTOMER.phone,
      fullName: DEFAULT_DEMO_CUSTOMER.fullName,
      email: DEFAULT_DEMO_CUSTOMER.email,
      role: UserRole.CUSTOMER,
      preferredLocale: DEFAULT_DEMO_CUSTOMER.preferredLocale,
      arrivalAlertsEnabled: DEFAULT_DEMO_CUSTOMER.arrivalAlertsEnabled,
      rewardPoints: DEFAULT_DEMO_CUSTOMER.rewardPoints,
    },
  });

  for (const pro of EGYPT_PROFESSIONALS) {
    const user = await prisma.user.upsert({
      where: { phone: pro.phone },
      update: {
        fullName: pro.fullNameEn,
        role: UserRole.PRO,
      },
      create: {
        id: pro.userId,
        phone: pro.phone,
        fullName: pro.fullNameEn,
        role: UserRole.PRO,
      },
    });

    const primaryZone = EGYPT_COVERAGE_ZONES.find((z) => z.slug === pro.primaryZoneSlug);

    await prisma.proProfile.upsert({
      where: { dossierCode: pro.dossierCode },
      update: {
        primaryCategoryId: pro.primaryCategoryId,
        primaryZoneId: primaryZone?.id,
        specialtyEn: pro.specialtyEn,
        specialtyAr: pro.specialtyAr,
        zonesLabelEn: pro.zonesLabelEn,
        zonesLabelAr: pro.zonesLabelAr,
        badgeEn: pro.badgeEn,
        badgeAr: pro.badgeAr,
        estimatedPriceEgp: pro.estimatedPriceEgp,
        reviewsCount: pro.reviewsCount,
        ratingAvg: pro.ratingAvg,
        completedJobsCount: pro.completedJobsCount,
        acceptanceRatePct: pro.acceptanceRatePct,
        verificationStatus: pro.verificationStatus,
        isOnline: pro.isOnline,
      },
      create: {
        id: pro.id,
        userId: user.id,
        dossierCode: pro.dossierCode,
        nationalIdSynthetic: '28501010100000',
        primaryCategoryId: pro.primaryCategoryId,
        primaryZoneId: primaryZone?.id,
        specialtyEn: pro.specialtyEn,
        specialtyAr: pro.specialtyAr,
        zonesLabelEn: pro.zonesLabelEn,
        zonesLabelAr: pro.zonesLabelAr,
        badgeEn: pro.badgeEn,
        badgeAr: pro.badgeAr,
        estimatedPriceEgp: pro.estimatedPriceEgp,
        reviewsCount: pro.reviewsCount,
        transportMode: pro.transportMode,
        experienceTier: pro.experienceTier,
        verificationStatus: pro.verificationStatus,
        isOnline: pro.isOnline,
        ratingAvg: pro.ratingAvg,
        completedJobsCount: pro.completedJobsCount,
        acceptanceRatePct: pro.acceptanceRatePct,
      },
    });
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error('Failed to seed FIXO PostgreSQL database:', error);
    await prisma.$disconnect();
    process.exit(1);
  });

