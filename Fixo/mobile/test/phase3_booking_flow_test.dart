import 'package:dio/dio.dart';
import 'package:fixo_mobile/app/router/app_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/booking/presentation/pages/create_booking_page.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBookingRepository implements BookingRepository {
  bool shouldFailAddresses = false;
  bool shouldFailZones = false;
  bool shouldFailCreateAddress = false;
  bool shouldFailCreateBooking = false;
  String createBookingErrorMessage = 'Service category is currently inactive';
  String createAddressErrorMessage = 'Coverage zone is invalid or inactive';
  List<CustomerAddressModel> fakeAddresses = [];
  List<CoverageZoneModel> fakeZones = [
    const CoverageZoneModel(
      id: 'zone-new-cairo',
      slug: 'new-cairo',
      nameEn: 'New Cairo, 5th Settlement',
      nameAr: 'القاهرة الجديدة، التجمع الخامس',
      governorate: 'Cairo',
    ),
    const CoverageZoneModel(
      id: 'zone-sheikh-zayed',
      slug: 'sheikh-zayed',
      nameEn: 'Sheikh Zayed City',
      nameAr: 'مدينة الشيخ زايد',
      governorate: 'Giza',
    ),
  ];
  CreateBookingRequest? lastCreatedRequest;
  CreateAddressRequest? lastCreatedAddressRequest;

  @override
  Future<List<CustomerAddressModel>> getCustomerAddresses() async {
    if (shouldFailAddresses) {
      throw Exception('Failed to load addresses from server');
    }
    return fakeAddresses;
  }

  @override
  Future<List<CoverageZoneModel>> getCoverageZones() async {
    if (shouldFailZones) {
      throw Exception('Failed to load coverage zones');
    }
    return fakeZones;
  }

  @override
  Future<CustomerAddressModel> createAddress(
      CreateAddressRequest request) async {
    lastCreatedAddressRequest = request;
    if (shouldFailCreateAddress) {
      throw DioException(
        requestOptions: RequestOptions(path: '/users/me/addresses'),
        response: Response(
          requestOptions: RequestOptions(path: '/users/me/addresses'),
          statusCode: 400,
          data: {'message': createAddressErrorMessage},
        ),
      );
    }
    final created = CustomerAddressModel(
      id: 'addr-created-99',
      userId: 'cust-101',
      zoneId: request.zoneId,
      label: request.label,
      buildingLine: request.buildingLine,
      districtLine: request.districtLine,
      gateNotes: request.gateNotes,
      isDefault: request.isDefault,
    );
    fakeAddresses = [...fakeAddresses, created];
    return created;
  }

  @override
  Future<BookingDetailModel> createBooking(CreateBookingRequest request) async {
    lastCreatedRequest = request;
    if (shouldFailCreateBooking) {
      throw DioException(
        requestOptions: RequestOptions(path: '/bookings'),
        response: Response(
          requestOptions: RequestOptions(path: '/bookings'),
          statusCode: 400,
          data: {'message': createBookingErrorMessage},
        ),
      );
    }
    return BookingDetailModel(
      id: 'bk-new-8842',
      orderCode: 'FX-8842',
      customerId: 'cust-101',
      proProfileId: request.preferredProId,
      offeringId: request.offeringId,
      addressId: request.addressId,
      status: 'DRAFT',
      scheduledDate: request.scheduledDate,
      timeWindow: request.timeWindow,
      issueDescription: request.issueDescription,
      issuePhotoUrls: request.issuePhotoUrls,
      pricing: const BookingPricingModel(
        baseInspectionEgp: 150,
        serviceFeeEgp: 250,
        transportFeeEgp: 0,
        totalEgp: 400,
        platformFeeEgp: 40,
        netArtisanEgp: 360,
      ),
      arrivalPinCode: '5841',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<List<BookingDetailModel>> getBookings({
    String? tab,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    return const [];
  }

  @override
  Future<BookingDetailModel> getBookingById(String bookingId) async {
    return BookingDetailModel(
      id: bookingId,
      orderCode: 'FX-8842',
      customerId: 'cust-101',
      offeringId: 'off-ac-clean',
      addressId: 'addr-01',
      status: 'DRAFT',
      scheduledDate: '2026-11-05',
      timeWindow: 'AFTERNOON_13_16',
      pricing: const BookingPricingModel(
        baseInspectionEgp: 150,
        serviceFeeEgp: 250,
        transportFeeEgp: 0,
        totalEgp: 400,
      ),
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<OtpChallengeResult> requestOtp({required String phone}) async {
    return OtpChallengeResult(
      challengeId: 'ch-test',
      phone: phone,
      resendAvailableInSec: 42,
      expiresInSec: 300,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? challengeId,
  }) async {
    return AuthSession(
      accessToken: 'jwt-token',
      refreshToken: 'refresh-token',
      user: AuthUser(
        id: 'cust-101',
        phone: phone,
        fullName: 'Ahmed Zaki',
        role: 'CUSTOMER',
      ),
    );
  }

  @override
  Future<AuthSession> refreshSession({required String refreshToken}) async {
    return const AuthSession(
      accessToken: 'jwt-token-refreshed',
      refreshToken: 'refresh-token-refreshed',
      user: AuthUser(
        id: 'cust-101',
        phone: '+201011110001',
        fullName: 'Ahmed Zaki',
        role: 'CUSTOMER',
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<AuthUser> fetchCurrentUser() async {
    return const AuthUser(
      id: 'cust-101',
      phone: '+201011110001',
      fullName: 'Ahmed Zaki',
      role: 'CUSTOMER',
    );
  }
}

class FakeMarketplaceRepository implements MarketplaceRepository {
  static CustomerHomeFeed sampleFeed() {
    return const CustomerHomeFeed(
      zones: [
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
          id: 'cat-ac',
          slug: 'ac-maintenance',
          nameEn: 'AC Maintenance',
          nameAr: 'صيانة تكييف',
          subtitleEn: 'Inverter & split',
          subtitleAr: 'سبليت وإنفرتر',
          iconName: 'mode_fan',
          startingPriceEgp: 450,
          sortOrder: 1,
        ),
      ],
      services: [
        ServiceOfferModel(
          id: 'off-ac-clean',
          categoryId: 'cat-ac',
          categorySlug: 'ac-maintenance',
          slug: 'summer-ac-deep-clean-gas-refill',
          titleEn: 'Summer AC Deep Clean & Gas Refill',
          titleAr: 'غسيل تكييف صيفي عميق وشحن غاز',
          descriptionEn: 'Full coil sanitization and pressure test.',
          descriptionAr: 'تعقيم كامل للوحدة واختبار الضغط.',
          baseInspectionEgp: 150,
          serviceFeeEgp: 200,
          flatPriceEgp: 350,
          estimatedDurationMins: 60,
          isSeasonalPromo: true,
          isBundle: false,
        ),
      ],
      professionals: [
        ProfessionalCardModel(
          id: 'pro-hassan-01',
          fullNameEn: 'Hassan El-Sayed',
          fullNameAr: 'حسن السيد',
          primaryCategoryId: 'cat-ac',
          primaryCategorySlug: 'ac-maintenance',
          primaryZoneSlug: 'new-cairo',
          specialtyEn: 'AC Specialist',
          specialtyAr: 'فني تكييف معتمد',
          zonesLabelEn: 'New Cairo & Tagamoa',
          zonesLabelAr: 'القاهرة الجديدة والتجمع',
          ratingAvg: 4.95,
          reviewsCount: 240,
          estimatedPriceEgp: 350,
          badgeEn: 'Fast Responder',
          badgeAr: 'سريع الاستجابة',
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
    return sampleFeed();
  }

  @override
  Future<ServiceOfferModel> fetchServiceById(String id) async {
    return sampleFeed().services.first;
  }
}

class FakeLocaleNotifier extends AppLocaleNotifier {
  FakeLocaleNotifier(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

class FakeThemeModeNotifier extends AppThemeModeNotifier {
  FakeThemeModeNotifier(this._initial);
  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBookingRepository fakeBookingRepo;
  late FakeAuthRepository fakeAuthRepo;
  late FakeMarketplaceRepository fakeMarketplaceRepo;
  late VaultTokenStorage tokenStorage;

  const sampleAddress = CustomerAddressModel(
    id: 'addr-palm-hills-14',
    userId: 'cust-101',
    zoneId: 'zone-new-cairo',
    label: 'Palm Hills Villa 14',
    buildingLine: 'Apartment 4B, Building 14',
    districtLine: 'Palm Hills, 6th of October / Sheikh Zayed, Giza',
    gateNotes: 'Private Gate 3',
    isDefault: true,
  );

  const sampleOffering = ServiceOfferModel(
    id: 'off-ac-clean',
    categoryId: 'cat-ac',
    categorySlug: 'ac-maintenance',
    slug: 'summer-ac-deep-clean-gas-refill',
    titleEn: 'Split AC Deep Cleaning & Chemical Wash',
    titleAr: 'غسيل تكييف سبليت عميق ومواد كيميائية',
    descriptionEn: 'Complete coil flush, antibacterial mist, and pressure test.',
    descriptionAr:
        'تنظيف شامل للوحدة الداخلية وتعقيم الفلاتر واختبار ضغط الغاز.',
    baseInspectionEgp: 150,
    serviceFeeEgp: 250,
    flatPriceEgp: 400,
    estimatedDurationMins: 60,
    isSeasonalPromo: true,
    isBundle: false,
    badgeEn: 'SEASONAL PEAK',
    badgeAr: 'الأكثر طلباً',
  );

  const samplePro = ProfessionalCardModel(
    id: 'pro-hassan-01',
    fullNameEn: 'Eng. Hassan El-Sayed',
    fullNameAr: 'م. حسن السيد',
    primaryCategoryId: 'cat-ac',
    primaryCategorySlug: 'ac-maintenance',
    primaryZoneSlug: 'new-cairo',
    specialtyEn: 'HVAC Specialist',
    specialtyAr: 'أخصائي تكييف',
    zonesLabelEn: 'New Cairo & Tagamoa',
    zonesLabelAr: 'القاهرة الجديدة والتجمع',
    ratingAvg: 4.95,
    reviewsCount: 142,
    estimatedPriceEgp: 350,
    badgeEn: 'Fast Responder',
    badgeAr: 'سريع الاستجابة',
    badgeVariant: 'fast_responder',
    isOnline: true,
  );

  setUp(() {
    fakeBookingRepo = FakeBookingRepository();
    fakeAuthRepo = FakeAuthRepository();
    fakeMarketplaceRepo = FakeMarketplaceRepository();
    tokenStorage = VaultTokenStorage();

    fakeBookingRepo.fakeAddresses = [sampleAddress];
  });

  Widget buildTestableApp({
    Widget? home,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(fakeBookingRepo),
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        marketplaceRepositoryProvider.overrideWithValue(fakeMarketplaceRepo),
        secureTokenStorageProvider.overrideWithValue(tokenStorage),
        appLocaleProvider.overrideWith(() => FakeLocaleNotifier(locale)),
        appThemeModeProvider
            .overrideWith(() => FakeThemeModeNotifier(themeMode)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FixoTheme.light(locale: locale),
        darkTheme: FixoTheme.dark(locale: locale),
        themeMode: themeMode,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home ??
            const CreateBookingPage(
              initialOffering: sampleOffering,
              initialPreferredPro: samplePro,
            ),
      ),
    );
  }

  group(
      'Screen 04: Create Booking Page — Approved Stitch Design & Elements',
      () {
    testWidgets(
        'renders all approved Stitch Screen 04 sections and truthful EGP fare breakdown',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Create Booking'), findsOneWidget);

      // 2. Step Progress Meta
      expect(find.text('Schedule Service'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);

      // 3. Selected Service Card
      expect(
          find.text('Split AC Deep Cleaning & Chemical Wash'), findsOneWidget);
      expect(find.text('Lead Pro: Eng. Hassan El-Sayed'), findsOneWidget);
      expect(find.text('4.95'), findsOneWidget);
      expect(find.text('Verified FIXO Master Pro'), findsOneWidget);
      expect(find.text('FIXO Assured'), findsOneWidget);

      // 4. Service Location Card
      expect(find.text('Service Location'), findsOneWidget);
      expect(find.text('Palm Hills Villa 14'), findsOneWidget);
      expect(find.text('Apartment 4B, Building 14'), findsOneWidget);

      // 5. Select Date Card
      expect(find.text('Select Date'), findsOneWidget);

      // 6. Preferred Time Window
      expect(find.text('Preferred Time Window'), findsOneWidget);
      expect(find.text('Morning Window'), findsOneWidget);
      expect(find.text('Afternoon Window'), findsOneWidget);
      expect(find.text('Evening Window'), findsOneWidget);

      // 7. Issue Description
      expect(find.text('Issue Description'), findsOneWidget);
      expect(find.byKey(const Key('booking-issue-description-input')),
          findsOneWidget);

      // 8. Fare Breakdown
      expect(find.text('Fare Breakdown'), findsOneWidget);
      expect(find.text('Service Base Inspection'), findsOneWidget);
      expect(find.text('150 EGP'), findsOneWidget);
      expect(find.text('Service & Labor Fee'), findsOneWidget);
      expect(find.text('250 EGP'), findsOneWidget);
      expect(find.text('Cairo/Giza Transport Fee'), findsOneWidget);
      expect(find.text('WAIVED'), findsOneWidget);
      expect(find.text('0 EGP'), findsOneWidget);
      expect(find.text('Estimated Total'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);

      // 9. Sticky Bottom Action Bar with Truthful Copy
      expect(find.text('Confirm Booking Draft'), findsOneWidget);
      expect(find.text('400 EGP'), findsOneWidget);
      expect(
          find.byKey(const Key('confirm-booking-draft-btn')), findsOneWidget);
    });

    testWidgets('allows interactive date and time window selection',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap Evening Window
      await tester.tap(find.text('Evening Window'));
      await tester.pumpAndSettle();

      // Enter issue description
      await tester.enterText(
        find.byKey(const Key('booking-issue-description-input')),
        'Water dripping from right flap',
      );
      await tester.pumpAndSettle();

      expect(find.text('Water dripping from right flap'), findsOneWidget);
    });
  });

  group('Screen 04: Neutral Pro & Missing Offering Safeguards', () {
    testWidgets(
        'displays neutral service info and auto-assignment notice when no preferred pro is specified',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableApp(
          home: const CreateBookingPage(
            initialOffering: sampleOffering,
            initialPreferredPro: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must show neutral professional state
      expect(find.text('No professional assigned yet'), findsOneWidget);
      expect(
        find.text('Professional: Auto-assigned upon booking confirmation'),
        findsOneWidget,
      );
      expect(find.text('FIXO Certified Home Service'), findsOneWidget);

      // Must NOT display fabricated professional name or rating
      expect(find.text('Eng. Hassan El-Sayed'), findsNothing);
      expect(find.text('Lead Pro: Eng. Hassan El-Sayed'), findsNothing);
      expect(find.text('4.95'), findsNothing);
      expect(find.text('(142 jobs)'), findsNothing);
    });

    testWidgets(
        'renders safe missing offering state with return button when initialOffering is null',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableApp(
          home: const CreateBookingPage(
            initialOffering: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must show safe missing offering state
      expect(find.text('No service selected'), findsOneWidget);
      expect(
        find.text(
            'Please select a service offering from the home catalog to create a booking.'),
        findsOneWidget,
      );
      expect(
          find.byKey(const Key('missing-offering-home-btn')), findsOneWidget);

      // Must NOT render booking draft action button
      expect(find.byKey(const Key('confirm-booking-draft-btn')), findsNothing);
    });
  });

  group('Screen 04: Address Ownership & Bottom Sheet Integration (Phase 3.3B)',
      () {
    testWidgets(
        'disables confirm button when customer has no saved address and opens address creation sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Empty addresses configuration
      fakeBookingRepo.fakeAddresses = const [];

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Verify empty address state is presented
      expect(find.text('No saved address found'), findsOneWidget);
      expect(find.text('A delivery address is required to book a service.'),
          findsOneWidget);
      expect(find.text('Palm Hills Villa 14'), findsNothing);

      // Confirm Booking Draft button must be disabled
      final confirmBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('confirm-booking-draft-btn')),
      );
      expect(confirmBtn.onPressed, isNull);

      // Tap Add New Address button
      await tester.tap(find.byKey(const Key('add-first-address-btn')));
      await tester.pumpAndSettle();

      // Bottom sheet is displayed
      expect(find.text('Add New Address'), findsWidgets);
      expect(find.byKey(const Key('save-address-btn')), findsOneWidget);
    });

    testWidgets(
        'creates new address from bottom sheet, persists via API, and selects it for booking',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeBookingRepo.fakeAddresses = const [];

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byKey(const Key('add-first-address-btn')));
      await tester.pumpAndSettle();

      // Enter address fields
      await tester.enterText(
        find.byKey(const Key('address-label-input')),
        'Work Office',
      );
      await tester.enterText(
        find.byKey(const Key('address-building-input')),
        'Building 88, Floor 4',
      );
      await tester.enterText(
        find.byKey(const Key('address-district-input')),
        '5th Settlement, New Cairo',
      );
      await tester.enterText(
        find.byKey(const Key('address-gate-notes-input')),
        'North Gate Security',
      );
      await tester.pumpAndSettle();

      // Tap Save Address
      await tester.tap(find.byKey(const Key('save-address-btn')));
      await tester.pumpAndSettle();

      // Check request to backend
      expect(fakeBookingRepo.lastCreatedAddressRequest, isNotNull);
      final addrReq = fakeBookingRepo.lastCreatedAddressRequest!;
      expect(addrReq.label, 'Work Office');
      expect(addrReq.buildingLine, 'Building 88, Floor 4');
      expect(addrReq.districtLine, '5th Settlement, New Cairo');
      expect(addrReq.gateNotes, 'North Gate Security');
      expect(addrReq.zoneId, 'zone-new-cairo');

      // Verify newly created address is selected on the main screen
      expect(find.text('Work Office'), findsOneWidget);
      expect(find.text('Building 88, Floor 4'), findsOneWidget);
      expect(find.text('5th Settlement, New Cairo'), findsOneWidget);

      // Confirm button is now enabled
      final confirmBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('confirm-booking-draft-btn')),
      );
      expect(confirmBtn.onPressed, isNotNull);
    });

    testWidgets('displays server error banner when address creation fails',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeBookingRepo.fakeAddresses = const [];
      fakeBookingRepo.shouldFailCreateAddress = true;
      fakeBookingRepo.createAddressErrorMessage =
          'Coverage zone is invalid or inactive';

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byKey(const Key('add-first-address-btn')));
      await tester.pumpAndSettle();

      // Fill in required fields
      await tester.enterText(
        find.byKey(const Key('address-building-input')),
        'Building 10',
      );
      await tester.enterText(
        find.byKey(const Key('address-district-input')),
        'Zayed',
      );
      await tester.pumpAndSettle();

      // Tap Save Address
      await tester.tap(find.byKey(const Key('save-address-btn')));
      await tester.pumpAndSettle();

      // Error banner is displayed in bottom sheet
      expect(find.byKey(const Key('address-error-banner')), findsOneWidget);
      expect(
        find.text('Coverage zone is invalid or inactive'),
        findsOneWidget,
      );
    });
  });

  group('Screen 04: Backend Persistence & Invariants', () {
    testWidgets(
        'submits booking draft to POST /api/v1/bookings and confirms persistence',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Enter diagnostic description
      await tester.enterText(
        find.byKey(const Key('booking-issue-description-input')),
        'Living room unit is leaking and making buzzing noise.',
      );
      await tester.pumpAndSettle();

      // Tap Confirm Booking Draft
      await tester.tap(find.byKey(const Key('confirm-booking-draft-btn')));
      await tester.pumpAndSettle();

      // Verify request sent to fake backend repository
      expect(fakeBookingRepo.lastCreatedRequest, isNotNull);
      final req = fakeBookingRepo.lastCreatedRequest!;
      expect(req.offeringId, 'off-ac-clean');
      expect(req.addressId, 'addr-palm-hills-14');
      expect(req.preferredProId, 'pro-hassan-01');
      expect(req.issueDescription,
          'Living room unit is leaking and making buzzing noise.');
      expect(req.timeWindow, 'AFTERNOON_13_16');

      // Verify success notification confirming DRAFT persistence
      expect(
        find.text('Booking #FX-8842 created in DRAFT status.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'displays server error banner when backend rejects booking creation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeBookingRepo.shouldFailCreateBooking = true;
      fakeBookingRepo.createBookingErrorMessage =
          'Scheduled date cannot be in the past.';

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-booking-draft-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('booking-error-banner')), findsOneWidget);
      expect(
        find.text('Scheduled date cannot be in the past.'),
        findsOneWidget,
      );
    });
  });

  group('Customer Home -> Create Booking Navigation Integration', () {
    testWidgets(
        'tapping Book Now on Seasonal Promo navigates to CreateBookingPage',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = createAppRouter(
        initialLocation: AppRoutes.customerHome,
        isAuthenticated: () => true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(fakeBookingRepo),
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            marketplaceRepositoryProvider.overrideWithValue(fakeMarketplaceRepo),
            secureTokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: FixoTheme.light(locale: const Locale('en')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Seasonal Promo card "Book Now" button
      final bookNowFinder = find.text('Book Now');
      expect(bookNowFinder, findsOneWidget);

      await tester.tap(bookNowFinder);
      await tester.pumpAndSettle();

      // Expect navigation to CreateBookingPage
      expect(find.text('Create Booking'), findsOneWidget);
      expect(find.text('Summer AC Deep Clean & Gas Refill'), findsOneWidget);
      expect(find.text('350 EGP'), findsOneWidget);
    });
  });

  group('Screen 04: Viewport, RTL & Dark Mode Adaptability', () {
    testWidgets(
        'renders cleanly without overflow at 360dp, 390dp, and 412dp viewports',
        (tester) async {
      for (final width in [360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width, 1800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(buildTestableApp());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Failed on viewport width $width');
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('supports Arabic RTL and Dark Mode seamlessly', (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableApp(
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إنشاء حجز'), findsOneWidget);
      expect(find.text('تحديد موعد الخدمة'), findsOneWidget);
      expect(find.text('الخطوة ١ من ٢'), findsOneWidget);
      expect(find.text('موقع تقديم الخدمة'), findsOneWidget);
      expect(find.text('الفترة الزمنية المفضلة'), findsOneWidget);
      expect(find.text('تفاصيل السعر'), findsOneWidget);
      expect(find.text('تأكيد مسودة الحجز'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
