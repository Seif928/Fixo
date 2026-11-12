import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/data/repeat_booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/booking/presentation/pages/orders_page.dart';
import 'package:fixo_mobile/features/favorites/data/favorites_models.dart';
import 'package:fixo_mobile/features/favorites/data/favorites_repository.dart';
import 'package:fixo_mobile/features/favorites/presentation/pages/favorites_page.dart';

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository({
    this.services = const [],
    this.pros = const [],
  }) : super(Dio());

  List<FavoriteServiceItem> services;
  List<FavoriteProfessionalItem> pros;
  final List<String> removedServices = [];
  final List<String> removedPros = [];

  @override
  Future<FavoritesPageResponse<FavoriteServiceItem>> listFavoriteServices({
    int page = 1,
    int limit = 20,
  }) async {
    return FavoritesPageResponse<FavoriteServiceItem>(
      items: List.from(services),
      page: page,
      limit: limit,
      total: services.length,
      totalPages: 1,
    );
  }

  @override
  Future<FavoritesPageResponse<FavoriteProfessionalItem>> listFavoriteProfessionals({
    int page = 1,
    int limit = 20,
  }) async {
    return FavoritesPageResponse<FavoriteProfessionalItem>(
      items: List.from(pros),
      page: page,
      limit: limit,
      total: pros.length,
      totalPages: 1,
    );
  }

  @override
  Future<bool> removeFavoriteService(String offeringId) async {
    removedServices.add(offeringId);
    services.removeWhere((s) => s.offeringId == offeringId);
    return true;
  }

  @override
  Future<bool> removeFavoriteProfessional(String proProfileId) async {
    removedPros.add(proProfileId);
    pros.removeWhere((p) => p.proProfileId == proProfileId);
    return true;
  }

  @override
  Future<FavoriteIdsResponse> getFavoriteIds() async {
    return FavoriteIdsResponse(
      serviceIds: services.map((s) => s.offeringId).toList(),
      proProfileIds: pros.map((p) => p.proProfileId).toList(),
    );
  }
}

class _FakeRepeatBookingRepository extends RepeatBookingRepository {
  _FakeRepeatBookingRepository({
    this.quoteToReturn,
    this.errorToThrow,
  }) : super(Dio());

  final RepeatBookingQuote? quoteToReturn;
  final Exception? errorToThrow;
  final List<String> requestedBookingIds = [];

  @override
  Future<RepeatBookingQuote> getRepeatQuote(String bookingId) async {
    requestedBookingIds.add(bookingId);
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return quoteToReturn!;
  }
}

class _FakeBookingRepository extends BookingRepository {
  _FakeBookingRepository(this.bookings) : super(Dio());

  final List<BookingDetailModel> bookings;

