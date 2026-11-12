import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/data/email_access_service.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/email_auth_page.dart';

class UnverifiedEmailService extends EmailAccessService {
  UnverifiedEmailService() : super(Dio());
  int calls = 0;
  @override
  Future<AuthSession?> signIn(
    String email,
    String password, {
    bool create = false,
  }) async {
    calls++;
    return null;
  }

  @override
  Future<AuthSession?> checkVerification() async => null;
}

void main() {
  testWidgets(
    'invalid form never calls Firebase; unverified email never creates FIXO session',
    (tester) async {
      final service = UnverifiedEmailService();
      final storage = MemoryTokenStorage();
      final container = ProviderContainer(
        overrides: [
          emailAccessProvider.overrideWithValue(service),
          secureTokenStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FixoTheme.light(),
            home: const EmailAuthPage(),
          ),
        ),
      );
      final submit = find.byKey(const Key('email-sign-in-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(service.calls, 0);
      await tester.enterText(
        find.byKey(const Key('email-sign-in-address')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('email-sign-in-password')),
        'long-password-123',
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      expect(find.text('I verified my email'), findsOneWidget);
      expect(container.read(authControllerProvider).isAuthenticated, false);
      expect(await storage.readTokens(), isNull);
      await tester.tap(find.text('I verified my email'));
      await tester.pumpAndSettle();
      expect(find.text('Email is not verified yet.'), findsOneWidget);
      expect(container.read(authControllerProvider).isAuthenticated, false);
    },
  );
}
