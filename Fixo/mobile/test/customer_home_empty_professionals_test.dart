import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/location/service_area_picker.dart';
import 'package:fixo_mobile/core/location/egypt_places.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/customer_home/presentation/pages/customer_home_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/service_catalog_sheet.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/customer_home_widgets.dart';

/// Deterministic fixture mirroring a catalog-only database: categories,
/// zones and offerings exist, but no approved professionals.
class _CatalogOnlyMarketplaceRepository implements MarketplaceRepository {
  final requestedCategories = <String?>[];
  static const CustomerHomeFeed feed = CustomerHomeFeed(
    zones: [
      CoverageZoneModel(
        id: 'zone-sheikh-zayed',
        slug: 'sheikh-zayed',
        nameEn: 'Sheikh Zayed, Dist. 9',
        nameAr: 'الشيخ زايد، الحي التاسع',
        governorate: 'Giza',
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
    ],
    services: [
      ServiceOfferModel(
        id: 'off-ac-deep-clean',
        categoryId: 'cat-ac-maintenance',
        categorySlug: 'ac-maintenance',
        slug: 'summer-ac-deep-clean-gas-refill',
        titleEn: 'Summer AC Deep Clean & Gas Refill',
        titleAr: 'غسيل التكييف العميق وشحن الفريون الصيفي',
        descriptionEn: 'Complete coil flush.',
        descriptionAr: 'تنظيف شامل للمكثف.',
        baseInspectionEgp: 150,
        serviceFeeEgp: 200,
        flatPriceEgp: 350,
        estimatedDurationMins: 60,
        isSeasonalPromo: true,
        isBundle: false,
      ),
      ServiceOfferModel(
        id: 'off-safety-inspection',
        categoryId: 'cat-electrical-lighting',
        categorySlug: 'electrical-lighting',
        slug: 'home-safety-inspection',
        titleEn: 'Home Safety Inspection',
        titleAr: 'فحص أمان المنزل الشامل',
        descriptionEn: 'Electrical and plumbing audit.',
        descriptionAr: 'فحص شامل للكهرباء والسباكة.',
        baseInspectionEgp: 200,
        serviceFeeEgp: 250,
        flatPriceEgp: 450,
        estimatedDurationMins: 90,
        isSeasonalPromo: false,
        isBundle: true,
      ),
    ],
    professionals: [],
    storageMode: 'POSTGRESQL_PRISMA',
    databaseConnected: true,
  );

  @override
  Future<CustomerHomeFeed> fetchCustomerHomeFeed({
    String? search,
    String? categoryId,
    String? zone,
  }) async => feed;

  @override
  Future<ServiceOfferModel> fetchServiceById(String id) async =>
      feed.services.first;

  @override
  Future<PaginatedServices> getPaginatedServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
  }) async {
    requestedCategories.add(categoryId);
    final items = feed.services
        .where((s) => categoryId == null || s.categoryId == categoryId)
        .toList();
    return PaginatedServices(
      items: items,
      page: page,
      totalPages: 1,
      total: items.length,
    );
  }
}

Widget _app(ProviderContainer container, Locale locale) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: FixoTheme.light(locale: locale),
      home: const CustomerHomePage(),
    ),
  );
}

