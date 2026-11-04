import '../../customer_home/domain/marketplace_models.dart';

class FavoriteServiceItem {
  const FavoriteServiceItem({
    required this.id,
    required this.offeringId,
    required this.createdAt,
    required this.isAvailable,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.baseInspectionEgp,
    required this.serviceFeeEgp,
    required this.flatPriceEgp,
    required this.estimatedDurationMins,
    required this.categorySlug,
    required this.categoryNameEn,
    required this.categoryNameAr,
    required this.categoryIcon,
    required this.isActive,
  });

  final String id;
  final String offeringId;
  final DateTime createdAt;
  final bool isAvailable;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final int baseInspectionEgp;
  final int serviceFeeEgp;
  final int flatPriceEgp;
  final int estimatedDurationMins;
  final String categorySlug;
  final String categoryNameEn;
  final String categoryNameAr;
  final String categoryIcon;
  final bool isActive;

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String localizedDescription(bool isArabic) =>
      isArabic ? descriptionAr : descriptionEn;
  String localizedCategoryName(bool isArabic) =>
      isArabic ? categoryNameAr : categoryNameEn;

  ServiceOfferModel toServiceOfferModel() {
    return ServiceOfferModel(
      id: offeringId,
      categoryId: categorySlug,
      categorySlug: categorySlug,
      slug: offeringId,
      titleEn: titleEn,
      titleAr: titleAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      baseInspectionEgp: baseInspectionEgp,
      serviceFeeEgp: serviceFeeEgp,
      flatPriceEgp: flatPriceEgp,
      estimatedDurationMins: estimatedDurationMins,
      isSeasonalPromo: false,
      isBundle: false,
    );
  }

  factory FavoriteServiceItem.fromJson(Map<String, dynamic> json) {
    final offering = (json['offering'] as Map<String, dynamic>?) ?? {};
    final category = (offering['category'] as Map<String, dynamic>?) ?? {};
    final base = (offering['baseInspectionEgp'] as num?)?.toInt() ?? 150;
    final fee = (offering['serviceFeeEgp'] as num?)?.toInt() ?? 50;
    return FavoriteServiceItem(
      id: json['id'] as String? ?? '',
      offeringId: json['offeringId'] as String? ?? offering['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      titleEn: offering['titleEn'] as String? ?? '',
      titleAr: offering['titleAr'] as String? ?? '',
      descriptionEn: offering['descriptionEn'] as String? ?? '',
      descriptionAr: offering['descriptionAr'] as String? ?? '',
      baseInspectionEgp: base,
      serviceFeeEgp: fee,
      flatPriceEgp:
          (offering['flatPriceEgp'] as num?)?.toInt() ?? (base + fee),
      estimatedDurationMins:
          (offering['estimatedDurationMins'] as num?)?.toInt() ?? 60,
      categorySlug: category['slug'] as String? ?? '',
      categoryNameEn: category['nameEn'] as String? ?? '',
      categoryNameAr: category['nameAr'] as String? ?? '',
      categoryIcon: category['iconName'] as String? ?? 'handyman',
      isActive: offering['isActive'] as bool? ?? true,
    );
  }
}

class FavoriteProfessionalItem {
  const FavoriteProfessionalItem({
    required this.id,
    required this.proProfileId,
    required this.createdAt,
    required this.isAvailable,
    required this.verificationStatus,
    required this.fullNameEn,
    required this.fullNameAr,
    required this.specialtyEn,
    required this.specialtyAr,
    required this.ratingAvg,
    required this.reviewsCount,
    required this.completedJobsCount,
    required this.isOnline,
    required this.categorySlug,
    required this.categoryNameEn,
    required this.categoryNameAr,
  });

  final String id;
  final String proProfileId;
  final DateTime createdAt;
  final bool isAvailable;
  final String verificationStatus;
  final String fullNameEn;
  final String fullNameAr;
  final String specialtyEn;
  final String specialtyAr;
  final double ratingAvg;
  final int reviewsCount;
  final int completedJobsCount;
  final bool isOnline;
  final String categorySlug;
  final String categoryNameEn;
  final String categoryNameAr;

  String localizedFullName(bool isArabic) => isArabic ? fullNameAr : fullNameEn;
  String localizedSpecialty(bool isArabic) => isArabic ? specialtyAr : specialtyEn;

  ProfessionalCardModel toProfessionalCardModel() {
    return ProfessionalCardModel(
      id: proProfileId,
      fullNameEn: fullNameEn,
      fullNameAr: fullNameAr,
      primaryCategoryId: categorySlug,
      primaryCategorySlug: categorySlug,
      primaryZoneSlug: '',
      specialtyEn: specialtyEn,
      specialtyAr: specialtyAr,
      zonesLabelEn: '',
      zonesLabelAr: '',
      ratingAvg: ratingAvg,
      reviewsCount: reviewsCount,
      estimatedPriceEgp: 250,
      badgeEn: 'Verified Pro',
      badgeAr: 'فني معتمد',
      badgeVariant: 'verified',
      isOnline: isOnline,
    );
  }

  factory FavoriteProfessionalItem.fromJson(Map<String, dynamic> json) {
    final pro = (json['professional'] as Map<String, dynamic>?) ?? {};
    final cat = (pro['primaryCategory'] as Map<String, dynamic>?) ?? {};
    return FavoriteProfessionalItem(
      id: json['id'] as String? ?? '',
      proProfileId: json['proProfileId'] as String? ?? pro['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isAvailable: json['isAvailable'] as bool? ?? false,
      verificationStatus: (json['verificationStatus'] ?? pro['verificationStatus']) as String? ?? 'DRAFT',
      fullNameEn: pro['fullNameEn'] as String? ?? 'FIXO technician',
      fullNameAr: pro['fullNameAr'] as String? ?? 'فني معتمد',
      specialtyEn: pro['specialtyEn'] as String? ?? '',
      specialtyAr: pro['specialtyAr'] as String? ?? '',
      ratingAvg: (pro['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (pro['reviewsCount'] as num?)?.toInt() ?? 0,
      completedJobsCount: (pro['completedJobsCount'] as num?)?.toInt() ?? 0,
      isOnline: pro['isOnline'] as bool? ?? false,
      categorySlug: cat['slug'] as String? ?? '',
      categoryNameEn: cat['nameEn'] as String? ?? '',
      categoryNameAr: cat['nameAr'] as String? ?? '',
    );
  }
}

class FavoriteIdsResponse {
  const FavoriteIdsResponse({
    required this.serviceIds,
    required this.proProfileIds,
  });

  final List<String> serviceIds;
  final List<String> proProfileIds;

  factory FavoriteIdsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteIdsResponse(
      serviceIds: (json['serviceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      proProfileIds: (json['proProfileIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class FavoritesPageResponse<T> {
  const FavoritesPageResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory FavoritesPageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) itemParser,
  ) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? {};
    final list = (json['items'] as List<dynamic>?) ?? const [];
    return FavoritesPageResponse<T>(
      items: list.map((e) => itemParser(e as Map<String, dynamic>)).toList(),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? 20,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
