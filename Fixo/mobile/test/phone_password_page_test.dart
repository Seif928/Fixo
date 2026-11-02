import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/data/email_access_service.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_password_page.dart';

const completeUser = AuthUser(
  id: 'test-user',
  phone: '+201023456789',
  fullName: 'Test Person',
  role: 'CUSTOMER',
);

class FakePhoneAccess extends EmailAccessService {
  FakePhoneAccess() : super(Dio());
  int logins = 0, setups = 0;
  int? googleFailureStatus;
  String? savedPhone;
  @override
  Future<AuthSession?> signInWithGoogle() async {
    if (googleFailureStatus != null) {
      final request = RequestOptions(path: '/auth/firebase/session');
      throw DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: googleFailureStatus,
        ),
      );
    }
    return const AuthSession(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      user: AuthUser(
        id: 'test-user',
        phone: '',
        fullName: '',
        role: 'CUSTOMER',
        requiresProfileSetup: true,
      ),
    );
  }

  @override
  Future<AuthSession> signInWithPhone(String phone, String password) async {
    logins++;
    savedPhone = phone;
    return const AuthSession(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      user: completeUser,
    );
  }

  @override
  Future<AuthUser> completePhoneProfile(
    String name,
    String phone,
    String password,
  ) async {
    setups++;
    savedPhone = phone;
    return completeUser;
  }
}

void main() {
  late FakePhoneAccess access;
  Future<void> pump(WidgetTester tester) async {
    access = FakePhoneAccess();
    final router = GoRouter(
      initialLocation: '/auth/phone',
      routes: [
        GoRoute(
          path: '/auth/phone',
          builder: (_, _) => const PhonePasswordPage(),
        ),
        GoRoute(
          path: '/customer/home',
          builder: (_, _) => const Scaffold(body: Text('Signed in')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emailAccessProvider.overrideWithValue(access),
          secureTokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        ],
        child: MaterialApp.router(
          theme: FixoTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('returning user signs in with phone/password and no OTP step', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('phone-password-submit')));
    await tester.pumpAndSettle();
    expect(access.logins, 0);
    await tester.enterText(
      find.byKey(const Key('phone-password-number')),
      '01023456789',
    );
    await tester.enterText(
      find.byKey(const Key('phone-password-secret')),
      'test-password',
    );
    await tester.ensureVisible(find.byKey(const Key('phone-password-submit')));
    await tester.tap(find.byKey(const Key('phone-password-submit')));
    await tester.pumpAndSettle();
    expect(access.logins, 1);
    expect(access.savedPhone, '+201023456789');
    expect(find.text('Signed in'), findsOneWidget);
  });
  testWidgets('Google verification failures never accuse the phone or password', (
    tester,
  ) async {
    await pump(tester);
    access.googleFailureStatus = 401;
    final google = find.byKey(const Key('first-use-google'));
    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pumpAndSettle();
    expect(find.text('Invalid phone or password.'), findsNothing);
    expect(
      find.text(
        'Your sign-in could not be verified. Continue with Google and try again.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('Google account conflicts do not describe a phone conflict', (
    tester,
  ) async {
    await pump(tester);
    access.googleFailureStatus = 409;
    final google = find.byKey(const Key('first-use-google'));
    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This Google email already uses another sign-in method. Use the original account to continue.',
      ),
      findsOneWidget,
    );
  });
  testWidgets(
    'Google first use requires name, phone and matching password before home',
    (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.byKey(const Key('first-use-google')));
      await tester.tap(find.byKey(const Key('first-use-google')));
      await tester.pumpAndSettle();
      expect(find.text('Signed in'), findsNothing);
      expect(find.byKey(const Key('first-profile-name')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('first-profile-name')),
        'Test Person',
      );
      await tester.enterText(
        find.byKey(const Key('phone-password-number')),
        '01023456789',
      );
      await tester.enterText(
        find.byKey(const Key('phone-password-secret')),
        'long-test-password',
      );
      await tester.enterText(
        find.byKey(const Key('first-profile-confirm')),
        'mismatch',
      );
      final submit = find.byKey(const Key('phone-password-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(access.setups, 0);
      await tester.enterText(
        find.byKey(const Key('first-profile-confirm')),
        'long-test-password',
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(access.setups, 1);
      expect(find.text('Signed in'), findsOneWidget);
    },
  );
}
