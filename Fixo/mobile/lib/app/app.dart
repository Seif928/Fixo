import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_locale_controller.dart';
import '../core/notifications/device_push_service.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../core/theme/fixo_theme.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';

final _messenger = GlobalKey<ScaffoldMessengerState>();

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
    ref.listen(pushActivityProvider, (previous, next) {
      if (!ref.read(authControllerProvider).isAuthenticated) return;
      _messenger.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            ref.read(appLocaleProvider).languageCode == 'ar'
                ? 'لديك تحديث جديد على طلبك.'
                : 'You have a new booking update.',
          ),
        ),
      );
    });
    ref.listen(pushOpenBookingProvider, (previous, id) {
      if (id != null && ref.read(authControllerProvider).isAuthenticated) {
        router.push(
          AppRoutes.customerChat.replaceFirst(
            ':orderId',
            Uri.encodeComponent(id),
          ),
        );
      }
    });

    return MaterialApp.router(
      title: 'FIXO — Home Services',
      scaffoldMessengerKey: _messenger,
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
