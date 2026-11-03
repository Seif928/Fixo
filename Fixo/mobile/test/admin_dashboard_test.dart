import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/admin/data/admin_repository.dart';
import 'package:fixo_mobile/features/admin/presentation/admin_page.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/app/router/app_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_password_page.dart';

class _Auth extends AuthController {
  @override
  Future<void> acceptVerifiedSession(AuthSession session) async {
    state = AuthState(session: session);
  }

  @override
  AuthState build() => const AuthState(
    session: AuthSession(
      accessToken: 'fixture',
      refreshToken: 'fixture',
      user: AuthUser(
        id: 'owner-fixture',
        phone: '+201023456789',
        fullName: 'Fixture',
        role: 'CUSTOMER',
      ),
    ),
  );
  void changeAccount() => state = const AuthState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in [
      ('Manrope', 'manrope/Manrope.ttf'),
      ('Cairo', 'cairo/Cairo.ttf'),
    ]) {
      await (FontLoader(
        font.$1,
      )..addFont(rootBundle.load('assets/fonts/${font.$2}'))).load();
    }
  });
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    double width = 1200,
    bool arabic = false,
    bool dark = false,
    bool owner = true,
    bool denied = false,
    bool failedSummary = false,
    bool needsConfirmation = false,
    bool wrongConfirmationAccount = false,
    Widget home = const AdminPage(),
    List<RequestOptions>? calls,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? invitedEmail;
    int draftVersion = 1;
    int? publishedVersion, inspection, serviceFee, duration;
    Map<String, dynamic> draft() => {
      'id': 'draft-fixture',
      'version': draftVersion,
      'publishedVersion': publishedVersion,
      'slug': 'home-test',
      'categorySlug': 'cleaning',
      'categoryNameEn': 'Cleaning',
      'categoryNameAr': 'التنظيف',
      'titleEn': 'Fixture cleaning service',
      'titleAr': 'خدمة تنظيف للاختبار',
      'descriptionEn': 'Fixture description',
      'descriptionAr': 'وصف الخدمة للاختبار',
      'baseInspectionEgp': inspection,
      'serviceFeeEgp': serviceFee,
      'estimatedDurationMins': duration,
    };
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            calls?.add(r);
            if (r.path == '/admin/member' && r.method == 'PUT') {
              invitedEmail = (r.data as Map)['email'] as String;
            }
            if (r.path == '/admin/member' && r.method == 'DELETE') {
              invitedEmail = null;
            }
            if (r.path == '/auth/phone-password') needsConfirmation = false;
            if (r.path == '/admin/catalog/draft-fixture' && r.method == 'PUT') {
              final data = r.data as Map;
              inspection = data['baseInspectionEgp'] as int?;
              serviceFee = data['serviceFeeEgp'] as int?;
              duration = data['estimatedDurationMins'] as int?;
              draftVersion++;
            }
            if (r.path == '/admin/catalog/draft-fixture/publish') {
              publishedVersion = draftVersion;
            }
            if ((denied && r.path == '/admin/me') ||
                (failedSummary && r.path == '/admin/summary')) {
              h.reject(
                DioException(
                  requestOptions: r,
                  response: Response(
                    requestOptions: r,
                    statusCode: denied ? 403 : 503,
                  ),
                ),
              );
              return;
            }
            h.resolve(
              Response(
                requestOptions: r,
                statusCode: 200,
                data: switch (r.path) {
                  '/admin/me' => {
                    'role': owner ? 'OWNER' : 'ADMIN',
                    'canManageMembers': owner,
                    'needsConfirmation': needsConfirmation,
                  },
                  '/admin/summary' => {
                    'users': 17,
                    'professionals': 6,
                    'pendingReviews': 3,
                    'activeBookings': 4,
                    'collectedCashEgp': 2250,
                  },
                  '/admin/catalog' => {
                    'items': [draft()],
                    'categories': [
                      {
                        'categorySlug': 'cleaning',
                        'categoryNameEn': 'Cleaning',
                        'categoryNameAr': 'التنظيف',
                      },
                    ],
                    'meta': {'page': 1, 'total': 1, 'totalPages': 1},
                  },
                  '/admin/catalog/draft-fixture' ||
                  '/admin/catalog/draft-fixture/publish' => draft(),
                  '/admin/members' => [
                    {
                      'slot': 1,
                      'email': 'owner@example.test',
                      'role': 'OWNER',
                      'isActive': true,
                      'userId': 'owner-fixture',
                      'expiresAt': null,
                    },
                    if (invitedEmail != null)
                      {
                        'slot': 2,
                        'email': invitedEmail,
                        'role': 'ADMIN',
                        'isActive': true,
                        'userId': null,
                        'expiresAt': '2099-11-10T10:00:00Z',
                      },
                  ],
                  '/admin/audit' => {
                    'items': [
                      {
                        'id': 'event',
                        'action': 'OWNER_INITIALIZED',
                        'createdAt': '2026-11-03T10:00:00Z',
                      },
                    ],
                  },
                  '/auth/phone-password' => {
                    'accessToken': 'confirmed-fixture',
                    'refreshToken': 'confirmed-fixture',
                    'user': {
                      'id': wrongConfirmationAccount
                          ? 'someone-else'
                          : 'owner-fixture',
                      'phone': '+201023456789',
                      'fullName': 'Fixture',
                      'role': 'CUSTOMER',
                    },
                  },
                  _ => <String, dynamic>{},
                },
              ),
            );
          },
        ),
      );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        dioClientProvider.overrideWithValue(dio),
      ],
    );
    if (arabic) {
      await container
          .read(appLocaleProvider.notifier)
          .setLocale(const Locale('ar'));
    }
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: arabic ? const Locale('ar') : const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: dark
              ? FixoTheme.dark(locale: arabic ? const Locale('ar') : null)
              : FixoTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.35)),
            child: Directionality(
              textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
          ),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'desktop sidebar shows actual counts; Owner grants and revokes only through confirmed actions',
    (tester) async {
      final calls = <RequestOptions>[];
      await mount(tester, calls: calls);
      expect(find.byKey(const Key('admin-sidebar')), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('2250 EGP'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      await tester.tap(find.byKey(const Key('admin-nav-members')));
      await tester.pumpAndSettle();
      expect(find.text('owner@example.test'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('admin-invite-email')),
        'friend@example.test',
      );
      await tester.tap(find.byKey(const Key('admin-invite-submit')));
      await tester.pumpAndSettle();
      expect(calls.where((r) => r.method == 'PUT'), isEmpty);
      await tester.tap(find.byKey(const Key('admin-confirm-action')));
      await tester.pumpAndSettle();
      final invite = calls.singleWhere((r) => r.method == 'PUT');
      expect(invite.path, '/admin/member');
      expect(invite.data, {'email': 'friend@example.test'});
      await tester.tap(find.byKey(const Key('admin-revoke')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-confirm-action')));
      await tester.pumpAndSettle();
      expect(
        calls.singleWhere((r) => r.method == 'DELETE').path,
        '/admin/member',
      );
    },
  );

  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets(
      'mobile drawer $width supports Arabic RTL and dark at 1.35x without overflow',
      (tester) async {
        await mount(tester, width: width, arabic: true, dark: true);
        expect(find.byKey(const Key('admin-sidebar')), findsNothing);
        await tester.tap(find.byTooltip('فتح القائمة'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('admin-nav-audit')));
        await tester.pumpAndSettle();
        expect(find.text('تفعيل حساب المالك'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Admin cannot see or request membership management', (
    tester,
  ) async {
    final calls = <RequestOptions>[];
    await mount(tester, owner: false, calls: calls);
    expect(find.byKey(const Key('admin-nav-members')), findsNothing);
    expect(calls.where((r) => r.path == '/admin/members'), isEmpty);
  });
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('Arabic catalog and draft editor fit $width at 1.35x', (
      tester,
    ) async {
      await mount(tester, width: width, arabic: true, dark: true);
      await tester.tap(find.byTooltip('فتح القائمة'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-nav-catalog')));
      await tester.pumpAndSettle();
      expect(find.text('السعر لسه مش محدد'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('admin-edit-draft-fixture')),
      );
      await tester.tap(find.byKey(const Key('admin-edit-draft-fixture')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('admin-draft-duration')));
      await tester.enterText(
        find.byKey(const Key('admin-draft-duration')),
        '٦٠',
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('denied access never loads private data', (tester) async {
    final calls = <RequestOptions>[];
    await mount(tester, denied: true, calls: calls);
    expect(
      find.text('Administration access is unavailable for this account.'),
      findsOneWidget,
    );
    expect(calls.map((r) => r.path), ['/admin/me']);
    expect(find.byKey(const Key('admin-sidebar')), findsNothing);
  });
  testWidgets('failed statistics do not render fabricated zero counts', (
    tester,
  ) async {
    await mount(tester, failedSummary: true);
    expect(
      find.text('Could not load this information. Please retry.'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
  });
  testWidgets('changing account immediately clears private content', (
    tester,
  ) async {
    final container = await mount(tester);
    (container.read(authControllerProvider.notifier) as _Auth).changeAccount();
    await tester.pumpAndSettle();
    expect(find.text('17'), findsNothing);
    expect(find.byKey(const Key('admin-sidebar')), findsNothing);
  });
  test('malformed admin payloads fail closed', () {
    expect(
      () => AdminAccess.fromJson({'role': 'CUSTOMER'}),
      throwsFormatException,
    );
    expect(() => AdminSummary.fromJson({'users': 10}), throwsFormatException);
  });
  testWidgets(
    'stale confirmation disables membership writes until the same account is confirmed',
    (tester) async {
      final calls = <RequestOptions>[];
      final container = await mount(
        tester,
        needsConfirmation: true,
        calls: calls,
      );
      await tester.tap(find.byKey(const Key('admin-nav-members')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('admin-invite-email')))
            .enabled,
        isFalse,
      );
      await tester.tap(find.text('Confirm your account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Current password'),
        'fixture-password',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();
      expect(
        container.read(authControllerProvider).session?.accessToken,
        'confirmed-fixture',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('admin-invite-email')))
            .enabled,
        isTrue,
      );
      expect(calls.where((r) => r.method == 'PUT'), isEmpty);
    },
  );
  testWidgets('confirmation cannot switch to an unexpected account', (
    tester,
  ) async {
    final container = await mount(
      tester,
      needsConfirmation: true,
      wrongConfirmationAccount: true,
    );
    await tester.tap(find.byKey(const Key('admin-nav-members')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm your account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Current password'),
      'fixture-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(
      container.read(authControllerProvider).session?.user.id,
      'owner-fixture',
    );
    expect(
      container.read(authControllerProvider).session?.accessToken,
      'fixture',
    );
    expect(
      find.text(
        'Could not confirm your account. Check your password and retry.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('profile entry is hidden for a denied account', (tester) async {
    await mount(
      tester,
      denied: true,
      home: const Scaffold(body: AdminProfileEntry()),
    );
    expect(find.text('Administration'), findsNothing);
  });
  testWidgets('anonymous admin URL redirects to sign in', (tester) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.admin,
      isAuthenticated: () => false,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdminPage), findsNothing);
    expect(find.byType(PhonePasswordPage), findsOneWidget);
  });
  testWidgets('desktop administration visual review', (tester) async {
    await mount(tester);
    await expectLater(
      find.byType(AdminPage),
      matchesGoldenFile('goldens/admin/desktop_overview.png'),
    );
  });
  testWidgets(
    'catalog saves actual prices as a private draft and publishes only after preview confirmation',
    (tester) async {
      final calls = <RequestOptions>[];
      await mount(tester, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-catalog')));
      await tester.pumpAndSettle();
      expect(find.text('Price not set'), findsOneWidget);
      expect(find.text('0 EGP'), findsNothing);
      await tester.tap(find.byKey(const Key('admin-edit-draft-fixture')));
      await tester.pumpAndSettle();
      for (final field in [
        ('inspection', '150'),
        ('service-fee', '250'),
        ('duration', '60'),
      ]) {
        final finder = find.byKey(Key('admin-draft-${field.$1}'));
        await tester.ensureVisible(finder);
        await tester.enterText(finder, field.$2);
      }
      await tester.tap(find.byKey(const Key('admin-draft-save')));
      await tester.pumpAndSettle();
      expect(calls.where((r) => r.method == 'POST'), isEmpty);
      await tester.tap(find.byKey(const Key('admin-publish-draft-fixture')));
      await tester.pumpAndSettle();
      expect(find.text('400 EGP'), findsWidgets);
      expect(calls.where((r) => r.method == 'POST'), isEmpty);
      await tester.tap(find.byKey(const Key('admin-publish-confirm')));
      await tester.pumpAndSettle();
      final publish = calls.singleWhere((r) => r.method == 'POST');
      expect(publish.data, {'version': 2});
      expect(find.text('Published'), findsOneWidget);
    },
  );
  testWidgets('Arabic mobile member management visual review', (tester) async {
    await mount(tester, width: 390, arabic: true, dark: true);
    await tester.tap(find.byTooltip('فتح القائمة'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-nav-members')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AdminPage),
      matchesGoldenFile('goldens/admin/mobile_members_ar_dark.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
