import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/email_auth_page.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_auth_page.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_password_page.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/booking/presentation/pages/create_booking_page.dart';
import 'package:fixo_mobile/features/booking/presentation/pages/orders_page.dart';
import 'package:fixo_mobile/features/chat/data/communications_repository.dart';
import 'package:fixo_mobile/features/chat/presentation/chat_page.dart';
import 'package:fixo_mobile/features/chat/presentation/notification_sheet.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/customer_home/presentation/pages/customer_home_page.dart';
import 'package:fixo_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fixo_mobile/features/payment/presentation/pages/checkout_page.dart';
import 'package:fixo_mobile/features/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/time/app_clock.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser> fetchCurrentUser() async => const AuthUser(
    id: 'cust-101',
    phone: '+201023456789',
    fullName: 'Salma El-Shazly',
    role: 'CUSTOMER',
  );

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<AuthSession> refreshSession({required String refreshToken}) async =>
      const AuthSession(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        user: AuthUser(
          id: 'cust-101',
          phone: '+201023456789',
          fullName: 'Salma El-Shazly',
          role: 'CUSTOMER',
        ),
      );

  @override
  Future<OtpChallengeResult> requestOtp({required String phone}) async =>
      OtpChallengeResult(
        challengeId: 'ch-01',
        phone: phone,
        resendAvailableInSec: 45,
        expiresInSec: 300,
        demoHint: 'Use 482910 in development/demo mode',
      );

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? challengeId,
  }) async => const AuthSession(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    user: AuthUser(
      id: 'cust-101',
      phone: '+201023456789',
      fullName: 'Salma El-Shazly',
      role: 'CUSTOMER',
    ),
  );
}

class _FakeMarketplaceRepository implements MarketplaceRepository {
  static const ServiceOfferModel sampleOffering = ServiceOfferModel(
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
  );

  @override
  Future<CustomerHomeFeed> fetchCustomerHomeFeed({
    String? search,
    String? categoryId,
    String? zone,
  }) async {
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
      ],
      services: [sampleOffering],
      professionals: [],
      storageMode: 'POSTGRES_PRISMA',
      databaseConnected: true,
    );
  }

  @override
  Future<ServiceOfferModel> fetchServiceById(String id) async => sampleOffering;

  @override
  Future<PaginatedServices> getPaginatedServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
  }) async => PaginatedServices(
    items: [sampleOffering],
    page: page,
    totalPages: 1,
    total: 1,
  );
}

class _FakeBookingRepository implements BookingRepository {
  @override
  Future<List<CustomerAddressModel>> getCustomerAddresses() async => const [
    CustomerAddressModel(
      id: 'addr-01',
      userId: 'cust-101',
      zoneId: 'zone-sheikh-zayed',
      label: 'Home Apartment',
      buildingLine: 'Villa 14, Street 7',
      districtLine: 'Sheikh Zayed, Dist. 9',
      gateNotes: 'Gate 2',
      isDefault: true,
    ),
  ];

  @override
  Future<List<CoverageZoneModel>> getCoverageZones() async => const [
    CoverageZoneModel(
      id: 'zone-sheikh-zayed',
      slug: 'sheikh-zayed',
      nameEn: 'Sheikh Zayed, Dist. 9',
      nameAr: 'الشيخ زايد، الحي التاسع',
      governorate: 'Giza',
    ),
  ];

  @override
  Future<CustomerAddressModel> createAddress(
    CreateAddressRequest request,
  ) async {
    return CustomerAddressModel(
      id: 'addr-02',
      userId: 'cust-101',
      zoneId: request.zoneId,
      label: request.label,
      buildingLine: request.buildingLine,
      districtLine: request.districtLine,
      gateNotes: request.gateNotes,
      isDefault: request.isDefault,
    );
  }

  @override
  Future<BookingDetailModel> createBooking(CreateBookingRequest request) async {
    return getBookingById('bk-8842');
  }

