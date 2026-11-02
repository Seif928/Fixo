import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_token_storage.dart';
import 'session_refresh_interceptor.dart';

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
        final tokens = await tokenStorage.readTokens();
        final requestOwner = options.extra['fixo_session_user'];
        final activeOwner = ref.read(activeSessionOwnerProvider);
        final authBootstrap =
            options.path.startsWith('/auth/') &&
            options.path != '/auth/first-profile';
        if (!authBootstrap &&
            ((requestOwner != null && requestOwner != activeOwner) ||
                tokens?.userId != activeOwner)) {
          if (requestOwner == null && activeOwner != null) {
            ref.read(sessionExpiredProvider.notifier).state++;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: 'The account session changed. Please sign in again.',
            ),
          );
          return;
        }
        if (options.extra['fixo_refresh_retry'] == true &&
            requestOwner != tokens?.userId) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message:
                  'The account changed before this request could be retried.',
            ),
          );
          return;
        }
        if (tokens != null && tokens.accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          options.extra['fixo_session_user'] = tokens.userId;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final request = response.requestOptions;
        final owner = request.extra['fixo_session_user'];
        final authBootstrap =
            request.path.startsWith('/auth/') &&
            request.path != '/auth/first-profile';
        if (!authBootstrap &&
            owner != null &&
            owner != ref.read(activeSessionOwnerProvider)) {
          handler.reject(
            DioException(
              requestOptions: request,
              type: DioExceptionType.cancel,
              message: 'The account changed before this response completed.',
            ),
          );
          return;
        }
        handler.next(response);
      },
    ),
  );

  final refreshDio = Dio(
    BaseOptions(
      baseUrl: resolveDefaultApiBaseUrl(),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );
  dio.interceptors.add(
    SessionRefreshInterceptor(
      dio,
      refreshDio,
      tokenStorage,
      () => ref.read(sessionExpiredProvider.notifier).state++,
    ),
  );
  ref.onDispose(() {
    dio.close();
    refreshDio.close();
  });

  return dio;
});
