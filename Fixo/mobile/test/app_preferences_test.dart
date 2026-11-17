import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';

void main() {
  test('Arabic and system/dark/light survive a new application container', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(overrides: [appPreferencesProvider.overrideWithValue(prefs)]);
    await first.read(appLocaleProvider.notifier).setLocale(const Locale('ar'));
    await first.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    first.dispose();
    final second = ProviderContainer(overrides: [appPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(second.dispose);
    expect(second.read(appLocaleProvider), const Locale('ar'));
    expect(second.read(appThemeModeProvider), ThemeMode.dark);
    await second.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.system);
    expect(prefs.getString('fixo.theme'), 'system');
  });
  test('invalid stored settings fall back to supported values', () async {
    SharedPreferences.setMockInitialValues({'fixo.locale': 'invalid', 'fixo.theme': 'invalid'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [appPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    expect(container.read(appLocaleProvider), const Locale('en'));
    expect(container.read(appThemeModeProvider), ThemeMode.system);
    await expectLater(container.read(appLocaleProvider.notifier).setLocale(const Locale('xx')), throwsArgumentError);
  });
}