  @override
  Future<List<BookingDetailModel>> getBookings({
    String? tab,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    return [await getBookingById('bk-8842')];
  }

  @override
  Future<BookingDetailModel> getBookingById(String bookingId) async {
    return BookingDetailModel(
      id: bookingId,
      orderCode: 'FX-8842',
      customerId: 'cust-101',
      offeringId: 'off-ac-deep-clean',
      addressId: 'addr-01',
      status: 'DRAFT',
      scheduledDate: '2026-11-05',
      timeWindow: 'AFTERNOON_13_16',
      pricing: const BookingPricingModel(
        baseInspectionEgp: 150,
        serviceFeeEgp: 200,
        transportFeeEgp: 0,
        totalEgp: 350,
      ),
      offering: const {
        'id': 'off-ac-deep-clean',
        'titleEn': 'Summer AC Deep Clean & Gas Refill',
        'titleAr': 'غسيل التكييف العميق وشحن الفريون الصيفي',
      },
      address: const {
        'id': 'addr-01',
        'label': 'Home Apartment',
        'districtLine': 'Sheikh Zayed, Dist. 9',
      },
      createdAt: '2026-11-01T10:00:00Z',
    );
  }

  @override
  Future<BookingDetailModel> checkoutBooking(
    String bookingId, {
    String paymentMethod = 'CASH_ON_SERVICE',
  }) async {
    final draft = await getBookingById(bookingId);
    return BookingDetailModel(
      id: draft.id,
      orderCode: draft.orderCode,
      customerId: draft.customerId,
      offeringId: draft.offeringId,
      addressId: draft.addressId,
      status: 'PENDING_DISPATCH',
      scheduledDate: draft.scheduledDate,
      timeWindow: draft.timeWindow,
      pricing: draft.pricing,
      offering: draft.offering,
      address: draft.address,
      createdAt: draft.createdAt,
    );
  }

  @override
  Future<BookingTrackingModel> getBookingTracking(String bookingId) async {
    throw UnimplementedError();
  }

  @override
  Future<BookingDetailModel> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BookingReceiptModel> getBookingReceipt(String bookingId) async {
    throw UnimplementedError();
  }

  @override
  Future<BookingReviewModel?> getBookingReview(String bookingId) async {
    return null;
  }

  @override
  Future<BookingReviewModel> submitBookingReview(
    String bookingId, {
    required int rating,
    List<String> tags = const [],
    String? comment,
    List<String> photoUrls = const [],
    int tipAmountEgp = 0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PrivateUploadResultModel> uploadPrivateMedia({
    required String purpose,
    required String fileName,
    required String mimeType,
    required String contentBase64,
    String? bookingId,
  }) async {
    return PrivateUploadResultModel(
      uploadId: 'mock-upl-01',
      purpose: purpose,
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: 1024,
      sha256: 'mock-sha',
      accessToken: 'mock-token',
      expiresAt: '2099-01-01T00:00:00Z',
      privateDataUri: 'data:$mimeType;base64,$contentBase64',
    );
  }
}

class _FakeCommunicationsRepository extends CommunicationsRepository {
  _FakeCommunicationsRepository() : super(Dio());

  @override
  Future<MessagePage> messages(String bookingId, {String? before}) async =>
      const MessagePage([], null);

  @override
  Future<List<Map<String, dynamic>>> notifications() async => [
    {
      'id': 'notif-1',
      'bookingId': 'bk-8842',
      'orderCode': 'FX-8842',
      'kind': 'STATUS_CHANGE',
      'status': 'PENDING_DISPATCH',
      'createdAt': '2026-11-01T14:30:00Z',
    },
    {
      'id': 'notif-2',
      'bookingId': 'bk-8842',
      'orderCode': 'FX-8842',
      'kind': 'UNREAD_MESSAGE',
      'status': 'CONFIRMED',
      'createdAt': '2026-11-01T15:00:00Z',
    },
  ];
}

class _FakeProfileAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = jsonEncode({
      'user': {
        'id': 'cust-101',
        'fullName': 'Salma El-Shazly',
        'email': 'salma.elshazly@example.com',
        'phone': '+201023456789',
        'role': 'CUSTOMER',
        'arrivalAlertsEnabled': true,
      },
    });
    return ResponseBody.fromString(
      payload,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Dio _buildFakeProfileDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3001/api/v1'));
  dio.httpClientAdapter = _FakeProfileAdapter();
  return dio;
}

Future<Widget> _buildTestHarness({
  required Widget child,
  required Locale locale,
  required ThemeMode themeMode,
  double textScale = 1.35,
}) async {
  SharedPreferences.setMockInitialValues({
    'fixo.locale': locale.languageCode,
    'fixo.theme': switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    },
  });
  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = MemoryTokenStorage();
  await tokenStorage.saveTokens(
    const StoredAuthTokens(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      userId: 'cust-101',
      phone: '+201023456789',
      role: 'CUSTOMER',
    ),
  );

  return ProviderScope(
    overrides: [
      appNowProvider.overrideWithValue(() => DateTime(2026, 11, 2)),
      appPreferencesProvider.overrideWithValue(prefs),
      secureTokenStorageProvider.overrideWithValue(tokenStorage),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      marketplaceRepositoryProvider.overrideWithValue(
        _FakeMarketplaceRepository(),
      ),
      bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
      communicationsRepositoryProvider.overrideWithValue(
        _FakeCommunicationsRepository(),
      ),
      dioClientProvider.overrideWithValue(_buildFakeProfileDio()),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final activeLocale = ref.watch(appLocaleProvider);
        final activeThemeMode = ref.watch(appThemeModeProvider);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: activeLocale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: FixoTheme.light(locale: activeLocale),
          darkTheme: FixoTheme.dark(locale: activeLocale),
          themeMode: activeThemeMode,
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: inner!,
          ),
          home: child,
        );
      },
    ),
  );
}

