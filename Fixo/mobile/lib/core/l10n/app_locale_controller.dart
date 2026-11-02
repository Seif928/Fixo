import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initialized by main before the application starts; tests can override it.
final appPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Controls active application locale (`en` default LTR, `ar` RTL supported).
class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => Locale(
    ref.read(appPreferencesProvider)?.getString('fixo.locale') == 'ar'
        ? 'ar'
        : 'en',
  );

  Future<void> setLocale(Locale locale) async {
    if (!const ['ar', 'en'].contains(locale.languageCode)) {
      throw ArgumentError('Supported languages are ar and en.');
    }
    state = locale;
    final prefs = ref.read(appPreferencesProvider);
    if (prefs != null &&
        !await prefs.setString('fixo.locale', locale.languageCode)) {
      throw StateError('Language preference could not be saved.');
    }
  }

  Future<void> toggleLocale() => setLocale(
    state.languageCode == 'en' ? const Locale('ar') : const Locale('en'),
  );
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

/// Controls active theme mode (`ThemeMode.light` default, `ThemeMode.dark` supported).
class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(appPreferencesProvider)?.getString('fixo.theme');
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(appPreferencesProvider);
    if (prefs != null && !await prefs.setString('fixo.theme', mode.name)) {
      throw StateError('Theme preference could not be saved.');
    }
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);
