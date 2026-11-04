import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'favorites_models.dart';

class FavoritesRepository {
  const FavoritesRepository(this._dio);

  final Dio _dio;

  Future<FavoriteIdsResponse> getFavoriteIds() async {
    final response = await _dio.get<Map<String, dynamic>>('/favorites/ids');
    return FavoriteIdsResponse.fromJson(response.data ?? {});
  }

  Future<FavoritesPageResponse<FavoriteServiceItem>> listFavoriteServices({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/favorites/services',
      queryParameters: {'page': page, 'limit': limit},
    );
    return FavoritesPageResponse.fromJson(
      response.data ?? {},
      (item) => FavoriteServiceItem.fromJson(item),
    );
  }

  Future<bool> addFavoriteService(String offeringId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/favorites/services/$offeringId',
    );
    return response.data?['favorited'] as bool? ?? true;
  }

  Future<bool> removeFavoriteService(String offeringId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/favorites/services/$offeringId',
    );
    return response.data?['favorited'] as bool? ?? false;
  }

  Future<FavoritesPageResponse<FavoriteProfessionalItem>> listFavoriteProfessionals({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/favorites/professionals',
      queryParameters: {'page': page, 'limit': limit},
    );
    return FavoritesPageResponse.fromJson(
      response.data ?? {},
      (item) => FavoriteProfessionalItem.fromJson(item),
    );
  }

  Future<bool> addFavoriteProfessional(String proProfileId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/favorites/professionals/$proProfileId',
    );
    return response.data?['favorited'] as bool? ?? true;
  }

  Future<bool> removeFavoriteProfessional(String proProfileId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/favorites/professionals/$proProfileId',
    );
    return response.data?['favorited'] as bool? ?? false;
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return FavoritesRepository(dio);
});

final favoriteIdsProvider = FutureProvider.autoDispose<FavoriteIdsResponse>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.getFavoriteIds();
});
