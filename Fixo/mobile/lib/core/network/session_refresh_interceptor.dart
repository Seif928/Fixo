import 'package:dio/dio.dart';
import '../../features/auth/domain/auth_models.dart';
import '../storage/secure_token_storage.dart';

/// One refresh for simultaneous 401s. Never replay an old user's request as a
/// newly signed-in user, and never retry password/authentication endpoints.
class SessionRefreshInterceptor extends Interceptor {
  SessionRefreshInterceptor(
    this.api,
    this.refreshApi,
    this.storage,
    this.onExpired,
  );
  final Dio api, refreshApi;
  final SecureTokenStorage storage;
  final void Function() onExpired;
  Future<bool>? _refreshing;

  Future<bool> _refresh(StoredAuthTokens original) async {
    try {
      final response = await refreshApi.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': original.refreshToken},
      );
      final session = AuthSession.fromJson(response.data!);
      final current = await storage.readTokens();
      if (current?.userId != original.userId ||
          current?.refreshToken != original.refreshToken) {
        return false;
      }
      if (session.user.id != original.userId) {
        await _expire(original);
        return false;
      }
      await storage.saveTokens(
        StoredAuthTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          userId: session.user.id,
          phone: session.user.phone,
          role: session.user.role,
        ),
      );
      return true;
    } on DioException catch (error) {
      if ([400, 401, 403].contains(error.response?.statusCode)) {
        await _expire(original);
      }
      return false; // Connection/provider failures preserve credentials for retry.
    } on FormatException {
      await _expire(original);
      return false;
    }
  }

  Future<void> _expire(StoredAuthTokens original) async {
    final current = await storage.readTokens();
    if (current?.userId == original.userId &&
        current?.refreshToken == original.refreshToken) {
      await storage.clearTokens();
      onExpired();
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        (request.path.startsWith('/auth/') &&
            request.path != '/auth/first-profile')) {
      handler.next(error);
      return;
    }
    try {
      final original = await storage.readTokens();
      if (original == null ||
          original.userId != request.extra['fixo_session_user']) {
        handler.next(error);
        return;
      }
      if (request.extra['fixo_refresh_retry'] == true) {
        await _expire(original);
        handler.next(error);
        return;
      }
      final usedToken = request.headers['Authorization'];
      if (usedToken == 'Bearer ${original.accessToken}') {
        _refreshing ??= _refresh(
          original,
        ).whenComplete(() => _refreshing = null);
        if (!await _refreshing!) {
          handler.next(error);
          return;
        }
      }
      final current = await storage.readTokens();
      if (current == null || current.userId != original.userId) {
        handler.next(error);
        return;
      }
      request.extra['fixo_refresh_retry'] = true;
      request.headers['Authorization'] = 'Bearer ${current.accessToken}';
      try {
        handler.resolve(await api.fetch<dynamic>(request));
      } on DioException catch (retryError) {
        handler.next(retryError);
      }
    } catch (_) {
      handler.next(error);
    }
  }
}
