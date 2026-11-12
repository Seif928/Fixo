import 'dart:async';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/session/session_providers.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/profile/data/profile_repository.dart';
import 'package:fixo_mobile/features/profile/domain/profile_models.dart';
import 'package:fixo_mobile/features/profile/presentation/controllers/profile_controller.dart';

const _userA = AuthUser(
  id: 'user-a',
  phone: '+201011111111',
  fullName: 'User Alpha',
  role: 'CUSTOMER',
);

const _sessionA = AuthSession(
  accessToken: 'token-a-1',
  refreshToken: 'refresh-a-1',
  user: _userA,
);

const _userB = AuthUser(
  id: 'user-b',
  phone: '+201022222222',
  fullName: 'User Beta',
  role: 'CUSTOMER',
);

const _sessionB = AuthSession(
  accessToken: 'token-b-1',
  refreshToken: 'refresh-b-1',
  user: _userB,
);

class _MockProfileRepository implements ProfileRepository {
  _MockProfileRepository();

  int getProfileCalls = 0;
  String currentUserId = 'user-a';
  Completer<void>? stallCompleter;

  @override
  Future<UserProfile> getProfile() async {
    getProfileCalls++;
    if (stallCompleter != null) {
      await stallCompleter!.future;
    }
    return UserProfile(
      id: currentUserId,
      fullName: currentUserId == 'user-a' ? 'User Alpha' : 'User Beta',
      phone: currentUserId == 'user-a' ? '+201011111111' : '+201022222222',
      role: 'CUSTOMER',
      arrivalAlertsEnabled: true,
    );
  }

  @override
  Future<UserProfile> updateProfile({
    String? fullName,
    String? phone,
    String? password,
  }) async {
    if (phone != null && password != null) {
      final session = await updatePhoneAlias(phone: phone, password: password);
      return UserProfile.fromAuthUser(session.user);
    }
    return UserProfile(
      id: currentUserId,
      fullName: fullName ?? 'Updated Name',
      phone: '+201011111111',
      role: 'CUSTOMER',
      arrivalAlertsEnabled: true,
    );
  }

  @override
  Future<AuthSession> updatePhoneAlias({
    required String phone,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'rotated-token',
      refreshToken: 'rotated-refresh',
      user: AuthUser(
        id: currentUserId,
        phone: phone,
        fullName: 'User Alpha',
        role: 'CUSTOMER',
      ),
    );
  }

  @override
  Future<void> updateNotificationPreferences({
    required bool arrivalAlertsEnabled,
  }) async {}
}

