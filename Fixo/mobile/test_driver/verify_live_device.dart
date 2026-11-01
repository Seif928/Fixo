// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

void main() async {
  print('=== FIXO DEVICE-LEVEL VERIFICATION (WINDOWS) ===');

  const defaultTimeout = Duration(seconds: 15);
  const shortTimeout = Duration(seconds: 5);

  final vmServiceUrl = Platform.environment['VM_SERVICE_URL'];
  print(
    'Connecting to Flutter Driver (VM Service: ${vmServiceUrl ?? 'auto'})...',
  );
  final driver = vmServiceUrl != null && vmServiceUrl.isNotEmpty
      ? await FlutterDriver.connect(dartVmServiceUrl: vmServiceUrl)
      : await FlutterDriver.connect();

  try {
    final health = await driver.checkHealth();
    print('STEP 0: Driver health status: ${health.status}');

    // -------------------------------------------------------------------------
    // STEP 1: Launch on Onboarding and Navigate to Sign In
    // -------------------------------------------------------------------------
    print('STEP 1: Onboarding screen — navigating to Sign In...');
    await driver.waitFor(
      find.text('Your home, in better hands.'),
      timeout: defaultTimeout,
    );
    print('FOUND: Onboarding headline');

    await driver.scrollIntoView(
      find.byValueKey('btn-sign-in'),
      timeout: defaultTimeout,
    );
    await driver.tap(find.byValueKey('btn-sign-in'), timeout: defaultTimeout);
    print('Tapped "I already have an account" (btn-sign-in)');

    // -------------------------------------------------------------------------
    // STEP 2: Phone Authentication with Existing Development User
    // -------------------------------------------------------------------------
    print('STEP 2: Phone Auth screen — entering development user phone...');
    await driver.waitFor(
      find.byValueKey('section-phone-input'),
      timeout: defaultTimeout,
    );
    print('FOUND: section-phone-input');

    await driver.scrollIntoView(
      find.byValueKey('input-egypt-phone'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('input-egypt-phone'),
      timeout: defaultTimeout,
    );
    await driver.enterText('010 2345 6789', timeout: defaultTimeout);
    print('Entered phone number: "010 2345 6789"');

    await driver.scrollIntoView(
      find.byValueKey('btn-continue-phone'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('btn-continue-phone'),
      timeout: defaultTimeout,
    );
    print('Tapped "Continue" (btn-continue-phone) -> Requesting OTP...');

    // -------------------------------------------------------------------------
    // STEP 3: OTP Verification with Development OTP (482910)
    // -------------------------------------------------------------------------
    print('STEP 3: OTP screen — verifying 6-digit development code...');
    await driver.waitFor(
      find.byValueKey('section-otp-code'),
      timeout: defaultTimeout,
    );
    print('FOUND: section-otp-code');

    final otpDigits = ['4', '8', '2', '9', '1', '0'];
    for (final digit in otpDigits) {
      await driver.scrollIntoView(
        find.byValueKey('keypad-digit-$digit'),
        timeout: defaultTimeout,
      );
      await driver.tap(
        find.byValueKey('keypad-digit-$digit'),
        timeout: defaultTimeout,
      );
    }
    print('Entered development OTP: 482910 via tactile keypad');

    await driver.scrollIntoView(
      find.byValueKey('btn-verify-otp'),
      timeout: defaultTimeout,
    );
    await driver.tap(find.byValueKey('btn-verify-otp'), timeout: defaultTimeout);
    print('Tapped "Verify & Access Account" (btn-verify-otp) -> Verifying OTP...');

    // -------------------------------------------------------------------------
    // STEP 4: Verify Customer Home Feed from Live Supabase
    // -------------------------------------------------------------------------
    print('STEP 4: Verifying Customer Home feed loaded from live Supabase API...');
    await driver.waitFor(find.text('FIXO'), timeout: defaultTimeout);
    print('FOUND: FIXO brand mark on Customer Home');

    await driver.waitFor(
      find.text('Sheikh Zayed, Dist. 9'),
      timeout: defaultTimeout,
    );
    print('FOUND: Active Zone: "Sheikh Zayed, Dist. 9"');

    final categories = [
      'AC Maintenance',
      'Plumbing & Leaks',
      'Electrical & Lighting',
      'Deep Home Cleaning',
      'Carpentry & Repairs',
      'Painting & Finishing',
    ];
    for (final cat in categories) {
      await driver.waitFor(find.text(cat), timeout: defaultTimeout);
      print('FOUND: Category "$cat"');
    }
    print('--> ALL 6 CATEGORIES VERIFIED.');

    await driver.waitFor(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );
    print(
      'FOUND: Seasonal Promo: "Summer AC Deep Clean & Gas Refill" (350 EGP)',
    );

    await driver.waitFor(
      find.text('Home Safety Inspection'),
      timeout: defaultTimeout,
    );
    print('FOUND: Bundle Offer: "Home Safety Inspection" (450 EGP)');
    print('--> LIVE OFFERINGS VERIFIED.');

    await driver.waitFor(
      find.byValueKey('empty-professionals-card'),
      timeout: defaultTimeout,
    );
    print('FOUND: empty-professionals-card');

    await driver.waitFor(
      find.text('No professionals available yet.'),
      timeout: defaultTimeout,
    );
    print('FOUND: Neutral text: "No professionals available yet."');
    print('--> EMPTY PROFESSIONALS STATE VERIFIED.');

    // -------------------------------------------------------------------------
    // STEP 5: Category Selection Actually Filters Displayed Results
    // -------------------------------------------------------------------------
    print('STEP 5: Testing category selection filtering on device...');

    // 5A: Select "AC Maintenance"
    await driver.scrollIntoView(
      find.byValueKey('category-tile-ac-maintenance'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('category-tile-ac-maintenance'),
      timeout: defaultTimeout,
    );
    print('Tapped category tile: ac-maintenance');

    await driver.waitFor(
      find.byValueKey('btn-clear-home-filters'),
      timeout: defaultTimeout,
    );
    print('FOUND: Reset button (btn-clear-home-filters) visible after selection');

    // Matching AC promo must be visible
    await driver.scrollIntoView(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );
    print('FOUND: AC promo "Summer AC Deep Clean & Gas Refill" is displayed');

    // Unrelated Electrical bundle must be filtered out (absent)
    await driver.waitForAbsent(
      find.text('Home Safety Inspection'),
      timeout: shortTimeout,
    );
    print('VERIFIED FILTERED OUT: Electrical bundle is absent when AC is selected');

    // 5B: Switch to "Electrical & Lighting"
    await driver.scrollIntoView(
      find.byValueKey('category-tile-electrical-lighting'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('category-tile-electrical-lighting'),
      timeout: defaultTimeout,
    );
    print('Tapped category tile: electrical-lighting');

    // Unrelated AC promo must now be filtered out (absent)
    await driver.waitForAbsent(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: shortTimeout,
    );
    print('VERIFIED FILTERED OUT: AC promo is absent when Electrical is selected');

    // Matching Electrical bundle must be visible
    await driver.scrollIntoView(
      find.text('Home Safety Inspection'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Home Safety Inspection'),
      timeout: defaultTimeout,
    );
    print('FOUND: Electrical bundle "Home Safety Inspection" is displayed');

    // 5C: Reset filters
    await driver.scrollIntoView(
      find.byValueKey('btn-clear-home-filters'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('btn-clear-home-filters'),
      timeout: defaultTimeout,
    );
    print('Tapped btn-clear-home-filters to reset category selection');

    // Both promo and bundle must be restored
    await driver.scrollIntoView(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );
    await driver.scrollIntoView(
      find.text('Home Safety Inspection'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Home Safety Inspection'),
      timeout: defaultTimeout,
    );
    print('--> CATEGORY SELECTION FILTERING & RESTORATION FULLY VERIFIED.');

    // -------------------------------------------------------------------------
    // STEP 6: Search Filtering & Exclusion Verification
    // -------------------------------------------------------------------------
    print('STEP 6: Testing search filtering and category exclusion on device...');
    await driver.scrollIntoView(
      find.byValueKey('input-customer-home-search'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('input-customer-home-search'),
      timeout: defaultTimeout,
    );
    await driver.enterText('Plumbing', timeout: defaultTimeout);
    print('Entered search query: "Plumbing"');

    // Matching category IS visible
    await driver.scrollIntoView(
      find.text('Plumbing & Leaks'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Plumbing & Leaks'),
      timeout: defaultTimeout,
    );
    print('FOUND: Matching category "Plumbing & Leaks" is visible');

    // Unrelated categories ARE EXCLUDED (absent)
    final excludedCategories = [
      'AC Maintenance',
      'Electrical & Lighting',
      'Deep Home Cleaning',
      'Carpentry & Repairs',
      'Painting & Finishing',
    ];
    for (final excluded in excludedCategories) {
      await driver.waitForAbsent(find.text(excluded), timeout: shortTimeout);
      print('VERIFIED EXCLUDED: "$excluded" is absent from search results');
    }
    print('--> SEARCH EXCLUSION VERIFIED FOR ALL UNRELATED CATEGORIES.');

    // Clear search and verify full catalog restored
    await driver.scrollIntoView(
      find.byValueKey('btn-clear-home-filters'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('btn-clear-home-filters'),
      timeout: defaultTimeout,
    );
    print('Tapped btn-clear-home-filters to reset search');

    for (final cat in categories) {
      await driver.scrollIntoView(find.text(cat), timeout: defaultTimeout);
      await driver.waitFor(find.text(cat), timeout: defaultTimeout);
    }
    print('--> FULL 6-CATEGORY CATALOG RESTORED AFTER SEARCH RESET.');

    // -------------------------------------------------------------------------
    // STEP 7: Real Connection Failure & Recovery on Running App
    // -------------------------------------------------------------------------
    print('STEP 7: Testing real backend connection failure on the running app...');

    // Stop the backend on port 3001
    print('Stopping backend process on port 3001...');
    await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      r'''
      $conns = Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue
      foreach ($conn in $conns) {
        Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
      }
      ''',
    ]);
    print('Backend process stopped.');

    // Trigger reload on running app
    print('Triggering feed reload while backend is stopped...');
    final reloadRes = await driver.requestData('reload_feed');
    print('reload_feed dispatched: $reloadRes');

    // Verify error state appears on device
    await driver.waitFor(
      find.byValueKey('customer-home-error'),
      timeout: defaultTimeout,
    );
    print('FOUND: customer-home-error widget on running app');

    await driver.waitFor(
      find.text('Could not load marketplace services'),
      timeout: defaultTimeout,
    );
    print('FOUND: "Could not load marketplace services" header');

    await driver.waitFor(
      find.byValueKey('btn-retry-home'),
      timeout: defaultTimeout,
    );
    print('FOUND: Retry action button: btn-retry-home');
    print('--> REAL CONNECTION FAILURE ON RUNNING APP VERIFIED.');

    // Restore the backend
    print('Restoring backend on port 3001...');
    await Process.start(
      'cmd.exe',
      ['/c', 'npm run start:supabase'],
      workingDirectory: r'E:\Fixo_Home_Services\Fixo\backend',
      mode: ProcessStartMode.detached,
    );

    // Wait until http://localhost:3001/api/v1/health/ready responds
    final client = HttpClient();
    bool backendReady = false;
    for (int i = 0; i < 40; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      try {
        final req = await client.getUrl(
          Uri.parse('http://localhost:3001/api/v1/health/ready'),
        );
        final resp = await req.close().timeout(const Duration(seconds: 2));
        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          if (body.contains('"ready":true') || body.contains('ready: true')) {
            print('Backend is healthy: $body');
            backendReady = true;
            break;
          }
        }
      } catch (_) {
        // Still starting...
      }
    }
    client.close();

    if (!backendReady) {
      throw Exception('Backend failed to recover on port 3001 within 40 seconds');
    }
    print('Backend successfully restored on port 3001.');

    // Tap Retry button on the device
    print('Tapping "Retry Connection" (btn-retry-home) on running app...');
    await driver.scrollIntoView(
      find.byValueKey('btn-retry-home'),
      timeout: defaultTimeout,
    );
    await driver.tap(find.byValueKey('btn-retry-home'), timeout: defaultTimeout);

    // Verify error state disappears and live catalog is restored
    await driver.waitForAbsent(
      find.byValueKey('customer-home-error'),
      timeout: defaultTimeout,
    );
    print('VERIFIED: customer-home-error disappeared after retry');

    await driver.waitFor(find.text('FIXO'), timeout: defaultTimeout);
    print('FOUND: FIXO brand mark on recovered Customer Home');

    for (final cat in categories) {
      await driver.scrollIntoView(find.text(cat), timeout: defaultTimeout);
      await driver.waitFor(find.text(cat), timeout: defaultTimeout);
    }
    print('--> LIVE CATALOG FULLY RECOVERED ON RUNNING APP WITHOUT RESTART!');

    print('====================================================');
    print('ALL DEVICE-LEVEL VERIFICATIONS COMPLETED SUCCESSFULLY!');
    print('====================================================');
  } catch (e, st) {
    print('VERIFICATION FAILED: $e');
    print(st);
    rethrow;
  } finally {
    print('Cleaning up and closing Flutter Driver...');
    await driver.close();
    print('Flutter Driver closed cleanly.');
  }
}
