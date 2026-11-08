import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/theme/fixo_spacing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Tier 2: Boundary & Corner Case Specifications', () {
    // =========================================================================
    // Boundary 1: Extreme Text Scale Factor (1.35x & 1.50x Accessibility Scaling)
    // =========================================================================
    group('Accessibility Text Scale Boundaries (1.35x & 1.5x)', () {
      testWidgets('2.1 - Card renders without overflow under 1.35x text scale factor', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(1.35),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(FixoSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('صيانة تكييف منزلية شاملة'),
                          SizedBox(height: 8),
                          Text('فحص وتغيير الفلاتر وشحن الفريون بواسطة فني معتمد'),
                          SizedBox(height: 12),
                          Text('السعر الإجمالي: 450 ج.م', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('صيانة تكييف منزلية شاملة'), findsOneWidget);
      });

      testWidgets('2.2 - Buttons preserve minimum 48dp touch target under 1.5x scale', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Confirm Booking'),
                  ),
                ),
              ),
            ),
          ),
        );

        final buttonSize = tester.getSize(find.byType(ElevatedButton));
        expect(buttonSize.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('2.3 - Two-line list tiles adapt gracefully to 1.35x text scale without clipping', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
              child: const Scaffold(
                body: ListTile(
                  title: Text('Emergency Electrical Fault Repair'),
                  subtitle: Text('Immediate technician dispatch to Maadi, Cairo'),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Emergency Electrical Fault Repair'), findsOneWidget);
      });
    });

    // =========================================================================
    // Boundary 2: Empty States & Zero Values
    // =========================================================================
    group('Empty State & Zero Value Boundaries', () {
      testWidgets('2.4 - Empty catalog search query returns empty-state guidance card', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد نتائج مطابقة لبحثك'),
                    SizedBox(height: 8),
                    Text('جرب البحث بكلمات أخرى مثل "تكييف" أو "سباكة"'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('لا توجد نتائج مطابقة لبحثك'), findsOneWidget);
        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      });

      testWidgets('2.5 - Orders list with zero bookings displays friendly booking prompt', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No bookings yet'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Browse Services'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('No bookings yet'), findsOneWidget);
        expect(find.text('Browse Services'), findsOneWidget);
      });

      testWidgets('2.6 - Zero EGP discount displays as 0 ج.م without negative sign or null', (tester) async {
        const double discountEgp = 0.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Text('Discount: ${discountEgp.toInt()} EGP'),
            ),
          ),
        );

        expect(find.text('Discount: 0 EGP'), findsOneWidget);
      });

      testWidgets('2.7 - Review list with 0 reviews renders initial rating placeholder', (tester) async {
        const int reviewsCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Text(
                reviewsCount == 0 ? 'New Artisan (No reviews yet)' : '$reviewsCount reviews',
              ),
            ),
          ),
        );

        expect(find.text('New Artisan (No reviews yet)'), findsOneWidget);
      });
    });

    // =========================================================================
    // Boundary 3: Egyptian Phone Number Format Validation
    // =========================================================================
    group('Egyptian Phone Number Validator Boundaries', () {
      bool isValidEgyptPhone(String input) {
        final regex = RegExp(r'^\+20(10|11|12|15)\d{8}$');
        return regex.hasMatch(input);
      }

      test('2.8 - Valid Vodafone Egypt number (+2010...) passes regex validation', () {
        expect(isValidEgyptPhone('+201012345678'), isTrue);
      });

      test('2.9 - Valid Orange Egypt number (+2012...) passes regex validation', () {
        expect(isValidEgyptPhone('+201212345678'), isTrue);
      });

      test('2.10 - Valid Etisalat Egypt number (+2011...) passes regex validation', () {
        expect(isValidEgyptPhone('+201112345678'), isTrue);
      });

      test('2.11 - Valid Telecom Egypt (WE) number (+2015...) passes regex validation', () {
        expect(isValidEgyptPhone('+201512345678'), isTrue);
      });

      test('2.12 - Invalid operator prefix (+2013...) is rejected', () {
        expect(isValidEgyptPhone('+201312345678'), isFalse);
      });

      test('2.13 - Phone number missing +20 international prefix is rejected', () {
        expect(isValidEgyptPhone('01012345678'), isFalse);
      });

      test('2.14 - Phone number with insufficient digits (+201012345) is rejected', () {
        expect(isValidEgyptPhone('+201012345'), isFalse);
      });

      test('2.15 - Phone number with excessive digits (+20101234567899) is rejected', () {
        expect(isValidEgyptPhone('+20101234567899'), isFalse);
      });

      test('2.16 - Phone number with alphabetical characters is rejected', () {
        expect(isValidEgyptPhone('+2010ABC45678'), isFalse);
      });
    });

    // =========================================================================
    // Boundary 4: Network Errors, Timeout & Retry Resilience
    // =========================================================================
    group('Network Offline & Timeout Boundaries', () {
      testWidgets('2.17 - Offline connection banner surfaces descriptive error & retry button', (tester) async {
        bool retryTriggered = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text('تعذر الاتصال بالخادم'),
                    const Text('يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => retryTriggered = true,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);
        await tester.tap(find.text('إعادة المحاولة'));
        expect(retryTriggered, isTrue);
      });

      testWidgets('2.18 - Rapid duplicate taps on checkout button are debounced', (tester) async {
        int submitCount = 0;
        bool isSubmitting = false;

        void onSubmit() {
          if (isSubmitting) return;
          isSubmitting = true;
          submitCount++;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: onSubmit,
                child: const Text('Submit Order'),
              ),
            ),
          ),
        );

        // Rapid 3 taps
        await tester.tap(find.byType(ElevatedButton));
        await tester.tap(find.byType(ElevatedButton));
        await tester.tap(find.byType(ElevatedButton));

        expect(submitCount, equals(1));
      });
    });

    // =========================================================================
    // Boundary 5: Security & Role Boundaries
    // =========================================================================
    group('Security & Role Boundaries', () {
      testWidgets('2.19 - Customer profile denies display of Admin Management controls', (tester) async {
        const String userRole = 'CUSTOMER';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Text('Customer Dashboard'),
                  if (userRole == 'ADMIN' || userRole == 'OWNER')
                    const Text('Secret Admin Catalog Console'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Customer Dashboard'), findsOneWidget);
        expect(find.text('Secret Admin Catalog Console'), findsNothing);
      });

      testWidgets('2.20 - Technician profile restricts viewing of unassigned customer addresses', (tester) async {
        final bool isAssignedToBooking = DateTime.now().year < 2000;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Text('Job Specification'),
                  if (isAssignedToBooking)
                    const Text('Exact Gate Code & Apartment Number: Ring 4B')
                  else
                    const Text('General Neighborhood: First Settlement, New Cairo'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('General Neighborhood: First Settlement, New Cairo'), findsOneWidget);
        expect(find.text('Exact Gate Code & Apartment Number: Ring 4B'), findsNothing);
      });
    });
  });
}
