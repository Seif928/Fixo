// OPT-IN live API verification. Skipped during normal `flutter test` runs.
//
// Uses localhost:3001 by default. Override FIXO_LIVE_API_URL to inspect a
// deployed API without mutating its catalog. Run explicitly with:
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
const String _liveApiUrl = String.fromEnvironment(
  'FIXO_LIVE_API_URL',
  defaultValue: 'http://localhost:3001/api/v1',
);

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  group(
    'Live Customer Home API contract (opt-in, read-only)',
    () {
      late DioMarketplaceRepository repository;
      late Dio dio;
      HttpOverrides? previousOverrides;

      setUpAll(() {
        // flutter_test blocks real HTTP by default; allow it only in this opt-in suite.
        previousOverrides = HttpOverrides.current;
        HttpOverrides.global = _RealHttpOverrides();
        dio = Dio(
          BaseOptions(
            baseUrl: _liveApiUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
          ),
        );
        repository = DioMarketplaceRepository(dio);
      });
      tearDownAll(() {
        dio.close(force: true);
        HttpOverrides.global = previousOverrides;
      });

      test(
        'live catalog has valid linked services and matching detail',
        () async {
          final feed = await repository.fetchCustomerHomeFeed();

          expect(feed.storageMode, 'POSTGRESQL_PRISMA');
          expect(feed.databaseConnected, isTrue);
          expect(feed.categories, isNotEmpty);
          expect(feed.zones, isNotEmpty);
          expect(feed.services, isNotEmpty);
          final categoryIds = feed.categories.map((c) => c.id).toSet();
          expect(categoryIds.length, feed.categories.length);
          expect(
            feed.services.map((s) => s.id).toSet().length,
            feed.services.length,
          );
          for (final service in feed.services) {
            expect(service.id, isNotEmpty);
            expect(categoryIds, contains(service.categoryId));
            expect(service.titleEn, isNotEmpty);
            expect(service.titleAr, isNotEmpty);
            expect(service.baseInspectionEgp, greaterThanOrEqualTo(0));
            expect(service.serviceFeeEgp, greaterThanOrEqualTo(0));
            expect(service.flatPriceEgp, greaterThanOrEqualTo(0));
          }
          final listed = feed.services.first;
          final detail = await repository.fetchServiceById(listed.id);
          expect(detail.id, listed.id);
          expect(detail.categoryId, listed.categoryId);
          expect(detail.flatPriceEgp, listed.flatPriceEgp);

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
            containsAll(<String>[
              'sheikh-zayed',
              'new-cairo',
              'maadi',
              'zamalek',
              'dokki',
            ]),
          );
        },
      );
    },
    skip: _runLiveApi
        ? false
        : 'Live API check is opt-in: pass --dart-define=FIXO_LIVE_API=true',
  );
}
