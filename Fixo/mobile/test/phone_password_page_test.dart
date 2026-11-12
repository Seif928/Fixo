import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/widgets/fixo_brand_mark.dart';
import 'package:fixo_mobile/features/auth/data/email_access_service.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_password_page.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/uploads/device_media_picker.dart';
import 'package:fixo_mobile/features/profile/data/avatar_repository.dart';
import 'package:image_picker/image_picker.dart';

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
  int? phoneFailureStatus;
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
    if (phoneFailureStatus != null) {
      final request = RequestOptions(path: '/auth/phone-password');
      throw DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: phoneFailureStatus,
        ),
      );
    }
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

class _PhotoPicker extends DeviceMediaPicker {
  @override
  bool get supportsCamera => false;
  @override
  Future<PickedPrivateMedia?> pick(
    ImageSource source,
  ) async => const PickedPrivateMedia(
    fileName: 'photo.png',
    mimeType: 'image/png',
    contentBase64:
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+sDj8AAAAASUVORK5CYII=',
    sourceLabelEn: 'Photo library',
    sourceLabelAr: 'الصور',
  );
}

class _Avatars extends AvatarRepository {
  _Avatars() : super(Dio());
  int uploads = 0;
  bool fail = false;
  @override
  Future<String> upload(PickedPrivateMedia photo) async {
    uploads++;
    if (fail) throw StateError('Storage unavailable');
    return 'photo-version';
  }
}

void main() {
  late FakePhoneAccess access;
  late _Avatars avatars;
  Future<void> pump(
    WidgetTester tester, {
    bool professional = false,
    bool arabic = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'fixo.entry.pro': professional,
      'fixo.locale': arabic ? 'ar' : 'en',
    });
    final preferences = await SharedPreferences.getInstance();
    access = FakePhoneAccess();
    avatars = _Avatars();
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
        GoRoute(
          path: '/pro',
          builder: (_, _) => const Scaffold(body: Text('Professional entry')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
          emailAccessProvider.overrideWithValue(access),
          avatarRepositoryProvider.overrideWithValue(avatars),
          deviceMediaPickerProvider.overrideWithValue(_PhotoPicker()),
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

  testWidgets(
    'professional login goes to professional onboarding without granting a role',
    (tester) async {
      await pump(tester, professional: true);
      expect(find.text('Welcome to FIXO Pro'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('phone-password-number')),
        '01023456789',
      );
      await tester.enterText(
        find.byKey(const Key('phone-password-secret')),
        'test-password',
      );
      final submit = find.byKey(const Key('phone-password-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Professional entry'), findsOneWidget);
      expect(find.text('Signed in'), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.text('Professional entry')),
      );
      expect(
        (await container.read(secureTokenStorageProvider).readTokens())?.role,
        'CUSTOMER',
      );
    },
  );

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
  for (final arabic in [false, true]) {
    testWidgets(
      'field errors and rejected credentials stay distinct (${arabic ? "ar" : "en"})',
      (tester) async {
        await pump(tester, arabic: arabic);
        final phone = find.byKey(const Key('phone-password-number'));
        final password = find.byKey(const Key('phone-password-secret'));
        final submit = find.byKey(const Key('phone-password-submit'));
        await tester.enterText(phone, '123');
        await tester.enterText(password, 'test-password');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.text(EgyptPhoneValidator.validate('123', isArabic: arabic)!),
          findsOneWidget,
        );
        expect(access.logins, 0);

        await tester.enterText(phone, '01023456789');
        await tester.enterText(password, '');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.text(arabic ? 'أدخل كلمة المرور.' : 'Enter your password.'),
          findsOneWidget,
        );
        expect(access.logins, 0);

        access.phoneFailureStatus = 401;
        await tester.enterText(password, 'wrong-password');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        final message = arabic
            ? 'رقم الموبايل أو كلمة المرور غير صحيحة. راجعهم أو استخدم «نسيت كلمة المرور؟».'
            : 'Incorrect phone number or password. Check both or use "Forgot password?".';
        expect(find.text(message), findsOneWidget);
        expect(access.logins, 1);
        await tester.enterText(password, 'corrected-password');
        await tester.pumpAndSettle();
        expect(find.text(message), findsNothing);
      },
    );
  }

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
  for (final professional in [false, true]) {
    testWidgets(
      'Google first use requires complete profile before ${professional ? "professional" : "customer"} entry',
      (tester) async {
        await pump(tester, professional: professional);
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
        expect(
          find.text(professional ? 'Professional entry' : 'Signed in'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'photo failure preserves completed Google profile and allows sign-in',
    (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.byKey(const Key('first-use-google')));
      await tester.tap(find.byKey(const Key('first-use-google')));
      await tester.pumpAndSettle();
      final photo = find.byKey(const Key('first-profile-photo'));
      await tester.ensureVisible(photo);
      await tester.tap(photo);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-gallery-btn')));
      await tester.pumpAndSettle();
      avatars.fail = true;
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
        'test-password',
      );
      await tester.enterText(
        find.byKey(const Key('first-profile-confirm')),
        'test-password',
      );
      await tester.ensureVisible(
        find.byKey(const Key('phone-password-submit')),
      );
      await tester.tap(find.byKey(const Key('phone-password-submit')));
      await tester.pumpAndSettle();
      expect(avatars.uploads, 1);
      expect(access.setups, 1);
      expect(find.text('Signed in'), findsOneWidget);
      expect(
        find.text('Your account is ready. Add your photo later from Profile.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders real Google emblem and Email & Password entry button', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(FixoGoogleMark), findsOneWidget);
    expect(find.byKey(const Key('first-use-email')), findsOneWidget);
  });
}
