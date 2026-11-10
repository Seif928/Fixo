import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../l10n/app_locale_controller.dart';
import '../network/dio_client.dart';
import '../storage/secure_token_storage.dart';

enum PushOptInResult { enabled, denied, unavailable }

final pushActivityProvider = StateProvider<int>((ref) => 0);
final pushOpenBookingProvider = StateProvider<String?>((ref) => null);

class PushPlatformClient {
  String get platform => kIsWeb
      ? 'WEB'
      : defaultTargetPlatform == TargetPlatform.android
      ? 'ANDROID'
      : 'IOS';
  bool get supported =>
      kIsWeb ||
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);
  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<bool> permission({required bool request}) async {
    final settings = request
        ? await FirebaseMessaging.instance.requestPermission()
        : await FirebaseMessaging.instance.getNotificationSettings();
    return [
      AuthorizationStatus.authorized,
      AuthorizationStatus.provisional,
    ].contains(settings.authorizationStatus);
  }

  Future<String?> token(String? vapidKey) async {
    final messaging = FirebaseMessaging.instance;
    final results = await Future.wait<Object?>([
      messaging.onRegistered.first,
      messaging.register(vapidKey: vapidKey),
    ]).timeout(const Duration(seconds: 20));
    return results.first as String;
  }

  Future<void> deleteToken() async {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseMessaging.instance.unregister();
    }
  }

  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onRegistered;
  Stream<void> get foreground => FirebaseMessaging.onMessage.map((_) {});
  Stream<String> get opened => FirebaseMessaging.onMessageOpenedApp
      .map((message) => message.data['bookingId'])
      .where((id) => id is String && id.isNotEmpty)
      .cast<String>();
  Future<String?> initialBooking() async =>
      (await FirebaseMessaging.instance.getInitialMessage())?.data['bookingId']
          as String?;
}

/// Requests OS permission only after the user explicitly opts in from Profile.
class DevicePushService {
  DevicePushService(
    this.dio,
    this.storage,
    this.preferences,
    this.client, {
    this.onActivity,
    this.onOpen,
  });
  final VoidCallback? onActivity;
  final void Function(String bookingId)? onOpen;
  final Dio dio;
  final SecureTokenStorage storage;
  final SharedPreferences? preferences;
  final PushPlatformClient client;
  StreamSubscription<String>? _refresh;
  StreamSubscription<void>? _foreground;
  StreamSubscription<String>? _opened;
  bool _busy = false;
  int _generation = 0;

  Future<PushOptInResult> enable({bool requestPermission = true}) async {
    if (_busy || !client.supported) return PushOptInResult.unavailable;
    _busy = true;
    final generation = _generation;
    try {
      final owner = (await storage.readTokens())?.userId;
      if (owner == null || owner.isEmpty) return PushOptInResult.unavailable;
      final response = await dio.get<Map<String, dynamic>>('/users/me/push-status', options: Options(extra: {'fixo_session_user': owner}));
      final status = response.data ?? {};
      final vapid = status['webVapidKey'] as String?;
      if (status['configured'] != true ||
          (client.platform == 'WEB' && (vapid == null || vapid.isEmpty)) ||
          (client.platform == 'IOS' && status['iosConfigured'] != true)) {
        return PushOptInResult.unavailable;
      }
      if (!await _isCurrent(owner, generation)) return PushOptInResult.unavailable;
      await client.initialize();
      if (!await _isCurrent(owner, generation)) return PushOptInResult.unavailable;
      if (!await client.permission(request: requestPermission)) {
        return PushOptInResult.denied;
      }
      if (!await _isCurrent(owner, generation)) return PushOptInResult.unavailable;
      final token = await client.token(vapid);
      if (token == null || token.isEmpty) return PushOptInResult.unavailable;
      if (!await _register(owner, token, generation)) {
        return PushOptInResult.unavailable;
      }
      await _refresh?.cancel();
      _refresh = client.tokenRefresh.listen((token) async {
        try {
          await _register(owner, token, generation);
        } catch (_) {
          /* Retry on next foreground sign-in. */
        }
      });
      await _foreground?.cancel();
      await _opened?.cancel();
      _foreground = client.foreground.listen((_) {
        if (generation == _generation) onActivity?.call();
      });
      _opened = client.opened.listen((id) {
        if (generation == _generation && id.length <= 100) onOpen?.call(id);
      });
      final initial = await client.initialBooking();
      if (generation == _generation &&
          initial != null &&
          initial.isNotEmpty &&
          initial.length <= 100) {
        onOpen?.call(initial);
      }
      return PushOptInResult.enabled;
    } catch (_) {
      return PushOptInResult.unavailable;
    } finally {
      _busy = false;
    }
  }

  Future<bool> _register(String owner, String token, int generation) async {
    if (generation != _generation ||
        (await storage.readTokens())?.userId != owner) {
      return false;
    }
    final result = await dio.post<Map<String, dynamic>>('/users/me/push-devices', data: {'token': token, 'platform': client.platform}, options: Options(extra: {'fixo_session_user': owner}));
    final id = result.data?['id'];
    if (id is! String || id.isEmpty) return false;
    if (generation != _generation || (await storage.readTokens())?.userId != owner) { return false; }
    await preferences?.setString('fixo.push.device.$owner', id);
    return true;
  }

  Future<bool> _isCurrent(String owner, int generation) async {
    final session = await storage.readTokens();
    return generation == _generation && session?.userId == owner;
  }

  Future<void> resume() async {
    final owner = (await storage.readTokens())?.userId;
    if (owner != null &&
        preferences?.getString('fixo.push.device.$owner') != null) {
      await enable(requestPermission: false);
    }
  }

  Future<void> disable() async {
    _generation++;
    await _refresh?.cancel();
    await _foreground?.cancel();
    await _opened?.cancel();
    _refresh = null;
    final owner = (await storage.readTokens())?.userId;
    final id = preferences?.getString('fixo.push.device.$owner');
    await client.deleteToken();
    if (owner != null) {
      await preferences?.remove('fixo.push.device.$owner');
    }
    if (id != null) {
      await dio.delete(
        '/users/me/push-devices/${Uri.encodeComponent(id)}',
        options: Options(extra: {'fixo_session_user': owner}),
      );
    }
  }

  /// A revoked session cannot call protected unregister endpoints.
  Future<void> invalidateLocalSession() async {
    _generation++;
    await _refresh?.cancel();
    await _foreground?.cancel();
    await _opened?.cancel();
    _refresh = null;
    try {
      await client.deleteToken();
    } catch (_) {
      /* Best effort offline. */
    }
  }

  void dispose() {
    _generation++;
    unawaited(_refresh?.cancel());
    unawaited(_foreground?.cancel());
    unawaited(_opened?.cancel());
  }
}

final devicePushProvider = Provider<DevicePushService>((ref) {
  final service = DevicePushService(
    ref.watch(dioClientProvider),
    ref.watch(secureTokenStorageProvider),
    ref.watch(appPreferencesProvider),
    PushPlatformClient(),
    onActivity: () => ref.read(pushActivityProvider.notifier).state++,
    onOpen: (id) => ref.read(pushOpenBookingProvider.notifier).state = id,
  );
  ref.onDispose(service.dispose);
  return service;
});
