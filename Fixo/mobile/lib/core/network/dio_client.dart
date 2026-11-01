import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_token_storage.dart';

/// Resolves the default base URL for the FIXO NestJS backend (`/api/v1`).
///
/// Priority:
/// 1. Compile-time `--dart-define=FIXO_API_BASE_URL=...`
/// 2. Android emulator host alias (`http://10.0.2.2:3001/api/v1`)
/// 3. Localhost default (`http://localhost:3001/api/v1`) for iOS simulator, Web, and Desktop.
String resolveDefaultApiBaseUrl() {
  const envUrl = String.fromEnvironment('FIXO_API_BASE_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3001/api/v1';
  }
  return 'http://localhost:3001/api/v1';
}

/// Central Dio HTTP client configured for the FIXO NestJS backend (`/api/v1`).
///
/// Automatically attaches the `Authorization: Bearer <accessToken>` header
/// when a valid session is present in `SecureTokenStorage`.
final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: resolveDefaultApiBaseUrl(),
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
