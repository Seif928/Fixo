// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

void check(bool condition, String message) {
  if (!condition) {
    throw StateError('Verification check failed: $message');
  }
}

Future<void> verifyPostgresBookingInvariants(
  String bookingId, {
  required String expectedOrderCode,
  required String phase,
}) async {
  print('[$phase] Verifying PostgreSQL invariants in local fixo_test for booking $bookingId...');

  final dbCheck = await Process.run(
    'docker',
    <String>[
      'exec',
      'fixo-postgres',
      'psql',
      '-U',
      'fixo_user',
      '-d',
      'fixo_test',
      '-t',
      '-A',
      '-c',
      'SELECT current_database();',
    ],
  );
  check(
    dbCheck.exitCode == 0 && dbCheck.stdout.toString().trim() == 'fixo_test',
    '[$phase] Target PostgreSQL database must be fixo_test, got: ${dbCheck.stdout} ${dbCheck.stderr}',
  );

  final safeId = bookingId.replaceAll("'", '');
  final sql = '''
SELECT json_build_object(
  'bookingId', b.id,
  'orderCode', b."orderCode",
  'status', b.status::text,
  'proProfileId', b."proProfileId",
  'totalEgp', b."totalEgp",
  'paymentCount', (SELECT COUNT(*)::int FROM "PaymentRecord" WHERE "bookingId" = b.id),
  'pendingCashCount', (
    SELECT COUNT(*)::int
    FROM "PaymentRecord"
    WHERE "bookingId" = b.id
      AND method = 'CASH_ON_SERVICE'
      AND status = 'PENDING'
      AND "paidAt" IS NULL
      AND "externalReference" IS NULL
      AND "amountEgp" = b."totalEgp"
  ),
  'totalEventsCount', (SELECT COUNT(*)::int FROM "BookingStatusEvent" WHERE "bookingId" = b.id),
  'draftToPendingDispatchCount', (
    SELECT COUNT(*)::int
    FROM "BookingStatusEvent"
    WHERE "bookingId" = b.id
      AND "fromStatus" = 'DRAFT'
      AND "toStatus" = 'PENDING_DISPATCH'
  )
)::text
FROM "Booking" b
WHERE b.id = '$safeId';
''';

  final proc = await Process.start(
    'docker',
    <String>[
      'exec',
      '-i',
      'fixo-postgres',
      'psql',
      '-U',
      'fixo_user',
      '-d',
      'fixo_test',
      '-t',
      '-A',
    ],
  );
  proc.stdin.writeln(sql);
  await proc.stdin.close();

  final stdoutStr = await proc.stdout.transform(utf8.decoder).join();
  final stderrStr = await proc.stderr.transform(utf8.decoder).join();
  final exitCode = await proc.exitCode;

  check(
    exitCode == 0,
    '[$phase] psql query failed (exit $exitCode): $stderrStr',
  );

  final rawJson = stdoutStr.trim();
  check(rawJson.isNotEmpty, '[$phase] Booking $bookingId not found in fixo_test');

  final row = jsonDecode(rawJson) as Map<String, dynamic>;
  print('[$phase] fixo_test DB snapshot: $row');

  check(row['bookingId'] == bookingId, '[$phase] DB bookingId mismatch: ${row['bookingId']} != $bookingId');
  check(row['orderCode'] == expectedOrderCode, '[$phase] DB orderCode mismatch: ${row['orderCode']} != $expectedOrderCode');
  check(row['status'] == 'PENDING_DISPATCH', '[$phase] DB status must be PENDING_DISPATCH, got ${row['status']}');
  check(row['proProfileId'] == null, '[$phase] DB proProfileId must be null, got ${row['proProfileId']}');
  check(row['totalEgp'] == 350, '[$phase] DB totalEgp must be 350, got ${row['totalEgp']}');
  check(row['paymentCount'] == 1, '[$phase] Expected exactly 1 PaymentRecord, got ${row['paymentCount']}');
  check(
    row['pendingCashCount'] == 1,
    '[$phase] Expected exactly 1 PENDING CASH_ON_SERVICE PaymentRecord with paidAt null, got ${row['pendingCashCount']}',
  );
  check(
    row['totalEventsCount'] == 2,
    '[$phase] Expected exactly 2 BookingStatusEvent rows (NULL->DRAFT and DRAFT->PENDING_DISPATCH), got ${row['totalEventsCount']}',
  );
  check(
    row['draftToPendingDispatchCount'] == 1,
    '[$phase] Expected exactly 1 DRAFT -> PENDING_DISPATCH transition event, got ${row['draftToPendingDispatchCount']}',
  );
  print('--> [$phase] POSTGRESQL fixo_test INVARIANTS VERIFIED FOR BOOKING $bookingId!');
}

