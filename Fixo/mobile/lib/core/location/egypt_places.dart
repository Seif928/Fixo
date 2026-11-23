import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    : byId = {for (final p in places) p.id: p} {
    for (final p in places) {
      if (p.parent == null) {
        _governorates.add(p);
      } else {
        (_childrenByGov[p.governorateId] ??= <EgyptPlace>[]).add(p);
      }
    }
    for (final entry in _childrenByGov.entries) {
      for (final p in entry.value) {
        final parent = byId[p.parent];
        _searchById[p.id] = normalizePlaceName(
          '${p.nameEn} ${p.nameAr} ${parent?.nameAr ?? ''} ${parent?.nameEn ?? ''}',
        );
      }
    }
  }

  final Map<String, EgyptPlace> byId;
  final List<EgyptPlace> _governorates = <EgyptPlace>[];
  final Map<String, List<EgyptPlace>> _childrenByGov =
      <String, List<EgyptPlace>>{};
  final Map<String, String> _searchById = <String, String>{};

  List<EgyptPlace> get governorates => List.unmodifiable(_governorates);

  List<EgyptPlace> search(String governorateId, String query) {
    final children = _childrenByGov[governorateId];
    if (children == null || children.isEmpty) return const <EgyptPlace>[];
    final q = normalizePlaceName(query);
    if (q.isEmpty) {
      return children
          .where((p) => p.parent == governorateId)
          .take(50)
          .toList();
    }
    final results = <EgyptPlace>[];
    for (final p in children) {
      if ((_searchById[p.id] ?? '').contains(q)) {
        results.add(p);
        if (results.length >= 50) break;
      }
    }
    return results;
  }

  String localLabel(EgyptPlace place, bool ar) {
    final parent = byId[place.parent];
    return parent == null || parent.parent == null
        ? place.name(ar)
        : '${place.name(ar)}، ${parent.name(ar)}';
  }
}

List<EgyptPlace> _parseEgyptPlacesList(String rawJson) {
  final data = jsonDecode(rawJson) as Map<String, dynamic>;
  return (data['places'] as List)
      .map((p) => EgyptPlace.fromJson(Map<String, dynamic>.from(p)))
      .toList();
}

final egyptPlacesProvider = FutureProvider<EgyptPlaces>((ref) async {
  final raw = await rootBundle.loadString('assets/locations/egypt.json');
  final places = await compute(_parseEgyptPlacesList, raw);
  return EgyptPlaces(places);
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
