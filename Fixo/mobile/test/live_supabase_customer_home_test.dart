// OPT-IN live API verification. Skipped during normal `flutter test` runs.
//
// Requires the FIXO backend running on http://localhost:3001 (for example
// `npm run start:supabase` from backend/). Run explicitly with:
//
//   flutter test test/live_supabase_customer_home_test.dart --dart-define=FIXO_LIVE_API=true
//
// This is an API contract check from Dart against the running backend. It is
// NOT device-level end-to-end verification of the app UI.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const bool _runLiveApi = bool.fromEnvironment('FIXO_LIVE_API');

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  group(
    'Live Customer Home API contract (opt-in, localhost:3001)',
    () {
      late DioMarketplaceRepository repository;

      setUpAll(() {
        // flutter_test blocks real HTTP by default; allow it only in this opt-in suite.
        HttpOverrides.global = _RealHttpOverrides();
        repository = DioMarketplaceRepository(
          Dio(
            BaseOptions(
              baseUrl: 'http://localhost:3001/api/v1',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            ),
          ),
        );
      });

      test('feed contains 6 categories, 5 zones, 8 offerings and no professionals', () async {
        final feed = await repository.fetchCustomerHomeFeed();

        expect(feed.storageMode, 'POSTGRESQL_PRISMA');
        expect(feed.databaseConnected, isTrue);
        expect(feed.categories, hasLength(6));
        expect(feed.zones, hasLength(5));
        expect(feed.services, hasLength(8));
        expect(feed.professionals, isEmpty);

        expect(
          feed.categories.map((c) => c.slug),
          containsAll(<String>[
            'ac-maintenance',
            'plumbing-leaks',
            'electrical-lighting',
            'deep-home-cleaning',
            'carpentry-repairs',
            'painting-finishing',
          ]),
        );
        expect(
          feed.zones.map((z) => z.slug),
          containsAll(<String>['sheikh-zayed', 'new-cairo', 'maadi', 'zamalek', 'dokki']),
        );
        expect(feed.seasonalPromo?.slug, 'summer-ac-deep-clean-gas-refill');
        expect(feed.bundleOffer?.slug, 'home-safety-inspection-bundle');
      });
    },
    skip: _runLiveApi
        ? false
        : 'Live API check is opt-in: pass --dart-define=FIXO_LIVE_API=true',
  );
}
