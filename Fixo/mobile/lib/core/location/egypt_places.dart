import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String normalizePlaceName(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class EgyptPlace {
  const EgyptPlace({
    required this.id,
    required this.governorateId,
    required this.nameEn,
    required this.nameAr,
    this.parent,
    this.slug,
  });
  final String id, governorateId, nameEn, nameAr;
  final String? parent, slug;
  String name(bool ar) => ar ? nameAr : nameEn;
  factory EgyptPlace.fromJson(Map<String, dynamic> json) => EgyptPlace(
    id: json['id'] as String,
    governorateId: json['governorateId'] as String,
    nameEn: json['nameEn'] as String,
    nameAr: json['nameAr'] as String,
    parent: json['parent'] as String?,
    slug: json['slug'] as String?,
  );
}

/// Name lookup only: catalog centroids cannot become address coordinates.
class EgyptPlaces {
  EgyptPlaces(List<EgyptPlace> places)
    : byId = {for (final p in places) p.id: p};
  final Map<String, EgyptPlace> byId;
  List<EgyptPlace> get governorates =>
      byId.values.where((p) => p.parent == null).toList();
  List<EgyptPlace> search(String governorateId, String query) {
    final q = normalizePlaceName(query);
    return byId.values
        .where(
          (p) =>
              p.governorateId == governorateId &&
              p.parent != null &&
              (q.isEmpty
                  ? p.parent == governorateId
                  : normalizePlaceName(
                      '${p.nameEn} ${p.nameAr} ${byId[p.parent]?.nameAr ?? ''} ${byId[p.parent]?.nameEn ?? ''}',
                    ).contains(q)),
        )
        .take(50)
        .toList();
  }

  String localLabel(EgyptPlace place, bool ar) {
    final parent = byId[place.parent];
    return parent == null || parent.parent == null
        ? place.name(ar)
        : '${place.name(ar)}، ${parent.name(ar)}';
  }
}

final egyptPlacesProvider = FutureProvider<EgyptPlaces>((ref) async {
  final data =
      jsonDecode(await rootBundle.loadString('assets/locations/egypt.json'))
          as Map<String, dynamic>;
  return EgyptPlaces(
    (data['places'] as List)
        .map((p) => EgyptPlace.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
  );
});

class SelectedServiceArea {
  const SelectedServiceArea({
    required this.zoneSlug,
    required this.governorateEn,
    required this.governorateAr,
    this.localityEn = '',
    this.localityAr = '',
  });
  final String zoneSlug, governorateEn, governorateAr, localityEn, localityAr;
  String label(bool ar) {
    final local = ar ? localityAr : localityEn;
    final gov = ar ? governorateAr : governorateEn;
    return local.isEmpty ? gov : '$local، $gov';
  }

  Map<String, String> toJson() => {
    'zoneSlug': zoneSlug,
    'governorateEn': governorateEn,
    'governorateAr': governorateAr,
    'localityEn': localityEn,
    'localityAr': localityAr,
  };
  factory SelectedServiceArea.fromJson(Map<String, dynamic> json) {
    for (final field in ['zoneSlug', 'governorateEn', 'governorateAr']) {
      if (json[field] is! String || (json[field] as String).trim().isEmpty) {
        throw const FormatException('Invalid area');
      }
    }
    return SelectedServiceArea(
      zoneSlug: json['zoneSlug'],
      governorateEn: json['governorateEn'],
      governorateAr: json['governorateAr'],
      localityEn: json['localityEn'] as String? ?? '',
      localityAr: json['localityAr'] as String? ?? '',
    );
  }
}
