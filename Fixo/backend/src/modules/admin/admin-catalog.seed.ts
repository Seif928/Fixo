import type { PrismaClient } from '@prisma/client';
/** Curated draft services, never public offers or fabricated prices/availability. */
interface DraftGroup {
  slug: string;
  en: string;
  ar: string;
  icon: string;
  services: [string, string, string][];
}
export const CATALOG_DRAFT_GROUPS: DraftGroup[] = [
  {
    slug: 'ac-maintenance',
    en: 'Air conditioning',
    ar: 'التكييف والتبريد',
    icon: 'ac_unit',
    services: [
      ['ac-install', 'Split AC installation', 'تركيب تكييف سبليت'],
      ['ac-relocate', 'AC removal and relocation', 'فك ونقل التكييف'],
      ['ac-leak', 'AC refrigerant leak inspection', 'فحص تسريب فريون التكييف'],
      ['ac-drain', 'AC drainage repair', 'إصلاح صرف التكييف'],
      [
        'ac-electronics',
        'AC control board inspection',
        'فحص لوحة تحكم التكييف',
      ],
      ['central-ac', 'Central AC maintenance', 'صيانة التكييف المركزي'],
      [
        'ac-filter',
        'AC filter cleaning and replacement',
        'تنظيف وتغيير فلاتر التكييف',
      ],
    ],
  },
  {
    slug: 'plumbing-leaks',
    en: 'Plumbing',
    ar: 'السباكة',
    icon: 'plumbing',
    services: [
      ['tap-repair', 'Tap and mixer repair', 'إصلاح الحنفيات والخلاطات'],
      [
        'concealed-leak',
        'Concealed water leak inspection',
        'فحص تسريب المياه المخفي',
      ],
      ['drain-clean', 'Drain unblocking', 'تسليك الصرف'],
      ['toilet-repair', 'Toilet and cistern repair', 'إصلاح التواليت والسيفون'],
      ['sink-install', 'Basin and sink installation', 'تركيب الأحواض'],
      [
        'water-pump',
        'Household water pump repair',
        'إصلاح موتور المياه المنزلي',
      ],
      ['bathroom-pipe', 'Bathroom pipe replacement', 'تغيير مواسير الحمام'],
      [
        'tank-float',
        'Water tank float valve replacement',
        'تغيير عوامة خزان المياه',
      ],
    ],
  },
  {
    slug: 'electrical-lighting',
    en: 'Electrical and lighting',
    ar: 'الكهرباء والإضاءة',
    icon: 'electrical_services',
    services: [
      [
        'socket-install',
        'Socket and switch installation',
        'تركيب البرايز والمفاتيح',
      ],
      ['breaker-check', 'Circuit breaker inspection', 'فحص القواطع الكهربائية'],
      ['chandelier-install', 'Chandelier installation', 'تركيب النجف'],
      ['ceiling-fan', 'Ceiling fan installation', 'تركيب مروحة سقف'],
      [
        'power-fault',
        'Household power fault diagnosis',
        'تشخيص أعطال كهرباء المنزل',
      ],
      [
        'led-install',
        'LED and concealed lighting installation',
        'تركيب إضاءة ليد وإضاءة مخفية',
      ],
      [
        'earthing-check',
        'Household earthing inspection',
        'فحص التأريض المنزلي',
      ],
      ['intercom-repair', 'Intercom repair', 'إصلاح الإنتركم'],
    ],
  },
  {
    slug: 'deep-home-cleaning',
    en: 'Home cleaning',
    ar: 'تنظيف المنازل',
    icon: 'cleaning_services',
    services: [
      ['apartment-clean', 'Apartment cleaning', 'تنظيف الشقق'],
      ['villa-clean', 'Villa cleaning', 'تنظيف الفلل'],
      ['after-renovation', 'Post-renovation cleaning', 'تنظيف ما بعد التشطيب'],
      ['sofa-clean', 'Sofa upholstery cleaning', 'تنظيف الكنب والانتريه'],
      ['carpet-clean', 'Carpet cleaning', 'تنظيف السجاد'],
      ['mattress-clean', 'Mattress cleaning', 'تنظيف المراتب'],
      [
        'kitchen-degrease',
        'Kitchen deep cleaning',
        'تنظيف المطابخ وإزالة الدهون',
      ],
      ['bathroom-clean', 'Bathroom deep cleaning', 'تنظيف الحمامات'],
      [
        'window-clean',
        'Accessible window cleaning',
        'تنظيف الشبابيك سهلة الوصول',
      ],
      ['tank-clean', 'Water tank cleaning', 'تنظيف خزانات المياه'],
    ],
  },
  {
    slug: 'carpentry-repairs',
    en: 'Carpentry and furniture',
    ar: 'النجارة والأثاث',
    icon: 'carpenter',
    services: [
      ['furniture-assembly', 'Flat-pack furniture assembly', 'تجميع الأثاث'],
      ['wardrobe-repair', 'Wardrobe repair', 'إصلاح الدواليب'],
      ['door-adjust', 'Wooden door adjustment', 'ضبط الأبواب الخشبية'],
      ['kitchen-hinge', 'Kitchen hinge replacement', 'تغيير مفصلات المطبخ'],
      ['drawer-runner', 'Drawer runner replacement', 'تغيير مجاري الأدراج'],
      ['bed-repair', 'Bed frame repair', 'إصلاح هياكل السراير'],
      ['shelf-install', 'Shelf installation', 'تركيب الأرفف'],
      ['wood-restoration', 'Wood furniture restoration', 'ترميم الأثاث الخشبي'],
    ],
  },
  {
    slug: 'painting-finishing',
    en: 'Painting and finishing',
    ar: 'الدهانات والتشطيب',
    icon: 'format_paint',
    services: [
      ['room-paint', 'Room repainting', 'دهان الغرف'],
      ['apartment-paint', 'Apartment repainting', 'دهان الشقق'],
      ['crack-fill', 'Wall crack repair', 'معالجة شروخ الحوائط'],
      ['wallpaper-install', 'Wallpaper installation', 'تركيب ورق الحائط'],
      ['wood-paint', 'Wood and door painting', 'دهان الأخشاب والأبواب'],
      ['damp-wall', 'Damp wall assessment', 'فحص رطوبة الحوائط'],
    ],
  },
  {
    slug: 'laundry-appliances',
    en: 'Laundry appliances',
    ar: 'الغسالات والمجففات',
    icon: 'local_laundry_service',
    services: [
      ['washer-install', 'Washing machine installation', 'تركيب الغسالات'],
      ['washer-drain', 'Washing machine drainage repair', 'إصلاح صرف الغسالات'],
      [
        'washer-spin',
        'Washing machine spin fault diagnosis',
        'تشخيص عطل عصر الغسالة',
      ],
      ['washer-leak', 'Washing machine leak repair', 'إصلاح تسريب الغسالات'],
      ['dryer-repair', 'Tumble dryer maintenance', 'صيانة المجففات'],
      [
        'washer-clean',
        'Washing machine deep cleaning',
        'تنظيف الغسالات من الداخل',
      ],
    ],
  },
  {
    slug: 'refrigerators',
    en: 'Refrigerators and freezers',
    ar: 'الثلاجات والديب فريزر',
    icon: 'kitchen',
    services: [
      [
        'fridge-cooling',
        'Refrigerator cooling fault diagnosis',
        'تشخيص ضعف تبريد الثلاجات',
      ],
      ['freezer-repair', 'Freezer maintenance', 'صيانة الديب فريزر'],
      [
        'fridge-seal',
        'Refrigerator door seal replacement',
        'تغيير كاوتش باب الثلاجة',
      ],
      [
        'fridge-defrost',
        'Refrigerator defrost system repair',
        'إصلاح نظام إذابة الثلج',
      ],
      ['fridge-drain', 'Refrigerator drainage repair', 'إصلاح صرف الثلاجة'],
      [
        'fridge-thermostat',
        'Refrigerator thermostat replacement',
        'تغيير ترموستات الثلاجة',
      ],
    ],
  },
  {
    slug: 'kitchen-appliances',
    en: 'Kitchen appliances',
    ar: 'أجهزة المطبخ',
    icon: 'microwave',
    services: [
      ['dishwasher-install', 'Dishwasher installation', 'تركيب غسالة الأطباق'],
      ['dishwasher-repair', 'Dishwasher maintenance', 'صيانة غسالة الأطباق'],
      [
        'oven-electric',
        'Electric oven maintenance',
        'صيانة الأفران الكهربائية',
      ],
      ['microwave-repair', 'Microwave maintenance', 'صيانة الميكروويف'],
      [
        'extractor-install',
        'Kitchen extractor installation',
        'تركيب شفاط المطبخ',
      ],
      [
        'extractor-repair',
        'Kitchen extractor maintenance',
        'صيانة شفاط المطبخ',
      ],
    ],
  },
  {
    slug: 'heaters-and-purifiers',
    en: 'Water heaters and filters',
    ar: 'السخانات وفلاتر المياه',
    icon: 'water_drop',
    services: [
      [
        'electric-heater-install',
        'Electric water heater installation',
        'تركيب سخان مياه كهربائي',
      ],
      [
        'electric-heater-repair',
        'Electric water heater maintenance',
        'صيانة سخان المياه الكهربائي',
      ],
      [
        'heater-descaling',
        'Water heater descaling',
        'إزالة ترسبات سخان المياه',
      ],
      [
        'water-filter-install',
        'Water filter installation',
        'تركيب فلاتر المياه',
      ],
      [
        'filter-cartridge',
        'Water filter cartridge replacement',
        'تغيير شمع فلاتر المياه',
      ],
      ['water-dispenser', 'Water dispenser maintenance', 'صيانة مبردات المياه'],
    ],
  },
  {
    slug: 'moving-and-installation',
    en: 'Moving and installation',
    ar: 'النقل والتركيب',
    icon: 'local_shipping',
    services: [
      ['home-moving', 'Household furniture moving', 'نقل أثاث المنزل'],
      ['furniture-pack', 'Furniture packing', 'تغليف الأثاث'],
      [
        'furniture-disassembly',
        'Furniture disassembly and reassembly',
        'فك وتركيب الأثاث',
      ],
      ['appliance-moving', 'Large appliance moving', 'نقل الأجهزة الكبيرة'],
      ['tv-wall-mount', 'TV wall mounting', 'تعليق شاشات التلفزيون'],
      [
        'picture-hanging',
        'Picture and mirror hanging',
        'تعليق البراويز والمرايات',
      ],
      ['curtain-rod', 'Curtain rod installation', 'تركيب مواسير الستائر'],
      ['clothes-airer', 'Clothes airer installation', 'تركيب مناشر الغسيل'],
    ],
  },
  {
    slug: 'pest-control',
    en: 'Pest control',
    ar: 'مكافحة الحشرات والقوارض',
    icon: 'pest_control',
    services: [
      ['cockroach-control', 'Cockroach control', 'مكافحة الصراصير'],
      ['ant-control', 'Ant control', 'مكافحة النمل'],
      ['bedbug-control', 'Bedbug treatment', 'مكافحة بق الفراش'],
      ['rodent-control', 'Rodent control', 'مكافحة القوارض'],
      ['mosquito-control', 'Mosquito control', 'مكافحة الناموس'],
      ['pest-inspection', 'Home pest inspection', 'معاينة آفات المنزل'],
    ],
  },
  {
    slug: 'gardens',
    en: 'Gardens and outdoor care',
    ar: 'الحدائق والعناية الخارجية',
    icon: 'yard',
    services: [
      ['garden-care', 'Garden maintenance', 'صيانة الحدائق'],
      ['lawn-cut', 'Lawn mowing', 'قص النجيل'],
      ['hedge-trim', 'Hedge trimming', 'تقليم الأسيجة'],
      [
        'irrigation-repair',
        'Garden irrigation repair',
        'إصلاح شبكة ري الحديقة',
      ],
      ['planting', 'Planting and repotting', 'زراعة النباتات وتغيير الأصص'],
      ['balcony-plants', 'Balcony plant care', 'العناية بنباتات البلكونة'],
    ],
  },
  {
    slug: 'aluminium-and-glass',
    en: 'Aluminium and glass',
    ar: 'الألوميتال والزجاج',
    icon: 'window',
    services: [
      [
        'aluminium-window',
        'Aluminium window repair',
        'إصلاح شبابيك الألوميتال',
      ],
      [
        'sliding-door',
        'Sliding door roller replacement',
        'تغيير عجل الأبواب الجرارة',
      ],
      ['mosquito-screen', 'Insect screen replacement', 'تغيير سلك الناموس'],
      ['glass-replace', 'Window glass replacement', 'تغيير زجاج الشبابيك'],
      [
        'shower-enclosure',
        'Shower enclosure maintenance',
        'صيانة كبائن الاستحمام',
      ],
      ['window-seal', 'Window seal repair', 'إصلاح عزل الشبابيك'],
    ],
  },
  {
    slug: 'metalwork',
    en: 'Metalwork',
    ar: 'الحدادة والأعمال المعدنية',
    icon: 'hardware',
    services: [
      ['metal-door', 'Metal door repair', 'إصلاح الأبواب الحديدية'],
      ['gate-hinge', 'Gate hinge repair', 'إصلاح مفصلات البوابات'],
      ['railing-repair', 'Railing repair', 'إصلاح الدرابزين'],
      [
        'window-grille',
        'Window grille installation',
        'تركيب حديد حماية الشبابيك',
      ],
      [
        'metal-welding',
        'Household metal welding',
        'لحام القطع المعدنية المنزلية',
      ],
      ['shutter-repair', 'Manual shutter repair', 'إصلاح الشتر اليدوي'],
    ],
  },
  {
    slug: 'tiles-and-masonry',
    en: 'Tiles and masonry',
    ar: 'السيراميك والمباني',
    icon: 'grid_view',
    services: [
      ['tile-replace', 'Broken tile replacement', 'تغيير السيراميك المكسور'],
      ['tile-grout', 'Tile regrouting', 'تجديد فواصل السيراميك'],
      ['marble-polish', 'Marble polishing', 'تلميع الرخام'],
      ['plaster-repair', 'Wall plaster repair', 'إصلاح محارة الحوائط'],
      ['gypsum-repair', 'Gypsum board repair', 'إصلاح الجبس بورد'],
      [
        'brick-repair',
        'Non-structural masonry repair',
        'إصلاحات مباني غير إنشائية',
      ],
    ],
  },
  {
    slug: 'waterproofing',
    en: 'Waterproofing',
    ar: 'العزل ومعالجة التسريب',
    icon: 'roofing',
    services: [
      ['roof-waterproof', 'Roof waterproofing', 'عزل الأسطح ضد المياه'],
      ['bathroom-waterproof', 'Bathroom waterproofing', 'عزل الحمامات'],
      ['balcony-waterproof', 'Balcony waterproofing', 'عزل البلكونات'],
      [
        'silicone-reseal',
        'Bathroom silicone resealing',
        'تجديد سيليكون الحمام',
      ],
      ['roof-leak-check', 'Roof leak assessment', 'فحص تسريب السطح'],
    ],
  },
  {
    slug: 'locks-and-security',
    en: 'Locks and home security',
    ar: 'الأقفال وأمان المنزل',
    icon: 'lock',
    services: [
      ['door-cylinder', 'Door cylinder replacement', 'تغيير كالون الباب'],
      ['door-lock', 'Door lock maintenance', 'صيانة أقفال الأبواب'],
      ['smart-lock', 'Smart lock installation', 'تركيب أقفال ذكية'],
      ['door-closer', 'Door closer installation', 'تركيب ماكينة غلق الأبواب'],
      ['doorbell', 'Doorbell installation', 'تركيب جرس الباب'],
      [
        'home-camera',
        'Home security camera installation',
        'تركيب كاميرات مراقبة منزلية',
      ],
    ],
  },
  {
    slug: 'home-networks',
    en: 'Home networks and smart devices',
    ar: 'شبكات المنزل والأجهزة الذكية',
    icon: 'router',
    services: [
      ['wifi-setup', 'Home Wi-Fi setup', 'ضبط شبكة الواي فاي المنزلية'],
      ['wifi-coverage', 'Wi-Fi coverage improvement', 'تحسين تغطية الواي فاي'],
      [
        'network-cable',
        'Home network cable installation',
        'تمديد كابلات شبكة المنزل',
      ],
      ['smart-switch', 'Smart switch setup', 'ضبط المفاتيح الذكية'],
      ['smart-device', 'Smart home device setup', 'ضبط أجهزة المنزل الذكية'],
      ['tv-setup', 'Smart TV setup', 'ضبط التلفزيون الذكي'],
    ],
  },
  {
    slug: 'upholstery-and-curtains',
    en: 'Upholstery and curtains',
    ar: 'التنجيد والستائر',
    icon: 'chair',
    services: [
      ['sofa-upholstery', 'Sofa upholstery repair', 'إصلاح تنجيد الكنب'],
      ['chair-upholstery', 'Chair upholstery repair', 'إصلاح تنجيد الكراسي'],
      ['foam-replace', 'Furniture foam replacement', 'تغيير إسفنج الأثاث'],
      ['curtain-install', 'Curtain installation', 'تركيب الستائر'],
      ['blind-repair', 'Blind mechanism repair', 'إصلاح آليات الستائر'],
      ['curtain-rail', 'Curtain rail repair', 'إصلاح قضبان الستائر'],
    ],
  },
  {
    slug: 'small-home-appliances',
    en: 'Small home appliances',
    ar: 'الأجهزة المنزلية الصغيرة',
    icon: 'blender',
    services: [
      [
        'vacuum-repair',
        'Vacuum cleaner maintenance',
        'صيانة المكانس الكهربائية',
      ],
      ['iron-repair', 'Clothes iron maintenance', 'صيانة المكواة'],
      [
        'blender-repair',
        'Blender and food processor maintenance',
        'صيانة الخلاطات ومحضرات الطعام',
      ],
      [
        'kettle-repair',
        'Electric kettle maintenance',
        'صيانة الغلايات الكهربائية',
      ],
      ['fan-repair', 'Household fan maintenance', 'صيانة المراوح المنزلية'],
      [
        'coffee-machine',
        'Home coffee machine maintenance',
        'صيانة ماكينات القهوة المنزلية',
      ],
    ],
  },
];

