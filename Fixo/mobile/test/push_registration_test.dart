import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/notifications/push_registration.dart';

class RegistrationFixture implements PushRegistrationGateway {
  late final events = StreamController<String>.broadcast(
    onListen: () => listening = true,
    onCancel: () => listening = false,
  );
  bool listening = false;
  String? apns = 'fixture-apns';
  int calls = 0, apnsReads = 0;
  bool fail = false, hang = false;
  @override
  Stream<String> get registered => events.stream;
  @override
  Future<String?> appleToken() async {
    apnsReads++;
    return apns;
  }

  @override
  Future<void> register(String? vapidKey) async {
    calls++;
    expect(listening, isTrue);
    if (fail) throw StateError('provider failure');
    if (hang) return Completer<void>().future;
    events.add('cAb0_9-Ab0_9-Ab0_9-XYZ');
  }
}

void main() {
  late RegistrationFixture gateway;
  setUp(() => gateway = RegistrationFixture());
  tearDown(() async => gateway.events.close());
  test(
    'subscribes before registration and cancels after the FID is received',
    () async {
      final result = await PushRegistration(
        gateway,
        isApple: false,
      ).register('public-vapid');
      expect(result, 'cAb0_9-Ab0_9-Ab0_9-XYZ');
      expect(gateway.listening, isFalse);
      expect(gateway.apnsReads, 0);
    },
  );
  test('iOS does not register with FCM until an APNs token exists', () async {
    gateway.apns = null;
    expect(
      await PushRegistration(gateway, isApple: true).register(null),
      isNull,
    );
    expect(gateway.calls, 0);
    expect(gateway.listening, isFalse);
  });
  test('iOS registers once APNs is available', () async {
    expect(
      await PushRegistration(gateway, isApple: true).register(null),
      isNotNull,
    );
    expect(gateway.apnsReads, 1);
    expect(gateway.calls, 1);
  });
  test(
    'provider registration failure cancels the pending event subscription',
    () async {
      gateway.fail = true;
      await expectLater(
        PushRegistration(gateway, isApple: false).register(null),
        throwsStateError,
      );
      expect(gateway.listening, isFalse);
    },
  );
  test(
    'registration is bounded even if the native method never completes',
    () async {
      gateway.hang = true;
      await expectLater(
        PushRegistration(
          gateway,
          isApple: false,
          timeout: const Duration(milliseconds: 20),
        ).register(null),
        throwsA(isA<TimeoutException>()),
      );
      expect(gateway.listening, isFalse);
    },
  );
}
