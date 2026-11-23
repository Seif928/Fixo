import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/marketplace_models.dart';

class MarketplaceApiException implements Exception {
  const MarketplaceApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class MarketplaceRepository {
  Future<CustomerHomeFeed> fetchCustomerHomeFeed({
    String? search,
    String? categoryId,
    String? zone,
  });

  Future<ServiceOfferModel> fetchServiceById(String id);

  Future<PaginatedServices> getPaginatedServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
  });
}

/// Real Dio-backed implementation of `MarketplaceRepository` consuming:
/// - `GET /api/v1/services/categories`
/// - `GET /api/v1/services`
/// - `GET /api/v1/services/:id`
/// - `GET /api/v1/professionals`
class DioMarketplaceRepository implements MarketplaceRepository {
  const DioMarketplaceRepository(this._dio);

  final Dio _dio;

  static final Expando<_CachedCategoriesEntry> _categoriesCacheByDio =
      Expando<_CachedCategoriesEntry>('fixoCategoriesCache');

  static final Expando<Map<String, _CachedFeedEntry>> _feedCacheByDio =
      Expando<Map<String, _CachedFeedEntry>>('fixoFeedCache');

  static const Duration _categoriesCacheTtl = Duration(minutes: 5);
  static const Duration _feedCacheTtl = Duration(seconds: 45);

  Future<Response<Map<String, dynamic>>> _getCategoriesDeduped() {
    final now = DateTime.now();
    final existing = _categoriesCacheByDio[_dio];
    if (existing != null && now.isBefore(existing.expiresAt)) {
      return existing.future;
    }

    final future = _dio.get<Map<String, dynamic>>('/services/categories');
    final entry = _CachedCategoriesEntry(
      future: future,
      expiresAt: now.add(_categoriesCacheTtl),
    );
    _categoriesCacheByDio[_dio] = entry;

    future.catchError((Object error) {
      if (identical(_categoriesCacheByDio[_dio], entry)) {
        _categoriesCacheByDio[_dio] = null;
      }
      throw error;
    });

    return future;
  }

  @override
  Future<CustomerHomeFeed> fetchCustomerHomeFeed({
    String? search,
    String? categoryId,
    String? zone,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    final isDefaultFeed =
        (search == null || search.trim().isEmpty) &&
        (categoryId == null || categoryId.trim().isEmpty);
    final zoneKey = zone?.trim() ?? '';
    final now = DateTime.now();
    if (isDefaultFeed && !forceRefresh) {
      final cachedMap = _feedCacheByDio[_dio];
      final cachedEntry = cachedMap?[zoneKey];
      if (cachedEntry != null && now.isBefore(cachedEntry.expiresAt)) {
        return cachedEntry.feed;
      }
    }

    try {
      final categoriesFuture = _getCategoriesDeduped();
      final servicesFuture = _dio.get<Map<String, dynamic>>(
        '/services',
        cancelToken: cancelToken,
        queryParameters: <String, dynamic>{
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (categoryId != null && categoryId.trim().isNotEmpty)
            'categoryId': categoryId.trim(),
          'page': 1,
          'limit': 200,
        },
      );
      final prosFuture = _dio.get<Map<String, dynamic>>(
        '/professionals',
        cancelToken: cancelToken,
        queryParameters: <String, dynamic>{
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (categoryId != null && categoryId.trim().isNotEmpty)
            'categoryId': categoryId.trim(),
          if (zone != null && zone.trim().isNotEmpty) 'zone': zone.trim(),
          'page': 1,
          'limit': 50,
        },
      );

      final responses = await Future.wait<Response<Map<String, dynamic>>>([
        categoriesFuture,
        servicesFuture,
        prosFuture,
      ]);

      final categoriesPayload = responses[0].data ?? const <String, dynamic>{};
      final servicesPayload = responses[1].data ?? const <String, dynamic>{};
      final prosPayload = responses[2].data ?? const <String, dynamic>{};

      final rawCategories =
          (categoriesPayload['categories'] as List<dynamic>?) ?? const <dynamic>[];
      final rawZones =
          (categoriesPayload['zones'] as List<dynamic>?) ?? const <dynamic>[];
      final rawServices =
          (servicesPayload['items'] as List<dynamic>?) ?? const <dynamic>[];
      final rawPros =
          (prosPayload['items'] as List<dynamic>?) ?? const <dynamic>[];

      final meta =
          (categoriesPayload['meta'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};

      final feed = CustomerHomeFeed(
        zones: rawZones
            .whereType<Map<String, dynamic>>()
            .map(CoverageZoneModel.fromJson)
            .toList(),
        categories: rawCategories
            .whereType<Map<String, dynamic>>()
            .map(ServiceCategoryModel.fromJson)
            .toList(),
        services: rawServices
            .whereType<Map<String, dynamic>>()
            .map(ServiceOfferModel.fromJson)
            .toList(),
        professionals: rawPros
            .whereType<Map<String, dynamic>>()
            .map(ProfessionalCardModel.fromJson)
            .toList(),
        storageMode: meta['storageMode'] as String? ?? 'UNKNOWN',
        databaseConnected: meta['databaseConnected'] as bool? ?? false,
      );
      if (isDefaultFeed) {
        final cacheMap = _feedCacheByDio[_dio] ??= <String, _CachedFeedEntry>{};
        cacheMap[zoneKey] = _CachedFeedEntry(
          feed: feed,
          expiresAt: DateTime.now().add(_feedCacheTtl),
        );
      }
      return feed;
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback:
            'Unable to load Cairo & Giza marketplace services. Please check that the FIXO backend server is running.',
      );
    }
  }

  @override
  Future<ServiceOfferModel> fetchServiceById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/services/$id');
      final data = response.data ?? const <String, dynamic>{};
      final serviceJson =
          (data['service'] as Map<String, dynamic>?) ?? data;
      return ServiceOfferModel.fromJson(serviceJson);
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'Requested service details could not be loaded.',
      );
    }
  }

  @override
  Future<PaginatedServices> getPaginatedServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/services',
        cancelToken: cancelToken,
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (categoryId != null && categoryId.trim().isNotEmpty)
            'categoryId': categoryId.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Service catalog is unavailable.');
      }
      return PaginatedServices.fromJson(data, expectedPage: page);
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'Could not load service catalog.',
      );
    }
  }

  MarketplaceApiException _mapError(
    DioException error, {
    required String fallback,
  }) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        return MarketplaceApiException(msg, statusCode: statusCode);
      }
    }
    return MarketplaceApiException(fallback, statusCode: statusCode);
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DioMarketplaceRepository(dio);
});

class _CachedCategoriesEntry {
  const _CachedCategoriesEntry({
    required this.future,
    required this.expiresAt,
  });

  final Future<Response<Map<String, dynamic>>> future;
  final DateTime expiresAt;
}

class _CachedFeedEntry {
  const _CachedFeedEntry({
    required this.feed,
    required this.expiresAt,
  });

  final CustomerHomeFeed feed;
  final DateTime expiresAt;
}

