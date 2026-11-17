import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixo_mobile/core/location/egypt_places.dart';
import 'package:fixo_mobile/core/location/device_location_service.dart';
import 'package:fixo_mobile/core/location/service_area_picker.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/customer_home/presentation/controllers/customer_home_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EgyptPlaces catalog;
  setUpAll(() async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/locations/egypt.json'),
    );
    catalog = EgyptPlaces(
      (raw['places'] as List)
          .map((p) => EgyptPlace.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
    );
  });
  test('Home never invents a selected location or falls back to a zone', () {
    const state = CustomerHomeState();
    expect(state.selectedZoneSlug, isNull);
    expect(state.activeZone, isNull);
  });
  test(
    'bundled Egypt catalog has valid parents, bilingual names and bounded search',
    () {
      expect(catalog.governorates.length, 27);
      expect(catalog.byId.length, 6108);
      for (final place in catalog.byId.values) {
        expect(place.nameAr, isNotEmpty);
        expect(place.nameEn, isNotEmpty);
        expect(catalog.byId[place.governorateId], isNotNull);
        if (place.parent != null) expect(catalog.byId[place.parent], isNotNull);
      }
      expect(catalog.search('EG21', '').length, lessThanOrEqualTo(50));
      expect(
        normalizePlaceName('الإسكَنْدَرِيَّة'),
        normalizePlaceName('الاسكندرية'),
      );
    },
  );
  test(
    'newer area results win and account switching clears the prior selection',
    () async {
      final repo = _DelayedMarketplace();
      final container = ProviderContainer(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(repo),
          authControllerProvider.overrideWith(_TestAuth.new),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        customerHomeControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      repo.requests[0].complete(_feed('initial'));
      await Future<void>.delayed(Duration.zero);
      final first = controller.selectArea(
        const SelectedServiceArea(
          zoneSlug: 'cairo',
          governorateEn: 'Cairo',
          governorateAr: 'القاهرة',
        ),
      );
      final second = controller.selectArea(
        const SelectedServiceArea(
          zoneSlug: 'aswan',
          governorateEn: 'Aswan',
          governorateAr: 'أسوان',
        ),
      );
      repo.requests[2].complete(_feed('aswan'));
      await second;
      repo.requests[1].complete(_feed('cairo'));
      await first;
      expect(
        container.read(customerHomeControllerProvider).feed!.storageMode,
        'aswan',
      );
      expect(repo.zones, ['', 'cairo', 'aswan']);
      (container.read(authControllerProvider.notifier) as _TestAuth).switchUser(
        'other',
      );
      expect(
        container.read(customerHomeControllerProvider).selectedArea,
        isNull,
      );
      await Future<void>.delayed(Duration.zero);
      repo.requests.last.complete(_feed('other'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(customerHomeControllerProvider).feed!.storageMode,
        'other',
      );
    },
  );
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('manual area survives GPS denial at ${width}dp, RTL, 1.35x', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            egyptPlacesProvider.overrideWith((ref) async => catalog),
            areaLocatorProvider.overrideWithValue(() async {
              calls++;
              throw const LocationChoiceException('denied');
            }),
          ],
          child: MaterialApp(
            theme: FixoTheme.dark(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 850),
                textScaler: const TextScaler.linear(1.35),
              ),
              child: const Scaffold(body: ServiceAreaPicker(isArabic: true)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.byKey(const Key('detect-service-area')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.textContaining('إذن الموقع'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('place-search')), 'الجيزة');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('place-EG21')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('place-manual')),
        'قرية جديدة',
      );
      await tester.pumpAndSettle();
      expect(find.text('قرية جديدة، الجيزة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

CustomerHomeFeed _feed(String tag) => CustomerHomeFeed(
  zones: const [],
  categories: const [],
  services: const [],
  professionals: const [],
  storageMode: tag,
  databaseConnected: true,
);

class _DelayedMarketplace implements MarketplaceRepository {
  final requests = <Completer<CustomerHomeFeed>>[], zones = <String>[];
  @override
  Future<CustomerHomeFeed> fetchCustomerHomeFeed({
    String? search,
    String? categoryId,
    String? zone,
  }) {
    zones.add(zone ?? '');
    final pending = Completer<CustomerHomeFeed>();
    requests.add(pending);
    return pending.future;
  }

  @override
  Future<ServiceOfferModel> fetchServiceById(String id) =>
      throw UnimplementedError();

  @override
  Future<PaginatedServices> getPaginatedServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
  }) async => PaginatedServices(
    items: const [],
    page: page,
    totalPages: 1,
    total: 0,
  );
}

class _TestAuth extends AuthController {
  @override
  AuthState build() => const AuthState();
  void switchUser(String id) {
    state = AuthState(
      session: AuthSession(
        accessToken: 'test',
        refreshToken: 'test',
        user: AuthUser(id: id, phone: '', fullName: 'Test', role: 'CUSTOMER'),
      ),
    );
  }
}
