import { ExperienceTier, ProVerificationStatus, TransportMode, UserRole } from '@prisma/client';

export interface SeedCoverageZone {
  id: string;
  slug: string;
  nameEn: string;
  nameAr: string;
  governorate: string;
  isActive: boolean;
}

export interface SeedServiceCategory {
  id: string;
  slug: string;
  nameEn: string;
  nameAr: string;
  subtitleEn: string;
  subtitleAr: string;
  iconName: string;
  startingPriceEgp: number;
  sortOrder: number;
  isActive: boolean;
}

export interface SeedServiceSubSkill {
  id: string;
  categoryId: string;
  categorySlug: string;
  slug: string;
  nameEn: string;
  nameAr: string;
}

export interface SeedServiceOffering {
  id: string;
  categoryId: string;
  categorySlug: string;
  slug: string;
  titleEn: string;
  titleAr: string;
  descriptionEn: string;
  descriptionAr: string;
  badgeEn: string | null;
  badgeAr: string | null;
  providerTagEn: string | null;
  providerTagAr: string | null;
  baseInspectionEgp: number;
  serviceFeeEgp: number;
  flatPriceEgp: number;
  estimatedDurationMins: number;
  isSeasonalPromo: boolean;
  isBundle: boolean;
}

export interface SeedProfessionalRecord {
  id: string;
  userId: string;
  fullNameEn: string;
  fullNameAr: string;
  phone: string;
  dossierCode: string;
  primaryCategoryId: string;
  primaryCategorySlug: string;
  primaryZoneSlug: string;
  specialtyEn: string;
  specialtyAr: string;
  zonesLabelEn: string;
  zonesLabelAr: string;
  ratingAvg: number;
  reviewsCount: number;
  completedJobsCount: number;
  acceptanceRatePct: number;
  estimatedPriceEgp: number;
  badgeEn: string;
  badgeAr: string;
  badgeVariant: 'verified_master' | 'fast_responder';
  transportMode: TransportMode;
  experienceTier: ExperienceTier;
  verificationStatus: ProVerificationStatus;
  isOnline: boolean;
}

export interface SeedUserRecord {
  id: string;
  phone: string;
  fullName: string | null;
  email: string | null;
  avatarUrl: string | null;
  role: UserRole;
  preferredLocale: string;
  arrivalAlertsEnabled: boolean;
  rewardPoints: number;
  createdAt: Date;
  updatedAt: Date;
}

export const EGYPT_COVERAGE_ZONES: SeedCoverageZone[] = [
  {
    id: 'zone-sheikh-zayed',
    slug: 'sheikh-zayed',
    nameEn: 'Sheikh Zayed, Dist. 9',
    nameAr: 'الشيخ زايد، الحي التاسع',
    governorate: 'Giza',
    isActive: true,
  },
  {
    id: 'zone-new-cairo',
    slug: 'new-cairo',
    nameEn: 'New Cairo, 5th Settlement',
    nameAr: 'القاهرة الجديدة، التجمع الخامس',
    governorate: 'Cairo',
    isActive: true,
  },
  {
    id: 'zone-maadi',
    slug: 'maadi',
    nameEn: 'Maadi, Sarayat & Degla',
    nameAr: 'المعادي، السرايات ودجلة',
    governorate: 'Cairo',
    isActive: true,
  },
  {
    id: 'zone-zamalek',
    slug: 'zamalek',
    nameEn: 'Zamalek, 26th of July',
    nameAr: 'الزمالك، ٢٦ يوليو',
    governorate: 'Cairo',
    isActive: true,
  },
  {
    id: 'zone-dokki',
    slug: 'dokki',
    nameEn: 'Dokki & Mohandessin',
    nameAr: 'الدقي والمهندسين',
    governorate: 'Giza',
    isActive: true,
  },
];

/**
 * Six official service categories from live Stitch Screen 03 (`ba52cf458e2a49b191b6912ea76117fa`).
 */
