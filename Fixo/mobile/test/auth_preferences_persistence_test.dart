import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/session/session_providers.dart';
import 'package:fixo_mobile/core/storage/auth_session_preferences.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/app/router/app_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? refreshError;
  int refreshCallCount = 0;
  String? lastLoggedOutToken;

  final defaultSession = const AuthSession(
    accessToken: 'server-access-token',
    refreshToken: 'server-refresh-token',
    user: AuthUser(
      id: 'usr-123',
      phone: '+201012345678',
      fullName: 'Ahmed Fixo',
      role: 'CUSTOMER',
      rewardPoints: 150,
    ),
  );

  @override
  Future<AuthSession> refreshSession({required String refreshToken}) async {
    refreshCallCount++;
    if (refreshError != null) throw refreshError!;
    return defaultSession;
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    lastLoggedOutToken = refreshToken;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = AuthUser(
    id: 'user-cairo-1',
    phone: '+201012345678',
    fullName: 'Mahmoud Test',
    role: 'CUSTOMER',
    rewardPoints: 200,
  );

  const testSession = AuthSession(
    accessToken: 'access-token-initial',
    refreshToken: 'refresh-token-initial',
    user: testUser,
  );

  group('AuthSessionPreferences & Persistent Login', () {
    late SharedPreferences prefs;
    late MemoryTokenStorage secureStorage;
    late _FakeAuthRepository fakeRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      secureStorage = MemoryTokenStorage();
      fakeRepo = _FakeAuthRepository();
    });

    test('User login writes persistent session to SharedPreferences and SecureStorage', () async {
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(authControllerProvider.notifier);
      await authNotifier.acceptVerifiedSession(testSession);

      // Verify SharedPreferences state
      final authPrefs = container.read(authSessionPreferencesProvider);
      expect(authPrefs.isLoggedIn, isTrue);
      expect(authPrefs.isOnboardingCompleted, isTrue);

      final saved = authPrefs.getSavedSession();
      expect(saved, isNotNull);
      expect(saved?.user.id, 'user-cairo-1');
      expect(saved?.user.fullName, 'Mahmoud Test');
      expect(saved?.accessToken, 'access-token-initial');
      expect(saved?.refreshToken, 'refresh-token-initial');

      // Verify SecureTokenStorage has matching tokens
      final tokens = await secureStorage.readTokens();
      expect(tokens?.userId, 'user-cairo-1');
      expect(tokens?.refreshToken, 'refresh-token-initial');

      // Verify session providers
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(currentUserIdProvider), 'user-cairo-1');
    });

    test('App restart immediately restores session from SharedPreferences before network', () async {
      // 1. First session logs in and saves to SharedPreferences
      final authPrefs = AuthSessionPreferences(prefs);
      await authPrefs.saveSession(testSession);
      await secureStorage.saveTokens(
        const StoredAuthTokens(
          accessToken: 'access-token-initial',
          refreshToken: 'refresh-token-initial',
          userId: 'user-cairo-1',
          phone: '+201012345678',
          role: 'CUSTOMER',
        ),
      );

      // 2. Simulate complete app restart with new ProviderContainer reading from SharedPreferences
      final newContainer = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(newContainer.dispose);

      // Synchronous build() immediately restores authenticated state from SharedPreferences!
      final authState = newContainer.read(authControllerProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.session?.user.id, 'user-cairo-1');
      expect(authState.session?.user.fullName, 'Mahmoud Test');
      expect(newContainer.read(isAuthenticatedProvider), isTrue);
      expect(newContainer.read(currentUserIdProvider), 'user-cairo-1');
    });

    test('Offline launch: network failure on restore keeps user logged in from SharedPreferences', () async {
      // Pre-populate SharedPreferences with saved session
      final authPrefs = AuthSessionPreferences(prefs);
      await authPrefs.saveSession(testSession);
      await secureStorage.saveTokens(
        const StoredAuthTokens(
          accessToken: 'access-token-initial',
          refreshToken: 'refresh-token-initial',
          userId: 'user-cairo-1',
          phone: '+201012345678',
          role: 'CUSTOMER',
        ),
      );

      // Backend is offline / unreachable
      fakeRepo.refreshError = const AuthApiException('Network connection failed');

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Run restoreSession
      await container.read(authControllerProvider.notifier).restoreSession();

      // User MUST REMAIN logged in! Not kicked to login or onboarding!
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(authSessionPreferencesProvider).isLoggedIn, isTrue);
      expect(container.read(currentUserIdProvider), 'user-cairo-1');
    });

    test('Explicit logout wipes SharedPreferences and leaves user logged out on restart', () async {
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Log in
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(testSession);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(container.read(authSessionPreferencesProvider).isLoggedIn, isTrue);

      // User performs explicit logout
      await container.read(authControllerProvider.notifier).logout();

      // Verified logged out
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(authSessionPreferencesProvider).isLoggedIn, isFalse);
      expect(container.read(authSessionPreferencesProvider).getSavedSession(), isNull);
      expect(await secureStorage.readTokens(), isNull);

      // Simulate app restart
      final restartedContainer = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(restartedContainer.dispose);

      expect(restartedContainer.read(authControllerProvider).isAuthenticated, isFalse);
      expect(restartedContainer.read(isAuthenticatedProvider), isFalse);
    });

    test('Server 401 revocation correctly clears SharedPreferences session', () async {
      final authPrefs = AuthSessionPreferences(prefs);
      await authPrefs.saveSession(testSession);
      await secureStorage.saveTokens(
        const StoredAuthTokens(
          accessToken: 'access-token-initial',
          refreshToken: 'refresh-token-initial',
          userId: 'user-cairo-1',
          phone: '+201012345678',
          role: 'CUSTOMER',
        ),
      );

      // Server explicitly rejects token (revoked / deleted)
      fakeRepo.refreshError = const AuthApiException('Unauthorized', statusCode: 401);

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restoreSession();

      // Session cleared because server rejected credential
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      expect(container.read(authSessionPreferencesProvider).isLoggedIn, isFalse);
      expect(container.read(authSessionPreferencesProvider).getSavedSession(), isNull);
      expect(await secureStorage.readTokens(), isNull);
    });

    testWidgets('Router initialLocation sends authenticated user directly to home, redirects from onboarding', (tester) async {
      final authPrefs = AuthSessionPreferences(prefs);
      await authPrefs.saveSession(testSession);

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      // Initial location is customerHome
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.customerHome);

      // Attempting to go to /onboarding redirects authenticated user to /customer/home
      router.go(AppRoutes.onboarding);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.customerHome);
    });
  });
}
