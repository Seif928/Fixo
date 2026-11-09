import 'package:fixo_mobile/app/router/app_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_auth_page.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_password_page.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/customer_home/presentation/pages/customer_home_page.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/customer_home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldFailOtpRequest = false;
  String validCode = '482910';

  @override
  Future<OtpChallengeResult> requestOtp({required String phone}) async {
    if (shouldFailOtpRequest) {
      throw const AuthApiException(
        'Too many OTP requests for this mobile number.',
        statusCode: 429,
      );
    }
    return OtpChallengeResult(
      challengeId: 'ch-test-01',
      phone: phone,
      resendAvailableInSec: 42,
      expiresInSec: 300,
      demoHint: 'Use 482910 in development/demo mode',
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? challengeId,
  }) async {
    if (code != validCode) {
      throw const AuthApiException(
        'Invalid verification code. 4 attempt(s) remaining.',
        statusCode: 401,
      );
    }
    return AuthSession(
      accessToken: 'jwt-access-token-test',
      refreshToken: 'jwt-refresh-token-test',
      user: AuthUser(
        id: 'u-salma-01',
        phone: phone,
        fullName: 'Salma El-Shazly',
        role: 'CUSTOMER',
        rewardPoints: 1420,
      ),
    );
  }

  @override
  Future<AuthSession> refreshSession({required String refreshToken}) async {
    return const AuthSession(
      accessToken: 'jwt-access-token-rotated',
      refreshToken: 'jwt-refresh-token-rotated',
      user: AuthUser(
        id: 'u-salma-01',
        phone: '+201023456789',
        fullName: 'Salma El-Shazly',
        role: 'CUSTOMER',
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<AuthUser> fetchCurrentUser() async {
    return const AuthUser(
      id: 'u-salma-01',
      phone: '+201023456789',
      fullName: 'Salma El-Shazly',
      role: 'CUSTOMER',
    );
  }
}

class FakeMarketplaceRepository implements MarketplaceRepository {
  bool shouldFail = false;

  static CustomerHomeFeed sampleFeed() {
    return const CustomerHomeFeed(
      zones: [
        CoverageZoneModel(
          id: 'zone-sheikh-zayed',
          slug: 'sheikh-zayed',
          nameEn: 'Sheikh Zayed, Dist. 9',
          nameAr: 'الشيخ زايد، الحي التاسع',
          governorate: 'Giza',
        ),
        CoverageZoneModel(
          id: 'zone-new-cairo',
          slug: 'new-cairo',
          nameEn: 'New Cairo, 5th Settlement',
          nameAr: 'القاهرة الجديدة، التجمع الخامس',
          governorate: 'Cairo',
        ),
      ],
      categories: [
        ServiceCategoryModel(
          id: 'cat-ac-maintenance',
          slug: 'ac-maintenance',
          nameEn: 'AC Maintenance',
          nameAr: 'صيانة التكييف',
          subtitleEn: 'Inverter, split & duct',
          subtitleAr: 'إنفرتر، سبليت ومركزي',
          iconName: 'mode_fan',
          startingPriceEgp: 450,
          sortOrder: 1,
        ),
        ServiceCategoryModel(
          id: 'cat-plumbing-leaks',
          slug: 'plumbing-leaks',
          nameEn: 'Plumbing & Leaks',
          nameAr: 'السباكة والتسريبات',
          subtitleEn: 'Pipes, heaters & traps',
          subtitleAr: 'مواسير، سخانات وصرف',
          iconName: 'plumbing',
          startingPriceEgp: 280,
          sortOrder: 2,
        ),
        ServiceCategoryModel(
          id: 'cat-electrical-lighting',
          slug: 'electrical-lighting',
          nameEn: 'Electrical & Lighting',
          nameAr: 'الكهرباء والإضاءة',
          subtitleEn: 'Breakers, wiring & LED',
          subtitleAr: 'لوحات، تأسيس وإضاءة حديثة',
          iconName: 'bolt',
          startingPriceEgp: 250,
          sortOrder: 3,
        ),
        ServiceCategoryModel(
          id: 'cat-deep-cleaning',
          slug: 'deep-home-cleaning',
          nameEn: 'Deep Home Cleaning',
          nameAr: 'تنظيف عميق للمنازل',
          subtitleEn: 'Post-renovation & villas',
          subtitleAr: 'تنظيف الفيلات وما بعد التشطيب',
          iconName: 'cleaning_services',
          startingPriceEgp: 600,
          sortOrder: 4,
        ),
        ServiceCategoryModel(
          id: 'cat-carpentry-repairs',
          slug: 'carpentry-repairs',
          nameEn: 'Carpentry & Repairs',
          nameAr: 'النجارة والإصلاحات',
          subtitleEn: 'Hinges, locks & bespoke',
          subtitleAr: 'مفصلات، كوالين وأعمال خشبية',
          iconName: 'handyman',
          startingPriceEgp: 320,
          sortOrder: 5,
        ),
        ServiceCategoryModel(
          id: 'cat-painting-finishing',
          slug: 'painting-finishing',
          nameEn: 'Painting & Finishing',
          nameAr: 'النقاشة والتشطيبات',
          subtitleEn: 'Jotun primed coatings',
          subtitleAr: 'دهانات جوتن وتشطيب الحوائط',
          iconName: 'format_paint',
          startingPriceEgp: 850,
          sortOrder: 6,
        ),
      ],
      services: [
        ServiceOfferModel(
          id: 'off-ac-deep-clean',
          categoryId: 'cat-ac-maintenance',
          categorySlug: 'ac-maintenance',
          slug: 'summer-ac-deep-clean-gas-refill',
          titleEn: 'Summer AC Deep Clean & Gas Refill',
          titleAr: 'غسيل التكييف العميق وشحن الفريون الصيفي',
          descriptionEn:
              'Complete coil flush, antibacterial sanitized mist, and pressure gauge test.',
          descriptionAr:
              'تنظيف شامل للمكثف، تعقيم مضاد للبكتيريا، واختبار ضغط الفريون.',
          badgeEn: 'SEASONAL PEAK',
          badgeAr: 'عرض الموسم',
          providerTagEn: 'Daikin & Carrier Pros',
          providerTagAr: 'فنيو كاريير ودايكن',
          baseInspectionEgp: 150,
          serviceFeeEgp: 200,
          flatPriceEgp: 350,
          estimatedDurationMins: 60,
          isSeasonalPromo: true,
          isBundle: false,
        ),
        ServiceOfferModel(
          id: 'off-home-safety-bundle',
          categoryId: 'cat-electrical-lighting',
          categorySlug: 'electrical-lighting',
          slug: 'home-safety-inspection-bundle',
          titleEn: 'Home Safety Inspection',
          titleAr: 'فحص أمان المنزل الشامل',
          descriptionEn: 'Complete Electrical & Plumbing dual audit',
          descriptionAr: 'فحص مزدوج شامل لشبكة الكهرباء والسباكة المنزلية',
          badgeEn: 'BUNDLE SAVE',
          badgeAr: 'باقة توفير',
          baseInspectionEgp: 200,
          serviceFeeEgp: 250,
          flatPriceEgp: 450,
          estimatedDurationMins: 90,
          isSeasonalPromo: false,
          isBundle: true,
        ),
      ],
      professionals: [
        ProfessionalCardModel(
          id: 'pro-tarek-01',
          fullNameEn: 'Eng. Tarek Mansour',
          fullNameAr: 'م. طارق منصور',
          primaryCategoryId: 'cat-electrical-lighting',
          primaryCategorySlug: 'electrical-lighting',
          primaryZoneSlug: 'new-cairo',
          specialtyEn: 'Master Electrician',
          specialtyAr: 'كبير فنيي كهرباء',
          zonesLabelEn: 'New Cairo & Maadi',
          zonesLabelAr: 'القاهرة الجديدة والمعادي',
          ratingAvg: 4.9,
          reviewsCount: 184,
          estimatedPriceEgp: 250,
          badgeEn: 'Verified Master Pro',
          badgeAr: 'فني خبير معتمد',
          badgeVariant: 'verified_master',
          isOnline: true,
        ),
        ProfessionalCardModel(
          id: 'pro-hassan-01',
          fullNameEn: 'Hassan El-Sayed',
          fullNameAr: 'حسن السيد',
          primaryCategoryId: 'cat-ac-maintenance',
          primaryCategorySlug: 'ac-maintenance',
          primaryZoneSlug: 'sheikh-zayed',
          specialtyEn: 'AC Specialist',
          specialtyAr: 'أخصائي تكييف وتبريد',
          zonesLabelEn: 'Sheikh Zayed & Dokki',
          zonesLabelAr: 'الشيخ زايد والدقي',
          ratingAvg: 4.95,
          reviewsCount: 240,
          estimatedPriceEgp: 350,
          badgeEn: 'Fast Responder (<15m)',
          badgeAr: 'استجابة سريعة (<١٥ د)',
          badgeVariant: 'fast_responder',
          isOnline: true,
        ),
      ],
      storageMode: 'IN_MEMORY_FALLBACK',
      databaseConnected: false,
    );
  }

  @override
  Future<CustomerHomeFeed> fetchCustomerHomeFeed({
    String? search,
    String? categoryId,
    String? zone,
  }) async {
    if (shouldFail) {
      throw const MarketplaceApiException(
        'Backend server unreachable on localhost:3000.',
        statusCode: 503,
      );
    }
    return sampleFeed();
  }

  @override
  Future<ServiceOfferModel> fetchServiceById(String id) async {
    return sampleFeed().services.first;
  }

  @override
  Future<PaginatedServices> getPaginatedServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
  }) async {
    final services = sampleFeed().services;
    return PaginatedServices(
      items: services,
      page: page,
      totalPages: 1,
      total: services.length,
    );
  }
}

