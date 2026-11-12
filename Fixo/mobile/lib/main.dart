import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/l10n/app_locale_controller.dart';

import 'app/app.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'core/notifications/device_push_service.dart';
import 'core/uploads/device_media_picker.dart';

SemanticsHandle? _webSemanticsHandle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Use clean path URLs matching Vercel/Firebase SPA rewrites and attach the
    // web semantics tree so accessibility readers and browser tests can inspect controls.
    usePathUrlStrategy();
    _webSemanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
  }
  LicenseRegistry.addLicense(() async* {
    for (final family in ['cairo', 'manrope']) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/$family/OFL.txt'));
    }
  });
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(preferences)],
  );
  await container.read(authControllerProvider.notifier).restoreSession();
  runApp(
    UncontrolledProviderScope(container: container, child: const FixoApp()),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(deviceMediaPickerProvider).prepareRecovery();
    container.read(devicePushProvider).resume();
  });
}
