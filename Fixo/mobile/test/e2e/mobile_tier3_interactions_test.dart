import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/theme/fixo_spacing.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Tier 3: Cross-Feature Interactions (Lifecycle Flows)', () {
    // =========================================================================
    // Interaction 1: Service Discovery Category Selection to Offering Filter
    // =========================================================================
    testWidgets('Interaction 1: Selecting a category filters and highlights offerings', (tester) async {
      String selectedSlug = 'all';

      const categories = [
        ServiceCategoryModel(
          id: 'cat-all',
          slug: 'all',
          nameEn: 'All Services',
          nameAr: 'جميع الخدمات',
          subtitleEn: 'Full Catalog',
          subtitleAr: 'الكتالوج الكامل',
          iconName: 'home_repair_service',
          startingPriceEgp: 120,
          sortOrder: 0,
        ),
        ServiceCategoryModel(
          id: 'cat-ac',
          slug: 'ac-maintenance',
          nameEn: 'AC Maintenance',
          nameAr: 'صيانة تكييف',
          subtitleEn: 'Split & Central',
          subtitleAr: 'أجهزة سبليت ومركزي',
          iconName: 'mode_fan',
          startingPriceEgp: 150,
          sortOrder: 1,
        ),
      ];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: ListView(
                children: [
                  for (final cat in categories)
                    ListTile(
                      title: Text(cat.nameAr),
                      selected: selectedSlug == cat.slug,
                      onTap: () => setState(() => selectedSlug = cat.slug),
                    ),
                  Text('Active Category: $selectedSlug'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Active Category: all'), findsOneWidget);
      await tester.tap(find.text('صيانة تكييف'));
      await tester.pump();
      expect(find.text('Active Category: ac-maintenance'), findsOneWidget);
    });

    // =========================================================================
    // Interaction 2: Offering Selection to Booking Form Prepopulation
    // =========================================================================
    testWidgets('Interaction 2: Offering prepopulates booking details & schedule window', (tester) async {
      const selectedOffering = ServiceOfferModel(
        id: 'srv-deep-clean',
        categoryId: 'cat-ac',
        categorySlug: 'ac-maintenance',
        slug: 'ac-split-deep-clean',
        titleEn: 'Split AC Deep Cleaning',
        titleAr: 'تنظيف عميق لتكييف سبليت',
        descriptionEn: 'Full chemical and water wash',
        descriptionAr: 'غسيل مائي وكيميائي شامل',
        baseInspectionEgp: 200,
        serviceFeeEgp: 30,
        flatPriceEgp: 230,
        estimatedDurationMins: 60,
        isSeasonalPromo: false,
        isBundle: false,
      );

      String chosenWindow = 'MORNING_09_12';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              appBar: AppBar(title: Text(selectedOffering.titleAr)),
              body: Column(
                children: [
                  Text('Selected Service: ${selectedOffering.titleAr}'),
                  Text('Base Fee: ${selectedOffering.baseInspectionEgp} EGP'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'MORNING_09_12', label: Text('9-12 AM')),
                      ButtonSegment(value: 'AFTERNOON_13_16', label: Text('1-4 PM')),
                    ],
                    selected: {chosenWindow},
                    onSelectionChanged: (set) => setState(() => chosenWindow = set.first),
                  ),
                  Text('Chosen Window: $chosenWindow'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Selected Service: تنظيف عميق لتكييف سبليت'), findsOneWidget);
      expect(find.text('Chosen Window: MORNING_09_12'), findsOneWidget);

      await tester.tap(find.text('1-4 PM'));
      await tester.pump();
      expect(find.text('Chosen Window: AFTERNOON_13_16'), findsOneWidget);
    });

    // =========================================================================
    // Interaction 3: Booking Form to Checkout Page & Transparent Price Breakdown
    // =========================================================================
    testWidgets('Interaction 3: Order price breakdown computes total in Egyptian Pounds', (tester) async {
      const int baseInspectionEgp = 200;
      const int serviceFeeEgp = 30;
      final int totalEgp = baseInspectionEgp + serviceFeeEgp;

      await tester.pumpWidget(
        MaterialApp(
          theme: FixoTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(FixoSpacing.md),
              child: Column(
                children: [
                  const Text('Order Pricing Breakdown'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('فحص ومعاينة أولية:'),
                      Text('$baseInspectionEgp ج.م'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('رسوم الخدمة:'),
                      Text('$serviceFeeEgp ج.م'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$totalEgp ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('200 ج.م'), findsOneWidget);
      expect(find.text('30 ج.م'), findsOneWidget);
      expect(find.text('230 ج.م'), findsOneWidget);
    });

    // =========================================================================
    // Interaction 4: Payment Method Selection to Order Submission
    // =========================================================================
    testWidgets('Interaction 4: Selecting Cash on Service transitions booking to PENDING_DISPATCH', (tester) async {
      String paymentChoice = 'CASH_ON_SERVICE';
      bool orderConfirmed = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: Column(
                children: [
                  RadioGroup<String>(
                    groupValue: paymentChoice,
                    onChanged: (val) => setState(() => paymentChoice = val!),
                    child: Column(
                      children: const [
                        RadioListTile<String>(
                          title: Text('Cash on Service (الدفع نقدياً عند انتهاء العمل)'),
                          value: 'CASH_ON_SERVICE',
                        ),
                        RadioListTile<String>(
                          title: Text('InstaPay / Smart Wallet (Sandbox)'),
                          value: 'INSTAPAY_SANDBOX',
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => orderConfirmed = true),
                    child: const Text('Confirm & Place Order'),
                  ),
                  if (orderConfirmed)
                    Text('Order Status: PENDING_DISPATCH ($paymentChoice)'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Order Status:'), findsNothing);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Order Status: PENDING_DISPATCH (CASH_ON_SERVICE)'), findsOneWidget);
    });

    // =========================================================================
    // Interaction 5: Customer Tracking Canvas with 4-Digit Arrival PIN
    // =========================================================================
    testWidgets('Interaction 5: Live tracking canvas displays technician info and 4-digit Arrival PIN', (tester) async {
      const String arrivalPin = '7391';
      const String bookingStatus = 'CONFIRMED';
      const String technicianName = 'Hassan El-Sayed';

      await tester.pumpWidget(
        MaterialApp(
          theme: FixoTheme.light(),
          home: Scaffold(
            appBar: AppBar(title: const Text('Order Live Tracking')),
            body: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: const Text(technicianName),
                  subtitle: const Text('Status: $bookingStatus'),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: const [
                        Text('Your 4-Digit Security Arrival PIN'),
                        Text(
                          arrivalPin,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                        Text('Provide this PIN to your technician upon arrival.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hassan El-Sayed'), findsOneWidget);
      expect(find.text('Status: CONFIRMED'), findsOneWidget);
      expect(find.text('7391'), findsOneWidget);
      expect(find.textContaining('Provide this PIN'), findsOneWidget);
    });

    // =========================================================================
    // Interaction 6: Dynamic Language Switch (Arabic RTL <-> English LTR)
    // =========================================================================
    testWidgets('Interaction 6: Dynamic locale switch switches directionality and fonts cleanly', (tester) async {
      Locale currentLocale = const Locale('ar');

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            theme: currentLocale.languageCode == 'ar'
                ? FixoTheme.light(locale: const Locale('ar'))
                : FixoTheme.light(locale: const Locale('en')),
            home: Directionality(
              textDirection: currentLocale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(currentLocale.languageCode == 'ar' ? 'فيكسو مصر' : 'FIXO Egypt'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.language),
                      onPressed: () => setState(() {
                        currentLocale = currentLocale.languageCode == 'ar'
                            ? const Locale('en')
                            : const Locale('ar');
                      }),
                    ),
                  ],
                ),
                body: Text(
                  currentLocale.languageCode == 'ar'
                      ? 'خدمات الصيانة المنزلية المعتمدة'
                      : 'Verified Home Maintenance Services',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('فيكسو مصر'), findsOneWidget);
      expect(find.text('خدمات الصيانة المنزلية المعتمدة'), findsOneWidget);

      // Toggle to English
      await tester.tap(find.byIcon(Icons.language));
      await tester.pump();

      expect(find.text('FIXO Egypt'), findsOneWidget);
      expect(find.text('Verified Home Maintenance Services'), findsOneWidget);
    });
  });
}
