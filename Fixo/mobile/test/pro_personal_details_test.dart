import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_signup_page.dart';

void main() {
  testWidgets('personal step sends only name and ID then continues to skills', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    final requested = <String>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requested.add(options.path);
            if (options.method == 'POST') {
              saved = Map<String, dynamic>.from(options.data as Map);
            }
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: options.method == 'POST'
                    ? {
                        'id': 'pro-fixture',
                        'userId': 'fixture-user',
                        'verificationStatus': 'DRAFT',
                        ...?saved,
                      }
                    : options.path == '/pro/me'
                    ? {'profile': null}
                    : {'categories': [], 'zones': []},
              ),
            );
          },
        ),
      );
    final router = GoRouter(
      initialLocation: '/pro/onboarding/signup',
      routes: [
        GoRoute(
          path: '/pro/onboarding/signup',
          builder: (_, _) => const ProSignUpPage(),
        ),
        GoRoute(
          path: '/pro/onboarding/skills',
          builder: (_, _) => const Scaffold(body: Text('Skills step')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioClientProvider.overrideWithValue(dio)],
        child: MaterialApp.router(
          theme: FixoTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Primary Transport Mode'), findsNothing);
    expect(requested, isNot(contains('/pro/catalog-options')));
    await tester.enterText(find.byType(TextFormField).first, 'Test Legal Name');
    await tester.enterText(find.byType(TextFormField).last, '12345678901234');
    final next = find.text('Continue to Skills & Coverage');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(saved, {
      'fullName': 'Test Legal Name',
      'nationalIdSynthetic': '12345678901234',
    });
    expect(find.text('Skills step'), findsOneWidget);
  });
}
