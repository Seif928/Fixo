import 'dart:async';

abstract interface class PushRegistrationGateway {
  Stream<String> get registered;
  Future<String?> appleToken();
  Future<void> register(String? vapidKey);
}

/// Keeps native registration bounded and never leaves an event listener behind.
class PushRegistration {
  const PushRegistration(
    this.gateway, {
    required this.isApple,
    this.timeout = const Duration(seconds: 20),
  });
  final PushRegistrationGateway gateway;
  final bool isApple;
  final Duration timeout;

  Future<String?> register(String? vapidKey) async {
    // The OS may still be provisioning APNs immediately after permission is granted.
    // Return unavailable so the user's next attempt/resume can retry safely.
    if (isApple && await gateway.appleToken().timeout(timeout) == null) {
      return null;
    }
    final registered = Completer<String>();
    final subscription = gateway.registered.listen(
      (id) {
        if (!registered.isCompleted) registered.complete(id);
      },
      onError: (Object error, StackTrace stack) {
        if (!registered.isCompleted) registered.completeError(error, stack);
      },
      onDone: () {
        if (!registered.isCompleted) {
          registered.completeError(
            StateError('Push registration ended without an identifier.'),
          );
        }
      },
    );
    try {
      final result = await Future.wait<String?>([
        registered.future,
        gateway.register(vapidKey).then<String?>((_) => null),
      ], eagerError: true).timeout(timeout);
      return result.first;
    } finally {
      await subscription.cancel();
    }
  }
}
