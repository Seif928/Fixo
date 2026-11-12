import 'dart:async';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/service_catalog_sheet.dart';

Map<String, dynamic> service(String id) => {
  'id': id,
  'titleEn': id,
  'titleAr': id,
  'baseInspectionEgp': 150,
  'serviceFeeEgp': 250,
  'flatPriceEgp': 400,
  'estimatedDurationMins': 60,
};
Map<String, dynamic> page(String id, {int current = 1, int pages = 1}) => {
  'items': [service(id)],
  'meta': {'page': current, 'totalPages': pages},
};

void main() {
  Future<void> pump(
    WidgetTester tester,
    Future<Map<String, dynamic>> Function(RequestOptions) read,
  ) async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            try {
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: await read(request),
                ),
              );
            } catch (error) {
              handler.reject(
                DioException(requestOptions: request, error: error),
              );
            }
          },
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioClientProvider.overrideWithValue(dio)],
        child: MaterialApp(
          theme: FixoTheme.light(),
          home: const Scaffold(body: ServiceCatalogSheet(isArabic: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'catalog paginates all live services instead of stopping after Home results',
    (tester) async {
      final requests = <int>[];
      await pump(tester, (request) async {
        final current = request.queryParameters['page'] as int;
        requests.add(current);
        expect(request.queryParameters['limit'], 20);
        return page('Service $current', current: current, pages: 2);
      });
      expect(find.text('Service 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('catalog-load-more')));
      await tester.pumpAndSettle();
      expect(find.text('Service 1'), findsOneWidget);
      expect(find.text('Service 2'), findsOneWidget);
      expect(requests, [1, 2]);
      expect(find.byKey(const Key('catalog-load-more')), findsNothing);
    },
  );

  testWidgets('incomplete prices show retry rather than fabricated amounts', (
    tester,
  ) async {
    var valid = false;
    await pump(
      tester,
      (_) async => valid
          ? page('Real price')
          : {
              'items': [
                {'id': 'bad', 'titleEn': 'Incomplete service'},
              ],
              'meta': {'page': 1, 'totalPages': 1},
            },
    );
    expect(find.text('Incomplete service'), findsNothing);
    expect(find.text('Could not load services. Please retry.'), findsOneWidget);
    valid = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Real price'), findsOneWidget);
    expect(find.text('400 EGP · 60 min'), findsOneWidget);
  });

  testWidgets('new search results win over an older slow response', (
    tester,
  ) async {
    final old = Completer<Map<String, dynamic>>();
    await pump(
      tester,
      (request) async => request.queryParameters['search'] == 'old'
          ? old.future
          : page(request.queryParameters['search'] as String? ?? 'Initial'),
    );
    await tester.enterText(find.byKey(const Key('catalog-search')), 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('catalog-search')), 'new');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog-service-new')), findsOneWidget);
    old.complete(page('Stale service'));
    await tester.pumpAndSettle();
    expect(find.text('Stale service'), findsNothing);
    expect(find.byKey(const ValueKey('catalog-service-new')), findsOneWidget);
  });
}
