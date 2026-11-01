// Device-level verification entrypoint on Windows.
//
// Launches the normal FixoApp without router overrides or forced authentication.
// Authentication is performed dynamically via the live development OTP flow.
import 'package:fixo_mobile/app/app.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/features/customer_home/presentation/controllers/customer_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final container = ProviderContainer();

  enableFlutterDriverExtension(
    handler: (message) async {
      if (message == 'reload_feed') {
        await container
            .read(customerHomeControllerProvider.notifier)
            .loadFeed();
        return 'ok';
      }
      if (message == 'get_access_token') {
        final token = await container
            .read(secureTokenStorageProvider)
            .readAccessToken();
        return token ?? '';
      }
      return 'unknown';
    },
  );

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FixoApp(),
    ),
  );
}
