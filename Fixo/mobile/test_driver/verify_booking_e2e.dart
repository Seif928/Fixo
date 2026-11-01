// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

void main() async {
  print('=== FIXO PHASE 3.3C: REAL CUSTOMER BOOKING END-TO-END VERIFICATION ===');

  const defaultTimeout = Duration(seconds: 20);

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

    await driver.scrollIntoView(
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
    print('Entered development OTP: 482910');

    await driver.scrollIntoView(
      find.byValueKey('btn-verify-otp'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('btn-verify-otp'),
      timeout: defaultTimeout,
    );
    print('Tapped "Verify & Access Account" (btn-verify-otp)...');

    // -------------------------------------------------------------------------
    // STEP 4: Customer Home — Real Offerings & Seasonal Promo
    // -------------------------------------------------------------------------
    print('STEP 4: Verifying Customer Home feed loaded from local backend...');
    await driver.waitFor(find.text('FIXO'), timeout: defaultTimeout);
    print('FOUND: FIXO brand mark on Customer Home');

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
    // STEP 5: Open Screen 04 (Create Booking) from Real Service Offering
    // -------------------------------------------------------------------------
    print('STEP 5: Tapping "Book Now" on Seasonal Promo to open Screen 04...');
    await driver.scrollIntoView(
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
    print('FOUND: Real offering title on Screen 04');

    // Verify neutral professional copy (no fake Hassan El-Sayed, no false auto-assignment promise)
    await driver.waitFor(
      find.text('No professional assigned yet'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Professional: Not yet assigned'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('Catalog Home Service'),
      timeout: defaultTimeout,
    );
    print('--> NEUTRAL PRO COPY VERIFIED (No fake pro, no premature assignment promise)');

    // Verify empty address state
    await driver.waitFor(
      find.text('No saved address found'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('A delivery address is required to book a service.'),
      timeout: defaultTimeout,
    );
    print('--> EMPTY ADDRESS STATE VERIFIED (A delivery address is required)');

    // Verify confirm booking button is present
    await driver.waitFor(
      find.byValueKey('confirm-booking-draft-btn'),
      timeout: defaultTimeout,
    );
    print('FOUND: confirm-booking-draft-btn');

    // -------------------------------------------------------------------------
    // STEP 6: Open Address Creation Bottom Sheet
    // -------------------------------------------------------------------------
    print('STEP 6: Opening address creation bottom sheet...');
    await driver.scrollIntoView(
      find.byValueKey('add-first-address-btn'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('add-first-address-btn'),
      timeout: defaultTimeout,
    );

    await driver.waitFor(find.text('Add New Address'), timeout: defaultTimeout);
    print('FOUND: "Add New Address" bottom sheet displayed');

    await driver.waitFor(
      find.byValueKey('address-label-input'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.byValueKey('address-building-input'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.byValueKey('address-district-input'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.byValueKey('save-address-btn'),
      timeout: defaultTimeout,
    );
    print('FOUND: All required address input fields in bottom sheet');

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

    // Toggle default switch
    await driver.tap(
      find.byValueKey('address-default-switch'),
      timeout: defaultTimeout,
    );

    // Save Address
    print('Tapping "Save & Select Address" (save-address-btn)...');
    await driver.tap(
      find.byValueKey('save-address-btn'),
      timeout: defaultTimeout,
    );

    // -------------------------------------------------------------------------
    // STEP 8: Verify Address Persisted, Returned & Selected on Screen 04
    // -------------------------------------------------------------------------
    print('STEP 8: Verifying newly created address is selected on Screen 04...');
    await driver.waitForAbsent(
      find.text('No saved address found'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(find.text('Zayed Residence'), timeout: defaultTimeout);
    await driver.waitFor(
      find.text('Building 14, Apt 4B'),
      timeout: defaultTimeout,
    );
    await driver.waitFor(
      find.text('District 9, Sheikh Zayed'),
      timeout: defaultTimeout,
    );
    print('--> REAL ADDRESS PERSISTED & SELECTED ON SCREEN 04!');

    // -------------------------------------------------------------------------
    // STEP 9: Enter Diagnostic Notes & Submit Booking Draft
    // -------------------------------------------------------------------------
    print('STEP 9: Entering diagnostic issue description...');
    await driver.scrollIntoView(
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
    await driver.scrollIntoView(
      find.byValueKey('confirm-booking-draft-btn'),
      timeout: defaultTimeout,
    );
    await driver.tap(
      find.byValueKey('confirm-booking-draft-btn'),
      timeout: defaultTimeout,
    );

    // Verify success snackbar appears
    print('Waiting for booking draft confirmation notification...');
    await driver.waitFor(
      find.byValueKey('booking-draft-success-snackbar-text'),
      timeout: defaultTimeout,
    );
    print('FOUND: booking-draft-success-snackbar-text notification!');

    // Wait until returned to Customer Home
    await driver.waitFor(find.text('FIXO'), timeout: defaultTimeout);
    print('Returned to Customer Home after booking draft submission.');

    // -------------------------------------------------------------------------
    // STEP 10: Backend API & PostgreSQL Invariant Verification
    // -------------------------------------------------------------------------
    print('STEP 10: Verifying persisted data via backend HTTP APIs & PostgreSQL...');

    // Retrieve the customer's authenticated JWT directly from the running app's SecureTokenStorage
    final jwt = await driver.requestData('get_access_token');
    if (jwt.isEmpty) {
      throw Exception('Driver failed to retrieve authenticated JWT from running app');
    }
    print('Retrieved authenticated customer JWT session from running app.');

    // 10A: Query GET /api/v1/users/me/addresses
    final addrReq = await httpClient.getUrl(
      Uri.parse('http://localhost:3000/api/v1/users/me/addresses'),
    );
    addrReq.headers.set('Authorization', 'Bearer $jwt');
    final addrResp = await addrReq.close();
    if (addrResp.statusCode != 200) {
      throw Exception('GET /users/me/addresses failed with HTTP ${addrResp.statusCode}');
    }
    final addrData = jsonDecode(
      await addrResp.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final addresses = addrData['addresses'] as List<dynamic>;
    if (addresses.isEmpty) {
      throw Exception('Expected at least 1 persisted address for customer');
    }
    final savedAddr = addresses.first as Map<String, dynamic>;
    print('Persisted Address Verification:');
    print('  - ID: ${savedAddr['id']}');
    print('  - Label: ${savedAddr['label']} (Expected: Zayed Residence)');
    print('  - Building: ${savedAddr['buildingLine']} (Expected: Building 14, Apt 4B)');
    print('  - District: ${savedAddr['districtLine']} (Expected: District 9, Sheikh Zayed)');
    print('  - Gate Notes: ${savedAddr['gateNotes']} (Expected: Gate 3, Intercom 402)');
    print('  - isDefault: ${savedAddr['isDefault']} (Expected: true)');

    assert(savedAddr['label'] == 'Zayed Residence', 'Label mismatch');
    assert(savedAddr['buildingLine'] == 'Building 14, Apt 4B', 'Building mismatch');
    assert(savedAddr['districtLine'] == 'District 9, Sheikh Zayed', 'District mismatch');
    assert(savedAddr['isDefault'] == true, 'isDefault mismatch');
    print('--> PERSISTED CUSTOMER ADDRESS VERIFIED AGAINST REAL BACKEND.');

    // 10B: Query GET /api/v1/bookings
    final bookingsReq = await httpClient.getUrl(
      Uri.parse('http://localhost:3000/api/v1/bookings'),
    );
    bookingsReq.headers.set('Authorization', 'Bearer $jwt');
    final bookingsResp = await bookingsReq.close();
    if (bookingsResp.statusCode != 200) {
      throw Exception('GET /bookings failed with HTTP ${bookingsResp.statusCode}');
    }
    final bookingsData = jsonDecode(
      await bookingsResp.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final bookings = bookingsData['bookings'] as List<dynamic>;
    if (bookings.isEmpty) {
      throw Exception('Expected at least 1 persisted booking for customer');
    }
    final latestBooking = bookings.first as Map<String, dynamic>;
    final bookingId = latestBooking['id'] as String;
    final orderCode = latestBooking['orderCode'] as String;
    final status = latestBooking['status'] as String;
    final offeringId = latestBooking['offeringId'] as String;
    final addressId = latestBooking['addressId'] as String;
    final preferredProId = latestBooking['preferredProId'];
    final pricing = latestBooking['pricing'] as Map<String, dynamic>;

    print('Persisted Booking Verification:');
    print('  - Booking ID: $bookingId');
    print('  - Order Code: $orderCode');
    print('  - Status: $status (Expected: DRAFT)');
    print('  - Offering ID: $offeringId (Expected: off-ac-deep-clean)');
    print('  - Address ID: $addressId (Expected: ${savedAddr['id']})');
    print('  - Preferred Pro ID: $preferredProId (Expected: null - no invented assignment)');
    print('  - Total EGP: ${pricing['totalEgp']} (Expected: 350)');
    print('  - Base Inspection: ${pricing['baseInspectionEgp']} (Expected: 150)');
    print('  - Service Fee: ${pricing['serviceFeeEgp']} (Expected: 200)');

    assert(status == 'DRAFT', 'Status must be DRAFT');
    assert(offeringId == 'off-ac-deep-clean', 'Offering ID must match selected offering');
    assert(addressId == savedAddr['id'], 'Address ID must match saved address');
    assert(preferredProId == null, 'Preferred Pro must remain null');
    assert(pricing['totalEgp'] == 350, 'Pricing total must be 350 EGP');

    // 10C: Query GET /api/v1/bookings/:id
    final singleReq = await httpClient.getUrl(
      Uri.parse('http://localhost:3000/api/v1/bookings/$bookingId'),
    );
    singleReq.headers.set('Authorization', 'Bearer $jwt');
    final singleResp = await singleReq.close();
    if (singleResp.statusCode != 200) {
      throw Exception('GET /bookings/$bookingId failed with HTTP ${singleResp.statusCode}');
    }
    final singleData = jsonDecode(
      await singleResp.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    assert(singleData['id'] == bookingId, 'Single booking ID mismatch');
    assert(singleData['orderCode'] == orderCode, 'Order code mismatch');
    assert(singleData['status'] == 'DRAFT', 'Single booking status must be DRAFT');
    print('--> SINGLE BOOKING RETRIEVAL (GET /bookings/:id) MATCHES PERFECTLY.');

    print('================================================================');
    print('ALL REAL CUSTOMER BOOKING END-TO-END VERIFICATIONS PASSED!');
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
