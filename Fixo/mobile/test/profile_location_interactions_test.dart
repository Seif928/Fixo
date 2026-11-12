import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/location/egypt_places.dart';
import 'package:fixo_mobile/core/location/service_area_picker.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/session/session_providers.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/uploads/private_media_picker_sheet.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/customer_home/presentation/controllers/customer_home_controller.dart';
import 'package:fixo_mobile/features/customer_home/presentation/pages/customer_home_page.dart';
import 'package:fixo_mobile/features/profile/data/avatar_repository.dart';
import 'package:fixo_mobile/features/profile/presentation/profile_avatar.dart';
import 'package:fixo_mobile/features/profile/presentation/profile_page.dart';

const _serviceJson = {
  'id': 'service-fixture',
  'categoryId': 'cat-fixture',
  'categorySlug': 'plumbing',
  'slug': 'test-service',
  'titleEn': 'Actual test service',
  'titleAr': 'خدمة اختبار',
  'descriptionEn': 'Fixture',
  'descriptionAr': 'اختبار',
  'baseInspectionEgp': 150,
  'serviceFeeEgp': 250,
  'flatPriceEgp': 400,
  'estimatedDurationMins': 60,
  'isSeasonalPromo': false,
  'isBundle': false,
};

const _user = AuthUser(
  id: 'fixture-user',
  phone: '+201023456789',
  fullName: 'Test User',
  role: 'CUSTOMER',
);
const _area = SelectedServiceArea(
  zoneSlug: 'giza',
  governorateEn: 'Giza',
  governorateAr: 'الجيزة',
);
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+sDj8AAAAASUVORK5CYII=',
);

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
      user: _user,
    ),
  );
  @override
  Future<void> acceptUpdatedProfile(AuthUser user) async {
    state = AuthState(
      session: AuthSession(
        accessToken: 'fixture',
        refreshToken: 'fixture',
        user: user,
      ),
    );
  }
}

class _Market implements MarketplaceRepository {
  final zones = <String?>[];
  @override
  Future<CustomerHomeFeed> fetchCustomerHomeFeed({
    String? search,
    String? categoryId,
    String? zone,
  }) async {
    zones.add(zone);
    return const CustomerHomeFeed(
      zones: [],
      categories: [],
      services: [],
      professionals: [],
      storageMode: 'TEST',
      databaseConnected: true,
    );
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
    items: [ServiceOfferModel.fromJson(_serviceJson)],
    page: page,
    totalPages: 1,
    total: 1,
  );
}

class _Avatars extends AvatarRepository {
  _Avatars() : super(Dio());
  int uploads = 0;
  bool fail = false;
  @override
  Future<String> upload(PickedPrivateMedia photo) async {
    if (fail) throw StateError('Test failure');
    uploads++;
    return 'version-$uploads';
  }

