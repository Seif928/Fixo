import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/l10n/app_locale_controller.dart';

import 'app/app.dart';
import 'app/startup_gate.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'core/notifications/device_push_service.dart';
import 'core/uploads/device_media_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Expose real controls to screen readers and browser-based test runners.
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
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
  final restoration = container
      .read(authControllerProvider.notifier)
      .restoreSession();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: FixoStartupGate(
        restoration: restoration,
        onReady: () {
          container.read(deviceMediaPickerProvider).prepareRecovery();
          container.read(devicePushProvider).resume();
        },
        child: const FixoApp(),
      ),
    ),
  );
}
