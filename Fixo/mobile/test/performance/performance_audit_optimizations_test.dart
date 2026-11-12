import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/widgets/deferred_route_view.dart';
import 'package:fixo_mobile/core/widgets/fixo_skeleton.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/favorites/data/favorites_models.dart';
import 'package:fixo_mobile/features/favorites/data/favorites_repository.dart';
import 'package:fixo_mobile/features/favorites/presentation/pages/favorites_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _StubCategoriesAdapter implements HttpClientAdapter {
  int categoriesRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/services/categories')) {
      categoriesRequests++;
      final payload = jsonEncode({
        'categories': [
          {
            'id': 'cat-1',
            'slug': 'ac-maintenance',
            'nameEn': 'AC Maintenance',
            'nameAr': 'صيانة التكييف',
            'subtitleEn': 'Clean & refill',
            'subtitleAr': 'تنظيف وشحن',
            'iconName': 'ac_unit',
            'startingPriceEgp': 350,
            'sortOrder': 1,
          },
        ],
        'zones': <dynamic>[],
        'meta': {'storageMode': 'postgres', 'databaseConnected': true},
      });
      return ResponseBody.fromString(
        payload,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'items': <dynamic>[],
        'meta': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ControllableFavoritesRepository extends FavoritesRepository {
  _ControllableFavoritesRepository(super.dio);

  Completer<FavoritesPageResponse<FavoriteServiceItem>>? loadServicesCompleter;
  Completer<FavoritesPageResponse<FavoriteProfessionalItem>>? loadProsCompleter;
  Completer<bool>? removeServiceCompleter;
  bool prosRequestedBeforeServicesDone = false;
  bool servicesLoaded = false;

  @override
  Future<FavoritesPageResponse<FavoriteServiceItem>> listFavoriteServices({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await (loadServicesCompleter ??
            (Completer<FavoritesPageResponse<FavoriteServiceItem>>()
              ..complete(
                FavoritesPageResponse<FavoriteServiceItem>(
                  items: [
                    FavoriteServiceItem(
                      id: 'fav-1',
                      offeringId: 'off-1',
                      createdAt: DateTime(2026),
                      isAvailable: true,
                      titleEn: 'AC Deep Clean',
                      titleAr: 'تنظيف التكييف',
                      descriptionEn: 'Full coil wash',
                      descriptionAr: 'غسيل كامل',
                      baseInspectionEgp: 150,
                      serviceFeeEgp: 200,
                      flatPriceEgp: 350,
                      estimatedDurationMins: 60,
                      categorySlug: 'ac-maintenance',
                      categoryNameEn: 'AC Maintenance',
                      categoryNameAr: 'صيانة التكييف',
                      categoryIcon: 'ac_unit',
                      isActive: true,
                    ),
                    FavoriteServiceItem(
                      id: 'fav-2',
                      offeringId: 'off-2',
                      createdAt: DateTime(2026),
                      isAvailable: true,
                      titleEn: 'Pipe Leak Fix',
                      titleAr: 'إصلاح تسريب',
                      descriptionEn: 'Seal joint',
                      descriptionAr: 'معالجة التسريب',
                      baseInspectionEgp: 120,
                      serviceFeeEgp: 160,
                      flatPriceEgp: 280,
                      estimatedDurationMins: 45,
                      categorySlug: 'plumbing',
                      categoryNameEn: 'Plumbing',
                      categoryNameAr: 'سباكة',
                      categoryIcon: 'plumbing',
                      isActive: true,
                    ),
                  ],
                  page: 1,
                  limit: 20,
                  total: 2,
                  totalPages: 1,
                ),
              )))
        .future;
    servicesLoaded = true;
    return result;
  }

  @override
  Future<FavoritesPageResponse<FavoriteProfessionalItem>>
      listFavoriteProfessionals({
    int page = 1,
    int limit = 20,
  }) {
    if (!servicesLoaded) {
      prosRequestedBeforeServicesDone = true;
    }
    if (loadProsCompleter != null) {
      return loadProsCompleter!.future;
    }
    return Future.value(
      const FavoritesPageResponse<FavoriteProfessionalItem>(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<bool> removeFavoriteService(String offeringId) {
    return (removeServiceCompleter ?? (Completer<bool>()..complete(false)))
        .future;
  }
}

void main() {
  test('DioMarketplaceRepository deduplicates concurrent categories calls', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    final adapter = _StubCategoriesAdapter();
    dio.httpClientAdapter = adapter;
    final repo = DioMarketplaceRepository(dio);

    await Future.wait([
      repo.fetchCustomerHomeFeed(),
      repo.fetchCustomerHomeFeed(zone: 'nasr-city'),
    ]);

    expect(adapter.categoriesRequests, 1);
  });

  testWidgets(
    'FavoritesPage loads parallel, renders skeleton, and rolls back failed optimistic removal',
    (tester) async {
      final servicesCompleter =
          Completer<FavoritesPageResponse<FavoriteServiceItem>>();
      final removeCompleter = Completer<bool>();
      final repo = _ControllableFavoritesRepository(Dio())
        ..loadServicesCompleter = servicesCompleter
        ..removeServiceCompleter = removeCompleter;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: FixoTheme.light(),
            home: const FavoritesPage(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(FixoListSkeleton), findsOneWidget);
      expect(repo.prosRequestedBeforeServicesDone, isTrue);

      servicesCompleter.complete(
        FavoritesPageResponse<FavoriteServiceItem>(
          items: [
            FavoriteServiceItem(
              id: 'fav-1',
              offeringId: 'off-1',
              createdAt: DateTime(2026),
              isAvailable: true,
              titleEn: 'AC Deep Clean',
              titleAr: 'تنظيف التكييف',
              descriptionEn: 'Full coil wash',
              descriptionAr: 'غسيل كامل',
              baseInspectionEgp: 150,
              serviceFeeEgp: 200,
              flatPriceEgp: 350,
              estimatedDurationMins: 60,
              categorySlug: 'ac-maintenance',
              categoryNameEn: 'AC Maintenance',
              categoryNameAr: 'صيانة التكييف',
              categoryIcon: 'ac_unit',
              isActive: true,
            ),
            FavoriteServiceItem(
              id: 'fav-2',
              offeringId: 'off-2',
              createdAt: DateTime(2026),
              isAvailable: true,
              titleEn: 'Pipe Leak Fix',
              titleAr: 'إصلاح تسريب',
              descriptionEn: 'Seal joint',
              descriptionAr: 'معالجة التسريب',
              baseInspectionEgp: 120,
              serviceFeeEgp: 160,
              flatPriceEgp: 280,
              estimatedDurationMins: 45,
              categorySlug: 'plumbing',
              categoryNameEn: 'Plumbing',
              categoryNameAr: 'سباكة',
              categoryIcon: 'plumbing',
              isActive: true,
            ),
          ],
          page: 1,
          limit: 20,
          total: 2,
          totalPages: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('favorite-service-card-fav-1')), findsOneWidget);
      expect(find.byKey(const Key('favorite-service-card-fav-2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('remove-favorite-service-fav-1')));
      await tester.pump();

      // Optimistically removed immediately while network call is still pending.
      expect(find.byKey(const Key('favorite-service-card-fav-1')), findsNothing);
      expect(find.byKey(const Key('favorite-service-card-fav-2')), findsOneWidget);

      removeCompleter.completeError(Exception('Network failure'));
      await tester.pumpAndSettle();

      // Rolled back on error and surfaced error feedback.
      expect(find.byKey(const Key('favorite-service-card-fav-1')), findsOneWidget);
      expect(
        find.text('Could not remove service. Please retry.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('DeferredRouteView shows skeleton then resolves target or retries',
      (tester) async {
    var shouldFail = true;
    var completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        theme: FixoTheme.light(),
        home: DeferredRouteView(
          loadLibrary: () => completer.future,
          builder: (_) => const Text('Loaded Chunk'),
        ),
      ),
    );

    expect(find.byType(FixoListSkeleton), findsOneWidget);

    completer.completeError(Exception('chunk failed'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    shouldFail = false;
    completer = Completer<void>()..complete();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(shouldFail, isFalse);
    expect(find.text('Loaded Chunk'), findsOneWidget);
  });

  test('Static hosting configs cache immutable assets while keeping entrypoints uncached',
      () {
    final vercel = jsonDecode(
      File('vercel.static.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final vercelHeaders = (vercel['headers'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final vercelBySource = {
      for (final rule in vercelHeaders)
        rule['source'] as String:
            ((rule['headers'] as List<dynamic>).first as Map<String, dynamic>)['value']
                as String,
    };

    expect(vercelBySource['/index.html'], contains('no-cache'));
    expect(vercelBySource['/flutter_bootstrap.js'], contains('no-cache'));
    expect(vercelBySource['/main.dart.js'], contains('no-cache'));
    expect(vercelBySource['/main.dart.mjs'], contains('no-cache'));
    expect(vercelBySource['/main.dart.wasm'], contains('no-cache'));
    expect(vercelBySource['/assets/:path*'], contains('immutable'));
    expect(vercelBySource['/canvaskit/:path*'], contains('immutable'));

    final firebase = jsonDecode(
      File('firebase.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final firebaseHeaders =
        ((firebase['hosting'] as Map<String, dynamic>)['headers']
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final firebaseBySource = {
      for (final rule in firebaseHeaders)
        rule['source'] as String:
            ((rule['headers'] as List<dynamic>).first as Map<String, dynamic>)['value']
                as String,
    };

    expect(firebaseBySource['/index.html'], contains('no-cache'));
    expect(firebaseBySource['/main.dart.wasm'], contains('no-cache'));
    expect(firebaseBySource['/assets/**'], contains('immutable'));
    expect(firebaseBySource['/canvaskit/**'], contains('immutable'));
  });
}

