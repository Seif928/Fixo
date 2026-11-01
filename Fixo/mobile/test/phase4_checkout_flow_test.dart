import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/payment/presentation/pages/checkout_page.dart';

/// Fake repository for deterministic Screen 05 (Checkout) testing.
class FakeCheckoutBookingRepository implements BookingRepository {
  bool shouldFailGetBooking = false;
  String getBookingErrorMessage = 'Server connection error';

  bool shouldFailCheckout = false;
  String checkoutErrorMessage = 'Checkout transition failed';

  int checkoutCallCount = 0;
  String? lastCheckoutBookingId;
  String? lastCheckoutPaymentMethod;
  bool shouldThrowPricingDataError = false;

  BookingDetailModel? currentBooking;

  @override
  Future<BookingDetailModel> getBookingById(String bookingId) async {
    if (shouldThrowPricingDataError) {
      throw const FormatException('Missing or invalid required price: baseInspectionEgp');
    }

    if (shouldFailGetBooking) {
      throw DioException(
        requestOptions: RequestOptions(path: '/bookings/$bookingId'),
        response: Response(
          requestOptions: RequestOptions(path: '/bookings/$bookingId'),
          statusCode: 500,
          data: {'message': getBookingErrorMessage},
        ),
      );
    }

    return currentBooking ??
        BookingDetailModel(
          id: bookingId,
          orderCode: 'FX-8842',
          customerId: 'cust-101',
          offeringId: 'off-ac-clean',
          addressId: 'addr-01',
          status: 'DRAFT',
          scheduledDate: '2026-11-05',
          timeWindow: 'AFTERNOON_13_16',
          pricing: const BookingPricingModel(
            baseInspectionEgp: 150,
            serviceFeeEgp: 250,
            transportFeeEgp: 0,
            totalEgp: 400,
          ),
          offering: const {
            'id': 'off-ac-clean',
            'titleEn': 'AC Deep Cleaning & Wash',
            'titleAr': 'تنظيف عميق وغسيل تكييف',
          },
          address: const {
            'id': 'addr-01',
            'label': 'Home Apartment',
            'districtLine': 'Sheikh Zayed, Dist. 9',
          },
          arrivalPinCode: '5841', // Invariant: must NEVER be displayed on Screen 05!
          createdAt: '2026-11-01T07:00:00.000Z',
        );
  }

  @override
  Future<BookingDetailModel> checkoutBooking(
    String bookingId, {
    String paymentMethod = 'CASH_ON_SERVICE',
  }) async {
    checkoutCallCount++;
    lastCheckoutBookingId = bookingId;
    lastCheckoutPaymentMethod = paymentMethod;

    if (shouldFailCheckout) {
      throw DioException(
        requestOptions: RequestOptions(path: '/bookings/$bookingId/checkout'),
        response: Response(
          requestOptions: RequestOptions(path: '/bookings/$bookingId/checkout'),
          statusCode: 400,
          data: {'message': checkoutErrorMessage},
        ),
      );
    }

    final updated = BookingDetailModel(
      id: bookingId,
      orderCode: 'FX-8842',
      customerId: 'cust-101',
      offeringId: 'off-ac-clean',
      addressId: 'addr-01',
      status: 'PENDING_DISPATCH',
      scheduledDate: '2026-11-05',
      timeWindow: 'AFTERNOON_13_16',
      pricing: const BookingPricingModel(
        baseInspectionEgp: 150,
        serviceFeeEgp: 250,
        transportFeeEgp: 0,
        totalEgp: 400,
      ),
      offering: const {
        'id': 'off-ac-clean',
        'titleEn': 'AC Deep Cleaning & Wash',
        'titleAr': 'تنظيف عميق وغسيل تكييف',
      },
      address: const {
        'id': 'addr-01',
        'label': 'Home Apartment',
        'districtLine': 'Sheikh Zayed, Dist. 9',
      },
      payment: PaymentRecordModel(
        id: 'pay-uuid-01',
        bookingId: bookingId,
        method: paymentMethod,
        status: 'PENDING',
        amountEgp: 400,
        createdAt: '2026-11-01T07:30:00.000Z',
      ),
      arrivalPinCode: '5841',
      createdAt: '2026-11-01T07:00:00.000Z',
    );

    currentBooking = updated;
    return updated;
  }

