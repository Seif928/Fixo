// Web Booking-to-Checkout Verification Suite.
//
// 1. Offline Responsive & Localization Widget Tests:
//    Run during normal `flutter test` without any backend or network calls.
//
// 2. Opt-In Live Chrome Web Full UI E2E Test:
//    Skipped during normal `flutter test`. Requires the isolated test backend
//    on port 3002 (`fixo_test`). Run in Chrome with:
//
//    flutter test -d chrome test/web_booking_checkout_flow_test.dart --dart-define=FIXO_LIVE_WEB_E2E=true --dart-define=FIXO_API_BASE_URL=http://localhost:3002/api/v1
import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixo_mobile/app/app.dart';
import 'package:fixo_mobile/app/router/app_router.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/booking/presentation/controllers/create_booking_controller.dart';
import 'package:fixo_mobile/features/customer_home/presentation/controllers/customer_home_controller.dart';
import 'package:fixo_mobile/features/payment/presentation/controllers/checkout_controller.dart';
import 'package:fixo_mobile/features/payment/presentation/widgets/checkout_widgets.dart';

const bool _runLiveWebE2e =
    bool.fromEnvironment('FIXO_LIVE_WEB_E2E') ||
    bool.fromEnvironment('FIXO_LIVE_API');

Future<void> _pumpFrames(
  WidgetTester tester, [
  int count = 5,
  Duration step = const Duration(milliseconds: 100),
]) async {
  for (int i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

Future<void> _runAsyncAndWait(
  WidgetTester tester, {
  Future<void> Function()? action,
  required bool Function() until,
  required String description,
  int maxPolls = 120,
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  await tester.runAsync(() async {
    if (action != null) {
      await action();
    }
    for (int i = 0; i < maxPolls; i++) {
      await tester.pump();
      if (until()) return;
      await Future<void>.delayed(pollInterval);
    }
    throw StateError('Timed out waiting for condition: $description');
  });
  await _pumpFrames(tester);
}

void main() {
  group(
    'Screen 05 Web Responsive Viewports & Localization (Offline Deterministic)',
    () {
      testWidgets(
        'Responsive Viewports: Desktop 1080p (1920x1080), Desktop 1280x800, and Mobile (390x844) render cleanly without overflow',
        (WidgetTester tester) async {
          const testBooking = BookingDetailModel(
            id: 'bk-resp-desktop',
            orderCode: 'FX-7788',
            customerId: 'cust-101',
            offeringId: 'off-ac-clean',
            addressId: 'addr-01',
            status: 'DRAFT',
            scheduledDate: '2026-11-12',
            timeWindow: 'MORNING_09_12',
            pricing: BookingPricingModel(
              baseInspectionEgp: 150,
              serviceFeeEgp: 250,
              transportFeeEgp: 0,
              totalEgp: 400,
            ),
            offering: {'id': 'off-ac-clean', 'titleEn': 'AC Deep Clean'},
            address: {
              'id': 'addr-01',
              'label': 'Home',
              'districtLine': 'Zayed',
            },
            arrivalPinCode: '1122',
            createdAt: '2026-11-01T07:00:00.000Z',
          );

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          // 1. Desktop 1920x1080
          tester.view.physicalSize = const Size(1920, 1080);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: FixoTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const CheckoutReassuranceBanner(),
                      CheckoutOrderSummaryCard(booking: testBooking),
                      const CheckoutPaymentMethodsSection(),
                      CheckoutReceiptCard(pricing: testBooking.pricing),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Due now: 0 EGP'), findsOneWidget);
          expect(find.text('Due after service: 400 EGP'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(CheckoutOrderSummaryCard),
              matching: find.text('0 EGP'),
            ),
            findsNothing,
          );
          expect(find.text('0 EGP'), findsNothing);
          expect(tester.takeException(), isNull);

          // 2. Desktop 1280x800
          tester.view.physicalSize = const Size(1280, 800);
          await tester.pumpWidget(
            MaterialApp(
              theme: FixoTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const CheckoutReassuranceBanner(),
                      CheckoutOrderSummaryCard(booking: testBooking),
                      const CheckoutPaymentMethodsSection(),
                      CheckoutReceiptCard(pricing: testBooking.pricing),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Due now: 0 EGP'), findsOneWidget);
          expect(find.text('Due after service: 400 EGP'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // 3. Mobile 390x844
          tester.view.physicalSize = const Size(390, 844);
          await tester.pumpWidget(
            MaterialApp(
              theme: FixoTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const CheckoutReassuranceBanner(),
                      CheckoutOrderSummaryCard(booking: testBooking),
                      const CheckoutPaymentMethodsSection(),
                      CheckoutReceiptCard(pricing: testBooking.pricing),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Due now: 0 EGP'), findsOneWidget);
          expect(find.text('Due after service: 400 EGP'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Arabic RTL Localization: Explicit Arabic summary rows and absence of standalone 0 ج.م',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          const testBooking = BookingDetailModel(
            id: 'bk-ar-test',
            orderCode: 'FX-AR-01',
            customerId: 'cust-101',
            offeringId: 'off-ac-clean',
            addressId: 'addr-01',
            status: 'DRAFT',
            scheduledDate: '2026-11-12',
            timeWindow: 'MORNING_09_12',
            pricing: BookingPricingModel(
              baseInspectionEgp: 150,
              serviceFeeEgp: 200,
              transportFeeEgp: 0,
              totalEgp: 350,
            ),
            offering: {'id': 'off-ac-clean', 'titleAr': 'تنظيف عميق للتكييف'},
            address: {
              'id': 'addr-01',
              'label': 'المنزل',
              'districtLine': 'الشيخ زايد',
            },
            arrivalPinCode: '3344',
            createdAt: '2026-11-01T07:00:00.000Z',
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ar'),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: FixoTheme.light(locale: const Locale('ar')),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        const CheckoutReassuranceBanner(),
                        CheckoutOrderSummaryCard(booking: testBooking),
                        const CheckoutPaymentMethodsSection(),
                        CheckoutReceiptCard(pricing: testBooking.pricing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('المستحق الآن: 0 ج.م'), findsOneWidget);
          expect(find.text('المستحق بعد الخدمة: 350 ج.م'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(CheckoutOrderSummaryCard),
              matching: find.text('0 ج.م'),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byType(CheckoutOrderSummaryCard),
              matching: find.text('0 EGP'),
            ),
            findsNothing,
          );
          expect(find.text('0 ج.م'), findsNothing);
          expect(find.text('0 EGP'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Arabic RTL Confirmation View: Invariants, order code, and arrival PIN absence',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          const testBooking = BookingDetailModel(
            id: 'bk-ar-conf',
            orderCode: 'FX-AR-99',
            customerId: 'cust-101',
            offeringId: 'off-ac-clean',
            addressId: 'addr-01',
            status: 'PENDING_DISPATCH',
            scheduledDate: '2026-11-12',
            timeWindow: 'MORNING_09_12',
            pricing: BookingPricingModel(
              baseInspectionEgp: 150,
              serviceFeeEgp: 200,
              transportFeeEgp: 0,
              totalEgp: 350,
            ),
            offering: {'id': 'off-ac-clean', 'titleAr': 'تنظيف عميق للتكييف'},
            address: {
              'id': 'addr-01',
              'label': 'المنزل',
              'districtLine': 'الشيخ زايد',
            },
            payment: PaymentRecordModel(
              id: 'pay-01',
              bookingId: 'bk-ar-conf',
              method: 'CASH_ON_SERVICE',
              status: 'PENDING',
              amountEgp: 350,
              createdAt: '2026-11-01T07:00:00.000Z',
            ),
            arrivalPinCode: '7799',
            createdAt: '2026-11-01T07:00:00.000Z',
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ar'),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: FixoTheme.light(locale: const Locale('ar')),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: CheckoutConfirmationView(
                    booking: testBooking,
                    onReturnHome: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(CheckoutConfirmationView), findsOneWidget);
          expect(find.text('تم تأكيد الحجز — قيد التعيين'), findsOneWidget);
          expect(
            find.byKey(const Key('checkout-order-code-text')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('checkout-return-home-btn')),
            findsOneWidget,
          );
          expect(find.text('7799'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    },
  );

  group(
    'Live Chrome Web Full UI E2E Journey (Opt-In, Port 3002, No Overrides)',
    () {
      setUp(() {
        HttpOverrides.global = null;
      });

      testWidgets(
        'Normal FixoApp UI Journey: Onboarding -> Dev OTP Sign-In -> Service Selection -> Address Bottom Sheet -> Draft Booking -> Screen 05 Cash Checkout -> Reopen & Idempotent Retry',
        (WidgetTester tester) async {
          HttpOverrides.global = null;
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;

          // Zero overrides: production FixoApp, GoRouter, controllers, and repositories
          final container = ProviderContainer();
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            container.dispose();
          });

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const FixoApp(),
            ),
          );
          await _pumpFrames(tester);

          // -------------------------------------------------------------------
          // STEP 1: Onboarding Screen -> Navigate to Sign-In
          // -------------------------------------------------------------------
          expect(find.text('Your home, in better hands.'), findsOneWidget);
          final signInBtn = find.byKey(const Key('btn-sign-in'));
          await tester.ensureVisible(signInBtn);
          await _pumpFrames(tester);
          await tester.tap(signInBtn);
          await _pumpFrames(tester);

          // -------------------------------------------------------------------
          // STEP 2: Phone Auth Screen -> Request Development OTP
          // -------------------------------------------------------------------
          expect(find.byKey(const Key('section-phone-input')), findsOneWidget);

          final uniqueDigits =
              (DateTime.now().millisecondsSinceEpoch % 100000000)
                  .toString()
                  .padLeft(8, '0');
          final phoneInput = find.byKey(const Key('input-egypt-phone'));
          await tester.ensureVisible(phoneInput);
          await tester.enterText(phoneInput, '010$uniqueDigits');
          await tester.pump();

          final continuePhoneBtn = find.byKey(const Key('btn-continue-phone'));
          await tester.ensureVisible(continuePhoneBtn);
          await tester.pump();

          await _runAsyncAndWait(
            tester,
            action: () async {
              await tester.tap(continuePhoneBtn);
            },
            until: () {
              final s = container.read(authControllerProvider);
              if (s.errorMessage != null) {
                throw StateError('OTP request failed: ${s.errorMessage}');
              }
              return s.step == PhoneAuthStep.otpCode;
            },
            description: 'AuthController transitions to PhoneAuthStep.otpCode',
          );

          // -------------------------------------------------------------------
          // STEP 3: OTP Screen -> Enter 6-Digit Dev OTP (482910) via UI Keypad
          // -------------------------------------------------------------------
          expect(find.byKey(const Key('section-otp-code')), findsOneWidget);
          for (final digit in const ['4', '8', '2', '9', '1', '0']) {
            final digitKey = find.byKey(Key('keypad-digit-$digit'));
            await tester.ensureVisible(digitKey);
            await tester.tap(digitKey);
            await tester.pump();
          }

          final verifyOtpBtn = find.byKey(const Key('btn-verify-otp'));
          await tester.ensureVisible(verifyOtpBtn);
          await tester.pump();

          await _runAsyncAndWait(
            tester,
            action: () async {
              await tester.tap(verifyOtpBtn);
            },
            until: () {
              final s = container.read(authControllerProvider);
              if (s.errorMessage != null) {
                throw StateError('OTP verify failed: ${s.errorMessage}');
              }
              return s.isAuthenticated;
            },
            description: 'AuthController completes OTP verification',
          );

          // -------------------------------------------------------------------
          // STEP 4: Customer Home -> Wait for Catalog Feed & Select Offering
          // -------------------------------------------------------------------
          await _runAsyncAndWait(
            tester,
            until: () {
              final homeState = container.read(customerHomeControllerProvider);
              return !homeState.isLoading && homeState.feed != null;
            },
            description: 'CustomerHomeController loads live feed from port 3002',
          );

          expect(find.text('FIXO'), findsWidgets);
          expect(find.byKey(const Key('card-seasonal-promo')), findsOneWidget);
          expect(
            find.text('Summer AC Deep Clean & Gas Refill'),
            findsOneWidget,
          );

          final bookPromoBtn = find.byKey(const Key('btn-book-seasonal-promo'));
          await tester.ensureVisible(bookPromoBtn);
          await _pumpFrames(tester);

          // -------------------------------------------------------------------
          // STEP 5: Screen 04 (Create Booking) -> Open Address Bottom Sheet
          // -------------------------------------------------------------------
          await _runAsyncAndWait(
            tester,
            action: () async {
              await tester.tap(bookPromoBtn);
            },
            until: () {
              final bookingState = container.read(
                createBookingControllerProvider,
              );
              return !bookingState.isLoadingAddresses &&
                  !bookingState.isLoadingZones &&
                  bookingState.coverageZones.isNotEmpty;
            },
            description: 'CreateBookingController loads addresses & zones',
          );

          expect(find.text('Create Booking'), findsOneWidget);
          expect(find.text('No professional assigned yet'), findsOneWidget);
          expect(find.text('No saved address found'), findsOneWidget);

          final addFirstAddressBtn = find.byKey(
            const Key('add-first-address-btn'),
          );
          await tester.ensureVisible(addFirstAddressBtn);
          await _pumpFrames(tester);
          await tester.tap(addFirstAddressBtn);
          await _pumpFrames(tester);

          // -------------------------------------------------------------------
          // STEP 6: Fill & Submit Address Creation Bottom Sheet
          // -------------------------------------------------------------------
          expect(find.text('Add New Address'), findsWidgets);
          expect(find.byKey(const Key('address-label-input')), findsOneWidget);

          await tester.enterText(
            find.byKey(const Key('address-label-input')),
            'Zayed Web Residence',
          );
          await tester.enterText(
            find.byKey(const Key('address-building-input')),
            'Building 22, Apt 5A',
          );
          await tester.enterText(
            find.byKey(const Key('address-district-input')),
            'District 8, Sheikh Zayed',
          );
          await tester.enterText(
            find.byKey(const Key('address-gate-notes-input')),
            'Gate 2, Bell 5',
          );
          await tester.pump();

          final saveAddressBtn = find.byKey(const Key('save-address-btn'));
          await tester.ensureVisible(saveAddressBtn);
          await tester.pump();

          await _runAsyncAndWait(
            tester,
            action: () async {
              await tester.tap(saveAddressBtn);
            },
            until: () {
              final s = container.read(createBookingControllerProvider);
              if (s.addressCreationError != null) {
                throw StateError(
                  'Address creation failed: ${s.addressCreationError}',
                );
              }
              return !s.isCreatingAddress && s.selectedAddress != null;
            },
            description: 'Address created and selected on Screen 04',
          );

          expect(find.text('Zayed Web Residence'), findsOneWidget);

          // -------------------------------------------------------------------
          // STEP 7: Select Schedule Window, Enter Issue Notes & Submit Draft
          // -------------------------------------------------------------------
          final afternoonWindow = find.text('Afternoon Window');
          await tester.ensureVisible(afternoonWindow);
          await _pumpFrames(tester);
          await tester.tap(afternoonWindow);
          await tester.pump();

          final issueInput = find.byKey(
            const Key('booking-issue-description-input'),
          );
          await tester.ensureVisible(issueInput);
          await tester.enterText(
            issueInput,
            'Web Chrome full UI booking-to-checkout verification.',
          );
          await tester.pump();

          final confirmDraftBtn = find.byKey(
            const Key('confirm-booking-draft-btn'),
          );
          await tester.ensureVisible(confirmDraftBtn);
          await _pumpFrames(tester);

          // Tap Confirm Draft and wait for GoRouter navigation to Screen 05
          await _runAsyncAndWait(
            tester,
            action: () async {
              await tester.tap(confirmDraftBtn);
            },
            until: () {
              final s = container.read(createBookingControllerProvider);
              if (s.errorMessage != null) {
                throw StateError(
                  'Draft booking submission failed: ${s.errorMessage}',
                );
              }
              final path = container
                  .read(appRouterProvider)
                  .routeInformationProvider
                  .value
                  .uri
                  .path;
              return RegExp(
                r'^/customer/bookings/[^/]+/checkout$',
              ).hasMatch(path);
            },
            description: 'GoRouter navigates to Screen 05 checkout route',
          );

          final routePath = container
              .read(appRouterProvider)
              .routeInformationProvider
              .value
              .uri
              .path;
          final routeMatch = RegExp(
            r'^/customer/bookings/([^/]+)/checkout$',
          ).firstMatch(routePath);
          expect(routeMatch, isNotNull);
          final createdBookingId = routeMatch!.group(1)!;
          expect(createdBookingId, isNotEmpty);

          // Wait for Screen 05 CheckoutController to finish loading booking
          await _runAsyncAndWait(
            tester,
            until: () {
              final s = container.read(
                checkoutControllerProvider(createdBookingId),
              );
              if (s.errorMessage != null) {
                throw StateError('Checkout load failed: ${s.errorMessage}');
              }
              return !s.isLoading && s.booking != null;
            },
            description: 'CheckoutController loads booking $createdBookingId',
          );

          // -------------------------------------------------------------------
          // STEP 8: Screen 05 UI Verification & Cash on Service Submission
          // -------------------------------------------------------------------
          expect(find.text('Payment'), findsOneWidget);
          expect(
            find.text('Summer AC Deep Clean & Gas Refill'),
            findsOneWidget,
          );
          expect(find.text('Cash Collection After Service'), findsOneWidget);

          // Standalone "0 EGP" must be absent
          expect(
            find.descendant(
              of: find.byType(CheckoutOrderSummaryCard),
              matching: find.text('0 EGP'),
            ),
            findsNothing,
          );
          expect(find.text('0 EGP'), findsNothing);
          expect(find.text('0 ج.م'), findsNothing);

          // Clarified payment schedule rows
          expect(find.text('Due now: 0 EGP'), findsOneWidget);
          expect(find.text('Due after service: 350 EGP'), findsOneWidget);

          final cashMethodTile = find.byKey(
            const Key('payment-method-cash-on-service'),
          );
          await tester.ensureVisible(cashMethodTile);
          await tester.tap(cashMethodTile);
          await tester.pump();

          final confirmCheckoutBtn = find.byKey(
            const Key('confirm-checkout-btn'),
          );
          await tester.ensureVisible(confirmCheckoutBtn);
          await _pumpFrames(tester);

          await _runAsyncAndWait(
            tester,
            action: () async {
              await tester.tap(confirmCheckoutBtn);
            },
            until: () {
              final s = container.read(
                checkoutControllerProvider(createdBookingId),
              );
              if (s.errorMessage != null) {
                throw StateError('Checkout submit failed: ${s.errorMessage}');
              }
              return s.checkoutSuccess;
            },
            description: 'CheckoutController confirms CASH_ON_SERVICE',
          );

          // -------------------------------------------------------------------
          // STEP 9: Confirmation View & Reopen Same Booking Through the App
          // -------------------------------------------------------------------
          expect(find.byType(CheckoutConfirmationView), findsOneWidget);
          expect(
            find.text('Booking Confirmed — Pending Dispatch'),
            findsOneWidget,
          );
          final orderCodeFinder = find.byKey(
            const Key('checkout-order-code-text'),
          );
          expect(orderCodeFinder, findsOneWidget);
          final uiOrderCodeLabel =
              tester.widget<Text>(orderCodeFinder).data ?? '';
          expect(uiOrderCodeLabel, contains('#'));
          final expectedOrderCode = uiOrderCodeLabel.split('#').last.trim();
          expect(expectedOrderCode, isNotEmpty);

          // Return to Customer Home via UI button
          final returnHomeBtn = find.byKey(
            const Key('checkout-return-home-btn'),
          );
          await tester.ensureVisible(returnHomeBtn);
          await _pumpFrames(tester);
          await tester.tap(returnHomeBtn);
          await _pumpFrames(tester, 10);

          expect(find.byType(CheckoutConfirmationView), findsNothing);
          expect(find.text('FIXO'), findsWidgets);

          // Reopen the exact same booking through the app router
          await _runAsyncAndWait(
            tester,
            action: () async {
              container
                  .read(appRouterProvider)
                  .go('/customer/bookings/$createdBookingId/checkout');
            },
            until: () {
              final s = container.read(
                checkoutControllerProvider(createdBookingId),
              );
              return !s.isLoading && s.booking != null && s.checkoutSuccess;
            },
            description: 'Reopened CheckoutPage loads existing confirmation',
          );

          expect(find.byType(CheckoutConfirmationView), findsOneWidget);
          expect(
            find.text('Booking Confirmed — Pending Dispatch'),
            findsOneWidget,
          );
          expect(
            tester
                .widget<Text>(find.byKey(const Key('checkout-order-code-text')))
                .data,
            equals(uiOrderCodeLabel),
          );

          // -------------------------------------------------------------------
          // STEP 10: Verify Persisted State & Idempotent Retry on Port 3002
          // -------------------------------------------------------------------
          final bookingRepo = container.read(bookingRepositoryProvider);
          late BookingDetailModel verifiedBooking;
          late BookingDetailModel retryResult;

          await tester.runAsync(() async {
            verifiedBooking = await bookingRepo.getBookingById(
              createdBookingId,
            );
            retryResult = await bookingRepo.checkoutBooking(
              createdBookingId,
              paymentMethod: 'CASH_ON_SERVICE',
            );
          });

          expect(verifiedBooking.id, equals(createdBookingId));
          expect(verifiedBooking.orderCode, equals(expectedOrderCode));
          expect(verifiedBooking.status, equals('PENDING_DISPATCH'));
          expect(verifiedBooking.payment, isNotNull);
          expect(verifiedBooking.payment?.method, equals('CASH_ON_SERVICE'));
          expect(verifiedBooking.payment?.status, equals('PENDING'));
          expect(verifiedBooking.payment?.paidAt, isNull);
          expect(verifiedBooking.payment?.amountEgp, equals(350));

          expect(retryResult.id, equals(createdBookingId));
          expect(retryResult.status, equals('PENDING_DISPATCH'));
          expect(retryResult.payment?.id, equals(verifiedBooking.payment?.id));
          expect(retryResult.payment?.method, equals('CASH_ON_SERVICE'));
          expect(retryResult.payment?.status, equals('PENDING'));
          expect(retryResult.payment?.paidAt, isNull);
        },
      );
    },
    skip: _runLiveWebE2e
        ? false
        : 'Live Web E2E is opt-in: pass --dart-define=FIXO_LIVE_WEB_E2E=true',
  );
}
