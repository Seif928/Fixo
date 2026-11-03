import 'package:dio/dio.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/pro/data/pro_repository.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_account_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final cases = <String, (Map<String, dynamic>?, String)>{
    'new applicant': (null, '/pro/onboarding/signup'),
    'personal details saved': (
      {'verificationStatus': 'DRAFT', 'primaryZoneId': 'zone-test'},
      '/pro/onboarding/skills',
    ),
    'skills saved': (
      {'verificationStatus': 'DRAFT', 'primaryCategoryId': 'cat-test'},
      '/pro/onboarding/documents',
    ),
    'name and ID saved without an invented zone': (
      {'verificationStatus': 'DRAFT', 'nationalIdSynthetic': '12345678901234'},
      '/pro/onboarding/skills',
    ),
    'under review': (
      {'verificationStatus': 'PENDING_REVIEW'},
      '/pro/onboarding/status',
    ),
    'corrections required': (
      {'verificationStatus': 'ACTION_REQUIRED'},
      '/pro/onboarding/status',
    ),
    'suspended': (
      {'verificationStatus': 'SUSPENDED'},
      '/pro/onboarding/status',
    ),
    'approved': ({'verificationStatus': 'APPROVED'}, '/pro/dashboard'),
  };
  for (final entry in cases.entries) {
    testWidgets('${entry.key} resumes the server-authorized stage', (
      tester,
    ) async {
      final profile = entry.value.$1;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'profile': profile == null
                        ? null
                        : {'id': 'pro-test', 'userId': 'user-test', ...profile},
                  },
                ),
              );
            },
          ),
        );
      final router = GoRouter(
        initialLocation: '/pro',
        routes: [
          GoRoute(path: '/pro', builder: (_, _) => const ProAccountEntryPage()),
          for (final route in cases.values.map((c) => c.$2).toSet())
            GoRoute(
              path: route,
              builder: (_, state) => Scaffold(body: Text(state.uri.path)),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proRepositoryProvider.overrideWithValue(ProRepository(dio)),
          ],
          child: MaterialApp.router(
            theme: FixoTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
