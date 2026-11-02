import '../../customer_home/domain/marketplace_models.dart';

/// Available options returned by `GET /api/v1/pro/catalog-options`.
class ProCatalogOptionsModel {
  const ProCatalogOptionsModel({
    required this.categories,
    required this.subSkills,
    required this.zones,
    required this.transportModes,
    required this.experienceTiers,
  });

  final List<ServiceCategoryModel> categories;
  final List<ProSubSkillModel> subSkills;
  final List<CoverageZoneModel> zones;
  final List<ProOptionItemModel> transportModes;
  final List<ProOptionItemModel> experienceTiers;

  factory ProCatalogOptionsModel.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>? ?? const [])
        .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final subs = (json['subSkills'] as List<dynamic>? ?? const [])
        .map((e) => ProSubSkillModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final zns = (json['zones'] as List<dynamic>? ?? const [])
        .map((e) => CoverageZoneModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final trans = (json['transportModes'] as List<dynamic>? ?? const [])
        .map((e) => ProOptionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final exp = (json['experienceTiers'] as List<dynamic>? ?? const [])
        .map((e) => ProOptionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProCatalogOptionsModel(
      categories: cats,
      subSkills: subs,
      zones: zns,
      transportModes: trans,
      experienceTiers: exp,
    );
  }
}

class ProSubSkillModel {
  const ProSubSkillModel({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameAr,
    required this.categoryId,
  });

  final String id;
  final String slug;
  final String nameEn;
  final String nameAr;
  final String categoryId;

  factory ProSubSkillModel.fromJson(Map<String, dynamic> json) {
    return ProSubSkillModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
    );
  }
}

class ProOptionItemModel {
  const ProOptionItemModel({
    required this.key,
    required this.labelEn,
    required this.labelAr,
    this.descEn,
    this.descAr,
  });

  final String key;
  final String labelEn;
  final String labelAr;
  final String? descEn;
  final String? descAr;

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  factory ProOptionItemModel.fromJson(Map<String, dynamic> json) {
    return ProOptionItemModel(
      key: json['key'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      labelAr: json['labelAr'] as String? ?? '',
      descEn: json['descEn'] as String?,
      descAr: json['descAr'] as String?,
    );
  }
}

/// Professional Profile Representation (`GET /api/v1/pro/me`).
class ProProfileModel {
  const ProProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.nationalIdSynthetic,
    this.primaryZoneId,
    this.transportMode,
    this.vehicleDescription,
    this.vehiclePlateAr,
    this.primaryCategoryId,
    this.selectedSubSkillIds = const [],
    this.experienceTier,
    this.coverageZoneIds = const [],
    this.acceptsStandardRateCard = true,
    this.toolkitCommitmentConfirmed = false,
    this.verificationStatus = 'DRAFT',
    this.isOnline = false,
    this.ratingAvg = 5.0,
    this.reviewsCount = 0,
    this.completedJobsCount = 0,
    this.specialtyEn,
    this.specialtyAr,
    this.estimatedPriceEgp,
  });

  final String id;
  final String userId;
  final String? fullName;
  final String? phone;
  final String? nationalIdSynthetic;
  final String? primaryZoneId;
  final String? transportMode;
  final String? vehicleDescription;
  final String? vehiclePlateAr;
  final String? primaryCategoryId;
  final List<String> selectedSubSkillIds;
  final String? experienceTier;
  final List<String> coverageZoneIds;
  final bool acceptsStandardRateCard;
  final bool toolkitCommitmentConfirmed;
  final String verificationStatus;
  final bool isOnline;
  final double ratingAvg;
  final int reviewsCount;
  final int completedJobsCount;
  final String? specialtyEn;
  final String? specialtyAr;
  final int? estimatedPriceEgp;

  bool get isApproved => verificationStatus == 'APPROVED';
  bool get isPendingReview => verificationStatus == 'PENDING_REVIEW';

  factory ProProfileModel.fromJson(Map<String, dynamic> json) {
    final subSkills = (json['subSkills'] as List<dynamic>? ?? const [])
        .map((s) => (s is Map ? s['id'] ?? s['subSkillId'] : s).toString())
        .toList();
    final zones = (json['coverageZones'] as List<dynamic>? ?? const [])
        .map((z) => (z is Map ? z['zoneId'] ?? z['id'] : z).toString())
        .toList();

    return ProProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ??
          (json['user'] is Map ? json['user']['fullName'] as String? : null),
      phone: json['phone'] as String? ??
          (json['user'] is Map ? json['user']['phone'] as String? : null),
      nationalIdSynthetic: json['nationalIdSynthetic'] as String?,
      primaryZoneId: json['primaryZoneId'] as String?,
      transportMode: json['transportMode'] as String?,
      vehicleDescription: json['vehicleDescription'] as String?,
      vehiclePlateAr: json['vehiclePlateAr'] as String?,
      primaryCategoryId: json['primaryCategoryId'] as String?,
      selectedSubSkillIds: subSkills,
      experienceTier: json['experienceTier'] as String?,
      coverageZoneIds: zones,
      acceptsStandardRateCard: json['acceptsStandardRateCard'] as bool? ?? true,
      toolkitCommitmentConfirmed:
          json['toolkitCommitmentConfirmed'] as bool? ?? false,
      verificationStatus:
          json['verificationStatus'] as String? ?? 'DRAFT',
      isOnline: json['isOnline'] as bool? ?? false,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      completedJobsCount:
          (json['completedJobsCount'] as num?)?.toInt() ?? 0,
      specialtyEn: json['specialtyEn'] as String?,
      specialtyAr: json['specialtyAr'] as String?,
      estimatedPriceEgp: (json['estimatedPriceEgp'] as num?)?.toInt(),
    );
  }
}

