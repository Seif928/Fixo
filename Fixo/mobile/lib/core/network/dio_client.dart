import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_token_storage.dart';

/// Central Dio HTTP client configured for the FIXO NestJS backend (`/api/v1`).
///
/// Automatically attaches the `Authorization: Bearer <accessToken>` header
/// when a valid session is present in `SecureTokenStorage`.
final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'FIXO_API_BASE_URL',
        defaultValue: 'http://localhost:3000/api/v1',
      ),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await tokenStorage.readAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});