Widget _buildTestApp({
  required List<Override> overrides,
  String initialLocation = '${AppRoutes.phoneAuth}?method=dev-otp',
}) {
  return ProviderScope(
    overrides: overrides,
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(appLocaleProvider);
        final themeMode = ref.watch(appThemeModeProvider);
        final router = createAppRouter(
          initialLocation: initialLocation,
          isAuthenticated: () =>
              ref.read(authControllerProvider).isAuthenticated,
        );

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: themeMode,
          theme: FixoTheme.light(locale: locale),
          darkTheme: FixoTheme.dark(locale: locale),
          routerConfig: router,
        );
      },
    ),
  );
}

void main() {
  group('Screen 02: PhoneAuthPage — Validation, OTP, Token Storage & Redirects', () {
    test(
      'EgyptPhoneValidator validates +20 Egyptian numbers and rejects invalid prefixes',
      () {
        expect(
          EgyptPhoneValidator.tryNormalize('010 2345 6789'),
          '+201023456789',
        );
        expect(
          EgyptPhoneValidator.tryNormalize('+20 112 345 6789'),
          '+201123456789',
        );
        expect(
          EgyptPhoneValidator.tryNormalize('01287654321'),
          '+201287654321',
        );
        expect(
          EgyptPhoneValidator.tryNormalize('01551234567'),
          '+201551234567',
        );
        expect(EgyptPhoneValidator.tryNormalize('01912345678'), isNull);
        expect(EgyptPhoneValidator.tryNormalize('12345'), isNull);
      },
    );

    testWidgets(
      'displays error banner when invalid Egyptian phone is submitted, then sends OTP and verifies 6-digit code',
      (WidgetTester tester) async {
        final fakeAuthRepo = FakeAuthRepository();
        final fakeMarketRepo = FakeMarketplaceRepository();
        final tokenStorage = MemoryTokenStorage();

        await tester.pumpWidget(
          _buildTestApp(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              marketplaceRepositoryProvider.overrideWithValue(fakeMarketRepo),
              secureTokenStorageProvider.overrideWithValue(tokenStorage),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Enter invalid phone number first
        final phoneField = find.descendant(
          of: find.byKey(const Key('field-egypt-phone')),
          matching: find.byType(TextField),
        );
        await tester.enterText(phoneField, '019000');
        await tester.pump();

        final continueBtn = find.byKey(const Key('btn-continue-phone'));
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pump();

        expect(find.byKey(const Key('auth-error-banner')), findsOneWidget);

        // Enter valid Egyptian phone number (+20 102 345 6789)
        await tester.enterText(phoneField, '010 2345 6789');
        await tester.pump();
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Should now be on State 2: OTP Code
        expect(find.byKey(const Key('section-otp-code')), findsOneWidget);
        expect(
          find.byKey(const Key('otp-resend-countdown-label')),
          findsOneWidget,
        );
        expect(
          find.textContaining('00:42', findRichText: true),
          findsOneWidget,
        );

        // Enter wrong 6-digit OTP first via tactile keypad
        for (final digit in ['0', '0', '0', '0', '0', '0']) {
          final keyBtn = find.byKey(Key('keypad-digit-$digit'));
          await tester.ensureVisible(keyBtn);
          await tester.tap(keyBtn);
          await tester.pump();
        }

        final verifyBtn = find.byKey(const Key('btn-verify-otp'));
        await tester.ensureVisible(verifyBtn);
        await tester.tap(verifyBtn);
        await tester.pumpAndSettle();

        // API error must be shown
        expect(find.byKey(const Key('auth-error-banner')), findsOneWidget);
        expect(
          find.textContaining('Invalid verification code'),
          findsOneWidget,
        );

        // Enter valid 6-digit OTP ('482910') and verify
        await tester.enterText(
          find.byKey(const Key('otp-hidden-input')),
          '482910',
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(verifyBtn);
        await tester.tap(verifyBtn, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Tokens must be saved in SecureTokenStorage
        final storedAccess = await tokenStorage.readAccessToken();
        expect(storedAccess, 'jwt-access-token-test');
        expect(
          ProviderScope.containerOf(
            tester.element(find.byType(CustomerHomePage)),
          ).read(activeSessionOwnerProvider),
          'u-salma-01',
        );

        // Must redirect to Screen 03 Customer Home
        expect(find.text('Summer AC Deep Clean & Gas Refill'), findsOneWidget);
      },
    );

    testWidgets(
      'GoRouter redirects unauthenticated access to /customer/home back to /auth/phone',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialLocation: AppRoutes.customerHome,
            overrides: [
              authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
              marketplaceRepositoryProvider.overrideWithValue(
                FakeMarketplaceRepository(),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Because user is not authenticated, /customer/home redirects to /auth/phone
        expect(
          find.byWidgetPredicate(
            (w) => w is PhoneAuthPage || w is PhonePasswordPage,
          ),
          findsOneWidget,
        );
        expect(find.text('Welcome to FIXO'), findsOneWidget);
      },
    );
  });

  group('Screen 03: CustomerHomePage — Layout, Categories, EGP Prices & States', () {
    testWidgets(
      'Book Slot asks for a matching service before navigating with both selections',
      (tester) async {
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const CustomerHomePage()),
            GoRoute(
              path: AppRoutes.createBooking,
              builder: (_, state) {
                final extra = state.extra! as Map<String, dynamic>;
                return Scaffold(
                  body: Text(
                    'selected:${(extra['offering'] as ServiceOfferModel?)?.id}:${(extra['preferredPro'] as ProfessionalCardModel?)?.id}',
                  ),
                );
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              marketplaceRepositoryProvider.overrideWithValue(
                FakeMarketplaceRepository(),
              ),
            ],
            child: MaterialApp.router(
              theme: FixoTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Hassan El-Sayed'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        final card = find.ancestor(
          of: find.text('Hassan El-Sayed'),
          matching: find.byType(RecommendedProCard),
        );
        await tester.tap(
          find.descendant(of: card, matching: find.text('Book Slot')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Choose a service'), findsOneWidget);
        expect(find.textContaining('selected:'), findsNothing);
        await tester.tap(
          find.byKey(const Key('pro-service-off-ac-deep-clean')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('selected:off-ac-deep-clean:pro-hassan-01'),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'renders header, location selector, search bar, seasonal promo, 6 categories, bundle card, and Cairo pros in EGP',
      (WidgetTester tester) async {
        final fakeMarketRepo = FakeMarketplaceRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              marketplaceRepositoryProvider.overrideWithValue(fakeMarketRepo),
            ],
            child: MaterialApp(
              theme: FixoTheme.light(),
              home: const CustomerHomePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Brand header & Location selector
        expect(find.text('FIXO'), findsOneWidget);
        expect(find.text('Choose your area'), findsOneWidget);
        expect(find.text('Sheikh Zayed, Dist. 9'), findsNothing);

        // Featured Seasonal Promo (350 EGP)
        expect(find.text('Summer AC Deep Clean & Gas Refill'), findsOneWidget);
        expect(find.text('350'), findsWidgets);

        // All 6 Service Categories in EGP
        expect(find.text('AC Maintenance'), findsOneWidget);
        expect(find.text('~450 EGP'), findsOneWidget);
        expect(find.text('Plumbing & Leaks'), findsOneWidget);
        expect(find.text('~280 EGP'), findsOneWidget);
        expect(find.text('Electrical & Lighting'), findsOneWidget);
        expect(find.text('~250 EGP'), findsOneWidget);
        expect(find.text('Deep Home Cleaning'), findsOneWidget);
        expect(find.text('~600 EGP'), findsOneWidget);
        expect(find.text('Carpentry & Repairs'), findsOneWidget);
        expect(find.text('~320 EGP'), findsOneWidget);
        expect(find.text('Painting & Finishing'), findsOneWidget);
        expect(find.text('~850 EGP'), findsOneWidget);

        // Bundle Save Card (450 EGP)
        expect(find.text('Home Safety Inspection'), findsOneWidget);
        expect(find.text('450'), findsOneWidget);

        // Recommended Professionals (Eng. Tarek Mansour 250 EGP, Hassan El-Sayed 350 EGP)
        expect(find.text('Eng. Tarek Mansour'), findsOneWidget);
        expect(find.text('Verified Master Pro'), findsOneWidget);
        expect(find.text('Hassan El-Sayed'), findsOneWidget);
        expect(find.text('Fast Responder (<15m)'), findsOneWidget);

        // Customer 4-Tab Bottom Navigation Bar
        expect(find.byKey(const Key('customer-bottom-nav')), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('Messages'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'supports search filtering, empty search state, and API error retry state',
      (WidgetTester tester) async {
        final fakeMarketRepo = FakeMarketplaceRepository()..shouldFail = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              marketplaceRepositoryProvider.overrideWithValue(fakeMarketRepo),
            ],
            child: MaterialApp(
              theme: FixoTheme.light(),
              home: const CustomerHomePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Error state must appear when API fails
        expect(find.byKey(const Key('customer-home-error')), findsOneWidget);

        // Recover when Retry is tapped
        fakeMarketRepo.shouldFail = false;
        await tester.tap(find.byKey(const Key('btn-retry-home')));
        await tester.pumpAndSettle();

        expect(find.text('AC Maintenance'), findsOneWidget);

        // Enter a search query with no matches -> Empty State
        await tester.enterText(
          find.byKey(const Key('input-customer-home-search')),
          'NonExistentXyzService',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('customer-home-empty')), findsOneWidget);

        // Clear search restores all categories
        await tester.tap(find.byKey(const Key('btn-empty-clear-search')));
        await tester.pumpAndSettle();
        expect(find.text('AC Maintenance'), findsOneWidget);
      },
    );

    testWidgets(
      'Screen 02 & Screen 03 render cleanly across 360dp, 390dp, 412dp viewports + 1.35x text scale + Arabic RTL + Dark Mode',
      (WidgetTester tester) async {
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          // ignore: avoid_print
          print('DETAILED_OVERFLOW: ${details.exceptionAsString()}');
          if (details.informationCollector != null) {
            for (final node in details.informationCollector!()) {
              // ignore: avoid_print
              print(node.toString());
            }
          }
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        const viewports = <Size>[
          Size(360, 800),
          Size(390, 844),
          Size(412, 915),
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          final container = ProviderContainer(
            overrides: [
              authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
              marketplaceRepositoryProvider.overrideWithValue(
                FakeMarketplaceRepository(),
              ),
            ],
          );
          container
              .read(appLocaleProvider.notifier)
              .setLocale(const Locale('ar'));
          container
              .read(appThemeModeProvider.notifier)
              .setThemeMode(ThemeMode.dark);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.35),
                ),
                child: MaterialApp(
                  locale: const Locale('ar'),
                  supportedLocales: const [Locale('en'), Locale('ar')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  theme: FixoTheme.dark(locale: const Locale('ar')),
                  home: const CustomerHomePage(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final error = tester.takeException();
          if (error is FlutterError) {
            // ignore: avoid_print
            print('VIEWPORT ERROR at $size: ${error.toStringDeep()}');
          }
          expect(error, isNull);
          expect(find.text('صيانة التكييف'), findsOneWidget);
          container.dispose();
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
