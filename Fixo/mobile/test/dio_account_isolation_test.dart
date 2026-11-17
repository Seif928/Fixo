import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';

const _a = StoredAuthTokens(
  accessToken: 'a-token',
  refreshToken: 'a-refresh',
  userId: 'a',
  phone: '',
  role: 'CUSTOMER',
);
const _b = StoredAuthTokens(
  accessToken: 'b-token',
  refreshToken: 'b-refresh',
  userId: 'b',
  phone: '',
  role: 'CUSTOMER',
);

class _PrivateAdapter implements HttpClientAdapter {
  int calls = 0;
  final started = Completer<void>();
  Completer<void>? release;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    calls++;
    if (!started.isCompleted) started.complete();
    if (release != null) await release!.future;
    return ResponseBody.fromString(
      '{"private":"account-a"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ProviderContainer container;
  late MemoryTokenStorage storage;
  late Dio dio;
  late _PrivateAdapter adapter;
  setUp(() async {
    storage = MemoryTokenStorage();
    await storage.saveTokens(_a);
    container = ProviderContainer(
      overrides: [secureTokenStorageProvider.overrideWithValue(storage)],
    );
    container.read(activeSessionOwnerProvider.notifier).state = 'a';
    dio = container.read(dioClientProvider);
    adapter = _PrivateAdapter();
    dio.httpClientAdapter = adapter;
  });
  tearDown(() => container.dispose());
  test(
    'another tab changing stored account does not silently send that identity under the old UI',
    () async {
      await storage.saveTokens(_b);
      await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));
      expect(adapter.calls, 0);
      expect((await storage.readTokens())?.userId, 'b');
    },
  );
  for (final ended in [false, true]) {
    test(
      'late private response is rejected after ${ended ? 'logout' : 'account switch'}',
      () async {
        adapter.release = Completer<void>();
        final response = dio
            .get('/users/me')
            .then<Object>((value) => value, onError: (Object e) => e);
        await adapter.started.future;
        if (ended) {
          await storage.clearTokens();
        } else {
          await storage.saveTokens(_b);
        }
        container.read(activeSessionOwnerProvider.notifier).state = ended
            ? null
            : 'b';
        adapter.release!.complete();
        expect(await response, isA<DioException>());
      },
    );
  }
}