/// Verification Document item
class ProDocumentModel {
  const ProDocumentModel({
    required this.id,
    required this.docType,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  final String id;
  final String docType;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String status;
  final String? rejectionReason;
  final String createdAt;

  factory ProDocumentModel.fromJson(Map<String, dynamic> json) {
    return ProDocumentModel(
      id: json['id'] as String? ?? '',
      docType: json['docType'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType'] as String? ?? 'image/png',
      status: json['status'] as String? ?? 'PENDING',
      rejectionReason: json['reviewerComment'] as String? ??
          json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Verification Milestone for Screen 14
class ProVerificationMilestoneModel {
  const ProVerificationMilestoneModel({
    required this.key,
    required this.stepNumber,
    required this.titleEn,
    required this.titleAr,
    required this.descEn,
    required this.descAr,
    required this.status,
  });

  final String key;
  final int stepNumber;
  final String titleEn;
  final String titleAr;
  final String descEn;
  final String descAr;
  final String status; // DONE, CURRENT, UPCOMING, REJECTED

  factory ProVerificationMilestoneModel.fromJson(Map<String, dynamic> json) {
    return ProVerificationMilestoneModel(
      key: json['key'] as String? ?? '',
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 1,
      titleEn: json['titleEn'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      descEn: json['descEn'] as String? ?? '',
      descAr: json['descAr'] as String? ?? '',
      status: json['status'] as String? ?? 'UPCOMING',
    );
  }
}

/// Verification status response for Screen 14 (`GET /api/v1/pro/onboarding/status`)
class ProVerificationStatusModel {
  const ProVerificationStatusModel({
    required this.status,
    required this.dossierCode,
    this.submittedAt,
    this.reviewerNote,
    this.reviewedAt,
    this.isComplete = false,
    required this.milestones,
    required this.documents,
  });

  final String status;
  final String dossierCode;
  final String? submittedAt;
  final String? reviewerNote;
  final String? reviewedAt;
  final bool isComplete;
  final List<ProVerificationMilestoneModel> milestones;
  final List<ProDocumentModel> documents;

  bool get isApproved => status == 'APPROVED';
  bool get isPendingReview => status == 'PENDING_REVIEW';
  bool get isActionRequired => status == 'ACTION_REQUIRED';

  factory ProVerificationStatusModel.fromJson(Map<String, dynamic> json) {
    final mls = (json['milestones'] as List<dynamic>? ?? const [])
        .map((m) =>
            ProVerificationMilestoneModel.fromJson(m as Map<String, dynamic>))
        .toList();
    final docs = (json['documents'] as List<dynamic>? ?? const [])
        .map((d) => ProDocumentModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return ProVerificationStatusModel(
      status: json['status'] as String? ?? 'DRAFT',
      dossierCode: json['dossierCode'] as String? ?? '',
      submittedAt: json['submittedAt'] as String?,
      reviewerNote: json['reviewerNote'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      isComplete: json['isComplete'] as bool? ?? false,
      milestones: mls,
      documents: docs,
    );
  }
}

/// Daily Earnings point for Screen 15 weekly chart
class ProDashboardDailyEarningsModel {
  const ProDashboardDailyEarningsModel({
    required this.dayKey,
    required this.dayLabelEn,
    required this.dayLabelAr,
    required this.netEgp,
  });

  final String dayKey;
  final String dayLabelEn;
  final String dayLabelAr;
  final int netEgp;

  factory ProDashboardDailyEarningsModel.fromJson(Map<String, dynamic> json) {
    return ProDashboardDailyEarningsModel(
      dayKey: json['dayKey'] as String? ?? '',
      dayLabelEn: json['dayLabelEn'] as String? ?? '',
      dayLabelAr: json['dayLabelAr'] as String? ?? '',
      netEgp: (json['netEgp'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Incoming / Active Job Offer for Screen 16 (`GET /api/v1/pro/job-offers/:id`)
class JobOfferModel {
  const JobOfferModel({
    required this.id,
    required this.bookingId,
    required this.orderCode,
    required this.status,
    required this.expiresAt,
    required this.remainingSeconds,
    required this.serviceTitleEn,
    required this.serviceTitleAr,
    required this.categoryNameEn,
    required this.categoryNameAr,
    required this.customerName,
    required this.customerPhoneMasked,
    required this.districtLine,
    required this.zoneNameEn,
    required this.zoneNameAr,
    required this.scheduledDate,
    required this.timeWindow,
    required this.grossEgp,
    required this.platformFeeEgp,
    required this.netArtisanEgp,
  });

  final String id;
  final String bookingId;
  final String orderCode;
  final String status;
  final String expiresAt;
  final int remainingSeconds;
  final String serviceTitleEn;
  final String serviceTitleAr;
  final String categoryNameEn;
  final String categoryNameAr;
  final String customerName;
  final String customerPhoneMasked;
  final String districtLine;
  final String zoneNameEn;
  final String zoneNameAr;
  final String scheduledDate;
  final String timeWindow;
  final int grossEgp;
  final int platformFeeEgp;
  final int netArtisanEgp;

  bool get isExpired => remainingSeconds <= 0 || status == 'EXPIRED';

  factory JobOfferModel.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>? ?? const {};
    final offering = booking['offering'] as Map<String, dynamic>? ?? const {};
    final cat = offering['category'] as Map<String, dynamic>? ?? const {};
    final customer = booking['customer'] as Map<String, dynamic>? ?? const {};
    final addr = booking['address'] as Map<String, dynamic>? ?? const {};
    final zone = addr['zone'] as Map<String, dynamic>? ?? const {};
    final pricing = booking['pricing'] as Map<String, dynamic>? ?? const {};

    return JobOfferModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? (booking['id'] as String? ?? ''),
      orderCode: json['orderCode'] as String? ??
          (booking['orderCode'] as String? ?? ''),
      status: json['status'] as String? ?? 'OFFERED',
      expiresAt: json['expiresAt'] as String? ?? '',
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
      serviceTitleEn: json['serviceTitleEn'] as String? ??
          (offering['titleEn'] as String? ?? 'Service Request'),
      serviceTitleAr: json['serviceTitleAr'] as String? ??
          (offering['titleAr'] as String? ?? 'طلب خدمة'),
      categoryNameEn: json['categoryNameEn'] as String? ??
          (cat['nameEn'] as String? ?? ''),
      categoryNameAr: json['categoryNameAr'] as String? ??
          (cat['nameAr'] as String? ?? ''),
      customerName: json['customerName'] as String? ??
          (customer['fullName'] as String? ?? 'FIXO Customer'),
      customerPhoneMasked: json['customerPhoneMasked'] as String? ??
          (customer['phone'] as String? ?? '010****'),
      districtLine: json['districtLine'] as String? ??
          (addr['districtLine'] as String? ?? ''),
      zoneNameEn: json['zoneNameEn'] as String? ??
          (zone['nameEn'] as String? ?? ''),
      zoneNameAr: json['zoneNameAr'] as String? ??
          (zone['nameAr'] as String? ?? ''),
      scheduledDate: json['scheduledDate'] as String? ??
          (booking['scheduledDate'] as String? ?? ''),
      timeWindow: json['timeWindow'] as String? ??
          (booking['timeWindow'] as String? ?? ''),
      grossEgp: (json['grossEgp'] as num?)?.toInt() ??
          (pricing['totalEgp'] as num?)?.toInt() ??
          0,
      platformFeeEgp: (json['platformFeeEgp'] as num?)?.toInt() ??
          (pricing['platformFeeEgp'] as num?)?.toInt() ??
          0,
      netArtisanEgp: (json['netArtisanEgp'] as num?)?.toInt() ??
          (pricing['netArtisanEgp'] as num?)?.toInt() ??
          0,
    );
  }
}

/// Assigned Job item in Screen 15 Today Schedule
class ProScheduledJobModel {
  const ProScheduledJobModel({
    required this.bookingId,
    required this.orderCode,
    required this.status,
    required this.serviceTitleEn,
    required this.serviceTitleAr,
    required this.customerName,
    required this.customerPhoneMasked,
    required this.addressLine,
    required this.districtLine,
    required this.zoneNameEn,
    required this.zoneNameAr,
    required this.timeWindow,
    required this.scheduledDate,
    required this.totalEgp,
    required this.netArtisanEgp,
    this.hasArrivalPin = false,
  });

  final String bookingId;
  final String orderCode;
  final String status;
  final String serviceTitleEn;
  final String serviceTitleAr;
  final String customerName;
  final String customerPhoneMasked;
  final String addressLine;
  final String districtLine;
  final String zoneNameEn;
  final String zoneNameAr;
  final String timeWindow;
  final String scheduledDate;
  final int totalEgp;
  final int netArtisanEgp;
  final bool hasArrivalPin;

  factory ProScheduledJobModel.fromJson(Map<String, dynamic> json) {
    return ProScheduledJobModel(
      bookingId: json['bookingId'] as String? ?? json['id'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      status: json['status'] as String? ?? 'CONFIRMED',
      serviceTitleEn: json['serviceTitleEn'] as String? ?? 'Service',
      serviceTitleAr: json['serviceTitleAr'] as String? ?? 'خدمة',
      customerName: json['customerName'] as String? ?? 'Customer',
      customerPhoneMasked: json['customerPhoneMasked'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      districtLine: json['districtLine'] as String? ?? '',
      zoneNameEn: json['zoneNameEn'] as String? ?? '',
      zoneNameAr: json['zoneNameAr'] as String? ?? '',
      timeWindow: json['timeWindow'] as String? ?? '',
      scheduledDate: json['scheduledDate'] as String? ?? '',
      totalEgp: (json['totalEgp'] as num?)?.toInt() ?? 0,
      netArtisanEgp: (json['netArtisanEgp'] as num?)?.toInt() ?? 0,
      hasArrivalPin: json['hasArrivalPin'] as bool? ?? false,
    );
  }
}

/// Pro Dashboard Response for Screen 15 (`GET /api/v1/pro/dashboard`)
class ProDashboardModel {
  const ProDashboardModel({
    required this.isOnline,
    required this.todayEarningsEgp,
    required this.weekEarningsEgp,
    required this.completedJobsCount,
    required this.ratingAvg,
    required this.reviewsCount,
    required this.dailyTrajectory,
    required this.activeOffers,
    required this.todaySchedule,
  });

  final bool isOnline;
  final int todayEarningsEgp;
  final int weekEarningsEgp;
  final int completedJobsCount;
  final double ratingAvg;
  final int reviewsCount;
  final List<ProDashboardDailyEarningsModel> dailyTrajectory;
  final List<JobOfferModel> activeOffers;
  final List<ProScheduledJobModel> todaySchedule;

  factory ProDashboardModel.fromJson(Map<String, dynamic> json) {
    final daily = (json['dailyTrajectory'] as List<dynamic>? ?? const [])
        .map((d) => ProDashboardDailyEarningsModel.fromJson(
            d as Map<String, dynamic>))
        .toList();
    final offers = (json['activeOffers'] as List<dynamic>? ?? const [])
        .map((o) => JobOfferModel.fromJson(o as Map<String, dynamic>))
        .toList();
    final sched = (json['todaySchedule'] as List<dynamic>? ?? const [])
        .map((s) => ProScheduledJobModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return ProDashboardModel(
      isOnline: json['isOnline'] as bool? ?? false,
      todayEarningsEgp: (json['todayEarningsEgp'] as num?)?.toInt() ?? 0,
      weekEarningsEgp: (json['weekEarningsEgp'] as num?)?.toInt() ?? 0,
      completedJobsCount: (json['completedJobsCount'] as num?)?.toInt() ?? 0,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      dailyTrajectory: daily,
      activeOffers: offers,
      todaySchedule: sched,
    );
  }
}