export const EGYPT_SERVICE_CATEGORIES: SeedServiceCategory[] = [
  {
    id: 'cat-ac-maintenance',
    slug: 'ac-maintenance',
    nameEn: 'AC Maintenance',
    nameAr: 'صيانة التكييف',
    subtitleEn: 'Inverter, split & duct',
    subtitleAr: 'إنفرتر، سبليت ومركزي',
    iconName: 'mode_fan',
    startingPriceEgp: 450,
    sortOrder: 1,
    isActive: true,
  },
  {
    id: 'cat-plumbing-leaks',
    slug: 'plumbing-leaks',
    nameEn: 'Plumbing & Leaks',
    nameAr: 'السباكة والتسريبات',
    subtitleEn: 'Pipes, heaters & traps',
    subtitleAr: 'مواسير، سخانات وصرف',
    iconName: 'plumbing',
    startingPriceEgp: 280,
    sortOrder: 2,
    isActive: true,
  },
  {
    id: 'cat-electrical-lighting',
    slug: 'electrical-lighting',
    nameEn: 'Electrical & Lighting',
    nameAr: 'الكهرباء والإضاءة',
    subtitleEn: 'Breakers, wiring & LED',
    subtitleAr: 'لوحات، تأسيس وإضاءة حديثة',
    iconName: 'bolt',
    startingPriceEgp: 250,
    sortOrder: 3,
    isActive: true,
  },
  {
    id: 'cat-deep-cleaning',
    slug: 'deep-home-cleaning',
    nameEn: 'Deep Home Cleaning',
    nameAr: 'تنظيف عميق للمنازل',
    subtitleEn: 'Post-renovation & villas',
    subtitleAr: 'تنظيف الفيلات وما بعد التشطيب',
    iconName: 'cleaning_services',
    startingPriceEgp: 600,
    sortOrder: 4,
    isActive: true,
  },
  {
    id: 'cat-carpentry-repairs',
    slug: 'carpentry-repairs',
    nameEn: 'Carpentry & Repairs',
    nameAr: 'النجارة والإصلاحات',
    subtitleEn: 'Hinges, locks & bespoke',
    subtitleAr: 'مفصلات، كوالين وأعمال خشبية',
    iconName: 'handyman',
    startingPriceEgp: 320,
    sortOrder: 5,
    isActive: true,
  },
  {
    id: 'cat-painting-finishing',
    slug: 'painting-finishing',
    nameEn: 'Painting & Finishing',
    nameAr: 'النقاشة والتشطيبات',
    subtitleEn: 'Jotun primed coatings',
    subtitleAr: 'دهانات جوتن وتشطيب الحوائط',
    iconName: 'format_paint',
    startingPriceEgp: 850,
    sortOrder: 6,
    isActive: true,
  },
];

