import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/logout_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const testUser = AuthUser(
    id: 'user-vip-1',
    phone: '+201012345678',
    fullName: 'Ahmed Gamal',
    role: 'CUSTOMER',
  );

  Future<void> pumpLogout(
    WidgetTester tester, {
    bool arabic = true,
    AuthUser? user = testUser,
  }) async {
    SharedPreferences.setMockInitialValues({
      'fixo.locale': arabic ? 'ar' : 'en',
    });
    final preferences = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: '/auth/logout',
      routes: [
        GoRoute(path: '/auth/logout', builder: (_, _) => const LogoutPage()),
        GoRoute(
          path: '/auth/phone',
          builder: (_, _) => const Scaffold(body: Text('Auth Phone Page')),
        ),
        GoRoute(
          path: '/customer/home',
          builder: (_, _) => const Scaffold(body: Text('Customer Home Page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
          authControllerProvider.overrideWith(
            () => _TestAuthController(
              user != null
                  ? AuthSession(
                      accessToken: 'mock-token',
                      refreshToken: 'mock-refresh',
                      user: user,
                    )
                  : null,
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: FixoTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders premium logout page with active user info and actions (AR)',
    (tester) async {
      await pumpLogout(tester, arabic: true);

      expect(find.text('تأكيد تسجيل الخروج'), findsOneWidget);
      expect(find.text('Ahmed Gamal'), findsOneWidget);
      expect(find.text('+201012345678'), findsOneWidget);
      expect(find.text('عميل'), findsOneWidget);
      expect(find.byKey(const Key('confirm-sign-out-btn')), findsOneWidget);
      expect(find.byKey(const Key('switch-account-btn')), findsOneWidget);
      expect(find.byKey(const Key('cancel-logout-btn')), findsOneWidget);
    },
  );

  testWidgets('renders premium logout page in EN', (tester) async {
    await pumpLogout(tester, arabic: false);

    expect(find.text('Secure Sign Out'), findsOneWidget);
    expect(find.text('Ahmed Gamal'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Confirm Secure Sign Out'), findsOneWidget);
  });

  testWidgets('tapping confirm sign out transitions to success state', (
    tester,
  ) async {
    await pumpLogout(tester, arabic: true);

    await tester.tap(find.byKey(const Key('confirm-sign-out-btn')));
    await tester.pumpAndSettle();

    expect(find.text('تم تسجيل الخروج بنجاح'), findsOneWidget);
    expect(find.byKey(const Key('post-logout-signin-btn')), findsOneWidget);
    expect(find.byKey(const Key('post-logout-explore-btn')), findsOneWidget);
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController(this._initialSession);
  final AuthSession? _initialSession;

  @override
  AuthState build() {
    return AuthState(session: _initialSession);
  }

  @override
  Future<void> logout() async {
    state = const AuthState();
  }
}
