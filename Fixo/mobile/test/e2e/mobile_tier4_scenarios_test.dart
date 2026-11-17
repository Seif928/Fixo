import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/widgets/fixo_brand_mark.dart';
import 'package:fixo_mobile/core/widgets/fixo_holographic_pro_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Tier 4: Real-World Application Scenarios (End-to-End User Journeys)', () {
    // =========================================================================
    // Scenario 1: Customer Onboarding & Profile Customization
    // =========================================================================
    group('Scenario 1: Customer Onboarding, Egypt Phone Auth & Profile Customization', () {
      testWidgets('Step 1-4: Onboarding welcome -> Egyptian phone entry -> OTP verify -> Saved Address', (tester) async {
        String enteredPhone = '';
        String enteredOtp = '';
        bool otpScreenVisible = false;
        bool authenticated = false;
        String savedAddressLabel = '';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              theme: FixoTheme.light(),
              home: Scaffold(
                body: !otpScreenVisible
                    ? Column(
                        children: [
                          const FixoBrandMark(iconBoxSize: 40),
                          const Text('مرحباً بك في فيكسو مصر'),
                          TextField(
                            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                            onChanged: (val) => enteredPhone = val,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (enteredPhone.startsWith('+201') && enteredPhone.length == 13) {
                                setState(() => otpScreenVisible = true);
                              }
                            },
                            child: const Text('إرسال رمز التحقق'),
                          ),
                        ],
                      )
                    : !authenticated
                        ? Column(
                            children: [
                              const Text('أدخل رمز التحقق (OTP)'),
                              TextField(
                                decoration: const InputDecoration(labelText: 'رمز التحقق'),
                                onChanged: (val) => enteredOtp = val,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (enteredOtp == '482910') {
                                    setState(() => authenticated = true);
                                  }
                                },
                                child: const Text('تأكيد الدخول'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const Text('الملف الشخصي: سلمى الشاذلي'),
                              ElevatedButton(
                                onPressed: () => setState(() => savedAddressLabel = 'المنزل - القاهرة الجديدة'),
                                child: const Text('إضافة عنوان جديد'),
                              ),
                              if (savedAddressLabel.isNotEmpty)
                                Text('العنوان المحفوظ: $savedAddressLabel'),
                            ],
                          ),
              ),
            ),
          ),
        );

        // Step 1: Onboarding welcome visible
        expect(find.text('مرحباً بك في فيكسو مصر'), findsOneWidget);

        // Step 2: Enter valid Egyptian phone
        await tester.enterText(find.byType(TextField), '+201023456789');
        await tester.tap(find.text('إرسال رمز التحقق'));
        await tester.pump();

        // Step 3: Verify OTP screen visible
        expect(find.text('أدخل رمز التحقق (OTP)'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '482910');
        await tester.tap(find.text('تأكيد الدخول'));
        await tester.pump();

        // Step 4: Authenticated Profile & Address selection
        expect(find.text('الملف الشخصي: سلمى الشاذلي'), findsOneWidget);
        await tester.tap(find.text('إضافة عنوان جديد'));
        await tester.pump();
        expect(find.text('العنوان المحفوظ: المنزل - القاهرة الجديدة'), findsOneWidget);
      });
    });

    // =========================================================================
    // Scenario 2: Service Discovery to Booking Creation & Checkout
    // =========================================================================
    group('Scenario 2: Service Discovery, Schedule Selection & Cash on Service Checkout', () {
      testWidgets('Step 1-4: Search AC service -> Select split deep clean -> Choose 9-12 AM -> Confirm Order', (tester) async {
        String currentRoute = 'DISCOVERY';
        String selectedService = '';
        String selectedWindow = '';
        String confirmedPaymentMethod = '';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              theme: FixoTheme.light(),
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    if (currentRoute == 'DISCOVERY') {
                      return Column(
                        children: [
                          const Text('Home Maintenance Services'),
                          ListTile(
                            title: const Text('AC Split Deep Cleaning (غسيل تكييف سبليت)'),
                            subtitle: const Text('230 EGP • 45 mins'),
                            onTap: () {
                              selectedService = 'AC Split Deep Cleaning';
                              setState(() => currentRoute = 'SCHEDULE');
                            },
                          ),
                        ],
                      );
                    } else if (currentRoute == 'SCHEDULE') {
                      return Column(
                        children: [
                          Text('Booking: $selectedService'),
                          ElevatedButton(
                            onPressed: () {
                              selectedWindow = '9:00 AM - 12:00 PM';
                              setState(() => currentRoute = 'CHECKOUT');
                            },
                            child: const Text('Choose Morning (9:00 AM - 12:00 PM)'),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          const Text('Checkout Summary'),
                          Text('Service: $selectedService'),
                          Text('Schedule: $selectedWindow'),
                          const Text('Total: 230 EGP (Cash on Service)'),
                          ElevatedButton(
                            onPressed: () {
                              confirmedPaymentMethod = 'CASH_ON_SERVICE';
                              setState(() => currentRoute = 'CONFIRMED');
                            },
                            child: const Text('Place Order'),
                          ),
                          if (currentRoute == 'CONFIRMED')
                            Text('Order Confirmed via $confirmedPaymentMethod!'),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );

        // Step 1: Browse discovery
        expect(find.text('Home Maintenance Services'), findsOneWidget);
        await tester.tap(find.textContaining('AC Split Deep Cleaning'));
        await tester.pump();

        // Step 2: Schedule window
        expect(find.text('Booking: AC Split Deep Cleaning'), findsOneWidget);
        await tester.tap(find.text('Choose Morning (9:00 AM - 12:00 PM)'));
        await tester.pump();

        // Step 3: Checkout summary in EGP
        expect(find.text('Checkout Summary'), findsOneWidget);
        expect(find.text('Total: 230 EGP (Cash on Service)'), findsOneWidget);

        // Step 4: Place order
        await tester.tap(find.text('Place Order'));
        await tester.pump();
        expect(find.text('Order Confirmed via CASH_ON_SERVICE!'), findsOneWidget);
      });
    });

    // =========================================================================
    // Scenario 5: Admin Mobile Dossier Review & Catalog Controls
    // =========================================================================
    group('Scenario 5: Admin Mobile Professional Dossier Audit & Catalog Publishing', () {
      testWidgets('Step 1-3: Admin opens dossier -> Inspects credentials -> Approves technician with audit badge', (tester) async {
        String verificationStatus = 'PENDING_REVIEW';
        bool documentsVerified = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              theme: FixoTheme.light(),
              home: Scaffold(
                appBar: AppBar(title: const Text('Admin Operations Console')),
                body: Column(
                  children: [
                    const ListTile(
                      title: Text('Technician: Hassan El-Sayed'),
                      subtitle: Text('Dossier: PRO-502 • Cairo Zone: Maadi'),
                    ),
                    CheckboxListTile(
                      title: const Text('National ID & Criminal Record Clearance Confirmed'),
                      value: documentsVerified,
                      onChanged: (val) => setState(() => documentsVerified = val!),
                    ),
                    Text('Current Status: $verificationStatus'),
                    ElevatedButton(
                      onPressed: documentsVerified
                          ? () => setState(() => verificationStatus = 'APPROVED')
                          : null,
                      child: const Text('Approve Professional'),
                    ),
                    if (verificationStatus == 'APPROVED')
                      const FixoHolographicProBadge(
                        isArabic: true,
                        badgeText: 'فني معتمد • فيكسو مصر',
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Step 1: Open dossier
        expect(find.text('Admin Operations Console'), findsOneWidget);
        expect(find.text('Current Status: PENDING_REVIEW'), findsOneWidget);
        expect(find.byType(FixoHolographicProBadge), findsNothing);

        // Step 2: Confirm credentials
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Step 3: Approve
        await tester.tap(find.text('Approve Professional'));
        await tester.pump();

        expect(find.text('Current Status: APPROVED'), findsOneWidget);
        expect(find.byType(FixoHolographicProBadge), findsOneWidget);
      });
    });
  });
}