void main() {
  testWidgets('booking help starts the real catalog and booking journey', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ServiceOfferModel? selected;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CustomerHomePage()),
        GoRoute(
          path: AppRoutes.createBooking,
          builder: (_, state) {
            selected =
                (state.extra as Map<String, dynamic>)['offering']
                    as ServiceOfferModel;
            return const Scaffold(body: Text('Booking destination'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          egyptPlacesProvider.overrideWith((ref) async => EgyptPlaces([])),
          marketplaceRepositoryProvider.overrideWithValue(
            _CatalogOnlyMarketplaceRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: FixoTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final banner = find.byType(ConciergeQuoteBanner);
    await tester.ensureVisible(banner);
    await tester.tap(find.text('How does booking work?'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking-help-start')), findsOneWidget);
    await tester.tap(find.byKey(const Key('booking-help-location')));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceAreaPicker), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How does booking work?'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-help-start')));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceCatalogSheet), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('catalog-service-off-safety-inspection')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Booking destination'), findsOneWidget);
    expect(selected?.id, 'off-safety-inspection');
  });

  for (final width in [360.0, 390.0, 412.0, 1280.0]) {
    testWidgets(
      'electrical category reaches booking with exact offering at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ServiceOfferModel? selected;
        final repository = _CatalogOnlyMarketplaceRepository();
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const CustomerHomePage()),
            GoRoute(
              path: AppRoutes.createBooking,
              builder: (_, state) {
                selected =
                    (state.extra as Map<String, dynamic>)['offering']
                        as ServiceOfferModel;
                return const Scaffold(body: Text('Booking destination'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              marketplaceRepositoryProvider.overrideWithValue(repository),
            ],
            child: MaterialApp.router(
              theme: FixoTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Both entry points must behave identically, including narrow mobile views.
        final category = find.byKey(
          Key(
            width == 390
                ? 'quick-cat-pill-electrical-lighting'
                : 'category-tile-electrical-lighting',
          ),
        );
        await tester.ensureVisible(category);
        await tester.tap(category);
        await tester.pumpAndSettle();
        expect(repository.requestedCategories, ['cat-electrical-lighting']);
        await tester.tap(
          find.byKey(const ValueKey('catalog-service-off-safety-inspection')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Booking destination'), findsOneWidget);
        expect(selected?.id, 'off-safety-inspection');
        expect(selected?.categorySlug, 'electrical-lighting');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'shows neutral English empty-professionals message without unsupported claims',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(
            _CatalogOnlyMarketplaceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.byKey(const Key('empty-professionals-card')), findsOneWidget);
      expect(find.text('No professionals available yet.'), findsOneWidget);
      expect(find.textContaining('background'), findsNothing);
      expect(find.textContaining('onboarding'), findsNothing);
    },
  );

  testWidgets('shows neutral Arabic empty-professionals message', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        marketplaceRepositoryProvider.overrideWithValue(
          _CatalogOnlyMarketplaceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(appLocaleProvider.notifier).setLocale(const Locale('ar'));

    await tester.pumpWidget(_app(container, const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-professionals-card')), findsOneWidget);
    expect(find.text('لا يوجد فنيون متاحون حاليًا.'), findsOneWidget);
    expect(find.text('تمت مراجعة الهوية وسجل الخبرة والتقييمات'), findsNothing);
  });

  testWidgets('every category opens its own bookable services immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        marketplaceRepositoryProvider.overrideWithValue(
          _CatalogOnlyMarketplaceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container, const Locale('en')));
    await tester.pumpAndSettle();

    // Initial state: Both offerings are displayed
    expect(find.text('Summer AC Deep Clean & Gas Refill'), findsOneWidget);
    expect(find.text('Home Safety Inspection'), findsOneWidget);

    // Select "AC Maintenance": Electrical bundle is filtered out
    await tester.tap(find.byKey(const Key('category-tile-ac-maintenance')));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceCatalogSheet), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-service-off-ac-deep-clean')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('catalog-service-off-safety-inspection')),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Summer AC Deep Clean & Gas Refill'), findsOneWidget);
    expect(find.text('Home Safety Inspection'), findsNothing);
    expect(find.byKey(const Key('btn-clear-home-filters')), findsOneWidget);

    // Select "Electrical & Lighting": AC promo is filtered out
    await tester.tap(
      find.byKey(const Key('category-tile-electrical-lighting')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ServiceCatalogSheet), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-service-off-safety-inspection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('catalog-service-off-ac-deep-clean')),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Summer AC Deep Clean & Gas Refill'), findsNothing);
    expect(find.text('Home Safety Inspection'), findsOneWidget);

    // Reset filters: Both offerings are restored
    await tester.tap(find.byKey(const Key('btn-clear-home-filters')));
    await tester.pumpAndSettle();

    expect(find.text('Summer AC Deep Clean & Gas Refill'), findsOneWidget);
    expect(find.text('Home Safety Inspection'), findsOneWidget);
  });
}
