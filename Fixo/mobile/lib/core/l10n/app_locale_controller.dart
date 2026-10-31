import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls active application locale (`en` default LTR, `ar` RTL supported).
class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLocale() {
    state = state.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

/// Controls active theme mode (`ThemeMode.light` default, `ThemeMode.dark` supported).
class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