  @override
  Future<Uint8List> read() async => _png;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EgyptPlaces catalog;
  setUpAll(() async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/locations/egypt.json'),
    );
    catalog = EgyptPlaces(
      (data['places'] as List)
          .map((p) => EgyptPlace.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
    );
  });
  Future<({ProviderContainer container, _Avatars avatars, _Market market})>
  pump(
    WidgetTester tester, {
    String route = '/customer/home',
    bool arabic = false,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'fixo.locale': arabic ? 'ar' : 'en',
      'fixo.area.fixture-user': jsonEncode(_area.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final avatars = _Avatars(), market = _Market();
    var profileName = _user.fullName;
    var profilePhone = _user.phone;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            if (request.path == '/users/me/profile' &&
                request.method == 'PATCH') {
              profileName = (request.data as Map)['fullName'] as String;
            }
            if (request.path == '/auth/phone-alias') {
              profilePhone = (request.data as Map)['phone'] as String;
            }
            final profile = {
              'id': _user.id,
              'fullName': profileName,
              'phone': profilePhone,
              'role': 'CUSTOMER',
              'addresses': [],
              'hasAvatar': avatars.uploads > 0,
              'avatarVersion': 'version-${avatars.uploads}',
            };
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: request.path == '/services'
                    ? {
                        'items': [_serviceJson],
                        'meta': {'page': 1, 'totalPages': 1, 'total': 1},
                      }
                    : request.path == '/auth/phone-alias'
                    ? {
                        'user': profile,
                        'accessToken': 'new-fixture',
                        'refreshToken': 'new-fixture',
                      }
                    : profile,
              ),
            );
          },
        ),
      );
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
        sessionProvider.overrideWith(
          (ref) => const AuthSession(
            accessToken: 'fixture',
            refreshToken: 'fixture',
            user: _user,
          ),
        ),
        authControllerProvider.overrideWith(_Auth.new),
        egyptPlacesProvider.overrideWith((ref) async => catalog),
        marketplaceRepositoryProvider.overrideWithValue(market),
        avatarRepositoryProvider.overrideWithValue(avatars),
        dioClientProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: route,
      routes: [
        GoRoute(
          path: '/customer/home',
          builder: (_, _) => const CustomerHomePage(),
        ),
        GoRoute(
          path: '/customer/profile',
          builder: (_, _) => const ProfilePage(),
        ),
        GoRoute(
          path: '/customer/bookings/new',
          builder: (_, state) =>
              Text('Chosen ${(state.extra as Map)['offering'].id}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: FixoTheme.light(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.35)),
            child: Directionality(
              textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container: container, avatars: avatars, market: market);
  }

  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets(
      'logo preserves selection and the location control opens governorates at $width',
      (tester) async {
        final result = await pump(tester, width: width, arabic: true);
        await tester.tap(find.byKey(const Key('home-brand')));
        await tester.pumpAndSettle();
        expect(find.byType(ServiceAreaPicker), findsNothing);
        expect(
          result.container
              .read(customerHomeControllerProvider)
              .selectedZoneSlug,
          'giza',
        );
        expect(find.byIcon(Icons.logout_rounded), findsNothing);

        await tester.tap(find.byKey(const Key('home-governorate-picker')));
        await tester.pumpAndSettle();
        expect(find.text('ابحث عن المحافظة'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('place-search')), 'أسوان');
        await tester.pumpAndSettle();
        final catalog = await result.container.read(egyptPlacesProvider.future);
        final aswan = catalog.governorates.singleWhere(
          (g) => g.slug == 'aswan',
        );
        await tester.tap(find.byKey(ValueKey('place-${aswan.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-service-area')));
        await tester.pumpAndSettle();
        expect(
          result.container
              .read(customerHomeControllerProvider)
              .selectedZoneSlug,
          'aswan',
        );
        expect(result.market.zones.last, 'aswan');

        await tester.tap(find.byKey(const Key('home-governorate-picker')));
        await tester.pumpAndSettle();
        expect(find.text('ابحث عن المحافظة'), findsOneWidget);
        await tester.tap(find.byTooltip('إغلاق'));
        await tester.pumpAndSettle();
        expect(
          result.container
              .read(customerHomeControllerProvider)
              .selectedZoneSlug,
          'aswan',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'search side button opens actual catalog without clearing Home search',
    (tester) async {
      final result = await pump(tester);
      await tester.enterText(
        find.byKey(const Key('input-customer-home-search')),
        'existing query',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn-search-filters')));
      await tester.pumpAndSettle();
      expect(find.text('All services'), findsOneWidget);
      expect(find.text('Actual test service'), findsOneWidget);
      expect(
        result.container.read(customerHomeControllerProvider).searchQuery,
        'existing query',
      );
      await tester.tap(find.text('Actual test service'));
      await tester.pumpAndSettle();
      expect(find.text('Chosen service-fixture'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping profile image opens sources and retains existing photo after cancellation',
    (tester) async {
      final result = await pump(tester, route: '/customer/profile');
      await tester.tapAt(
        tester.getTopLeft(find.byKey(const Key('profile-photo-button'))) +
            const Offset(20, 20),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-gallery-btn')), findsOneWidget);
      expect(find.byKey(const Key('choose-suggested-avatar')), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(result.avatars.uploads, 0);
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).hasAvatar,
        false,
      );
      await tester.scrollUntilVisible(find.text('Sign out'), 450);
      expect(find.text('Sign out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected illustration uploads, refreshes Home and survives a later upload failure',
    (tester) async {
      final result = await pump(tester, route: '/customer/profile');
      Future<void> choose(int index) async {
        await tester.tap(find.byKey(const Key('profile-change-photo')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('choose-suggested-avatar')));
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is InkWell &&
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith(
                  'suggested-avatar-',
                ),
          ),
          findsNWidgets(24),
        );
        final item = find.byKey(Key('suggested-avatar-$index'));
        await tester.ensureVisible(item);
        await tester.runAsync(() async {
          await tester.tap(item);
          for (
            var attempt = 0;
            attempt < 80 &&
                find.byType(PrivateMediaPickerSheet).evaluate().isNotEmpty;
            attempt++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      await choose(0);
      expect(result.avatars.uploads, 1);
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).version,
        'version-1',
      );
      expect(
        find.text('Profile photo updated.'),
        findsOneWidget,
        reason: find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' | '),
      );
      await tester.tap(find.byKey(const Key('nav-tab-home')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).version,
        'version-1',
      );
      expect(find.byIcon(Icons.logout_rounded), findsNothing);
      await tester.tap(find.byKey(const Key('btn-home-profile-avatar')));
      await tester.pumpAndSettle();
      result.avatars.fail = true;
      await choose(1);
      expect(result.avatars.uploads, 1);
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).version,
        'version-1',
      );
      expect(
        find.text('Could not save this setting. Please retry.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'profile edits display name and password-confirmed phone and updates the current session',
    (tester) async {
      final result = await pump(tester, route: '/customer/profile');
      await tester.tap(find.byKey(const Key('profile-edit-name')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-profile-value')),
        'Updated Name',
      );
      await tester.tap(find.byKey(const Key('save-profile-details')));
      await tester.pumpAndSettle();
      expect(find.text('Updated Name'), findsOneWidget);
      expect(
        result.container.read(authControllerProvider).session!.user.fullName,
        'Updated Name',
      );
      await tester.tap(find.byKey(const Key('profile-edit-phone')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-profile-value')),
        '01123456789',
      );
      await tester.enterText(
        find.byKey(const Key('confirm-profile-password')),
        'current-fixture-password',
      );
      await tester.tap(find.byKey(const Key('save-profile-details')));
      await tester.pumpAndSettle();
      expect(find.text('+201123456789'), findsOneWidget);
      expect(
        result.container.read(authControllerProvider).session!.user.phone,
        '+201123456789',
      );
    },
  );
}
