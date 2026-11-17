import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/storage/auth_session_preferences.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'session_restore_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('preferences retain no credentials after login', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await AuthSessionPreferences(prefs).saveSession(fixture.session);
    for (final key in prefs.getKeys()) {
      expect(prefs.get(key).toString(), isNot(contains('new-access')));
      expect(prefs.get(key).toString(), isNot(contains('new-refresh')));
    }
  });
  test(
    'legacy preference-only credentials migrate and rotate into an empty vault',
    () async {
      SharedPreferences.setMockInitialValues({
        AuthPreferenceKeys.isLoggedIn: true,
        AuthPreferenceKeys.session: jsonEncode(fixture.session.toJson()),
        AuthPreferenceKeys.tokens: jsonEncode(
          const StoredAuthTokens(
            accessToken: 'old-access',
            refreshToken: 'old-refresh',
            userId: 'customer',
            phone: '',
            role: 'CUSTOMER',
          ).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      final vault = MemoryTokenStorage();
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(vault),
          authRepositoryProvider.overrideWithValue(fixture.RestoreRepository()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).restoreSession();
      expect((await vault.readTokens())?.refreshToken, 'new-refresh');
      expect(
        container.read(authControllerProvider).session?.user.id,
        'customer',
      );
      expect(prefs.getString(AuthPreferenceKeys.tokens), isNull);
    },
  );
}
