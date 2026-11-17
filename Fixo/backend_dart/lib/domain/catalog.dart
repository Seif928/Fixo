abstract interface class DatabaseProbe {
  Future<bool> ping();
}

abstract interface class CatalogRepository {
  Future<CatalogSnapshot> categories();
}

final class Category {
  const Category({
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
  final String id, slug, nameEn, nameAr, subtitleEn, subtitleAr, iconName;
  final int startingPriceEgp, sortOrder;
}

final class Zone {
  const Zone({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameAr,
    required this.governorate,
  });
  final String id, slug, nameEn, nameAr, governorate;
}

final class CatalogSnapshot {
  CatalogSnapshot({
    required List<Category> categories,
    required List<Zone> zones,
  }) : categories = List.unmodifiable(categories),
       zones = List.unmodifiable(zones);
  final List<Category> categories;
  final List<Zone> zones;
}
