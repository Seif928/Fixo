import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fixo_mobile/app/router/app_router.dart';

void main() {
  for (final path in [
    '/login',
    '/register',
    '/dashboard',
    '/bookings',
    '/profile',
  ]) {
    testWidgets('$path reaches working sign-in and keeps private pages gated', (
      tester,
    ) async {
      final router = createAppRouter(
        initialLocation: path,
        isAuthenticated: () => false,
      );
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/auth/phone');
      expect(find.byKey(const Key('phone-password-number')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }
}
