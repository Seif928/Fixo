import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_locale_controller.dart';
import '../core/theme/fixo_theme.dart';
import 'router/app_router.dart';

/// Root application widget for FIXO.
///
/// Configures `GoRouter`, `FixoTheme` (Light and Dark), and EN/LTR + AR/RTL
/// localization delegates.
class FixoApp extends ConsumerWidget {
  const FixoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'FIXO — Home Services',
      debugShowCheckedModeBanner: false,
      theme: FixoTheme.light(locale: locale),
      darkTheme: FixoTheme.dark(locale: locale),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