  @override
  Future<List<BookingDetailModel>> getBookings({
    String? tab,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    return bookings;
  }
}

class _FakeLocaleNotifier extends AppLocaleNotifier {
  _FakeLocaleNotifier(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

Widget _wrapWithApp({
  required Widget child,
  required List<Override> overrides,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  Size surfaceSize = const Size(390, 844),
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith(() => _FakeLocaleNotifier(locale)),
      ...overrides,
    ],
    child: MaterialApp(
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
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixtureActiveService = FavoriteServiceItem(
    id: 'fav-serv-1',
    offeringId: 'offering-1',
    createdAt: DateTime.now(),
    isAvailable: true,
    titleEn: 'AC Split Cleaning',
    titleAr: 'تنظيف تكييف سبليت',
    descriptionEn: 'Full chemical coil wash',
    descriptionAr: 'غسيل كيميائي شامل للوحدة',
    baseInspectionEgp: 150,
    serviceFeeEgp: 150,
    flatPriceEgp: 300,
    estimatedDurationMins: 60,
    categorySlug: 'ac',
    categoryNameEn: 'AC Services',
    categoryNameAr: 'خدمات التكييف',
    categoryIcon: 'ac_unit',
    isActive: true,
  );

  final fixtureUnavailableService = FavoriteServiceItem(
    id: 'fav-serv-2',
    offeringId: 'offering-2',
    createdAt: DateTime.now(),
    isAvailable: false,
    titleEn: 'Discontinued Plumbing',
    titleAr: 'خدمة سباكة موقوفة',
    descriptionEn: 'Old service offering',
    descriptionAr: 'خدمة قديمة معطلة',
    baseInspectionEgp: 100,
    serviceFeeEgp: 50,
    flatPriceEgp: 150,
    estimatedDurationMins: 45,
    categorySlug: 'plumbing',
    categoryNameEn: 'Plumbing',
    categoryNameAr: 'سباكة',
    categoryIcon: 'plumbing',
    isActive: false,
  );

  final fixtureActivePro = FavoriteProfessionalItem(
    id: 'fav-pro-1',
    proProfileId: 'pro-1',
    createdAt: DateTime.now(),
    isAvailable: true,
    verificationStatus: 'APPROVED',
    fullNameEn: 'Ahmed Hassan',
    fullNameAr: 'أحمد حسن',
    specialtyEn: 'Master Electrician',
    specialtyAr: 'فني كهرباء معتمد',
    ratingAvg: 4.9,
    reviewsCount: 28,
    completedJobsCount: 104,
    isOnline: true,
    categorySlug: 'electrician',
    categoryNameEn: 'Electricity',
    categoryNameAr: 'كهرباء',
  );

  final fixtureUnavailablePro = FavoriteProfessionalItem(
    id: 'fav-pro-2',
    proProfileId: 'pro-2',
    createdAt: DateTime.now(),
    isAvailable: false,
    verificationStatus: 'SUSPENDED',
    fullNameEn: 'Mohamed Ali',
    fullNameAr: 'محمد علي',
    specialtyEn: 'Carpenter',
    specialtyAr: 'نجار',
    ratingAvg: 4.2,
    reviewsCount: 8,
    completedJobsCount: 15,
    isOnline: false,
    categorySlug: 'carpentry',
    categoryNameEn: 'Carpentry',
    categoryNameAr: 'نجارة',
  );

  group('Milestone B: Favorites Screen & Interactions', () {
    testWidgets('displays empty state when no services or pros are favorited',
        (tester) async {
      final fakeRepo = _FakeFavoritesRepository();

      await tester.pumpWidget(
        _wrapWithApp(
          child: const FavoritesPage(),
          overrides: [
            favoritesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites-empty-services')), findsOneWidget);
      expect(find.text('No favorite services yet'), findsOneWidget);

      // Switch to Pros tab
      await tester.tap(find.byKey(const Key('favorites-tab-pros')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorites-empty-pros')), findsOneWidget);
      expect(find.text('No favorite technicians yet'), findsOneWidget);
    });

    testWidgets('renders active and unavailable services with truthful badges',
        (tester) async {
      final fakeRepo = _FakeFavoritesRepository(
        services: [fixtureActiveService, fixtureUnavailableService],
        pros: [fixtureActivePro, fixtureUnavailablePro],
      );

      await tester.pumpWidget(
        _wrapWithApp(
          child: const FavoritesPage(),
          overrides: [
            favoritesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Active service card
      expect(find.text('AC Split Cleaning'), findsOneWidget);
      expect(find.text('300 EGP'), findsOneWidget);
      expect(
        find.byKey(Key('book-favorite-service-${fixtureActiveService.id}')),
        findsOneWidget,
      );

      // Unavailable service card
      expect(find.text('Discontinued Plumbing'), findsOneWidget);
      expect(find.text('Currently unavailable'), findsOneWidget);
      expect(find.text('Not bookable'), findsOneWidget);

      // Remove unavailable service
      await tester.tap(
        find.byKey(Key('remove-favorite-service-${fixtureUnavailableService.id}')),
      );
      await tester.pumpAndSettle();

      expect(fakeRepo.removedServices, contains('offering-2'));
      expect(find.text('Discontinued Plumbing'), findsNothing);
    });

    testWidgets('renders pro cards and switches between tabs', (tester) async {
      final fakeRepo = _FakeFavoritesRepository(
        services: [fixtureActiveService],
        pros: [fixtureActivePro, fixtureUnavailablePro],
      );

      await tester.pumpWidget(
        _wrapWithApp(
          child: const FavoritesPage(),
          overrides: [
            favoritesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pros tab
      await tester.tap(find.byKey(const Key('favorites-tab-pros')));
      await tester.pumpAndSettle();

      expect(find.text('Ahmed Hassan'), findsOneWidget);
      expect(find.text('Master Electrician'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);

      // Suspended pro shows truthful unavailable banner
      expect(find.text('Mohamed Ali'), findsOneWidget);
      expect(find.text('Currently unavailable'), findsOneWidget);

      // Remove pro
      await tester.tap(
        find.byKey(Key('remove-favorite-pro-${fixtureUnavailablePro.id}')),
      );
      await tester.pumpAndSettle();

      expect(fakeRepo.removedPros, contains('pro-2'));
      expect(find.text('Mohamed Ali'), findsNothing);
    });

    testWidgets('responsive layout at 360/390/412dp with 1.35x text, RTL, and dark theme',
        (tester) async {
      final fakeRepo = _FakeFavoritesRepository(
        services: [fixtureActiveService, fixtureUnavailableService],
        pros: [fixtureActivePro],
      );

      for (final width in [360.0, 390.0, 412.0]) {
        await tester.pumpWidget(
          _wrapWithApp(
            surfaceSize: Size(width, 844),
            textScale: 1.35,
            locale: const Locale('ar'),
            themeMode: ThemeMode.dark,
            child: const FavoritesPage(),
            overrides: [
              favoritesRepositoryProvider.overrideWithValue(fakeRepo),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Check Arabic titles and ensure no RenderFlex overflows
        expect(find.text('المفضلة'), findsOneWidget);
        expect(find.text('تنظيف تكييف سبليت'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Milestone C: Repeat Booking Flow', () {
    final completedBooking = BookingDetailModel(
      id: 'book-completed-1',
      orderCode: 'FX-COMP1',
      status: 'COMPLETED',
      customerId: 'user-1',
      offeringId: 'offering-1',
      addressId: 'addr-1',
      createdAt: '2026-04-01T10:00:00Z',
      offering: {
        'id': 'offering-1',
        'slug': 'ac-split-clean',
        'titleEn': 'AC Split Cleaning',
        'titleAr': 'تنظيف تكييف سبليت',
        'baseInspectionEgp': 150,
        'serviceFeeEgp': 150,
        'flatPriceEgp': 300,
      },
      scheduledDate: '2026-04-10T10:00:00Z',
      timeWindow: 'MORNING_09_12',
      pricing: const BookingPricingModel(
        baseInspectionEgp: 120,
        serviceFeeEgp: 120,
        transportFeeEgp: 0,
        totalEgp: 240,
      ),
    );

    testWidgets('orders page shows "Book again" button on completed order',
        (tester) async {
      final fakeBookingRepo = _FakeBookingRepository([completedBooking]);
      final fakeRepeatRepo = _FakeRepeatBookingRepository(
        quoteToReturn: const RepeatBookingQuote(
          originalBookingId: 'book-completed-1',
          orderCode: 'FX-COMP1',
          offeringId: 'offering-1',
          offeringSlug: 'ac-split-clean',
          titleEn: 'AC Split Cleaning',
          titleAr: 'تنظيف تكييف سبليت',
          descriptionEn: 'Full chemical coil wash',
          descriptionAr: 'غسيل كيميائي شامل للوحدة',
          baseInspectionEgp: 180, // Current fresh price
          serviceFeeEgp: 120,     // Current fresh price
          flatPriceEgp: 300,
          estimatedDurationMins: 60,
          categorySlug: 'ac',
          categoryNameEn: 'AC Services',
          categoryNameAr: 'خدمات التكييف',
          categoryIcon: 'ac_unit',
          isOfferingActive: true,
        ),
      );

      final router = GoRouter(
        initialLocation: AppRoutes.myOrders,
        routes: [
          GoRoute(
            path: AppRoutes.myOrders,
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.createBooking,
            builder: (context, state) => Text(
              'CreateBookingDestination:${(state.extra as Map)['offering'].titleEn}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(fakeBookingRepo),
            repeatBookingRepositoryProvider.overrideWithValue(fakeRepeatRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: FixoTheme.light(locale: const Locale('en')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap completed tab to reveal completed booking
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<String>),
          matching: find.text('Completed'),
        ),
      );
      await tester.pumpAndSettle();

      final repeatButton = find.byKey(const Key('booking-repeat-book-completed-1'));
      expect(repeatButton, findsOneWidget);

      // Tap "Book again"
      await tester.tap(repeatButton);
      await tester.pumpAndSettle();

      // Verified repeat repo was queried
      expect(fakeRepeatRepo.requestedBookingIds, contains('book-completed-1'));
      // Navigated to createBooking with offering passed in extra
      expect(find.text('CreateBookingDestination:AC Split Cleaning'), findsOneWidget);
    });

    testWidgets('shows explanation dialog and does not navigate when service is deactivated',
        (tester) async {
      final fakeBookingRepo = _FakeBookingRepository([completedBooking]);
      final fakeRepeatRepo = _FakeRepeatBookingRepository(
        errorToThrow: const RepeatBookingException(
          code: 'SERVICE_DEACTIVATED',
          messageEn:
              'This service is currently unavailable or deactivated and cannot be rebooked.',
          messageAr: 'هذه الخدمة غير متاحة حالياً أو معطلة ولا يمكن إعادة حجزها.',
        ),
      );

      final router = GoRouter(
        initialLocation: AppRoutes.myOrders,
        routes: [
          GoRoute(
            path: AppRoutes.myOrders,
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.createBooking,
            builder: (context, state) => const Text('ShouldNotNavigateHere'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(fakeBookingRepo),
            repeatBookingRepositoryProvider.overrideWithValue(fakeRepeatRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: FixoTheme.light(locale: const Locale('en')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<String>),
          matching: find.text('Completed'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('booking-repeat-book-completed-1')));
      await tester.pumpAndSettle();

      // Shows explanation dialog
      expect(find.text('Service Unavailable'), findsOneWidget);
      expect(
        find.text(
          'This service is currently unavailable or deactivated and cannot be rebooked.',
        ),
        findsOneWidget,
      );
      // Did NOT navigate to createBooking
      expect(find.text('ShouldNotNavigateHere'), findsNothing);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Service Unavailable'), findsNothing);
    });
  });
}
