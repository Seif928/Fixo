import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/network/session_refresh_interceptor.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.answer);
  final Future<(int, Map<String, dynamic>)> Function(RequestOptions) answer;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final (status, data) = await answer(options);
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late MemoryTokenStorage storage;
  late Dio api, refresh;
  int refreshCalls = 0, expired = 0;
  setUp(() async {
    storage = MemoryTokenStorage();
    refreshCalls = 0;
    expired = 0;
    await storage.saveTokens(
      const StoredAuthTokens(
        accessToken: 'old',
        refreshToken: 'refresh-old',
        userId: 'owner',
        phone: '',
        role: 'CUSTOMER',
      ),
    );
    refresh = Dio()
      ..httpClientAdapter = _Adapter((_) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return (
          200,
          {
            'accessToken': 'new',
            'refreshToken': 'refresh-new',
            'user': {'id': 'owner', 'role': 'CUSTOMER'},
          },
        );
      });
    api = Dio()
      ..httpClientAdapter = _Adapter(
        (request) async => request.headers['Authorization'] == 'Bearer new'
            ? (200, {'ok': true})
            : (401, {'message': 'expired'}),
      );
    api.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          final tokens = await storage.readTokens();
          request.headers['Authorization'] = 'Bearer ${tokens?.accessToken}';
          request.extra['fixo_session_user'] = tokens?.userId;
          handler.next(request);
        },
      ),
    );
    api.interceptors.add(
      SessionRefreshInterceptor(api, refresh, storage, () => expired++),
    );
  });
  test(
    'simultaneous expired requests rotate once and retry with the new token',
    () async {
      final results = await Future.wait([
        api.get('/users/me'),
        api.get('/bookings'),
      ]);
      expect(results.every((response) => response.statusCode == 200), true);
      expect(refreshCalls, 1);
      expect((await storage.readTokens())?.refreshToken, 'refresh-new');
    },
  );
  test(
    'revoked credentials are cleared and reported to the auth state',
    () async {
      refresh.httpClientAdapter = _Adapter(
        (_) async => (401, {'message': 'revoked'}),
      );
      await expectLater(api.get('/users/me'), throwsA(isA<DioException>()));
      expect(await storage.readTokens(), isNull);
      expect(expired, 1);
    },
  );
  test(
    'provider outage does not sign out or delete the refresh token',
    () async {
      refresh.httpClientAdapter = _Adapter(
        (_) async => (503, {'message': 'offline'}),
      );
      await expectLater(api.get('/users/me'), throwsA(isA<DioException>()));
      expect((await storage.readTokens())?.refreshToken, 'refresh-old');
      expect(expired, 0);
    },
  );
  test('wrong phone/password is never retried as a token refresh', () async {
    await expectLater(
      api.post('/auth/phone-password'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    expect(expired, 0);
  });
  test(
    'authenticated first-profile setup refreshes its expired session',
    () async {
      final response = await api.post('/auth/first-profile');
      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
    },
  );
  test('logout during refresh cannot restore the old session', () async {
    refresh.httpClientAdapter = _Adapter((_) async {
      await storage.clearTokens();
      return (
        200,
        {
          'accessToken': 'new',
          'refreshToken': 'refresh-new',
          'user': {'id': 'owner', 'role': 'CUSTOMER'},
        },
      );
    });
    await expectLater(api.get('/bookings'), throwsA(isA<DioException>()));
    expect(await storage.readTokens(), isNull);
    expect(expired, 0);
  });
  test('a second unauthorized response stops after one replay', () async {
    var calls = 0;
    api.httpClientAdapter = _Adapter((_) async {
      calls++;
      return (401, {'message': 'revoked'});
    });
    await expectLater(api.get('/users/me'), throwsA(isA<DioException>()));
    expect(calls, 2);
    expect(refreshCalls, 1);
    expect(await storage.readTokens(), isNull);
    expect(expired, 1);
  });
}