export const EGYPT_SERVICE_SUB_SKILLS: SeedServiceSubSkill[] = [
  // Plumbing & Leaks (Screen 12 official Stitch chips)
  {
    id: 'sub-pipe-leak',
    categoryId: 'cat-plumbing-leaks',
    categorySlug: 'plumbing-leaks',
    slug: 'pipe-leak-repair',
    nameEn: 'Pipe Leak Repair',
    nameAr: 'إصلاح تسريب المواسير',
  },
  {
    id: 'sub-water-heater',
    categoryId: 'cat-plumbing-leaks',
    categorySlug: 'plumbing-leaks',
    slug: 'water-heater-setup',
    nameEn: 'Water Heater Setup',
    nameAr: 'تركيب وصيانة السخانات',
  },
  {
    id: 'sub-drain-unclog',
    categoryId: 'cat-plumbing-leaks',
    categorySlug: 'plumbing-leaks',
    slug: 'drain-unclogging',
    nameEn: 'Drain Unclogging',
    nameAr: 'تسليك الصرف والأحواض',
  },
  {
    id: 'sub-bathroom-fixtures',
    categoryId: 'cat-plumbing-leaks',
    categorySlug: 'plumbing-leaks',
    slug: 'bathroom-fixtures',
    nameEn: 'Bathroom Fixtures',
    nameAr: 'تركيب أدوات صحية وخلاطات',
  },
  {
    id: 'sub-water-pump',
    categoryId: 'cat-plumbing-leaks',
    categorySlug: 'plumbing-leaks',
    slug: 'water-pump-maintenance',
    nameEn: 'Water Pump Maintenance',
    nameAr: 'صيانة مواتير المياه',
  },
  {
    id: 'sub-kitchen-sink',
    categoryId: 'cat-plumbing-leaks',
    categorySlug: 'plumbing-leaks',
    slug: 'kitchen-sink-mixer',
    nameEn: 'Kitchen Sink & Mixer',
    nameAr: 'صيانة حوض وخلاط المطبخ',
  },
  // Electrical & Lighting
  {
    id: 'sub-breaker-panel',
    categoryId: 'cat-electrical-lighting',
    categorySlug: 'electrical-lighting',
    slug: 'breaker-panel-diagnostics',
    nameEn: 'Breaker & Panel Diagnostics',
    nameAr: 'فحص لوحة القواطع والكهرباء',
  },
  {
    id: 'sub-chandelier-lighting',
    categoryId: 'cat-electrical-lighting',
    categorySlug: 'electrical-lighting',
    slug: 'lighting-chandelier-install',
    nameEn: 'Lighting & Chandelier Setup',
    nameAr: 'تركيب النجف والإضاءة الحديثة',
  },
  {
    id: 'sub-socket-wiring',
    categoryId: 'cat-electrical-lighting',
    categorySlug: 'electrical-lighting',
    slug: 'socket-switch-rewiring',
    nameEn: 'Sockets & Switch Rewiring',
    nameAr: 'تغيير البرايز والمفاتيح والأسلاك',
  },
  // AC Maintenance
  {
    id: 'sub-ac-chemical-wash',
    categoryId: 'cat-ac-maintenance',
    categorySlug: 'ac-maintenance',
    slug: 'split-ac-chemical-wash',
    nameEn: 'Split AC Deep Wash',
    nameAr: 'غسيل عميق للتكييف الاسبليت',
  },
  {
    id: 'sub-ac-freon-check',
    categoryId: 'cat-ac-maintenance',
    categorySlug: 'ac-maintenance',
    slug: 'freon-pressure-recharge',
    nameEn: 'Freon Pressure & Recharge',
    nameAr: 'فحص وشحن غاز الفريون',
  },
  {
    id: 'sub-ac-drain-fix',
    categoryId: 'cat-ac-maintenance',
    categorySlug: 'ac-maintenance',
    slug: 'ac-condensation-drain-fix',
    nameEn: 'Condensation Leak Repair',
    nameAr: 'إصلاح تسريب مياه التكييف',
  },
  // Deep Home Cleaning
  {
    id: 'sub-clean-apartment',
    categoryId: 'cat-deep-cleaning',
    categorySlug: 'deep-home-cleaning',
    slug: 'full-apartment-sanitization',
    nameEn: 'Full Home Sanitization',
    nameAr: 'تنظيف وتعقيم شامل للمنزل',
  },
  {
    id: 'sub-clean-upholstery',
    categoryId: 'cat-deep-cleaning',
    categorySlug: 'deep-home-cleaning',
    slug: 'sofa-carpet-steam-clean',
    nameEn: 'Sofa & Carpet Steam Clean',
    nameAr: 'تنظيف المفروشات والسجاد بالبخار',
  },
  // Carpentry & Repairs
  {
    id: 'sub-carpentry-locks',
    categoryId: 'cat-carpentry-repairs',
    categorySlug: 'carpentry-repairs',
    slug: 'door-locks-cylinders',
    nameEn: 'Door Locks & Cylinders',
    nameAr: 'تغيير كوالين وسلندرات الأبواب',
  },
  {
    id: 'sub-carpentry-cabinets',
    categoryId: 'cat-carpentry-repairs',
    categorySlug: 'carpentry-repairs',
    slug: 'kitchen-hinges-alignment',
    nameEn: 'Cabinet Hinges & Alignment',
    nameAr: 'ضبط مفصلات وأبواب المطابخ',
  },
  // Painting & Finishing
  {
    id: 'sub-paint-interior',
    categoryId: 'cat-painting-finishing',
    categorySlug: 'painting-finishing',
    slug: 'interior-wall-repaint',
    nameEn: 'Interior Wall Painting',
    nameAr: 'دهانات الحوائط الداخلية',
  },
  {
    id: 'sub-paint-putty',
    categoryId: 'cat-painting-finishing',
    categorySlug: 'painting-finishing',
    slug: 'crack-putty-treatment',
    nameEn: 'Crack & Moisture Treatment',
    nameAr: 'معالجة الشروخ والرطوبة بالمعجون',
  },
];

/**
 * Egyptian service offerings in EGP, including the featured seasonal AC promo (`350 EGP`)
 * and the Home Safety Inspection bundle (`450 EGP`) from Screen 03.
 */
