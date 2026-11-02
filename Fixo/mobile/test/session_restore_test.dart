import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/notifications/device_push_service.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';

const session = AuthSession(
  accessToken: 'new-access',
  refreshToken: 'new-refresh',
  user: AuthUser(id: 'customer', phone: '', fullName: '', role: 'CUSTOMER'),
);

class RestoreRepository implements AuthRepository {
  Object? error;
  Completer<AuthSession>? pending;
  int calls = 0;
  String? revokedToken;
  @override
  Future<AuthSession> refreshSession({required String refreshToken}) async {
    calls++;
    if (error != null) throw error!;
    return pending == null ? session : pending!.future;
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    revokedToken = refreshToken;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RotatingPush extends DevicePushService {
  RotatingPush(SecureTokenStorage storage)
    : super(Dio(), storage, null, PushPlatformClient());
  @override
  Future<void> disable() async {
    await storage.saveTokens(
      const StoredAuthTokens(
        accessToken: 'rotated',
        refreshToken: 'rotated-on-unregister',
        userId: 'customer',
        phone: '',
        role: 'CUSTOMER',
      ),
    );
  }
}

void main() {
  late MemoryTokenStorage storage;
  late RestoreRepository repository;
  late ProviderContainer container;
  setUp(() async {
    storage = MemoryTokenStorage();
    await storage.saveTokens(
      const StoredAuthTokens(
        accessToken: 'expired',
        refreshToken: 'original',
        userId: 'customer',
        phone: '',
        role: 'CUSTOMER',
      ),
    );
    repository = RestoreRepository();
    container = ProviderContainer(
      overrides: [
        secureTokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });
  test(
    'restores using server refresh and persists the rotated token pair',
    () async {
      await container.read(authControllerProvider.notifier).restoreSession();
      expect(
        container.read(authControllerProvider).session?.accessToken,
        'new-access',
      );
      expect((await storage.readTokens())?.refreshToken, 'new-refresh');
    },
  );
  test(
    'revoked refresh credentials are cleared; connection errors preserve retry',
    () async {
      repository.error = const AuthApiException('revoked', statusCode: 401);
      await container.read(authControllerProvider.notifier).restoreSession();
      expect(await storage.readTokens(), isNull);
      expect(container.read(authControllerProvider).isAuthenticated, false);
    },
  );
  test('offline restore never authenticates from cached user data', () async {
    repository.error = const AuthApiException('offline');
    await container.read(authControllerProvider.notifier).restoreSession();
    expect(await storage.readTokens(), isNotNull);
    expect(container.read(authControllerProvider).isAuthenticated, false);
  });
  test('logout during refresh cannot resurrect a session', () async {
    repository.pending = Completer<AuthSession>();
    final controller = container.read(authControllerProvider.notifier);
    final restore = controller.restoreSession();
    await Future<void>.delayed(Duration.zero);
    await controller.logout();
    repository.pending!.complete(session);
    await restore;
    expect(await storage.readTokens(), isNull);
    expect(container.read(authControllerProvider).isAuthenticated, false);
  });
  test(
    'logout revokes the latest refresh token after push unregister rotates it',
    () async {
      final scoped = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repository),
          devicePushProvider.overrideWithValue(RotatingPush(storage)),
        ],
      );
      addTearDown(scoped.dispose);
      await scoped.read(authControllerProvider.notifier).logout();
      expect(repository.revokedToken, 'rotated-on-unregister');
      expect(await storage.readTokens(), isNull);
    },
  );
  test(
    'malformed API sessions fail closed instead of creating a dummy user',
    () {
      expect(() => AuthSession.fromJson({}), throwsFormatException);
      expect(
        () => AuthSession.fromJson({
          'accessToken': 'a',
          'refreshToken': 'r',
          'user': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    },
  );
}