export const CATALOG_DRAFTS = CATALOG_DRAFT_GROUPS.flatMap((group) =>
  group.services.map(([key, titleEn, titleAr]) => ({
    slug: `home-${key}`,
    categorySlug: group.slug,
    categoryNameEn: group.en,
    categoryNameAr: group.ar,
    categoryIcon: group.icon,
    titleEn,
    titleAr,
    descriptionEn: `${titleEn}. Describe the work required when booking.`,
    descriptionAr: `${titleAr}. وضّح تفاصيل الشغل المطلوب عند الحجز.`,
  })),
);

/** Explicit operator operation: no automatic seed on public/admin requests. */
export async function seedAdminCatalogDrafts(db: PrismaClient) {
  return db.$transaction(async (tx) => {
    const published = await tx.serviceOffering.findMany({
      include: { category: true },
    });
    const linked = published.map((offer) => ({
      slug: offer.slug,
      categorySlug: offer.category.slug,
      categoryNameEn: offer.category.nameEn,
      categoryNameAr: offer.category.nameAr,
      categoryIcon: offer.category.iconName,
      titleEn: offer.titleEn,
      titleAr: offer.titleAr,
      descriptionEn: offer.descriptionEn,
      descriptionAr: offer.descriptionAr,
      baseInspectionEgp: offer.baseInspectionEgp,
      serviceFeeEgp: offer.serviceFeeEgp,
      estimatedDurationMins: offer.estimatedDurationMins,
      offeringId: offer.id,
      publishedVersion: 1,
    }));
    return tx.adminCatalogDraft.createMany({
      data: [...linked, ...CATALOG_DRAFTS],
      skipDuplicates: true,
    });
  });
}