Future<void> safeScrollIntoView(
  FlutterDriver driver,
  SerializableFinder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  try {
    await driver.scrollIntoView(finder, timeout: timeout);
  } catch (_) {
    // If widget is already visible or not inside a scrollable, continue gracefully
  }
}

void main() async {
  print('=== FIXO PHASE 4C: FULL BOOKING-TO-CHECKOUT E2E VERIFICATION (PORT 3002) ===');

  const defaultTimeout = Duration(seconds: 20);
  const absentTimeout = Duration(seconds: 5);

  final backendBaseUrl = Platform.environment['FIXO_TEST_BACKEND_URL'] ??
      'http://localhost:3002/api/v1';
  print('Target Host Backend Base URL: $backendBaseUrl');

  final vmServiceUrl = Platform.environment['VM_SERVICE_URL'];
  print(
    'Connecting to Flutter Driver (VM Service: ${vmServiceUrl ?? 'auto'})...',
  );
  final driver = vmServiceUrl != null && vmServiceUrl.isNotEmpty
      ? await FlutterDriver.connect(dartVmServiceUrl: vmServiceUrl)
      : await FlutterDriver.connect();

  final httpClient = HttpClient();

  try {
    final health = await driver.checkHealth();
    print('STEP 0: Flutter Driver health status: ${health.status}');

    // -------------------------------------------------------------------------
    // STEP 1: Launch on Onboarding and Navigate to Sign In
    // -------------------------------------------------------------------------
    print('STEP 1: Onboarding screen — navigating to Sign In...');
    await driver.waitFor(
      find.text('Your home, in better hands.'),
      timeout: defaultTimeout,
    );
    print('FOUND: Onboarding headline');

    await safeScrollIntoView(
      driver,
      find.byValueKey('btn-sign-in'),
      timeout: defaultTimeout,
    );
    await driver.tap(find.byValueKey('btn-sign-in'), timeout: defaultTimeout);
    print('Tapped "I already have an account" (btn-sign-in)');

    // -------------------------------------------------------------------------
    // STEP 2: Phone Authentication with Test Customer
    // -------------------------------------------------------------------------
    print('STEP 2: Phone Auth screen — entering development user phone...');
    await driver.waitFor(
      find.byValueKey('section-phone-input'),
      timeout: defaultTimeout,
    );

    await safeScrollIntoView(
      driver,
      find.byValueKey('input-egypt-phone'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('input-egypt-phone'),
      timeout: defaultTimeout,
    );
    await driver.enterText('010 2345 6789', timeout: defaultTimeout);
    print('Entered phone number: "010 2345 6789"');

    await safeScrollIntoView(
      driver,
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

    final otpDigits = ['4', '8', '2', '9', '1', '0'];
    for (final digit in otpDigits) {
      await safeScrollIntoView(
        driver,
        find.byValueKey('keypad-digit-$digit'),
        timeout: defaultTimeout,
      );
      await driver.tap(
        find.byValueKey('keypad-digit-$digit'),
        timeout: defaultTimeout,
      );
    }
    print('Entered development OTP: 482910');

    await safeScrollIntoView(
      driver,
      find.byValueKey('btn-verify-otp'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('btn-verify-otp'),
      timeout: defaultTimeout,
    );
    print('Tapped "Verify & Access Account" (btn-verify-otp)...');

    // -------------------------------------------------------------------------
    // STEP 4: Customer Home — Service Category & Offering Selection
    // -------------------------------------------------------------------------
    print('STEP 4: Verifying Customer Home feed loaded from isolated backend...');
    await driver.waitFor(find.text('FIXO'), timeout: defaultTimeout);
    print('FOUND: FIXO brand mark on Customer Home');

    // 4A: Category selection (try ac-maintenance or air-conditioning)
    print('Checking category tile on Customer Home...');
    try {
      final acTile = find.byValueKey('category-tile-ac-maintenance');
      await safeScrollIntoView(driver, acTile, timeout: const Duration(seconds: 4));
      await driver.tap(acTile, timeout: const Duration(seconds: 4));
      print('Tapped category tile: ac-maintenance');
    } catch (_) {
      try {
        final acTile2 = find.byValueKey('category-tile-air-conditioning');
        await safeScrollIntoView(driver, acTile2, timeout: const Duration(seconds: 4));
        await driver.tap(acTile2, timeout: const Duration(seconds: 4));
        print('Tapped category tile: air-conditioning');
      } catch (_) {
        print('Category tile tap skipped; proceeding to seasonal promo card.');
      }
    }

    // 4B: Offering selection (Seasonal Promo Card)
    await driver.waitFor(
      find.byValueKey('card-seasonal-promo'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );
    print('FOUND: Seasonal Promo "Summer AC Deep Clean & Gas Refill"');

    // -------------------------------------------------------------------------
    // STEP 5: Open Screen 04 (Create Booking)
    // -------------------------------------------------------------------------
    print('STEP 5: Tapping "Book Now" on Seasonal Promo to open Screen 04...');
    await safeScrollIntoView(
      driver,
      find.byValueKey('btn-book-seasonal-promo'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('btn-book-seasonal-promo'),
      timeout: defaultTimeout,
    );

    await driver.waitFor(find.text('Create Booking'), timeout: defaultTimeout);
    print('FOUND: Screen 04 "Create Booking" opened');

    await driver.waitFor(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );

    // Verify neutral professional copy
    await driver.waitFor(
      find.text('No professional assigned yet'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Professional: Not yet assigned'),
      timeout: defaultTimeout,
    );
    print('--> NEUTRAL PRO COPY VERIFIED');

    // Verify empty address state
    await driver.waitFor(
      find.text('No saved address found'),
      timeout: defaultTimeout,
    );
    print('--> EMPTY ADDRESS STATE VERIFIED');

    // -------------------------------------------------------------------------
    // STEP 6: Open Address Creation Bottom Sheet
    // -------------------------------------------------------------------------
    print('STEP 6: Opening address creation bottom sheet...');
    await safeScrollIntoView(
      driver,
      find.byValueKey('add-first-address-btn'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('add-first-address-btn'),
      timeout: defaultTimeout,
    );

    await driver.waitFor(find.text('Add New Address'), timeout: defaultTimeout);
    print('FOUND: "Add New Address" bottom sheet displayed');

    // -------------------------------------------------------------------------
    // STEP 7: Fill and Submit Address Form
    // -------------------------------------------------------------------------
    print('STEP 7: Entering real address details in bottom sheet...');
    await driver.tap(
      find.byValueKey('address-label-input'),
      timeout: defaultTimeout,
    );
    await driver.enterText('Zayed Residence', timeout: defaultTimeout);

    await driver.tap(
      find.byValueKey('address-building-input'),
      timeout: defaultTimeout,
    );
    await driver.enterText('Building 14, Apt 4B', timeout: defaultTimeout);

    await driver.tap(
      find.byValueKey('address-district-input'),
      timeout: defaultTimeout,
    );
    await driver.enterText('District 9, Sheikh Zayed', timeout: defaultTimeout);

    await driver.tap(
      find.byValueKey('address-gate-notes-input'),
      timeout: defaultTimeout,
    );
    await driver.enterText('Gate 3, Intercom 402', timeout: defaultTimeout);

    await driver.tap(
      find.byValueKey('address-default-switch'),
      timeout: defaultTimeout,
    );

    print('Tapping "Save & Select Address" (save-address-btn)...');
    await driver.tap(
      find.byValueKey('save-address-btn'),
      timeout: defaultTimeout,
    );

    // -------------------------------------------------------------------------
    // STEP 8: Verify Address Selected & Choose Schedule Time Window
    // -------------------------------------------------------------------------
    print('STEP 8: Verifying newly created address is selected on Screen 04...');
    await driver.waitForAbsent(
      find.text('No saved address found'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(find.text('Zayed Residence'), timeout: defaultTimeout);
    print('--> REAL ADDRESS PERSISTED & SELECTED ON SCREEN 04');

    // Select schedule time window
    print('Selecting schedule time window (Afternoon Window)...');
    await safeScrollIntoView(
      driver,
      find.text('Preferred Time Window'),
      timeout: defaultTimeout,
    );
    await safeScrollIntoView(
      driver,
      find.text('Afternoon Window'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.text('Afternoon Window'),
      timeout: defaultTimeout,
    );
    print('Selected time window: Afternoon Window');

    // -------------------------------------------------------------------------
    // STEP 9: Enter Notes & Submit Booking Draft -> Navigate to Screen 05
    // -------------------------------------------------------------------------
    print('STEP 9: Entering diagnostic issue description...');
    await safeScrollIntoView(
      driver,
      find.byValueKey('booking-issue-description-input'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('booking-issue-description-input'),
      timeout: defaultTimeout,
    );
    await driver.enterText(
      'AC unit is leaking water and coil needs chemical wash.',
      timeout: defaultTimeout,
    );

    print('Submitting booking draft via "Confirm Booking Draft"...');
    await safeScrollIntoView(
      driver,
      find.byValueKey('confirm-booking-draft-btn'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('confirm-booking-draft-btn'),
      timeout: defaultTimeout,
    );

    // Screen 04 routes directly to Screen 05 (/customer/bookings/:id/checkout)
    print('Waiting for navigation to Screen 05 (Payment)...');
    await driver.waitFor(find.text('Payment'), timeout: defaultTimeout);
    print('--> ARRIVED AT SCREEN 05 (PAYMENT / CHECKOUT)!');

    final currentRoute = await driver.requestData('get_current_location');
    print('Current GoRouter location on Screen 05: $currentRoute');
    final routeMatch =
        RegExp(r'^/customer/bookings/([^/]+)/checkout$').firstMatch(currentRoute);
    check(
      routeMatch != null && (routeMatch.group(1)?.isNotEmpty ?? false),
      'Expected Screen 05 route /customer/bookings/:bookingId/checkout, got: $currentRoute',
    );
    final createdBookingId = routeMatch!.group(1)!;
    print('--> CAPTURED EXACT CREATED BOOKING ID FROM RUN: $createdBookingId');

    // -------------------------------------------------------------------------
    // STEP 10: Screen 05 Checkout Summary UI & Cash Selection
    // -------------------------------------------------------------------------
    print('STEP 10: Verifying Screen 05 Checkout UI and Cash Collection Invariants...');

    // 10A: Order summary card verification
    await driver.waitFor(
      find.text('Summer AC Deep Clean & Gas Refill'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Cash Collection After Service'),
      timeout: defaultTimeout,
    );

    // 10B: Assert ABSENCE of ambiguous standalone "0 EGP"
    print('Asserting absence of ambiguous standalone "0 EGP" beside cash collection...');
    await driver.waitForAbsent(
      find.text('0 EGP'),
      timeout: absentTimeout,
    );
    print('--> CONFIRMED: Standalone "0 EGP" is ABSENT from Screen 05!');

    // 10C: Verify explicit summary rows in Receipt Card
    print('Verifying explicit summary rows in Receipt Card...');
    await safeScrollIntoView(
      driver,
      find.text('Due now: 0 EGP'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Due now: 0 EGP'),
      timeout: defaultTimeout,
    );
    print('FOUND: "Due now: 0 EGP" row');

    await safeScrollIntoView(
      driver,
      find.text('Due after service: 350 EGP'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Due after service: 350 EGP'),
      timeout: defaultTimeout,
    );
    print('FOUND: "Due after service: 350 EGP" row');

    // 10D: Verify and Select CASH_ON_SERVICE
    print('Selecting CASH_ON_SERVICE payment method...');
    await safeScrollIntoView(
      driver,
      find.byValueKey('payment-method-cash-on-service'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('payment-method-cash-on-service'),
      timeout: defaultTimeout,
    );
    print('Selected CASH_ON_SERVICE');

    // 10E: Confirm Checkout
    print('Tapping "Confirm Booking (Pay Cash Later)" (confirm-checkout-btn)...');
    await safeScrollIntoView(
      driver,
      find.byValueKey('confirm-checkout-btn'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('confirm-checkout-btn'),
      timeout: defaultTimeout,
    );

    // -------------------------------------------------------------------------
    // STEP 11: Wait for Checkout Confirmation View
    // -------------------------------------------------------------------------
    print('STEP 11: Waiting for CheckoutConfirmationView...');
    await driver.waitFor(
      find.byValueKey('checkout-confirmation-view'),
      timeout: defaultTimeout,
    );
    print('FOUND: checkout-confirmation-view');

    await driver.waitFor(
      find.text('Booking Confirmed — Pending Dispatch'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.byValueKey('checkout-order-code-text'),
      timeout: defaultTimeout,
    );
    final uiOrderCodeLabel = await driver.getText(
      find.byValueKey('checkout-order-code-text'),
      timeout: defaultTimeout,
    );
    check(
      uiOrderCodeLabel.contains('#'),
      'Displayed order code label must contain #, got: $uiOrderCodeLabel',
    );
    final uiOrderCode = uiOrderCodeLabel.split('#').last.trim();
    check(uiOrderCode.isNotEmpty, 'Parsed order code must not be empty');
    print('Captured UI Order Code: $uiOrderCode (label: "$uiOrderCodeLabel")');

    await driver.waitFor(
      find.byValueKey('checkout-return-home-btn'),
      timeout: defaultTimeout,
    );
    print('--> SCREEN 05 CONFIRMATION VIEW DISPLAYED SUCCESSFULLY!');

    // -------------------------------------------------------------------------
    // STEP 12: Out-of-Band Backend & Database Invariant Verification (Before Retry)
    // -------------------------------------------------------------------------
    print('STEP 12: Verifying persisted data via backend HTTP APIs & PostgreSQL fixo_test...');

    final jwt = await driver.requestData('get_access_token');
    check(jwt.isNotEmpty, 'Driver failed to retrieve authenticated JWT from running app');
    print('Retrieved customer JWT session from running app.');

    // 12A: GET /api/v1/users/me/addresses
    final addrReq = await httpClient.getUrl(
      Uri.parse('$backendBaseUrl/users/me/addresses'),
    );
    addrReq.headers.set('Authorization', 'Bearer $jwt');
    final addrResp = await addrReq.close();
    check(
      addrResp.statusCode == 200,
      'GET /users/me/addresses failed with HTTP ${addrResp.statusCode}',
    );
    final addrData = jsonDecode(
      await addrResp.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final addresses = addrData['addresses'] as List<dynamic>;
    check(addresses.isNotEmpty, 'Expected at least 1 persisted address for customer');
    final matchingAddresses = addresses
        .whereType<Map<String, dynamic>>()
        .where((a) => a['label'] == 'Zayed Residence' && a['buildingLine'] == 'Building 14, Apt 4B')
        .toList();
    check(matchingAddresses.isNotEmpty, 'Created address Zayed Residence not found in customer addresses');
    final savedAddr = matchingAddresses.first;
    check(savedAddr['districtLine'] == 'District 9, Sheikh Zayed', 'District mismatch');
    check(savedAddr['gateNotes'] == 'Gate 3, Intercom 402', 'Gate notes mismatch');
    check(savedAddr['isDefault'] == true, 'isDefault mismatch');
    print('--> PERSISTED CUSTOMER ADDRESS VERIFIED ON PORT 3002.');

    // 12B: GET /api/v1/bookings — find exact createdBookingId (never use bookings.first)
    final bookingsReq = await httpClient.getUrl(
      Uri.parse('$backendBaseUrl/bookings'),
    );
    bookingsReq.headers.set('Authorization', 'Bearer $jwt');
    final bookingsResp = await bookingsReq.close();
    check(
      bookingsResp.statusCode == 200,
      'GET /bookings failed with HTTP ${bookingsResp.statusCode}',
    );
    final bookingsData = jsonDecode(
      await bookingsResp.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final bookings = bookingsData['bookings'] as List<dynamic>;
    final matchingBookings = bookings
        .whereType<Map<String, dynamic>>()
        .where((b) => b['id'] == createdBookingId)
        .toList();
    check(
      matchingBookings.length == 1,
      'Expected exact created booking $createdBookingId in GET /bookings, found ${matchingBookings.length}',
    );
    final matchedBooking = matchingBookings.single;
    check(matchedBooking['orderCode'] == uiOrderCode, 'Order code mismatch in GET /bookings');
    check(matchedBooking['status'] == 'PENDING_DISPATCH', 'Status must be PENDING_DISPATCH in GET /bookings');
    print('--> EXACT CREATED BOOKING ($createdBookingId / $uiOrderCode) VERIFIED AS PENDING_DISPATCH!');

    // 12C: GET /api/v1/bookings/:id & PaymentRecord verification
    final singleReq = await httpClient.getUrl(
      Uri.parse('$backendBaseUrl/bookings/$createdBookingId'),
    );
    singleReq.headers.set('Authorization', 'Bearer $jwt');
    final singleResp = await singleReq.close();
    check(
      singleResp.statusCode == 200,
      'GET /bookings/$createdBookingId failed with HTTP ${singleResp.statusCode}',
    );
    final singleData = jsonDecode(
      await singleResp.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;

    check(singleData['id'] == createdBookingId, 'Single booking ID mismatch');
    check(singleData['orderCode'] == uiOrderCode, 'Single booking orderCode mismatch');
    check(singleData['status'] == 'PENDING_DISPATCH', 'Status must be PENDING_DISPATCH');

    final payment = singleData['payment'] as Map<String, dynamic>?;
    check(payment != null, 'Expected payment record on checked-out booking');
    print('PaymentRecord details:');
    print('  - Method: ${payment!['method']} (Expected: CASH_ON_SERVICE)');
    print('  - Status: ${payment['status']} (Expected: PENDING)');
    print('  - PaidAt: ${payment['paidAt']} (Expected: null)');
    print('  - Amount: ${payment['amountEgp']} EGP (Expected: 350)');

    check(payment['method'] == 'CASH_ON_SERVICE', 'Payment method mismatch');
    check(payment['status'] == 'PENDING', 'Payment status mismatch');
    check(payment['paidAt'] == null, 'paidAt must be null for pending cash');
    check(payment['amountEgp'] == 350, 'amountEgp mismatch');
    print('--> PAYMENT RECORD INVARIANTS VERIFIED!');

    // 12D: Direct PostgreSQL fixo_test check BEFORE retry
    await verifyPostgresBookingInvariants(
      createdBookingId,
      expectedOrderCode: uiOrderCode,
      phase: 'BEFORE_RETRY',
    );

    // -------------------------------------------------------------------------
    // STEP 13: Reopen Same Booking Through the App & Idempotent Retry
    // -------------------------------------------------------------------------
    print('STEP 13A: Returning to Customer Home and reopening booking $createdBookingId in the app...');
    await safeScrollIntoView(
      driver,
      find.byValueKey('checkout-return-home-btn'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('checkout-return-home-btn'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(find.text('FIXO'), timeout: defaultTimeout);
    await driver.waitForAbsent(
      find.byValueKey('checkout-confirmation-view'),
      timeout: absentTimeout,
    );
    print('Returned to Customer Home; CheckoutPage unmounted.');

    final goResp = await driver.requestData(
      'go:/customer/bookings/$createdBookingId/checkout',
    );
    check(goResp == 'ok', 'Failed to navigate to /customer/bookings/$createdBookingId/checkout');

    await driver.waitFor(
      find.byValueKey('checkout-confirmation-view'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Booking Confirmed — Pending Dispatch'),
      timeout: defaultTimeout,
    );
    final reopenedOrderCode = await driver.getText(
      find.byValueKey('checkout-order-code-text'),
      timeout: defaultTimeout,
    );
    check(
      reopenedOrderCode == uiOrderCodeLabel,
      'Reopened booking order code mismatch: $reopenedOrderCode != $uiOrderCodeLabel',
    );
    print('--> REOPENING SAME BOOKING ($createdBookingId) IN APP VERIFIED: shows existing confirmation ($reopenedOrderCode)!');

    print('STEP 13B: Verifying idempotent retry on POST /bookings/$createdBookingId/checkout...');
    final retryReq = await httpClient.postUrl(
      Uri.parse('$backendBaseUrl/bookings/$createdBookingId/checkout'),
    );
    retryReq.headers.set('Authorization', 'Bearer $jwt');
    retryReq.headers.set('Content-Type', 'application/json');
    retryReq.write(jsonEncode({'paymentMethod': 'CASH_ON_SERVICE'}));
    final retryResp = await retryReq.close();
    check(
      retryResp.statusCode == 200 || retryResp.statusCode == 201,
      'Idempotent retry failed with HTTP ${retryResp.statusCode}',
    );
    final retryData = jsonDecode(
      await retryResp.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    check(retryData['id'] == createdBookingId, 'ID changed on retry');
    check(retryData['status'] == 'PENDING_DISPATCH', 'Status changed on retry');
    final retryPayment = retryData['payment'] as Map<String, dynamic>?;
    check(retryPayment != null, 'Payment record missing on retry response');
    check(retryPayment!['id'] == payment['id'], 'PaymentRecord ID changed on retry (duplicate created)');
    check(retryPayment['method'] == 'CASH_ON_SERVICE', 'Payment method changed on retry');
    check(retryPayment['status'] == 'PENDING', 'Payment status changed on retry');
    check(retryPayment['paidAt'] == null, 'paidAt must remain null on retry');
    print('--> IDEMPOTENT RETRY HTTP RESPONSE VERIFIED: HTTP ${retryResp.statusCode}, same PaymentRecord ID ${payment['id']}.');

    // 13C: Direct PostgreSQL fixo_test check AFTER retry
    await verifyPostgresBookingInvariants(
      createdBookingId,
      expectedOrderCode: uiOrderCode,
      phase: 'AFTER_RETRY',
    );

    print('================================================================');
    print('ALL PHASE 4C REAL CUSTOMER BOOKING E2E VERIFICATIONS PASSED!');
    print('================================================================');
  } catch (e, st) {
    print('VERIFICATION FAILED: $e');
    print(st);
    rethrow;
  } finally {
    httpClient.close();
    print('Cleaning up and closing Flutter Driver...');
    await driver.close();
    print('Flutter Driver closed cleanly.');
  }
}
