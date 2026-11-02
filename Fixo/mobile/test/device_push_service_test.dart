import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/notifications/device_push_service.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';

class FakePushClient extends PushPlatformClient {
  bool allowed = true;
  int prompts = 0, deletions = 0;
  @override
  bool get supported => true;
  @override
  String get platform => 'ANDROID';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> permission({required bool request}) async {
    if (request) prompts++;
    return allowed;
  }

  @override
  Future<String?> token(String? vapidKey) async =>
      'test-only-registration-token';
  @override
  Future<void> deleteToken() async {
    deletions++;
  }

  @override
  Stream<String> get tokenRefresh => const Stream.empty();
  @override
  Stream<void> get foreground => const Stream.empty();
  @override
  Stream<String> get opened => const Stream.empty();
  @override
  Future<String?> initialBooking() async => null;
}

void main() {
  late DevicePushService service;
  late FakePushClient client;
  late List<RequestOptions> calls;
  bool configured = true;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = MemoryTokenStorage();
    await storage.saveTokens(
      const StoredAuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        userId: 'owner',
        phone: '',
        role: 'CUSTOMER',
      ),
    );
    calls = [];
    configured = true;
    client = FakePushClient();
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: request.path.endsWith('push-status')
                    ? {'configured': configured}
                    : {'id': 'registered-device', 'platform': 'ANDROID'},
              ),
            );
          },
        ),
      );
    service = DevicePushService(dio, storage, prefs, client);
    addTearDown(service.dispose);
  });
  test(
    'unconfigured sender does not trigger an OS permission prompt',
    () async {
      configured = false;
      expect(await service.enable(), PushOptInResult.unavailable);
      expect(client.prompts, 0);
      expect(calls.where((r) => r.method == 'POST'), isEmpty);
    },
  );
  test(
    'permission denial leaves in-app usage available and sends no device token',
    () async {
      client.allowed = false;
      expect(await service.enable(), PushOptInResult.denied);
      expect(calls.where((r) => r.method == 'POST'), isEmpty);
    },
  );
  test(
    'registers without client-supplied user ID, resumes silently, unregisters on disable',
    () async {
      expect(await service.enable(), PushOptInResult.enabled);
      expect(calls.last.data, {
        'token': 'test-only-registration-token',
        'platform': 'ANDROID',
      });
      await service.resume();
      expect(client.prompts, 1);
      await service.disable();
      expect(calls.last.method, 'DELETE');
      expect(calls.last.path, '/users/me/push-devices/registered-device');
      expect(client.deletions, 1);
    },
  );
}