export const EGYPT_SERVICE_OFFERINGS: SeedServiceOffering[] = [
  {
    id: 'off-ac-deep-clean',
    categoryId: 'cat-ac-maintenance',
    categorySlug: 'ac-maintenance',
    slug: 'summer-ac-deep-clean-gas-refill',
    titleEn: 'Summer AC Deep Clean & Gas Refill',
    titleAr: 'غسيل التكييف العميق وشحن الفريون الصيفي',
    descriptionEn: 'Complete coil flush, antibacterial sanitized mist, and pressure gauge test.',
    descriptionAr: 'تنظيف شامل للمكثف، تعقيم مضاد للبكتيريا، واختبار ضغط الفريون.',
    badgeEn: 'SEASONAL PEAK',
    badgeAr: 'عرض الموسم',
    providerTagEn: 'Daikin & Carrier Pros',
    providerTagAr: 'فنيو كاريير ودايكن',
    baseInspectionEgp: 150,
    serviceFeeEgp: 200,
    flatPriceEgp: 350,
    estimatedDurationMins: 60,
    isSeasonalPromo: true,
    isBundle: false,
  },
  {
    id: 'off-home-safety-bundle',
    categoryId: 'cat-electrical-lighting',
    categorySlug: 'electrical-lighting',
    slug: 'home-safety-inspection-bundle',
    titleEn: 'Home Safety Inspection',
    titleAr: 'فحص أمان المنزل الشامل',
    descriptionEn: 'Complete Electrical & Plumbing dual audit',
    descriptionAr: 'فحص مزدوج شامل لشبكة الكهرباء والسباكة المنزلية',
    badgeEn: 'BUNDLE SAVE',
    badgeAr: 'باقة توفير',
    providerTagEn: 'Dual Audit Bundle',
    providerTagAr: 'باقة فحص مزدوج',
    baseInspectionEgp: 200,
    serviceFeeEgp: 250,
    flatPriceEgp: 450,
    estimatedDurationMins: 90,
    isSeasonalPromo: false,
    isBundle: true,
  },
  {
    id: 'off-ac-inverter-diagnostic',
    categoryId: 'cat-ac-maintenance',
    categorySlug: 'ac-maintenance',
    slug: 'inverter-split-ac-maintenance',
    titleEn: 'Inverter & Split AC Full Tune-Up',
    titleAr: 'صيانة شاملة للتكييف الإنفرتر والسبليت',
    descriptionEn: 'Thermostat calibration, drainage line clearing, and capacitor load test.',
    descriptionAr: 'معايرة الثرموستات، تسليك خرطوم الصرف، واختبار كفاءة الكباس.',
    badgeEn: null,
    badgeAr: null,
    providerTagEn: 'Carrier & LG Certified',
    providerTagAr: 'معتمد لكاريير وإل جي',
    baseInspectionEgp: 150,
    serviceFeeEgp: 300,
    flatPriceEgp: 450,
    estimatedDurationMins: 60,
    isSeasonalPromo: false,
    isBundle: false,
  },
  {
    id: 'off-plumbing-leak-heater',
    categoryId: 'cat-plumbing-leaks',
    categorySlug: 'plumbing-leaks',
    slug: 'plumbing-leak-water-heater-repair',
    titleEn: 'Leak Detection & Water Heater Repair',
    titleAr: 'كشف التسريبات وصيانة السخانات',
    descriptionEn: 'Grohe mixer cartridges, pressure valve replacement, and thermal pipe sealing.',
    descriptionAr: 'تغيير قلب خلاطات جروهي، صمامات الأمان، ولحام مواسير البولي.',
    badgeEn: null,
    badgeAr: null,
    providerTagEn: 'Grohe & Ideal Standard',
    providerTagAr: 'جروهي وإيديال ستاندرد',
    baseInspectionEgp: 130,
    serviceFeeEgp: 150,
    flatPriceEgp: 280,
    estimatedDurationMins: 60,
    isSeasonalPromo: false,
    isBundle: false,
  },
  {
    id: 'off-electrical-panel-led',
    categoryId: 'cat-electrical-lighting',
    categorySlug: 'electrical-lighting',
    slug: 'electrical-breaker-led-installation',
    titleEn: 'Breaker Panel & LED Lighting Upgrade',
    titleAr: 'صيانة لوحة القواطع وتركيب إضاءة LED',
    descriptionEn: 'Schneider breaker diagnostics, voltage stabilizer wiring, and chandelier mounting.',
    descriptionAr: 'فحص قواطع شنايدر، ضبط الأحمال، وتركيب السبوتات والنجف.',
    badgeEn: null,
    badgeAr: null,
    providerTagEn: 'Schneider Electric Spec',
    providerTagAr: 'مواصفات شنايدر إلكتريك',
    baseInspectionEgp: 100,
    serviceFeeEgp: 150,
    flatPriceEgp: 250,
    estimatedDurationMins: 45,
    isSeasonalPromo: false,
    isBundle: false,
  },
  {
    id: 'off-deep-cleaning-villa',
    categoryId: 'cat-deep-cleaning',
    categorySlug: 'deep-home-cleaning',
    slug: 'deep-home-cleaning-steam-sanitization',
    titleEn: 'Deep Home & Post-Renovation Cleaning',
    titleAr: 'تنظيف عميق وتعقيم بالبخار للشقق والفيلات',
    descriptionEn: 'Marble polishing, kitchen degreasing, window tracks, and upholstery steam care.',
    descriptionAr: 'تلميع الرخام، إزالة دهون المطبخ، تنظيف الشبابيك وتعقيم المفروشات بالبخار.',
    badgeEn: null,
    badgeAr: null,
    providerTagEn: 'Eco-Safe Karcher Gear',
    providerTagAr: 'معدات كارشر الآمنة',
    baseInspectionEgp: 150,
    serviceFeeEgp: 450,
    flatPriceEgp: 600,
    estimatedDurationMins: 180,
    isSeasonalPromo: false,
    isBundle: false,
  },
  {
    id: 'off-carpentry-locks-hinges',
    categoryId: 'cat-carpentry-repairs',
    categorySlug: 'carpentry-repairs',
    slug: 'carpentry-door-alignment-lock-service',
    titleEn: 'Door Alignment, Locks & Hinges Service',
    titleAr: 'ضبط الأبواب وتغيير الكوالين والمفصلات',
    descriptionEn: 'Armored door cylinder replacement, kitchen cabinet soft-close hinges, and pergola care.',
    descriptionAr: 'تغيير سلندر الأبواب المصفحة، مفصلات المطابخ الهيدروليك وإصلاح الأخشاب.',
    badgeEn: null,
    badgeAr: null,
    providerTagEn: 'Yale & Blum Hardware',
    providerTagAr: 'إكسسوارات ييل وبلوم',
    baseInspectionEgp: 120,
    serviceFeeEgp: 200,
    flatPriceEgp: 320,
    estimatedDurationMins: 60,
    isSeasonalPromo: false,
    isBundle: false,
  },
  {
    id: 'off-painting-jotun-refresh',
    categoryId: 'cat-painting-finishing',
    categorySlug: 'painting-finishing',
    slug: 'jotun-room-wall-painting-finishing',
    titleEn: 'Jotun Fenomastic Wall Coating & Putty',
    titleAr: 'دهانات جوتن فينوماستيك ومعجون الحوائط',
    descriptionEn: 'Crack putty treatment, laser-masked edges, and 2-coat Jotun Fenomastic application.',
    descriptionAr: 'معالجة الشروخ بالمعجون، تغطية الأثاث والأرضيات، ودهان وجهين جوتن أصلي.',
    badgeEn: null,
    badgeAr: null,
    providerTagEn: 'Jotun Egypt Certified',
    providerTagAr: 'دهانات جوتن المعتمدة',
    baseInspectionEgp: 200,
    serviceFeeEgp: 650,
    flatPriceEgp: 850,
    estimatedDurationMins: 240,
    isSeasonalPromo: false,
    isBundle: false,
  },
];