  @override
  Future<BookingDetailModel> createBooking(CreateBookingRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<List<BookingDetailModel>> getBookings({
    String? tab,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CustomerAddressModel> createAddress(CreateAddressRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerAddressModel>> getCustomerAddresses() async {
    throw UnimplementedError();
  }

  @override
  Future<List<CoverageZoneModel>> getCoverageZones() async {
    throw UnimplementedError();
  }
}

void main() {
  late FakeCheckoutBookingRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeCheckoutBookingRepository();
  });

  Widget buildTestableApp({
    String bookingId = 'bk-test-8842',
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FixoTheme.light(locale: locale),
        darkTheme: FixoTheme.dark(locale: locale),
        themeMode: themeMode,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          );
        },
        home: CheckoutPage(bookingId: bookingId),
      ),
    );
  }

  group('Screen 05: Real Booking Details & Layout Rendering', () {
    testWidgets('loads and renders real order code, offering, address, and EGP fare breakdown',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Payment'), findsOneWidget);

      // Reassurance Banner (Neutral cash-on-service copy)
      expect(find.text('Cash on Service Checkout'), findsOneWidget);
      expect(find.text('Cash'), findsWidgets);

      // Order Summary Card
      expect(find.text('AC Deep Cleaning & Wash'), findsOneWidget);
      expect(find.text('#FX-8842'), findsOneWidget);
      expect(find.text('Verified Service'), findsOneWidget);
      expect(find.text('Home Apartment, Sheikh Zayed, Dist. 9'), findsOneWidget);
      expect(find.text('Cash Collection After Service'), findsOneWidget);
      expect(find.text('0 EGP'), findsNothing);

      // Payment Methods Section
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Cash to Artisan'), findsOneWidget);
      expect(find.text('Active in MVP'), findsOneWidget);
      expect(
        find.text(
          'Hand cash in EGP only after job completed & inspected',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Cash is collected in person by the technician only after service is performed and inspected. No upfront charge.',
        ),
        findsOneWidget,
      );

      // Disabled Methods have "Coming Soon" badge
      expect(find.text('InstaPay Egypt'), findsOneWidget);
      expect(find.text('Smart Wallets'), findsOneWidget);
      expect(find.text('Cards & Meeza'), findsOneWidget);
      expect(find.text('Fawry Pay Kiosk'), findsOneWidget);
      expect(find.text('Coming Soon'), findsNWidgets(4));

      // Receipt Breakdown with actual booking pricing rows
      expect(find.text('Receipt Breakdown'), findsOneWidget);
      expect(find.text('Base Inspection Fee'), findsOneWidget);
      expect(find.text('150 EGP'), findsOneWidget);
      expect(find.text('Service Fee'), findsOneWidget);
      expect(find.text('250 EGP'), findsOneWidget);
      expect(find.text('Transport Fee'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('Total Amount Due'), findsOneWidget);
      expect(find.text('400 EGP'), findsWidgets);
      expect(find.text('Due now: 0 EGP'), findsOneWidget);
      expect(find.text('Due after service: 400 EGP'), findsOneWidget);

      // Sticky Bottom CTA
      expect(find.text('Due Upon Completion'), findsOneWidget);
      expect(find.text('Confirm Booking (Pay Cash Later)'), findsOneWidget);
      expect(find.byKey(const Key('confirm-checkout-btn')), findsOneWidget);

      // Cash policy footnote
      expect(find.text('Cash on Service Policy'), findsOneWidget);

      // Invariant: arrival PIN must NEVER be displayed!
      expect(find.text('5841'), findsNothing);
    });

    testWidgets('renders receipt rows from actual booking pricing with nonzero transport fee',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeRepo.currentBooking = const BookingDetailModel(
        id: 'bk-nonzero-transport',
        orderCode: 'FX-9901',
        customerId: 'cust-101',
        offeringId: 'off-ac-clean',
        addressId: 'addr-01',
        status: 'DRAFT',
        scheduledDate: '2026-11-06',
        timeWindow: 'MORNING_09_12',
        pricing: BookingPricingModel(
          baseInspectionEgp: 150,
          serviceFeeEgp: 300,
          transportFeeEgp: 75,
          totalEgp: 525,
        ),
        offering: {
          'id': 'off-ac-clean',
          'titleEn': 'AC Deep Cleaning & Wash',
        },
        address: {
          'id': 'addr-01',
          'label': 'Villa 42',
          'districtLine': 'New Cairo',
        },
        createdAt: '2026-11-01T07:00:00.000Z',
      );

      await tester.pumpWidget(buildTestableApp(bookingId: 'bk-nonzero-transport'));
      await tester.pumpAndSettle();

      // Inspection fee
      expect(find.text('Base Inspection Fee'), findsOneWidget);
      expect(find.text('150 EGP'), findsOneWidget);

      // Service fee
      expect(find.text('Service Fee'), findsOneWidget);
      expect(find.text('300 EGP'), findsOneWidget);

      // Transport fee shows actual nonzero amount, NEVER free
      expect(find.text('Transport Fee'), findsOneWidget);
      expect(find.text('75 EGP'), findsOneWidget);
      expect(find.text('FREE'), findsNothing);

      // Total amount due is calculated correctly (150 + 300 + 75 = 525)
      expect(find.text('Total Amount Due'), findsOneWidget);
      expect(find.text('525 EGP'), findsWidgets);
      expect(find.text('Due now: 0 EGP'), findsOneWidget);
      expect(find.text('Due after service: 525 EGP'), findsOneWidget);
      expect(find.text('0 EGP'), findsNothing);
    });
  });

  group('Screen 05: Cash on Service Checkout Submission & Confirmation', () {
    testWidgets('submits CASH_ON_SERVICE and transitions to confirmed state with honest copy',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap Confirm Booking
      await tester.tap(find.byKey(const Key('confirm-checkout-btn')));
      await tester.pumpAndSettle();

      // Verify repository checkout invocation
      expect(fakeRepo.checkoutCallCount, 1);
      expect(fakeRepo.lastCheckoutBookingId, 'bk-test-8842');
      expect(fakeRepo.lastCheckoutPaymentMethod, 'CASH_ON_SERVICE');

      // Verify Confirmation View is rendered
      expect(find.byKey(const Key('checkout-confirmation-view')), findsOneWidget);
      expect(find.text('Booking Confirmed — Pending Dispatch'), findsOneWidget);
      expect(find.byKey(const Key('checkout-order-code-text')), findsOneWidget);
      expect(find.text('Order Code: #FX-8842'), findsOneWidget);

      // Verify honest cash collection explanation
      expect(
        find.text(
          'Cash of 400 EGP will be collected in person by the technician only after service is completed and inspected.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your request is in the dispatch queue. You will be notified as soon as a qualified artisan accepts your request.',
        ),
        findsOneWidget,
      );

      // Invariants:
      // Never display arrival PIN
      expect(find.text('5841'), findsNothing);
      // Return to home button exists
      expect(find.byKey(const Key('checkout-return-home-btn')), findsOneWidget);
    });

    testWidgets('prevents duplicate taps while submission is in progress',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap once
      await tester.tap(find.byKey(const Key('confirm-checkout-btn')));
      // Immediately try to tap again while in flight
      await tester.tap(find.byKey(const Key('confirm-checkout-btn')));
      await tester.pumpAndSettle();

      // Repository must have received strictly ONE checkout call
      expect(fakeRepo.checkoutCallCount, 1);
    });
  });

  group('Screen 05: Reopening Already Checked-Out Booking', () {
    testWidgets('directly displays confirmation view when reopened with PENDING_DISPATCH status',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-configure booking as already checked out in PENDING_DISPATCH
      fakeRepo.currentBooking = BookingDetailModel(
        id: 'bk-already-checked-out',
        orderCode: 'FX-9911',
        customerId: 'cust-101',
        offeringId: 'off-ac-clean',
        addressId: 'addr-01',
        status: 'PENDING_DISPATCH',
        scheduledDate: '2026-11-06',
        timeWindow: 'MORNING_09_12',
        pricing: const BookingPricingModel(
          baseInspectionEgp: 150,
          serviceFeeEgp: 200,
          transportFeeEgp: 0,
          totalEgp: 350,
        ),
        payment: const PaymentRecordModel(
          id: 'pay-pre-existing',
          bookingId: 'bk-already-checked-out',
          method: 'CASH_ON_SERVICE',
          status: 'PENDING',
          amountEgp: 350,
          createdAt: '2026-11-01T06:00:00.000Z',
        ),
        arrivalPinCode: '9123',
        createdAt: '2026-11-01T05:00:00.000Z',
      );

      await tester.pumpWidget(buildTestableApp(bookingId: 'bk-already-checked-out'));
      await tester.pumpAndSettle();

      // Confirmation view must immediately appear without user tapping confirm
      expect(find.byKey(const Key('checkout-confirmation-view')), findsOneWidget);
      expect(find.text('Booking Confirmed — Pending Dispatch'), findsOneWidget);
      expect(find.text('Order Code: #FX-9911'), findsOneWidget);
      expect(fakeRepo.checkoutCallCount, 0); // No extra checkout POST call made
      expect(find.text('9123'), findsNothing); // Arrival PIN never exposed!
    });
  });

  group('Screen 05: Error Handling & Retry States', () {
    testWidgets('displays error state and retries successfully when initial load fails',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeRepo.shouldFailGetBooking = true;
      fakeRepo.getBookingErrorMessage = 'Booking not found.';

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('Booking not found.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Fix error and tap Retry
      fakeRepo.shouldFailGetBooking = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Now loaded successfully
      expect(find.text('AC Deep Cleaning & Wash'), findsOneWidget);
      expect(find.text('Confirm Booking (Pay Cash Later)'), findsOneWidget);
    });

    testWidgets('displays error banner when checkout POST request fails and allows retry',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Make checkout fail
      fakeRepo.shouldFailCheckout = true;
      fakeRepo.checkoutErrorMessage = 'Unable to checkout booking';

      await tester.tap(find.byKey(const Key('confirm-checkout-btn')));
      await tester.pumpAndSettle();

      // Error banner must be visible
      expect(find.text('Unable to checkout booking'), findsOneWidget);
      expect(find.byKey(const Key('confirm-checkout-btn')), findsOneWidget);

      // Fix and retry
      fakeRepo.shouldFailCheckout = false;
      await tester.tap(find.byKey(const Key('confirm-checkout-btn')));
      await tester.pumpAndSettle();

      // Transitioned to confirmation view
      expect(find.byKey(const Key('checkout-confirmation-view')), findsOneWidget);
    });

    testWidgets('displays handled error state and retry button when pricing data is missing or invalid',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeRepo.shouldThrowPricingDataError = true;

      await tester.pumpWidget(buildTestableApp(bookingId: 'bk-corrupt-pricing'));
      await tester.pumpAndSettle();

      // Displays error state icon and message
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(
        find.textContaining('Missing or invalid required price'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      // Bottom bar action is disabled/not rendered
      expect(find.byKey(const Key('confirm-checkout-btn')), findsNothing);

      // Fix and retry recovers
      fakeRepo.shouldThrowPricingDataError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Receipt Breakdown'), findsOneWidget);
      expect(find.byKey(const Key('confirm-checkout-btn')), findsOneWidget);
    });
  });

  group('BookingPricingModel Parsing & Data Integrity', () {
    test('parses valid pricing without fallback defaults', () {
      final json = {
        'baseInspectionEgp': 120,
        'serviceFeeEgp': 180,
        'transportFeeEgp': 50,
        'totalEgp': 350,
        'platformFeeEgp': 35,
        'currency': 'EGP',
      };

      final pricing = BookingPricingModel.fromJson(json);
      expect(pricing.baseInspectionEgp, 120);
      expect(pricing.serviceFeeEgp, 180);
      expect(pricing.transportFeeEgp, 50);
      expect(pricing.totalEgp, 350);
      expect(pricing.platformFeeEgp, 35);
      expect(pricing.currency, 'EGP');
    });

    test('throws FormatException when baseInspectionEgp is missing or negative', () {
      expect(
        () => BookingPricingModel.fromJson({
          'serviceFeeEgp': 200,
          'transportFeeEgp': 0,
          'totalEgp': 200,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => BookingPricingModel.fromJson({
          'baseInspectionEgp': -10,
          'serviceFeeEgp': 200,
          'transportFeeEgp': 0,
          'totalEgp': 200,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when serviceFeeEgp is missing or negative', () {
      expect(
        () => BookingPricingModel.fromJson({
          'baseInspectionEgp': 150,
          'transportFeeEgp': 0,
          'totalEgp': 150,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when transportFeeEgp is missing or negative', () {
      expect(
        () => BookingPricingModel.fromJson({
          'baseInspectionEgp': 150,
          'serviceFeeEgp': 250,
          'totalEgp': 400,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when totalEgp is missing or negative', () {
      expect(
        () => BookingPricingModel.fromJson({
          'baseInspectionEgp': 150,
          'serviceFeeEgp': 250,
          'transportFeeEgp': 0,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('BookingDetailModel.fromJson throws FormatException when pricing is missing', () {
      final json = {
        'id': 'bk-missing-pricing',
        'orderCode': 'FX-1234',
        'customerId': 'cust-1',
        'offeringId': 'off-1',
        'addressId': 'addr-1',
        'status': 'DRAFT',
        'scheduledDate': '2026-11-05',
        'timeWindow': 'MORNING_09_12',
      };

      expect(
        () => BookingDetailModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Screen 05: Viewports (360/390/412dp), RTL & Text Scaling (1.35x)', () {
    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets('renders cleanly without overflow at ${width.toInt()}dp logical width and 1.35x text scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestableApp(textScale: 1.35));
        await tester.pumpAndSettle();

        expect(find.text('Payment'), findsOneWidget);
        expect(find.text('Receipt Breakdown'), findsOneWidget);
        expect(find.byKey(const Key('confirm-checkout-btn')), findsOneWidget);

        // Zero exceptions / RenderFlex overflows
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('supports Arabic RTL rendering cleanly without overflows',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('الدفع'), findsOneWidget);
      expect(find.text('الدفع نقداً للفني'), findsOneWidget);
      expect(find.text('تفاصيل الفاتورة'), findsOneWidget);
      expect(find.text('تأكيد الحجز (دفع نقدي لاحقاً)'), findsOneWidget);
      expect(find.text('تحصيل نقدي بعد اكتمال الخدمة'), findsOneWidget);
      expect(find.text('المستحق الآن: 0 ج.م'), findsOneWidget);
      expect(find.text('المستحق بعد الخدمة: 400 ج.م'), findsOneWidget);
      expect(find.text('0 ج.م'), findsNothing);
      expect(find.text('0 EGP'), findsNothing);

      expect(tester.takeException(), isNull);
    });
  });

  group('Screen 05: Clarified Checkout Summary & Arabic Localization (M1)', () {
    testWidgets('displays explicit Due now and Due after service rows and omits standalone 0 EGP in English',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // 1. Order Summary Card: Title is present, standalone '0 EGP' is ABSENT
      expect(find.text('Cash Collection After Service'), findsOneWidget);
      expect(find.text('0 EGP'), findsNothing);

      // 2. Receipt Card: Clarification summary rows are explicitly rendered
      expect(find.text('Due now: 0 EGP'), findsOneWidget);
      expect(find.text('Due after service: 400 EGP'), findsOneWidget);
    });

    testWidgets('displays explicit Arabic translations for summary rows and omits standalone 0 ج.م in RTL mode',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      // 1. Order Summary Card in Arabic: Title present, standalone '0 ج.م' or '0 EGP' ABSENT
      expect(find.text('تحصيل نقدي بعد اكتمال الخدمة'), findsOneWidget);
      expect(find.text('0 ج.م'), findsNothing);
      expect(find.text('0 EGP'), findsNothing);

      // 2. Receipt Card in Arabic: Explicit Arabic clarification rows
      expect(find.text('المستحق الآن: 0 ج.م'), findsOneWidget);
      expect(find.text('المستحق بعد الخدمة: 400 ج.م'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('dynamically calculates Due after service row for custom booking totals in English and Arabic',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeRepo.currentBooking = const BookingDetailModel(
        id: 'bk-custom-pricing',
        orderCode: 'FX-7733',
        customerId: 'cust-101',
        offeringId: 'off-ac-clean',
        addressId: 'addr-01',
        status: 'DRAFT',
        scheduledDate: '2026-11-08',
        timeWindow: 'MORNING_09_12',
        pricing: BookingPricingModel(
          baseInspectionEgp: 200,
          serviceFeeEgp: 650,
          transportFeeEgp: 150,
          totalEgp: 1000,
        ),
        offering: {
          'id': 'off-ac-clean',
          'titleEn': 'AC Deep Cleaning & Wash',
          'titleAr': 'تنظيف عميق وغسيل تكييف',
        },
        address: {
          'id': 'addr-01',
          'label': 'Villa 12',
          'districtLine': '6th of October',
        },
        createdAt: '2026-11-01T07:00:00.000Z',
      );

      // Test English
      await tester.pumpWidget(buildTestableApp(bookingId: 'bk-custom-pricing'));
      await tester.pumpAndSettle();

      expect(find.text('Due now: 0 EGP'), findsOneWidget);
      expect(find.text('Due after service: 1000 EGP'), findsOneWidget);
      expect(find.text('0 EGP'), findsNothing);

      // Test Arabic
      await tester.pumpWidget(buildTestableApp(
        bookingId: 'bk-custom-pricing',
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('المستحق الآن: 0 ج.م'), findsOneWidget);
      expect(find.text('المستحق بعد الخدمة: 1000 ج.م'), findsOneWidget);
      expect(find.text('0 ج.م'), findsNothing);
      expect(find.text('0 EGP'), findsNothing);
    });
  });
}
