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
import 'dart:ui' as ui;

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
  void restoreFixtureAccount() => state = build();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<int> documentPhoto;
  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 32, 32),
      ui.Paint()..color = const ui.Color(0xff173f35),
    );
    final image = await recorder.endRecording().toImage(32, 32);
    documentPhoto = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
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
    bool selfProfessional = false,
    bool corruptDocument = false,
    bool bookingConflict = false,
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
    var proStatus = 'PENDING_REVIEW';
    var bookingStatus = 'PENDING_DISPATCH';
    Map<String, dynamic> bookingSummary() => {
      'id': 'booking-fixture',
      'orderCode': 'FX-FIXTURE',
      'status': bookingStatus,
      'scheduledDate': '2026-11-04T00:00:00Z',
      'timeWindow': 'MORNING_09_12',
      'totalEgp': 400,
      'offering': {'titleEn': 'Fixture service', 'titleAr': 'خدمة اختبار'},
      'address': {
        'zone': {'nameEn': 'Fixture area', 'nameAr': 'منطقة اختبار'},
      },
    };
    Map<String, dynamic> bookingDetail() => {
      ...bookingSummary(),
      'version': 'b' * 64,
      'pricing': {
        'baseInspectionEgp': 150,
        'serviceFeeEgp': 250,
        'transportFeeEgp': 0,
        'totalEgp': 400,
      },
      'customer': {'fullName': 'Fixture customer', 'phone': '+201023456789'},
      'proProfile': null,
      'address': {
        'label': 'Home',
        'buildingLine': 'Fixture building',
        'districtLine': 'Fixture district',
        'gateNotes': null,
        'zone': {'nameEn': 'Fixture area', 'nameAr': 'منطقة اختبار'},
      },
      'payment': {
        'id': 'payment-fixture',
        'method': 'CASH_ON_SERVICE',
        'status': bookingStatus == 'CANCELLED' ? 'FAILED' : 'PENDING',
        'amountEgp': 400,
        'tipEgp': 0,
        'paidAt': null,
      },
      'issueDescription': 'Fixture issue',
      'completedAt': null,
      'cancellationReason': null,
      'history': [
        {
          'id': 'event-fixture',
          'fromStatus': 'DRAFT',
          'toStatus': bookingStatus,
          'note': 'Fixture event',
          'createdAt': '2026-11-03T10:00:00Z',
        },
      ],
      'hasOlderHistory': false,
      'canCancel': bookingStatus != 'CANCELLED',
      'canOffer': bookingStatus != 'CANCELLED',
    };
    final documentTypes = [
      'NATIONAL_ID_FRONT',
      'NATIONAL_ID_BACK',
      'CRIMINAL_RECORD_CERT',
    ];
    Map<String, dynamic> professional() => {
      'id': 'pro-fixture',
      'dossierCode': 'FX-PRO-fixture',
      'legalName': 'Fixture Legal Pro',
      'displayName': 'Fixture',
      'nationalId': '00000000000000',
      'phone': '+201023456789',
      'email': 'fixture@example.test',
      'verificationStatus': proStatus,
      'reviewerNote': null,
      'category': {'nameEn': 'Fixture trade', 'nameAr': 'حرفة اختبار'},
      'coverageZones': [
        {
          'id': 'fixture-zone',
          'nameEn': 'Fixture area',
          'nameAr': 'منطقة اختبار',
        },
      ],
      'reviewVersion': 'a' * 64,
      'canReview': !selfProfessional,
      'toolkitCommitmentConfirmed': true,
      'isOnline': false,
      'documents': [
        for (final type in documentTypes)
          {
            'id': type,
            'docType': type,
            'status': 'PENDING',
            'fileName': 'fixture.png',
            'mimeType': 'image/png',
            'fileSizeBytes': 68,
            'uploadedAt': '2026-11-03T10:00:00Z',
          },
      ],
    };
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
            if (bookingConflict &&
                r.path == '/admin/bookings/booking-fixture/cancel') {
              h.reject(
                DioException(
                  requestOptions: r,
                  response: Response(
                    requestOptions: r,
                    statusCode: 409,
                    data: {'code': 'BOOKING_VERSION_CONFLICT'},
                  ),
                ),
              );
              return;
            }
            if (r.path == '/admin/bookings/booking-fixture/cancel') {
              bookingStatus = 'CANCELLED';
            }
            if (r.path.startsWith('/admin/professionals/') &&
                r.path.endsWith('/content')) {
              h.resolve(
                Response(
                  requestOptions: r,
                  statusCode: 200,
                  data: corruptDocument ? <int>[1, 2, 3, 4] : documentPhoto,
                  headers: Headers.fromMap({
                    'content-type': ['image/png'],
                  }),
                ),
              );
              return;
            }
            if (r.path == '/admin/professionals/pro-fixture/review') {
              proStatus = (r.data as Map)['status'] as String;
            }
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
                  '/admin/bookings' => {
                    'items': [bookingSummary()],
                    'meta': {'page': 1, 'total': 1, 'totalPages': 1},
                  },
                  '/admin/bookings/booking-fixture' => bookingDetail(),
                  '/admin/bookings/booking-fixture/candidates' => {
                    'items': [
                      {
                        'id': 'pro-fixture',
                        'dossierCode': 'FX-PRO-fixture',
                        'user': {'fullName': 'Fixture professional'},
                      },
                    ],
                    'meta': {'page': 1, 'total': 1, 'totalPages': 1},
                  },
                  '/admin/bookings/booking-fixture/cancel' => {
                    'status': 'CANCELLED',
                  },
                  '/admin/bookings/booking-fixture/offer' => {
                    'offered': true,
                    'alreadyPending': false,
                  },
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
                  '/admin/professionals' => {
                    'items': [
                      {
                        'id': 'pro-fixture',
                        'dossierCode': 'FX-PRO-fixture',
                        'legalName': 'Fixture Legal Pro',
                        'verificationStatus': proStatus,
                        'documentCount': 3,
                      },
                    ],
                    'meta': {'page': 1, 'total': 1, 'totalPages': 1},
                  },
                  '/admin/professionals/pro-fixture' => professional(),
                  '/admin/professionals/pro-fixture/review' => {
                    'verificationStatus': proStatus,
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
          debugShowCheckedModeBanner: false,
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
    'professional approval requires viewing all three private images and explicit confirmation',
    (tester) async {
      final calls = <RequestOptions>[];
      await mount(tester, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-professionals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('admin-pro-approve')))
            .onPressed,
        isNull,
      );
      for (final type in [
        'NATIONAL_ID_FRONT',
        'NATIONAL_ID_BACK',
        'CRIMINAL_RECORD_CERT',
      ]) {
        final doc = find.byKey(Key('admin-pro-document-$type'));
        await tester.ensureVisible(doc);
        await tester.tap(doc);
        await tester.pumpAndSettle();
        // Wait for the real synthetic image codec, not an arbitrary clock delay.
        final image = find.byType(Image).last;
        await tester.runAsync(
          () => precacheImage(
            tester.widget<Image>(image).image,
            tester.element(image),
          ).timeout(const Duration(seconds: 5)),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('admin-document-reviewed')),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byKey(const Key('admin-document-reviewed')));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const Key('admin-pro-approve')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('admin-pro-approve')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('admin-pro-approve')));
      await tester.pumpAndSettle();
      expect(calls.where((r) => r.method == 'PATCH'), isEmpty);
      await tester.tap(find.byKey(const Key('admin-pro-review-confirmation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-review-submit')));
      await tester.pumpAndSettle();
      final review = calls.singleWhere((r) => r.method == 'PATCH');
      expect(review.data, containsPair('reviewVersion', 'a' * 64));
      expect(review.data, containsPair('confirmDocumentsReviewed', true));
      expect(review.path, '/admin/professionals/pro-fixture/review');
    },
  );
  testWidgets(
    'an administrator cannot approve their own professional dossier',
    (tester) async {
      final calls = <RequestOptions>[];
      await mount(tester, selfProfessional: true, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-professionals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
      await tester.pumpAndSettle();
      expect(
        find.text('You cannot review your own professional dossier.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('admin-pro-approve')), findsNothing);
      expect(calls.where((r) => r.method == 'PATCH'), isEmpty);
    },
  );
  testWidgets(
    'private dossier and document cannot revive after logout and a new login',
    (tester) async {
      final container = await mount(tester);
      await tester.tap(find.byKey(const Key('admin-nav-professionals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
      await tester.pumpAndSettle();
      final doc = find.byKey(const Key('admin-pro-document-NATIONAL_ID_FRONT'));
      await tester.ensureVisible(doc);
      await tester.tap(doc);
      await tester.pumpAndSettle();
      final image = find.byType(Image).last;
      await tester.runAsync(
        () => precacheImage(
          tester.widget<Image>(image).image,
          tester.element(image),
        ).timeout(const Duration(seconds: 5)),
      );
      await tester.pumpAndSettle();
      final auth = container.read(authControllerProvider.notifier) as _Auth;
      auth.changeAccount();
      await tester.pumpAndSettle();
      expect(find.textContaining('00000000000000'), findsNothing);
      auth.restoreFixtureAccount();
      await tester.pumpAndSettle();
      expect(find.textContaining('00000000000000'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('admin-document-reviewed')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets('corrupt private image never enables photo review confirmation', (
    tester,
  ) async {
    await mount(tester, corruptDocument: true);
    await tester.tap(find.byKey(const Key('admin-nav-professionals')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
    await tester.pumpAndSettle();
    final doc = find.byKey(const Key('admin-pro-document-NATIONAL_ID_FRONT'));
    await tester.ensureVisible(doc);
    await tester.tap(doc);
    await tester.pumpAndSettle();
    final image = find.byType(Image).last;
    await tester.runAsync(
      () => precacheImage(
        tester.widget<Image>(image).image,
        tester.element(image),
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 5)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not display the document photo.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('admin-document-reviewed')),
          )
          .onPressed,
      isNull,
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
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('Arabic professional dossier and photo fit $width at 1.35x', (
      tester,
    ) async {
      await mount(tester, width: width, arabic: true, dark: true);
      await tester.tap(find.byTooltip('فتح القائمة'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-nav-professionals')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('admin-pro-open-pro-fixture')),
      );
      await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
      await tester.pumpAndSettle();
      if (width == 390) {
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile('goldens/admin/professional_dossier_ar_dark.png'),
        );
      }
      final doc = find.byKey(const Key('admin-pro-document-NATIONAL_ID_FRONT'));
      await tester.ensureVisible(doc);
      await tester.tap(doc);
      await tester.pumpAndSettle();
      final image = find.byType(Image).last;
      await tester.runAsync(
        () => precacheImage(
          tester.widget<Image>(image).image,
          tester.element(image),
        ).timeout(const Duration(seconds: 5)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('desktop professional dossier visual review', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(const Key('admin-nav-professionals')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile('goldens/admin/professional_dossier_desktop.png'),
    );
  });
  testWidgets(
    'booking cancellation requires a reason and preserves the actual pricing display',
    (tester) async {
      final calls = <RequestOptions>[];
      await mount(tester, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-bookings')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('admin-booking-open-booking-fixture')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('400 EGP'), findsWidgets);
      expect(find.text('Fixture building'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('admin-booking-cancel')));
      await tester.tap(find.byKey(const Key('admin-booking-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-booking-action-submit')));
      await tester.pumpAndSettle();
      expect(calls.where((r) => r.path.endsWith('/cancel')), isEmpty);
      await tester.enterText(
        find.byKey(const Key('admin-booking-cancel-reason')),
        'Customer asked to cancel',
      );
      await tester.tap(find.byKey(const Key('admin-booking-action-submit')));
      await tester.pumpAndSettle();
      final mutation = calls.singleWhere((r) => r.path.endsWith('/cancel'));
      expect(mutation.data, {
        'version': 'b' * 64,
        'reason': 'Customer asked to cancel',
      });
      expect(find.text('Cancelled'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dispatch requires an explicitly selected pro and sends an offer rather than forcing assignment',
    (tester) async {
      final calls = <RequestOptions>[];
      await mount(tester, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-bookings')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('admin-booking-open-booking-fixture')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('admin-booking-offer')));
      await tester.tap(find.byKey(const Key('admin-booking-offer')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('admin-booking-action-submit')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.byKey(const Key('admin-booking-candidate-pro-fixture')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-booking-action-submit')));
      await tester.pumpAndSettle();
      expect(calls.singleWhere((r) => r.path.endsWith('/offer')).data, {
        'version': 'b' * 64,
        'proProfileId': 'pro-fixture',
      });
      expect(find.text('Confirmed'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('Arabic booking details and cancellation fit $width at 1.35x', (
      tester,
    ) async {
      await mount(tester, width: width, arabic: true, dark: true);
      await tester.tap(find.byTooltip('فتح القائمة'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-nav-bookings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('admin-booking-open-booking-fixture')),
      );
      await tester.tap(
        find.byKey(const Key('admin-booking-open-booking-fixture')),
      );
      await tester.pumpAndSettle();
      if (width == 390) {
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile('goldens/admin/booking_details_ar_dark.png'),
        );
      }
      await tester.ensureVisible(find.byKey(const Key('admin-booking-cancel')));
      await tester.tap(find.byKey(const Key('admin-booking-cancel')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('admin-booking-cancel-reason')),
        'طلب العميل إلغاء الحجز',
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'booking conflicts require a reload and never claim cancellation succeeded',
    (tester) async {
      await mount(tester, bookingConflict: true);
      await tester.tap(find.byKey(const Key('admin-nav-bookings')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('admin-booking-open-booking-fixture')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('admin-booking-cancel')));
      await tester.tap(find.byKey(const Key('admin-booking-cancel')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('admin-booking-cancel-reason')),
        'Cancellation request',
      );
      await tester.tap(find.byKey(const Key('admin-booking-action-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Reload and check'), findsOneWidget);
      expect(find.text('Cancelled'), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('admin-booking-cancel')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'an open booking and pending action stay invalid after logout and restoration',
    (tester) async {
      final calls = <RequestOptions>[];
      final container = await mount(tester, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-bookings')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('admin-booking-open-booking-fixture')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('admin-booking-cancel')));
      await tester.tap(find.byKey(const Key('admin-booking-cancel')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('admin-booking-cancel-reason')),
        'Pending private reason',
      );
      final auth = container.read(authControllerProvider.notifier) as _Auth;
      auth.changeAccount();
      await tester.pumpAndSettle();
      auth.restoreFixtureAccount();
      await tester.pumpAndSettle();
      expect(find.text('Pending private reason'), findsNothing);
      expect(find.text('Fixture building'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('admin-booking-action-submit')),
            )
            .onPressed,
        isNull,
      );
      expect(calls.where((r) => r.path.endsWith('/cancel')), isEmpty);
    },
  );
  testWidgets(
    'a pending private decision cannot act after logout and same-account restoration',
    (tester) async {
      final calls = <RequestOptions>[];
      final container = await mount(tester, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-professionals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Request corrections'));
      await tester.tap(find.text('Request corrections'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Please replace the blurry photo',
      );
      final auth = container.read(authControllerProvider.notifier) as _Auth;
      auth.changeAccount();
      await tester.pumpAndSettle();
      auth.restoreFixtureAccount();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-review-submit')));
      await tester.pumpAndSettle();
      expect(
        calls.where((r) => r.path.endsWith('/review') && r.method == 'PATCH'),
        isEmpty,
      );
    },
  );
  testWidgets(
    'corrections identify selected documents and require a clear reason',
    (tester) async {
      final calls = <RequestOptions>[];
      await mount(tester, calls: calls);
      await tester.tap(find.byKey(const Key('admin-nav-professionals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-open-pro-fixture')));
      await tester.pumpAndSettle();
      final corrections = find.widgetWithText(
        OutlinedButton,
        'Request corrections',
      );
      await tester.ensureVisible(corrections);
      await tester.tap(corrections);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-pro-review-submit')));
      await tester.pumpAndSettle();
      expect(calls.where((r) => r.method == 'PATCH'), isEmpty);
      await tester.enterText(
        find.byKey(const Key('admin-pro-review-note')),
        'Upload a clearer back photo.',
      );
      await tester.tap(
        find.byKey(const Key('admin-pro-correction-doc-NATIONAL_ID_BACK')),
      );
      await tester.tap(find.byKey(const Key('admin-pro-review-submit')));
      await tester.pumpAndSettle();
      expect(
        calls.singleWhere((r) => r.method == 'PATCH').data,
        containsPair('documentDecisions', [
          {'docType': 'NATIONAL_ID_BACK', 'status': 'REJECTED'},
        ]),
      );
    },
  );
}