/**
 * Top-rated Greater Cairo & Giza professionals from live Stitch Screen 03 (`ba52cf458e2a49b191b6912ea76117fa`).
 */
export const EGYPT_PROFESSIONALS: SeedProfessionalRecord[] = [
  {
    id: 'pro-tarek-01',
    userId: 'u-pro-tarek-01',
    fullNameEn: 'Eng. Tarek Mansour',
    fullNameAr: 'م. طارق منصور',
    phone: '+201091112233',
    dossierCode: 'FX-PRO-8810',
    primaryCategoryId: 'cat-electrical-lighting',
    primaryCategorySlug: 'electrical-lighting',
    primaryZoneSlug: 'new-cairo',
    specialtyEn: 'Master Electrician',
    specialtyAr: 'كبير فنيي كهرباء',
    zonesLabelEn: 'New Cairo & Maadi',
    zonesLabelAr: 'القاهرة الجديدة والمعادي',
    ratingAvg: 4.9,
    reviewsCount: 184,
    completedJobsCount: 312,
    acceptanceRatePct: 98,
    estimatedPriceEgp: 250,
    badgeEn: 'Verified Master Pro',
    badgeAr: 'فني خبير معتمد',
    badgeVariant: 'verified_master',
    transportMode: TransportMode.MOTORCYCLE,
    experienceTier: ExperienceTier.MASTER_8_PLUS_Y,
    verificationStatus: ProVerificationStatus.APPROVED,
    isOnline: true,
  },
  {
    id: 'pro-hassan-01',
    userId: 'u-pro-hassan-01',
    fullNameEn: 'Hassan El-Sayed',
    fullNameAr: 'حسن السيد',
    phone: '+201064445566',
    dossierCode: 'FX-PRO-9921',
    primaryCategoryId: 'cat-ac-maintenance',
    primaryCategorySlug: 'ac-maintenance',
    primaryZoneSlug: 'sheikh-zayed',
    specialtyEn: 'AC Specialist',
    specialtyAr: 'أخصائي تكييف وتبريد',
    zonesLabelEn: 'Sheikh Zayed & Dokki',
    zonesLabelAr: 'الشيخ زايد والدقي',
    ratingAvg: 4.95,
    reviewsCount: 240,
    completedJobsCount: 418,
    acceptanceRatePct: 96,
    estimatedPriceEgp: 350,
    badgeEn: 'Fast Responder (<15m)',
    badgeAr: 'استجابة سريعة (<١٥ د)',
    badgeVariant: 'fast_responder',
    transportMode: TransportMode.WORK_VAN,
    experienceTier: ExperienceTier.MASTER_8_PLUS_Y,
    verificationStatus: ProVerificationStatus.APPROVED,
    isOnline: true,
  },
  {
    id: 'pro-mahmoud-03',
    userId: 'u-pro-mahmoud-03',
    fullNameEn: 'Mahmoud Abdel-Rahman',
    fullNameAr: 'محمود عبد الرحمن',
    phone: '+201123334455',
    dossierCode: 'FX-PRO-7740',
    primaryCategoryId: 'cat-plumbing-leaks',
    primaryCategorySlug: 'plumbing-leaks',
    primaryZoneSlug: 'maadi',
    specialtyEn: 'Senior Sanitary Plumber',
    specialtyAr: 'فني أول سباكة صحية',
    zonesLabelEn: 'Maadi & Zamalek',
    zonesLabelAr: 'المعادي والزمالك',
    ratingAvg: 4.88,
    reviewsCount: 156,
    completedJobsCount: 275,
    acceptanceRatePct: 95,
    estimatedPriceEgp: 280,
    badgeEn: 'Verified Master Pro',
    badgeAr: 'فني خبير معتمد',
    badgeVariant: 'verified_master',
    transportMode: TransportMode.MOTORCYCLE,
    experienceTier: ExperienceTier.MASTER_8_PLUS_Y,
    verificationStatus: ProVerificationStatus.APPROVED,
    isOnline: true,
  },
  {
    id: 'pro-karim-04',
    userId: 'u-pro-karim-04',
    fullNameEn: 'Karim El-Masry',
    fullNameAr: 'كريم المصري',
    phone: '+201287776655',
    dossierCode: 'FX-PRO-6612',
    primaryCategoryId: 'cat-carpentry-repairs',
    primaryCategorySlug: 'carpentry-repairs',
    primaryZoneSlug: 'zamalek',
    specialtyEn: 'Bespoke Carpenter & Locksmith',
    specialtyAr: 'نجار موبيليا وكوالين حديثة',
    zonesLabelEn: 'Zamalek & Sheikh Zayed',
    zonesLabelAr: 'الزمالك والشيخ زايد',
    ratingAvg: 4.92,
    reviewsCount: 129,
    completedJobsCount: 210,
    acceptanceRatePct: 97,
    estimatedPriceEgp: 320,
    badgeEn: 'Fast Responder (<15m)',
    badgeAr: 'استجابة سريعة (<١٥ د)',
    badgeVariant: 'fast_responder',
    transportMode: TransportMode.WORK_VAN,
    experienceTier: ExperienceTier.SENIOR_6_8Y,
    verificationStatus: ProVerificationStatus.APPROVED,
    isOnline: true,
  },
];

export const DEFAULT_DEMO_CUSTOMER: SeedUserRecord = {
  id: 'u-salma-01',
  phone: '+201023456789',
  fullName: 'Salma El-Shazly',
  email: 'salma.elshazly@example.eg',
  avatarUrl: null,
  role: UserRole.CUSTOMER,
  preferredLocale: 'en',
  arrivalAlertsEnabled: true,
  rewardPoints: 1420,
  createdAt: new Date('2026-01-15T10:00:00.000Z'),
  updatedAt: new Date('2026-10-31T00:00:00.000Z'),
};

