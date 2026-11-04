class AdminCatalogCategory {
  const AdminCatalogCategory(this.slug, this.en, this.ar);
  final String slug, en, ar;
  factory AdminCatalogCategory.fromJson(Map<String, dynamic> json) =>
      AdminCatalogCategory(
        json['categorySlug'] as String,
        json['categoryNameEn'] as String,
        json['categoryNameAr'] as String,
      );
}

class AdminCatalogDraft {
  const AdminCatalogDraft({
    required this.id,
    required this.version,
    required this.categorySlug,
    required this.categoryEn,
    required this.categoryAr,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    this.inspection,
    this.serviceFee,
    this.duration,
    this.publishedVersion,
    this.isActive = true,
  });
  final String id,
      categorySlug,
      categoryEn,
      categoryAr,
      titleEn,
      titleAr,
      descriptionEn,
      descriptionAr;
  final int version;
  final int? inspection, serviceFee, duration, publishedVersion;
  final bool isActive;
  int? get total => inspection == null || serviceFee == null
      ? null
      : inspection! + serviceFee!;
  bool get publishable => total != null && total! > 0 && duration != null;
  bool get hasChanges => publishedVersion != version;
  bool get isDeactivated => publishedVersion != null && !isActive;
  bool get isPublishedActive => publishedVersion != null && isActive;
  bool get isDraftOnly => publishedVersion == null;
  factory AdminCatalogDraft.fromJson(Map<String, dynamic> json) {
    int? amount(String field) {
      final value = json[field];
      if (value == null) return null;
      if (value is! int || value < 0) {
        throw const FormatException('Invalid draft price.');
      }
      if (field == 'estimatedDurationMins' && (value < 5 || value > 1440) ||
          field == 'publishedVersion' &&
              (value < 1 || value > (json['version'] as int)) ||
          (field == 'baseInspectionEgp' || field == 'serviceFeeEgp') &&
              value > 1000000) {
        throw const FormatException('Draft value outside the allowed range.');
      }
      return value;
    }

    if (json['version'] is! int || (json['version'] as int) < 1) {
      throw const FormatException('Invalid draft version.');
    }
    return AdminCatalogDraft(
      id: json['id'] as String,
      version: json['version'] as int,
      categorySlug: json['categorySlug'] as String,
      categoryEn: json['categoryNameEn'] as String,
      categoryAr: json['categoryNameAr'] as String,
      titleEn: json['titleEn'] as String,
      titleAr: json['titleAr'] as String,
      descriptionEn: json['descriptionEn'] as String,
      descriptionAr: json['descriptionAr'] as String,
      inspection: amount('baseInspectionEgp'),
      serviceFee: amount('serviceFeeEgp'),
      duration: amount('estimatedDurationMins'),
      publishedVersion: amount('publishedVersion'),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AdminCatalogPageModel {
  const AdminCatalogPageModel(
    this.items,
    this.categories,
    this.page,
    this.totalPages,
    this.total,
  );
  final List<AdminCatalogDraft> items;
  final List<AdminCatalogCategory> categories;
  final int page, totalPages, total;
  factory AdminCatalogPageModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map;
    if (meta['page'] is! int ||
        meta['totalPages'] is! int ||
        meta['total'] is! int ||
        meta['page'] < 1 ||
        meta['totalPages'] < 1 ||
        meta['total'] < 0) {
      throw const FormatException('Invalid catalog page.');
    }
    return AdminCatalogPageModel(
      (json['items'] as List)
          .map(
            (e) =>
                AdminCatalogDraft.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      (json['categories'] as List)
          .map(
            (e) => AdminCatalogCategory.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      meta['page'] as int,
      meta['totalPages'] as int,
      meta['total'] as int,
    );
  }
}