void main() {
  testWidgets(
    'marketplace uses a wide desktop grid and preserves the narrow mobile layout',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [390.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          await _buildTestHarness(
            child: const CustomerHomePage(),
            locale: const Locale('en'),
            themeMode: ThemeMode.light,
            textScale: 1.35,
          ),
        );
        await tester.pumpAndSettle();
        final size = tester.getSize(
          find.byKey(const Key('home-marketplace-layout')),
        );
        expect(
          size.width,
          width < 1000 ? lessThanOrEqualTo(600) : greaterThan(900),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
  const widths = <double>[360.0, 390.0, 412.0];
  const locales = <Locale>[Locale('en'), Locale('ar')];
  const themeModes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

  final screens = <String, Widget Function()>{
    '01_OnboardingPage': () => const OnboardingPage(),
    '02A_PhoneAuthPage': () => const PhoneAuthPage(),
    '02B_EmailAuthPage': () => const EmailAuthPage(),
    '02C_PhonePasswordPage': () => const PhonePasswordPage(),
    '03_CustomerHomePage': () => const CustomerHomePage(),
    '04_CreateBookingPage': () => const CreateBookingPage(
      initialOffering: _FakeMarketplaceRepository.sampleOffering,
    ),
    '05_CheckoutPage': () => const CheckoutPage(bookingId: 'bk-8842'),
    '07_ChatPage': () => const ChatPage(bookingId: 'bk-8842'),
    '08_OrdersPage': () => const OrdersPage(),
    '08_ConversationsList': () => const OrdersPage(showChats: true),
    '10A_NotificationSheet': () => const Scaffold(body: NotificationSheet()),
    '10B_ProfilePage': () => const ProfilePage(),
  };

  group(
    'Responsive Matrix Verification (360/390/412dp, 1.35x scale, EN/AR, Light/Dark)',
    () {
      for (final entry in screens.entries) {
        for (final width in widths) {
          for (final locale in locales) {
            for (final themeMode in themeModes) {
              final modeName = themeMode == ThemeMode.dark ? 'dark' : 'light';
              testWidgets(
                '${entry.key} renders without overflow at ${width.toInt()}dp, 1.35x, ${locale.languageCode}, $modeName',
                (tester) async {
                  tester.view.physicalSize = Size(width, 900);
                  tester.view.devicePixelRatio = 1.0;
                  addTearDown(() {
                    tester.view.resetPhysicalSize();
                    tester.view.resetDevicePixelRatio();
                  });

                  final widget = await _buildTestHarness(
                    child: entry.value(),
                    locale: locale,
                    themeMode: themeMode,
                    textScale: 1.35,
                  );

                  await tester.pumpWidget(widget);
                  await tester.pumpAndSettle();

                  expect(tester.takeException(), isNull);

                  final scaffoldFinder = find.byType(Scaffold).first;
                  final expectedDirection = locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr;
                  expect(
                    Directionality.of(tester.element(scaffoldFinder)),
                    expectedDirection,
                  );

                  // Cleanup timers cleanly for ChatPage
                  await tester.pumpWidget(const SizedBox.shrink());
                  await tester.pump(const Duration(seconds: 11));
                  expect(tester.takeException(), isNull);
                },
              );
            }
          }
        }
      }
    },
  );

  group('Golden Screenshots for Polished Screens (Light/Dark & EN/AR)', () {
    final goldenTargets = <String, (Widget Function(), Locale, ThemeMode)>{
      '02_phone_password_light_en': (
        () => const PhonePasswordPage(),
        const Locale('en'),
        ThemeMode.light,
      ),
      '02_phone_password_dark_ar': (
        () => const PhonePasswordPage(),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '08_orders_light_en': (
        () => const OrdersPage(),
        const Locale('en'),
        ThemeMode.light,
      ),
      '08_orders_dark_ar': (
        () => const OrdersPage(),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '01_onboarding_light_en': (
        () => const OnboardingPage(),
        const Locale('en'),
        ThemeMode.light,
      ),
      '01_onboarding_dark_ar': (
        () => const OnboardingPage(),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '02_phone_auth_light_en': (
        () => const PhoneAuthPage(),
        const Locale('en'),
        ThemeMode.light,
      ),
      '02_email_auth_dark_ar': (
        () => const EmailAuthPage(),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '03_customer_home_light_en': (
        () => const CustomerHomePage(),
        const Locale('en'),
        ThemeMode.light,
      ),
      '03_customer_home_dark_ar': (
        () => const CustomerHomePage(),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '04_create_booking_light_en': (
        () => const CreateBookingPage(
          initialOffering: _FakeMarketplaceRepository.sampleOffering,
        ),
        const Locale('en'),
        ThemeMode.light,
      ),
      '04_create_booking_dark_ar': (
        () => const CreateBookingPage(
          initialOffering: _FakeMarketplaceRepository.sampleOffering,
        ),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '05_checkout_light_en': (
        () => const CheckoutPage(bookingId: 'bk-8842'),
        const Locale('en'),
        ThemeMode.light,
      ),
      '05_checkout_dark_ar': (
        () => const CheckoutPage(bookingId: 'bk-8842'),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '07_chat_light_en': (
        () => const ChatPage(bookingId: 'bk-8842'),
        const Locale('en'),
        ThemeMode.light,
      ),
      '07_chat_dark_ar': (
        () => const ChatPage(bookingId: 'bk-8842'),
        const Locale('ar'),
        ThemeMode.dark,
      ),
      '10_profile_light_en': (
        () => const ProfilePage(),
        const Locale('en'),
        ThemeMode.light,
      ),
      '10_profile_dark_ar': (
        () => const ProfilePage(),
        const Locale('ar'),
        ThemeMode.dark,
      ),
    };

    for (final entry in goldenTargets.entries) {
      testWidgets('captures golden screenshot ${entry.key}', (tester) async {
        tester.view.physicalSize = const Size(390, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (builder, locale, themeMode) = entry.value;
        final widget = await _buildTestHarness(
          child: builder(),
          locale: locale,
          themeMode: themeMode,
          textScale: 1.0,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/ui_polish/${entry.key}.png'),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 11));
      });
    }
  });

  group(
    'Desktop (1280x800), System Theme, Readability & Unsupported Claims Audit',
    () {
      for (final entry in screens.entries) {
        testWidgets(
          '${entry.key} renders cleanly on desktop (1280x800) with ThemeMode.system',
          (tester) async {
            tester.view.physicalSize = const Size(1280, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            final widget = await _buildTestHarness(
              child: entry.value(),
              locale: const Locale('en'),
              themeMode: ThemeMode.system,
              textScale: 1.0,
            );

            await tester.pumpWidget(widget);
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);

            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 11));
            expect(tester.takeException(), isNull);
          },
        );
      }

      testWidgets(
        'Checkout button stays readable at 360dp 1.35x in EN & AR and omits unsupported verification claims',
        (tester) async {
          tester.view.physicalSize = const Size(360, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final enWidget = await _buildTestHarness(
            child: const CheckoutPage(bookingId: 'bk-8842'),
            locale: const Locale('en'),
            themeMode: ThemeMode.light,
            textScale: 1.35,
          );
          await tester.pumpWidget(enWidget);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final enBtnFinder = find.byKey(const Key('confirm-checkout-btn'));
          expect(enBtnFinder, findsOneWidget);
          expect(tester.getSize(enBtnFinder).width, greaterThanOrEqualTo(300));
          expect(find.text('Confirm Booking (Pay Cash Later)'), findsOneWidget);
          expect(find.text('Scheduled Service'), findsOneWidget);
          expect(find.text('Verified Service'), findsNothing);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          final arWidget = await _buildTestHarness(
            child: const CheckoutPage(bookingId: 'bk-8842'),
            locale: const Locale('ar'),
            themeMode: ThemeMode.dark,
            textScale: 1.35,
          );
          await tester.pumpWidget(arWidget);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final arBtnFinder = find.byKey(const Key('confirm-checkout-btn'));
          expect(arBtnFinder, findsOneWidget);
          expect(tester.getSize(arBtnFinder).width, greaterThanOrEqualTo(300));
          expect(find.text('تأكيد الحجز (دفع نقدي لاحقاً)'), findsOneWidget);
          expect(find.text('خدمة مجدولة'), findsOneWidget);
          expect(find.text('خدمة معتمدة'), findsNothing);
        },
      );
    },
  );
}
