import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/notifications/device_push_service.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';

class FakePushClient extends PushPlatformClient {
  bool allowed = true;
  int prompts = 0, deletions = 0;
  final activities = StreamController<void>.broadcast(sync: true);
  final opens = StreamController<String>.broadcast(sync: true);
  Completer<void>? initializeGate, initializeEntered;
  @override
  bool get supported => true;
  @override
  String get platform => 'ANDROID';
  @override
  Future<void> initialize() async {
    initializeEntered?.complete();
    await initializeGate?.future;
  }
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
  Stream<void> get foreground => activities.stream;
  @override
  Stream<String> get opened => opens.stream;
  @override
  Future<String?> initialBooking() async => null;
}

void main() {
  late DevicePushService service;
  late FakePushClient client;
  late List<RequestOptions> calls;
  late SharedPreferences prefs;
  late MemoryTokenStorage storage;
  late Dio dio;
  Completer<void>? deleteGate, registerGate, deleteEntered, registerEntered;
  bool unregisterFails = false;
  bool configured = true;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = MemoryTokenStorage();
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
    unregisterFails = false;
    deleteGate = null;
    registerGate = null;
    deleteEntered = null;
    registerEntered = null;
    client = FakePushClient();
    dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            if (request.method == 'DELETE') {
              if (deleteEntered?.isCompleted == false) { deleteEntered!.complete(); }
              if (unregisterFails) {
                handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              if (deleteGate != null) {
                deleteGate!.future.then(
                  (_) => handler.resolve(
                    Response(requestOptions: request, statusCode: 200),
                  ),
                );
                return;
              }
            }
            if (request.method == 'POST') {
              if (registerEntered?.isCompleted == false) { registerEntered!.complete(); }
              if (registerGate != null) {
                registerGate!.future.then(
                  (_) => handler.resolve(
                    Response(
                      requestOptions: request,
                      statusCode: 200,
                      data: {'id': 'registered-device'},
                    ),
                  ),
                );
                return;
              }
            }
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
    addTearDown(() async {
      service.dispose();
      await client.activities.close();
      await client.opens.close();
    });
  });
  test(
    'logout during Firebase initialization cannot prompt the next account',
    () async {
      client.initializeGate = Completer<void>();
      client.initializeEntered = Completer<void>();
      final enabling = service.enable();
      await client.initializeEntered!.future;
      await service.disable();
      client.initializeGate!.complete();
      expect(await enabling, PushOptInResult.unavailable);
      expect(client.prompts, 0);
    },
  );
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
  test(
    'disable invalidates a native token even when the remembered server ID is missing',
    () async {
      await service.disable();
      expect(client.deletions, 1);
      expect(calls.where((r) => r.method == 'DELETE'), isEmpty);
      expect(client.prompts, 0);
    },
  );
  test(
    'native cleanup happens before a slow API deletion and a new account waits for cleanup',
    () async {
      expect(await service.enable(), PushOptInResult.enabled);
      deleteGate = Completer<void>();
      deleteEntered = Completer<void>();
      final stopping = service.disable();
      await deleteEntered!.future;
      expect(client.deletions, 1);
      await storage.saveTokens(
        const StoredAuthTokens(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          userId: 'new-owner',
          phone: '',
          role: 'CUSTOMER',
        ),
      );
      final enabling = service.enable();
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((r) => r.method == 'POST').length, 1);
      deleteGate!.complete();
      await stopping;
      expect(await enabling, PushOptInResult.enabled);
      expect(client.deletions, 1);
      expect(calls.last.extra['fixo_session_user'], 'new-owner');
    },
  );
  test(
    'offline unregister still deletes the token and clears remembered registration',
    () async {
      expect(await service.enable(), PushOptInResult.enabled);
      unregisterFails = true;
      await expectLater(service.disable(), throwsA(isA<DioException>()));
      expect(client.deletions, 1);
      expect(prefs.getString('fixo.push.device.owner'), isNull);
    },
  );
  test(
    'a stale registration response cannot repeat native deletion after logout',
    () async {
      registerGate = Completer<void>();
      registerEntered = Completer<void>();
      final enabling = service.enable();
      await registerEntered!.future;
      await service.disable();
      expect(client.deletions, 1);
      registerGate!.complete();
      expect(await enabling, PushOptInResult.unavailable);
      expect(client.deletions, 1);
      expect(prefs.getString('fixo.push.device.owner'), isNull);
    },
  );
  test(
    'status, registration and deletion requests bind to the account that started them',
    () async {
      expect(await service.enable(), PushOptInResult.enabled);
      await service.disable();
      expect(
        calls.every((r) => r.extra['fixo_session_user'] == 'owner'),
        isTrue,
      );
    },
  );
  test(
    'foreground and open callbacks stop immediately when notifications are disabled',
    () async {
      var activities = 0;
      final opened = <String>[];
      service.dispose();
      service = DevicePushService(
        dio,
        storage,
        prefs,
        client,
        onActivity: () => activities++,
        onOpen: opened.add,
      );
      expect(await service.enable(), PushOptInResult.enabled);
      client.activities.add(null);
      client.opens.add('booking-fixture');
      expect(activities, 1);
      expect(opened, ['booking-fixture']);
      await service.disable();
      client.activities.add(null);
      client.opens.add('old-booking');
      expect(activities, 1);
      expect(opened, ['booking-fixture']);
    },
  );
}
