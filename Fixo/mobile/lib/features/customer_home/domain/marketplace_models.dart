/// Domain models for Screen 03 (`03 — Customer Home`) and the Services/Professionals API.
class CoverageZoneModel {
  const CoverageZoneModel({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameAr,
    required this.governorate,
    this.isActive = true,
  });

  final String id;
  final String slug;
  final String nameEn;
  final String nameAr;
  final String governorate;
  final bool isActive;

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  factory CoverageZoneModel.fromJson(Map<String, dynamic> json) {
    for (final field in ['id', 'slug', 'nameEn', 'nameAr', 'governorate']) {
      if (json[field] is! String || (json[field] as String).trim().isEmpty) {
        throw const FormatException('Invalid coverage area.');
      }
    }
    return CoverageZoneModel(
      id: json['id'],
      slug: json['slug'],
      nameEn: json['nameEn'],
      nameAr: json['nameAr'],
      governorate: json['governorate'],
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'nameEn': nameEn,
    'nameAr': nameAr,
    'governorate': governorate,
    'isActive': isActive,
  };
}

class ServiceCategoryModel {
  const ServiceCategoryModel({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.iconName,
    required this.startingPriceEgp,
    required this.sortOrder,
  });

  final String id;
  final String slug;
  final String nameEn;
  final String nameAr;
  final String subtitleEn;
  final String subtitleAr;
  final String iconName;
  final int startingPriceEgp;
  final int sortOrder;

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
  String localizedSubtitle(bool isArabic) => isArabic ? subtitleAr : subtitleEn;

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      subtitleEn: json['subtitleEn'] as String? ?? '',
      subtitleAr: json['subtitleAr'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'handyman',
      startingPriceEgp: (json['startingPriceEgp'] as num?)?.toInt() ?? 250,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'nameEn': nameEn,
    'nameAr': nameAr,
    'subtitleEn': subtitleEn,
    'subtitleAr': subtitleAr,
    'iconName': iconName,
    'startingPriceEgp': startingPriceEgp,
    'sortOrder': sortOrder,
  };
}

class ServiceOfferModel {
  const ServiceOfferModel({
    required this.id,
    required this.categoryId,
    required this.categorySlug,
    required this.slug,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.baseInspectionEgp,
    required this.serviceFeeEgp,
    required this.flatPriceEgp,
    required this.estimatedDurationMins,
    required this.isSeasonalPromo,
    required this.isBundle,
    this.badgeEn,
    this.badgeAr,
    this.providerTagEn,
    this.providerTagAr,
  });

  final String id;
  final String categoryId;
  final String categorySlug;
  final String slug;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final String? badgeEn;
  final String? badgeAr;
  final String? providerTagEn;
  final String? providerTagAr;
  final int baseInspectionEgp;
  final int serviceFeeEgp;
  final int flatPriceEgp;
  final int estimatedDurationMins;
  final bool isSeasonalPromo;
  final bool isBundle;

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String localizedDescription(bool isArabic) =>
      isArabic ? descriptionAr : descriptionEn;
  String? localizedBadge(bool isArabic) => isArabic ? badgeAr : badgeEn;
  String? localizedProviderTag(bool isArabic) =>
      isArabic ? providerTagAr : providerTagEn;

