// Public native smoke verification; no account, booking or payment writes.
// Run with app_verify.dart, which uses the application's real router/guards.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect().timeout(
    const Duration(seconds: 45),
  );
  const timeout = Duration(seconds: 20);
  try {
    // The brand mark continuously shimmers. Waiting for every animation to
    // settle would block even when the target control is visible and usable.
    // Each command still has an explicit timeout and checks the real UI.
    await driver.runUnsynchronized(() async {
      await driver.waitFor(
        find.byValueKey('btn-get-started'),
        timeout: timeout,
      );
      await driver.scrollIntoView(
        find.text('EGP Price Breakdown'),
        timeout: timeout,
      );
      await driver.tap(find.text('EGP Price Breakdown'), timeout: timeout);
      await driver.waitFor(
        find.text('How booking pricing works'),
        timeout: timeout,
      );
      await driver.tap(find.text('Close'), timeout: timeout);
      await driver.tap(find.text('Cash After Service'), timeout: timeout);
      await driver.waitFor(find.text('Cash on service'), timeout: timeout);
      await driver.tap(find.text('Close'), timeout: timeout);
      await driver.scrollIntoView(
        find.byValueKey('btn-sign-in'),
        timeout: timeout,
      );
      await driver.tap(find.byValueKey('btn-sign-in'), timeout: timeout);
      await driver.waitFor(
        find.byValueKey('phone-password-number'),
        timeout: timeout,
      );
      await driver.scrollIntoView(
        find.byValueKey('phone-password-submit'),
        timeout: timeout,
      );
      await driver.tap(
        find.byValueKey('phone-password-submit'),
        timeout: timeout,
      );
      await driver.waitFor(
        find.text('Please enter your Egyptian mobile number (+20).'),
        timeout: timeout,
      );
      // Use the normal GoRouter navigation; auth guards must still reject guests.
      for (final route in ['/admin', '/customer/profile', '/support']) {
        await driver.requestData('go:$route', timeout: timeout);
        await driver.waitFor(
          find.byValueKey('phone-password-number'),
          timeout: timeout,
        );
        final current = await driver.requestData(
          'get_current_location',
          timeout: timeout,
        );
        if (current != '/auth/phone') {
          throw StateError('Guest route $route was not protected: $current');
        }
      }
      print(
        'PASS: native onboarding, price/cash dialogs, login validation and guest route protection.',
      );
    });
  } catch (error) {
    stderr.writeln('FAIL: native public smoke verification: $error');
    rethrow;
  } finally {
    await driver.close().timeout(const Duration(seconds: 10));
  }
}