void main() {
  group('1. State Synchronization & Session Providers', () {
    test('session providers update cleanly upon login, token rotation, and logout', () async {
      final storage = MemoryTokenStorage();
      final mockRepo = _MockProfileRepository();

      final container = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Listen to profileControllerProvider from start
      container.listen(profileControllerProvider, (prev, next) {});

      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(currentUserIdProvider), isNull);
      expect(container.read(sessionTokenProvider), isNull);
      expect(container.read(currentUserProvider), isNull);

      // LOGIN User A
      mockRepo.currentUserId = 'user-a';
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionA);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(currentUserIdProvider), 'user-a');
      expect(container.read(sessionTokenProvider), 'token-a-1');
      expect(container.read(currentUserProvider)?.fullName, 'User Alpha');

      final profileStateAfterLogin = container.read(profileControllerProvider);
      expect(profileStateAfterLogin.profile?.id, 'user-a');
      expect(profileStateAfterLogin.profile?.fullName, 'User Alpha');
      expect(mockRepo.getProfileCalls, greaterThanOrEqualTo(1));
      final callsBeforeRotation = mockRepo.getProfileCalls;

      // TOKEN ROTATION (acceptUpdatedProfile with same user ID)
      const updatedUserA = AuthUser(
        id: 'user-a',
        phone: '+201011111111',
        fullName: 'User Alpha Renamed',
        role: 'CUSTOMER',
      );
      await container.read(authControllerProvider.notifier).acceptUpdatedProfile(updatedUserA);

      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(currentUserIdProvider), 'user-a');
      expect(container.read(sessionTokenProvider), 'token-a-1');
      expect(container.read(currentUserProvider)?.fullName, 'User Alpha Renamed');

      // Token rotation with same user ID should NOT trigger redundant profile fetch
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(mockRepo.getProfileCalls, callsBeforeRotation);

      // LOGOUT User A
      await container.read(authControllerProvider.notifier).logout();

      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(currentUserIdProvider), isNull);
      expect(container.read(sessionTokenProvider), isNull);
      expect(container.read(currentUserProvider), isNull);

      // ProfileController state should be reset to empty on logout
      final profileStateAfterLogout = container.read(profileControllerProvider);
      expect(profileStateAfterLogout.profile, isNull);
      expect(profileStateAfterLogout.isLoading, isFalse);
    });

    test('account switch A -> B triggers profile reload for new user', () async {
      final storage = MemoryTokenStorage();
      final mockRepo = _MockProfileRepository();

      final container = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(profileControllerProvider, (prev, next) {});

      // Login A
      mockRepo.currentUserId = 'user-a';
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionA);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(profileControllerProvider).profile?.id, 'user-a');

      // Switch to B
      mockRepo.currentUserId = 'user-b';
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionB);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(currentUserIdProvider), 'user-b');
      expect(container.read(profileControllerProvider).profile?.id, 'user-b');
      expect(container.read(profileControllerProvider).profile?.fullName, 'User Beta');
    });
  });

  group('2. Race Condition Stress Testing', () {
    test('delayed profile fetch completing after logout does not leak stale user data into state', () async {
      final storage = MemoryTokenStorage();
      final mockRepo = _MockProfileRepository();
      mockRepo.stallCompleter = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // User A signs in
      mockRepo.currentUserId = 'user-a';
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionA);

      // Trigger loadProfile which stalls
      final loadFuture = container.read(profileControllerProvider.notifier).loadProfile();

      // User logs out while request is still pending
      await container.read(authControllerProvider.notifier).logout();
      expect(container.read(profileControllerProvider).profile, isNull);

      // Now release the stalled request
      mockRepo.stallCompleter!.complete();
      await loadFuture;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(profileControllerProvider);
      expect(state.profile, isNull);
      expect(state.isLoading, isFalse);
    });

    test('delayed profile fetch from User A does not overwrite User B profile after switch', () async {
      final storage = MemoryTokenStorage();
      final mockRepo = _MockProfileRepository();
      mockRepo.stallCompleter = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // User A signs in and triggers loadProfile (stalled)
      mockRepo.currentUserId = 'user-a';
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionA);
      final loadAFuture = container.read(profileControllerProvider.notifier).loadProfile();

      // Now switch to User B before A returns
      mockRepo.currentUserId = 'user-b';
      final stallA = mockRepo.stallCompleter!;
      mockRepo.stallCompleter = null; // B completes immediately
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionB);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(profileControllerProvider).profile?.id, 'user-b');

      // Now release stalled A
      stallA.complete();
      await loadAFuture;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Ensure B is NOT overwritten by A
      expect(container.read(profileControllerProvider).profile?.id, 'user-b');
      expect(container.read(profileControllerProvider).profile?.fullName, 'User Beta');
    });

    test('delayed Dio profile response after logout with AccountIsolationInterceptor', () async {
      final storage = MemoryTokenStorage();
      final started = Completer<void>();
      final release = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final dio = container.read(dioClientProvider);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.path == '/users/me') {
              if (!started.isCompleted) started.complete();
              await release.future;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'user-a',
                    'fullName': 'User Alpha',
                    'phone': '+201011111111',
                    'role': 'CUSTOMER',
                  },
                ),
              );
            }
            handler.next(options);
          },
        ),
      );

      // User A logs in
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionA);
      container.listen(profileControllerProvider, (prev, next) {});

      // Wait until onRequest intercepts /users/me
      await started.future;

      // User logs out while request is pending
      await container.read(authControllerProvider.notifier).logout();
      expect(container.read(profileControllerProvider).profile, isNull);

      // Release HTTP response
      release.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(profileControllerProvider);
      expect(state.profile, isNull);
      expect(state.isLoading, isFalse);
    });
    test('in-flight getProfile is discarded and does not resurrect profile into logged-out state', () async {
      final storage = MemoryTokenStorage();
      final mockRepo = _MockProfileRepository();
      mockRepo.stallCompleter = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // 1. User signs in
      mockRepo.currentUserId = 'user-a';
      await container.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionA);
      container.listen(profileControllerProvider, (prev, next) {});

      // 2. loadProfile is in-flight and stalled at mockRepo
      final inFlightLoad = container.read(profileControllerProvider.notifier).loadProfile();

      // 3. User logs out
      await container.read(authControllerProvider.notifier).logout();
      expect(container.read(authControllerProvider).session, isNull, reason: 'User must be logged out');
      expect(container.read(profileControllerProvider).profile, isNull, reason: 'Profile must be null immediately after logout');

      // 4. Stalled network response completes
      mockRepo.stallCompleter!.complete();
      await inFlightLoad;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 5. Check profile state
      final profileAfterLateResponse = container.read(profileControllerProvider).profile;
      expect(profileAfterLateResponse, isNull, reason: 'Profile must remain null; in-flight request was dropped after logout');
      expect(container.read(profileControllerProvider).isLoading, isFalse);
    });
  });

  group('3. Build-Phase Mutation Absence in Widgets', () {
    testWidgets('watching session providers does not trigger build-phase mutation exceptions', (tester) async {
      final storage = MemoryTokenStorage();
      final mockRepo = _MockProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureTokenStorageProvider.overrideWithValue(storage),
            profileRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final isAuth = ref.watch(isAuthenticatedProvider);
                final userId = ref.watch(currentUserIdProvider);
                final token = ref.watch(sessionTokenProvider);
                final user = ref.watch(currentUserProvider);

                return Scaffold(
                  body: Column(
                    children: [
                      Text('Auth: $isAuth'),
                      Text('User: $userId'),
                      Text('Token: $token'),
                      Text('Name: ${user?.fullName ?? "None"}'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).acceptVerifiedSession(_sessionA);
                        },
                        child: const Text('Login'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).logout();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Auth: false'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap Login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Auth: true'), findsOneWidget);
      expect(find.text('User: user-a'), findsOneWidget);
      expect(find.text('Token: token-a-1'), findsOneWidget);
      expect(find.text('Name: User Alpha'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap Logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Auth: false'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('4. DioProfileRepository Error Mapping & Updates', () {
    late Dio dio;
    late DioProfileRepository repository;

    setUp(() {
      dio = Dio();
      repository = DioProfileRepository(dio);
    });

    test('updateProfile sends PATCH /users/me/profile with fullName', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/users/me/profile');
            expect(options.method, 'PATCH');
            expect(options.data, {'fullName': 'Jane Doe'});
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'u1',
                  'fullName': 'Jane Doe',
                  'phone': '+201012345678',
                  'role': 'CUSTOMER',
                },
              ),
            );
          },
        ),
      );

      final result = await repository.updateProfile(fullName: 'Jane Doe');
      expect(result.id, 'u1');
      expect(result.fullName, 'Jane Doe');
    });

    test('updateProfile maps 400 Bad Request message to ProfileApiException', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {
                    'message': 'Name contains invalid characters',
                    'errorCode': 'VALIDATION_FAILED',
                  },
                ),
              ),
            );
          },
        ),
      );

      try {
        await repository.updateProfile(fullName: 'Inv@lid!');
        fail('Should have thrown ProfileApiException');
      } on ProfileApiException catch (e) {
        expect(e.statusCode, 400);
        expect(e.message, 'Name contains invalid characters');
        expect(e.code, 'VALIDATION_FAILED');
      }
    });

    test('updateProfile delegates to updatePhoneAlias when phone and password are provided', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/auth/phone-alias');
            expect(options.method, 'PATCH');
            expect(options.data, {'phone': '+201099999999', 'password': 'secretPassword'});
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'accessToken': 'new-jwt',
                  'refreshToken': 'new-refresh',
                  'user': {
                    'id': 'u1',
                    'fullName': 'Jane Doe',
                    'phone': '+201099999999',
                    'role': 'CUSTOMER',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await repository.updateProfile(
        phone: '+201099999999',
        password: 'secretPassword',
      );
      expect(result.phone, '+201099999999');
      expect(result.id, 'u1');
    });

    test('updatePhoneAlias maps 409 Conflict with isConflict flag', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'message': 'Phone number already registered',
                    'errorCode': 'PHONE_ALREADY_EXISTS',
                  },
                ),
              ),
            );
          },
        ),
      );

      try {
        await repository.updatePhoneAlias(
          phone: '+201099999999',
          password: 'secretPassword',
        );
        fail('Should have thrown ProfileApiException');
      } on ProfileApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.isConflict, isTrue);
        expect(e.code, 'PHONE_ALREADY_EXISTS');
        expect(e.message, 'Phone number already registered');
      }
    });

    test('updatePhoneAlias maps 401 Unauthorized with isUnauthorized flag', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {
                    'message': 'Invalid credentials',
                  },
                ),
              ),
            );
          },
        ),
      );

      try {
        await repository.updatePhoneAlias(
          phone: '+201099999999',
          password: 'wrongPassword',
        );
        fail('Should have thrown ProfileApiException');
      } on ProfileApiException catch (e) {
        expect(e.statusCode, 401);
        expect(e.isUnauthorized, isTrue);
      }
    });
  });
}