  factory ServiceOfferModel.fromJson(Map<String, dynamic> json) {
    final baseEgp = (json['baseInspectionEgp'] as num?)?.toInt() ?? 150;
    final feeEgp = (json['serviceFeeEgp'] as num?)?.toInt() ?? 200;
    return ServiceOfferModel(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categorySlug: json['categorySlug'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      badgeEn: json['badgeEn'] as String?,
      badgeAr: json['badgeAr'] as String?,
      providerTagEn: json['providerTagEn'] as String?,
      providerTagAr: json['providerTagAr'] as String?,
      baseInspectionEgp: baseEgp,
      serviceFeeEgp: feeEgp,
      flatPriceEgp:
          (json['flatPriceEgp'] as num?)?.toInt() ?? (baseEgp + feeEgp),
      estimatedDurationMins:
          (json['estimatedDurationMins'] as num?)?.toInt() ?? 60,
      isSeasonalPromo: json['isSeasonalPromo'] as bool? ?? false,
      isBundle: json['isBundle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'categorySlug': categorySlug,
    'slug': slug,
    'titleEn': titleEn,
    'titleAr': titleAr,
    'descriptionEn': descriptionEn,
    'descriptionAr': descriptionAr,
    'badgeEn': badgeEn,
    'badgeAr': badgeAr,
    'providerTagEn': providerTagEn,
    'providerTagAr': providerTagAr,
    'baseInspectionEgp': baseInspectionEgp,
    'serviceFeeEgp': serviceFeeEgp,
    'flatPriceEgp': flatPriceEgp,
    'estimatedDurationMins': estimatedDurationMins,
    'isSeasonalPromo': isSeasonalPromo,
    'isBundle': isBundle,
  };
}

class ProfessionalCardModel {
  const ProfessionalCardModel({
    required this.id,
    required this.fullNameEn,
    required this.fullNameAr,
    required this.primaryCategoryId,
    required this.primaryCategorySlug,
    required this.primaryZoneSlug,
    required this.specialtyEn,
    required this.specialtyAr,
    required this.zonesLabelEn,
    required this.zonesLabelAr,
    required this.ratingAvg,
    required this.reviewsCount,
    required this.estimatedPriceEgp,
    required this.badgeEn,
    required this.badgeAr,
    required this.badgeVariant,
    required this.isOnline,
  });

  final String id;
  final String fullNameEn;
  final String fullNameAr;
  final String primaryCategoryId;
  final String primaryCategorySlug;
  final String primaryZoneSlug;
  final String specialtyEn;
  final String specialtyAr;
  final String zonesLabelEn;
  final String zonesLabelAr;
  final double ratingAvg;
  final int reviewsCount;
  final int estimatedPriceEgp;
  final String badgeEn;
  final String badgeAr;
  final String badgeVariant;
  final bool isOnline;

  String localizedName(bool isArabic) => isArabic ? fullNameAr : fullNameEn;
  String localizedSpecialty(bool isArabic) =>
      isArabic ? specialtyAr : specialtyEn;
  String localizedZones(bool isArabic) =>
      isArabic ? zonesLabelAr : zonesLabelEn;
  String localizedBadge(bool isArabic) => isArabic ? badgeAr : badgeEn;

  bool get isFastResponder => badgeVariant == 'fast_responder';

  factory ProfessionalCardModel.fromJson(Map<String, dynamic> json) {
    final price = json['estimatedPriceEgp'];
    if (price is! num ||
        !price.isFinite ||
        price < 0 ||
        price != price.roundToDouble()) {
      throw const FormatException('Invalid professional pricing.');
    }
    return ProfessionalCardModel(
      id: json['id'] as String? ?? '',
      fullNameEn: json['fullNameEn'] as String? ?? '',
      fullNameAr: json['fullNameAr'] as String? ?? '',
      primaryCategoryId: json['primaryCategoryId'] as String? ?? '',
      primaryCategorySlug: json['primaryCategorySlug'] as String? ?? '',
      primaryZoneSlug: json['primaryZoneSlug'] as String? ?? '',
      specialtyEn: json['specialtyEn'] as String? ?? '',
      specialtyAr: json['specialtyAr'] as String? ?? '',
      zonesLabelEn: json['zonesLabelEn'] as String? ?? '',
      zonesLabelAr: json['zonesLabelAr'] as String? ?? '',
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      estimatedPriceEgp: price.toInt(),
      badgeEn: json['badgeEn'] as String? ?? '',
      badgeAr: json['badgeAr'] as String? ?? '',
      badgeVariant: json['badgeVariant'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullNameEn': fullNameEn,
    'fullNameAr': fullNameAr,
    'primaryCategoryId': primaryCategoryId,
    'primaryCategorySlug': primaryCategorySlug,
    'primaryZoneSlug': primaryZoneSlug,
    'specialtyEn': specialtyEn,
    'specialtyAr': specialtyAr,
    'zonesLabelEn': zonesLabelEn,
    'zonesLabelAr': zonesLabelAr,
    'ratingAvg': ratingAvg,
    'reviewsCount': reviewsCount,
    'estimatedPriceEgp': estimatedPriceEgp,
    'badgeEn': badgeEn,
    'badgeAr': badgeAr,
    'badgeVariant': badgeVariant,
    'isOnline': isOnline,
  };
}

class CustomerHomeFeed {
  const CustomerHomeFeed({
    required this.zones,
    required this.categories,
    required this.services,
    required this.professionals,
    required this.storageMode,
    required this.databaseConnected,
  });

  final List<CoverageZoneModel> zones;
  final List<ServiceCategoryModel> categories;
  final List<ServiceOfferModel> services;
  final List<ProfessionalCardModel> professionals;
  final String storageMode;
  final bool databaseConnected;

  factory CustomerHomeFeed.fromJson(Map<String, dynamic> json) {
    return CustomerHomeFeed(
      zones: (json['zones'] as List<dynamic>? ?? const [])
          .map((e) => CoverageZoneModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map((e) => ServiceCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      services: (json['services'] as List<dynamic>? ?? const [])
          .map((e) => ServiceOfferModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      professionals: (json['professionals'] as List<dynamic>? ?? const [])
          .map((e) => ProfessionalCardModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      storageMode: json['storageMode'] as String? ?? 'CACHED',
      databaseConnected: json['databaseConnected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'zones': zones.map((z) => z.toJson()).toList(),
    'categories': categories.map((c) => c.toJson()).toList(),
    'services': services.map((s) => s.toJson()).toList(),
    'professionals': professionals.map((p) => p.toJson()).toList(),
    'storageMode': storageMode,
    'databaseConnected': databaseConnected,
  };

  ServiceOfferModel? get seasonalPromo {
    for (final offer in services) {
      if (offer.isSeasonalPromo) {
        return offer;
      }
    }
    return null;
  }

  ServiceOfferModel? get bundleOffer {
    for (final offer in services) {
      if (offer.isBundle) {
        return offer;
      }
    }
    return null;
  }
}

class PaginatedServices {
  const PaginatedServices({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.limit = 20,
  });

  final List<ServiceOfferModel> items;
  final int page;
  final int totalPages;
  final int total;
  final int limit;

  factory PaginatedServices.fromJson(
    Map<String, dynamic> json, {
    int? expectedPage,
  }) {
    if (json['items'] is! List || json['meta'] is! Map) {
      throw const FormatException('Service catalog is unavailable.');
    }
    final meta = json['meta'] as Map<dynamic, dynamic>;
    final pages = meta['totalPages'];
    final currentPage = (meta['page'] as num?)?.toInt() ?? 1;
    if (pages is! int ||
        pages < 1 ||
        (expectedPage != null && currentPage != expectedPage)) {
      throw const FormatException('Service catalog pagination is invalid.');
    }
    final totalItems = (meta['total'] as num?)?.toInt() ?? (pages * 20);
    final pageLimit = (meta['limit'] as num?)?.toInt() ?? 20;

    final rawList = json['items'] as List<dynamic>;
    final parsedItems = rawList.map((value) {
      final itemMap = Map<String, dynamic>.from(value as Map);
      // Enforce price integrity: prices must be finite, non-negative, and integer EGP
      for (final field in [
        'baseInspectionEgp',
        'serviceFeeEgp',
        'flatPriceEgp',
      ]) {
        final val = itemMap[field];
        if (val is! num || !val.isFinite || val < 0 || val % 1 != 0) {
          throw const FormatException('Service price is unavailable.');
        }
      }
      if (itemMap['id'] is! String || (itemMap['id'] as String).isEmpty) {
        throw const FormatException('Service identity is unavailable.');
      }
      return ServiceOfferModel.fromJson(itemMap);
    }).toList();

    return PaginatedServices(
      items: parsedItems,
      page: currentPage,
      totalPages: pages,
      total: totalItems,
      limit: pageLimit,
    );
  }
}
