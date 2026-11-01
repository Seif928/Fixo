import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixo_mobile/core/network/dio_client.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/payment/presentation/controllers/checkout_controller.dart';
import 'package:fixo_mobile/features/payment/presentation/pages/checkout_page.dart';
import 'package:fixo_mobile/features/payment/presentation/widgets/checkout_widgets.dart';

void main() {
  setUpAll(() {
    // Disable TestWidgetsFlutterBinding default 400-mocking to permit real HTTP I/O in Chrome
    HttpOverrides.global = null;
  });

  group('Milestone M4: Flutter Web Chrome Booking-to-Checkout Journey (Port 3002)', () {
    const baseUrl = String.fromEnvironment(
      'FIXO_API_BASE_URL',
      defaultValue: 'http://localhost:3002/api/v1',
    );

    late Dio dio;
    late VaultTokenStorage tokenStorage;
    late DioAuthRepository authRepo;
    late DioMarketplaceRepository marketplaceRepo;
    late BookingRepository bookingRepo;

    setUp(() {
      HttpOverrides.global = null;
      tokenStorage = VaultTokenStorage();
      dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final accessToken = await tokenStorage.readAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
            handler.next(options);
          },
        ),
      );

      authRepo = DioAuthRepository(dio);
      marketplaceRepo = DioMarketplaceRepository(dio);
      bookingRepo = BookingRepository(dio);
    });

    testWidgets(
      'Full Customer Journey on Web: Auth -> Marketplace -> Address -> Draft -> Screen 05 (Desktop 1280x800) -> Cash Checkout -> Invariants & Idempotency',
      (WidgetTester tester) async {
        HttpOverrides.global = null;

        // Dynamic Egyptian phone number generator (+2010XXXXXXXX) to bypass 45s resend cooldown
        final phoneDigits = (DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0');
        final testPhone = '+2010$phoneDigits';

        late OtpChallengeResult challenge;
        late AuthSession session;
        late CustomerAddressModel address;
        late BookingDetailModel draftBooking;

        // Steps 1 to 5: Real API setup run inside tester.runAsync to allow browser network I/O
        await tester.runAsync(() async {
          // 1. Real Dev OTP Authentication
          challenge = await authRepo.requestOtp(phone: testPhone);
          expect(challenge.phone, isNotEmpty);

          session = await authRepo.verifyOtp(
            phone: testPhone,
            code: '482910',
            challengeId: challenge.challengeId,
          );
          expect(session.accessToken, isNotEmpty);
          expect(session.user.id, isNotEmpty);

          await tokenStorage.saveTokens(
            StoredAuthTokens(
              accessToken: session.accessToken,
              refreshToken: session.refreshToken,
              userId: session.user.id,
              phone: session.user.phone,
              role: session.user.role,
            ),
          );

          // 2. Marketplace Catalog Selection
          final feed = await marketplaceRepo.fetchCustomerHomeFeed();
          expect(feed.zones, isNotEmpty);
          expect(feed.services, isNotEmpty);

          final zone = feed.zones.first;
          final offering = feed.seasonalPromo ?? feed.services.first;

          // 3. Customer Address Creation
          address = await bookingRepo.createAddress(
            CreateAddressRequest(
              zoneId: zone.id,
              label: 'Zayed Web E2E Office',
              buildingLine: 'Building 12, Floor 3',
              districtLine: 'District 9, Sheikh Zayed',
              gateNotes: 'Web Test Gate 4',
              isDefault: true,
            ),
          );
          expect(address.id, isNotEmpty);

          // 4. Draft Booking Creation
          draftBooking = await bookingRepo.createBooking(
            CreateBookingRequest(
              offeringId: offering.id,
              addressId: address.id,
              scheduledDate: '2026-11-10',
              timeWindow: 'AFTERNOON_13_16',
              issueDescription: 'Chrome Web E2E Verification Test',
            ),
          );
          expect(draftBooking.id, isNotEmpty);
          expect(draftBooking.status, equals('DRAFT'));
          expect(draftBooking.pricing.totalEgp, greaterThan(0));
        });

        // Step 5: Screen 05 Navigation & Desktop 1280x800 Viewport
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final container = ProviderContainer(
          overrides: [
            secureTokenStorageProvider.overrideWithValue(tokenStorage),
            dioClientProvider.overrideWithValue(dio),
            bookingRepositoryProvider.overrideWithValue(bookingRepo),
          ],
        );
        addTearDown(container.dispose);

        await tester.runAsync(() async {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: FixoTheme.light(),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en'), Locale('ar')],
                home: CheckoutPage(bookingId: draftBooking.id),
              ),
            ),
          );

          // Bounded polling loop awaiting async loadBooking completion
          for (int i = 0; i < 50; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            final state = container.read(checkoutControllerProvider(draftBooking.id));
            if (!state.isLoading) break;
          }
        });
        await tester.pump();

        final loadedState = container.read(checkoutControllerProvider(draftBooking.id));
        expect(loadedState.isLoading, isFalse);
        expect(loadedState.booking, isNotNull);

        // Step 6: Summary Rows and Standalone "0 EGP" Absence Assertions
        expect(find.text('Due now: 0 EGP'), findsOneWidget);
        expect(find.text('Due after service: ${draftBooking.pricing.totalEgp} EGP'), findsOneWidget);

        final cashCard = find.byType(CheckoutOrderSummaryCard);
        expect(cashCard, findsOneWidget);
        expect(
          find.descendant(of: cashCard, matching: find.text('0 EGP')),
          findsNothing,
        );
        expect(find.text('0 EGP'), findsNothing);
        expect(find.text('0 ج.م'), findsNothing);
        expect(tester.takeException(), isNull);

        // Step 7: Cash Checkout Confirmation
        final confirmBtn = find.byKey(const Key('confirm-checkout-btn'));
        expect(confirmBtn, findsOneWidget);

        await tester.runAsync(() async {
          await tester.tap(confirmBtn);
          for (int i = 0; i < 50; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            final state = container.read(checkoutControllerProvider(draftBooking.id));
            if (state.checkoutSuccess) break;
          }
        });
        await tester.pump();

        final confirmedState = container.read(checkoutControllerProvider(draftBooking.id));
        expect(confirmedState.checkoutSuccess, isTrue);

        // Step 8: Confirmation View Assertions
        expect(find.byType(CheckoutConfirmationView), findsOneWidget);
        expect(find.text('Booking Confirmed — Pending Dispatch'), findsOneWidget);
        expect(find.byKey(const Key('checkout-order-code-text')), findsOneWidget);
        expect(find.byKey(const Key('checkout-return-home-btn')), findsOneWidget);
        if (draftBooking.arrivalPinCode != null && draftBooking.arrivalPinCode!.isNotEmpty) {
          expect(find.text(draftBooking.arrivalPinCode!), findsNothing);
        }

        // Step 9: Database Invariant Assertions on Port 3002
        late BookingDetailModel verifiedBooking;
        await tester.runAsync(() async {
          verifiedBooking = await bookingRepo.getBookingById(draftBooking.id);
        });
        expect(verifiedBooking.status, equals('PENDING_DISPATCH'));
        expect(verifiedBooking.payment, isNotNull);
        expect(verifiedBooking.payment?.method, equals('CASH_ON_SERVICE'));
        expect(verifiedBooking.payment?.status, equals('PENDING'));
        expect(verifiedBooking.payment?.paidAt, isNull);
        expect(verifiedBooking.payment?.amountEgp, equals(draftBooking.pricing.totalEgp));

        // Step 10: Idempotent Retry Assertion
        late BookingDetailModel retryResult;
        await tester.runAsync(() async {
          retryResult = await bookingRepo.checkoutBooking(
            draftBooking.id,
            paymentMethod: 'CASH_ON_SERVICE',
          );
        });
        expect(retryResult.status, equals('PENDING_DISPATCH'));
        expect(retryResult.payment?.status, equals('PENDING'));
        expect(retryResult.payment?.method, equals('CASH_ON_SERVICE'));
        expect(retryResult.payment?.paidAt, isNull);
      },
    );

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
          address: {'id': 'addr-01', 'label': 'Home', 'districtLine': 'Zayed'},
          arrivalPinCode: '1122',
          createdAt: '2026-11-01T07:00:00.000Z',
        );

        // 1. Desktop 1920x1080
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

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
          find.descendant(of: find.byType(CheckoutOrderSummaryCard), matching: find.text('0 EGP')),
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
        addTearDown(() => tester.view.resetPhysicalSize());

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
          address: {'id': 'addr-01', 'label': 'المنزل', 'districtLine': 'الشيخ زايد'},
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
          find.descendant(of: find.byType(CheckoutOrderSummaryCard), matching: find.text('0 ج.م')),
          findsNothing,
        );
        expect(
          find.descendant(of: find.byType(CheckoutOrderSummaryCard), matching: find.text('0 EGP')),
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
        addTearDown(() => tester.view.resetPhysicalSize());

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
          address: {'id': 'addr-01', 'label': 'المنزل', 'districtLine': 'الشيخ زايد'},
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
        expect(find.byKey(const Key('checkout-order-code-text')), findsOneWidget);
        expect(find.byKey(const Key('checkout-return-home-btn')), findsOneWidget);
        expect(find.text('7799'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
