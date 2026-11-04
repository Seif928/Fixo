import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/profile/data/account_deletion_repository.dart';
import 'package:fixo_mobile/features/profile/presentation/profile_page.dart';

class _FakeLocaleNotifier extends AppLocaleNotifier {
  _FakeLocaleNotifier(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  _FakeAccountDeletionRepository({this.hasConflict = false});

  final bool hasConflict;
  bool deleteAccountCalled = false;

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
    if (hasConflict) {
      throw const AccountDeletionException(
        'Cannot delete account with active or ongoing bookings.',
        code: 'ACTIVE_BOOKINGS_EXIST',
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends AuthController {
  _FakeAuthController() : super();
  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

Dio _createMockDio() {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final profile = {
            'id': 'fixture-user',
            'fullName': 'أحمد محمود',
            'phone': '+201023456789',
            'role': 'CUSTOMER',
            'preferredLocale': 'ar',
            'arrivalAlertsEnabled': true,
            'rewardPoints': 100,
          };
          return handler.resolve(
            Response(
              requestOptions: options,
              data: {'user': profile},
              statusCode: 200,
            ),
          );
        },
      ),
    );
}

void main() {
  Widget createTestWidget({
    required AccountDeletionRepository deletionRepo,
    required _FakeAuthController authController,
    Locale locale = const Locale('ar'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.customerProfile,
      routes: [
        GoRoute(
          path: AppRoutes.customerProfile,
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/auth/phone',
          builder: (context, state) => const Scaffold(body: Text('Auth Phone Page')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(_createMockDio()),
        accountDeletionRepositoryProvider.overrideWithValue(deletionRepo),
        authControllerProvider.overrideWith(() => authController),
        appLocaleProvider.overrideWith(() => _FakeLocaleNotifier(locale)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: FixoTheme.light(locale: locale),
        darkTheme: FixoTheme.dark(locale: locale),
        themeMode: themeMode,
      ),
    );
  }

  group('Milestone 3: Self-Service Account Deletion Tests', () {
    testWidgets('renders delete account button and shows confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAccountDeletionRepository();
      final fakeAuth = _FakeAuthController();

      await tester.pumpWidget(
        createTestWidget(
          deletionRepo: fakeRepo,
          authController: fakeAuth,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('profile-delete-account'));
      await tester.scrollUntilVisible(
        deleteBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(deleteBtn, findsOneWidget);
      expect(find.text('حذف الحساب والبيانات الشخصية'), findsOneWidget);

      // Tap delete account button
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify challenge dialog appears
      expect(find.text('حذف الحساب نهائيًا'), findsOneWidget);
      expect(
        find.textContaining('هل أنت متأكد من رغبتك في حذف حسابك؟'),
        findsOneWidget,
      );
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.byKey(const Key('confirm-delete-account-button')), findsOneWidget);

      // Cancel dismissal
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(find.text('حذف الحساب نهائيًا'), findsNothing);
      expect(fakeRepo.deleteAccountCalled, isFalse);
    });

    testWidgets('confirms deletion, calls repository, logs out, and redirects', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAccountDeletionRepository();
      final fakeAuth = _FakeAuthController();

      await tester.pumpWidget(
        createTestWidget(
          deletionRepo: fakeRepo,
          authController: fakeAuth,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('profile-delete-account'));
      await tester.scrollUntilVisible(
        deleteBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Tap confirm button
      final confirmBtn = find.byKey(const Key('confirm-delete-account-button'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.deleteAccountCalled, isTrue);
      expect(fakeAuth.logoutCalled, isTrue);
      expect(find.text('Auth Phone Page'), findsOneWidget);
    });

    testWidgets('displays conflict dialog when active bookings exist', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAccountDeletionRepository(hasConflict: true);
      final fakeAuth = _FakeAuthController();

      await tester.pumpWidget(
        createTestWidget(
          deletionRepo: fakeRepo,
          authController: fakeAuth,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('profile-delete-account'));
      await tester.scrollUntilVisible(
        deleteBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Tap confirm button
      final confirmBtn = find.byKey(const Key('confirm-delete-account-button'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.deleteAccountCalled, isTrue);
      expect(fakeAuth.logoutCalled, isFalse);

      // Verify conflict dialog
      expect(find.text('تعذر حذف الحساب'), findsOneWidget);
      expect(
        find.textContaining('لا يمكن حذف الحساب لوجود حجوزات جارية أو معلقة'),
        findsOneWidget,
      );

      // Dismiss dialog
      await tester.tap(find.text('حسنًا'));
      await tester.pumpAndSettle();
      expect(find.text('تعذر حذف الحساب'), findsNothing);
    });

    testWidgets('responsive layout at 360/390/412dp with 1.35x font scale and dark theme', (tester) async {
      final fakeRepo = _FakeAccountDeletionRepository();
      final fakeAuth = _FakeAuthController();

      for (final width in [360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: const TextScaler.linear(1.35),
            ),
            child: createTestWidget(
              deletionRepo: fakeRepo,
              authController: fakeAuth,
              locale: const Locale('ar'),
              themeMode: ThemeMode.dark,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final deleteBtn = find.byKey(const Key('profile-delete-account'));
        await tester.scrollUntilVisible(
          deleteBtn,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(deleteBtn, findsOneWidget);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
