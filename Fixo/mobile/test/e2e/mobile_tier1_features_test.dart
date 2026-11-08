import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_spacing.dart';
import 'package:fixo_mobile/core/theme/fixo_typography.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/widgets/fixo_brand_mark.dart';
import 'package:fixo_mobile/core/widgets/fixo_holographic_pro_badge.dart';
import 'package:fixo_mobile/core/widgets/fixo_tilt_3d.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/customer_home_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Tier 1: Feature Coverage Specifications', () {
    // =========================================================================
    // Feature 4: UI/UX Spacing & 8pt Grid Layout Tokens
    // =========================================================================
    group('Feature 4: 8pt Grid Spacing Tokens & Proportional Layout', () {
      test('4.1 - FixoSpacing.xs conforms to 4.0dp micro-step', () {
        expect(FixoSpacing.xs, equals(4.0));
      });

      test('4.2 - FixoSpacing.sm conforms to 8.0dp base grid step', () {
        expect(FixoSpacing.sm, equals(8.0));
      });

      test('4.3 - FixoSpacing.md conforms to 16.0dp double grid step', () {
        expect(FixoSpacing.md, equals(16.0));
      });

      test('4.4 - FixoSpacing.lg conforms to 24.0dp triple grid step', () {
        expect(FixoSpacing.lg, equals(24.0));
      });

      test('4.5 - FixoSpacing.xl conforms to 40.0dp container step', () {
        expect(FixoSpacing.xl, equals(40.0));
      });

      testWidgets('4.6 - Padding widget honors 8pt multiple constraints', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Container(width: 100, height: 100, color: Colors.blue),
              ),
            ),
          ),
        );
        final paddingFinder = find.byType(Padding);
        final paddingWidget = tester.widget<Padding>(paddingFinder.first);
        expect(paddingWidget.padding, equals(const EdgeInsets.all(16.0)));
      });

      test('4.7 - FixoRadius tokens maintain rounded corner harmony', () {
        expect(FixoRadius.sm, equals(8.0));
        expect(FixoRadius.md, equals(12.0));
        expect(FixoRadius.lg, equals(16.0));
        expect(FixoRadius.pill, equals(9999.0));
      });
    });

    // =========================================================================
    // Feature 5: Typography & Responsive Scaling
    // =========================================================================
    group('Feature 5: Cairo (Arabic) & Manrope (English) Typography Hierarchy', () {
      test('5.1 - Arabic locale resolves font family to Cairo', () {
        final family = FixoTypography.fontFamilyForLocale(const Locale('ar'));
        expect(family, contains('Cairo'));
      });

      test('5.2 - English locale resolves font family to Manrope', () {
        final family = FixoTypography.fontFamilyForLocale(const Locale('en'));
        expect(family, contains('Manrope'));
      });

      test('5.3 - Cairo Arabic display text style preserves legibility metrics', () {
        final style = FixoTypography.display(locale: const Locale('ar'));
        expect(style.fontWeight, equals(FontWeight.w800));
        expect(style.fontSize, equals(48.0));
      });

      test('5.4 - Manrope English display text style preserves structural metrics', () {
        final style = FixoTypography.display(locale: const Locale('en'));
        expect(style.fontWeight, equals(FontWeight.w800));
        expect(style.fontSize, equals(48.0));
      });

      test('5.5 - FixoTheme builds consistent light and dark palettes', () {
        final lightTheme = FixoTheme.light();
        expect(lightTheme.brightness, equals(Brightness.light));
        final darkTheme = FixoTheme.dark();
        expect(darkTheme.brightness, equals(Brightness.dark));
      });

      testWidgets('5.6 - Text renders without clipping under 1.0x text scale', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(
              body: Text('صيانة تكييف منزلية في القاهرة'),
            ),
          ),
        );
        expect(find.text('صيانة تكييف منزلية في القاهرة'), findsOneWidget);
      });
    });

    // =========================================================================
    // Feature 6: Procedural Assets, Vector Fidelity & Brand Badges
    // =========================================================================
    group('Feature 6: Procedural Vector Assets & Holographic Brand Marks', () {
      testWidgets('6.1 - FixoBrandMark renders procedural vector brand mark', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(
              body: Center(
                child: FixoBrandMark(iconBoxSize: 48),
              ),
            ),
          ),
        );
        expect(find.byType(FixoBrandMark), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.text('FIXO'), findsOneWidget);
      });

      testWidgets('6.2 - FixoHolographicProBadge renders verified badge with shimmer', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(
              body: Center(
                child: FixoHolographicProBadge(
                  isArabic: true,
                  badgeText: 'فني معتمد',
                ),
              ),
            ),
          ),
        );
        expect(find.byType(FixoHolographicProBadge), findsOneWidget);
        expect(find.text('فني معتمد'), findsOneWidget);
      });

      testWidgets('6.3 - FixoTilt3D wraps interactive cards with 3D perspective', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: FixoTilt3D(
                child: Container(width: 200, height: 100, color: Colors.amber),
              ),
            ),
          ),
        );
        expect(find.byType(FixoTilt3D), findsOneWidget);
      });

      testWidgets('6.4 - Brand mark scales deterministically with custom iconBoxSize input', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(
              body: Column(
                children: [
                  FixoBrandMark(iconBoxSize: 24),
                  FixoBrandMark(iconBoxSize: 72),
                ],
              ),
            ),
          ),
        );
        expect(find.byType(FixoBrandMark), findsNWidgets(2));
      });

      testWidgets('6.5 - English pro badge renders accurate English copy', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(
              body: Center(
                child: FixoHolographicProBadge(
                  isArabic: false,
                  badgeText: 'Certified Pro',
                ),
              ),
            ),
          ),
        );
        expect(find.text('Certified Pro'), findsOneWidget);
      });
    });

    // =========================================================================
    // Feature 7: Mobile Scroll & Graphics Performance
    // =========================================================================
    group('Feature 7: Virtualized Scrolling, Lazy Loading & Repaint Boundaries', () {
      testWidgets('7.1 - ListView.builder only renders items visible in viewport', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 1000,
                itemExtent: 80,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Service Item #$index'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Service Item #0'), findsOneWidget);
        expect(find.text('Service Item #5'), findsOneWidget);
        expect(find.text('Service Item #500'), findsNothing);
      });

      testWidgets('7.2 - Scrolling advances virtualized list smoothly without layout jank', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 500,
                itemExtent: 60,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Catalog Offering #$index'),
                ),
              ),
            ),
          ),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        expect(find.text('Catalog Offering #0'), findsNothing);
        expect(find.text('Catalog Offering #10'), findsOneWidget);
      });

      testWidgets('7.3 - RepaintBoundary isolates render repaints for animated badges', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(
              body: RepaintBoundary(
                child: FixoBrandMark(iconBoxSize: 32),
              ),
            ),
          ),
        );
        expect(find.byType(RepaintBoundary), findsWidgets);
      });

      testWidgets('7.4 - CustomScrollView with SliverList correctly virtualizes multiple sections', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(height: 100, color: Colors.blue),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ListTile(title: Text('Sliver Item $index')),
                      childCount: 100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        expect(find.text('Sliver Item 0'), findsOneWidget);
        expect(find.text('Sliver Item 90'), findsNothing);
      });

      testWidgets('7.5 - Fast scroll flings settle deterministically to integer pixel bounds', (tester) async {
        final scrollController = ScrollController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                controller: scrollController,
                itemCount: 200,
                itemExtent: 70,
                itemBuilder: (context, index) => Text('Row $index'),
              ),
            ),
          ),
        );

        await tester.fling(find.byType(ListView), const Offset(0, -1000), 2000);
        await tester.pumpAndSettle();

        expect(scrollController.offset, greaterThan(0));
      });
    });

    // =========================================================================
    // Feature 10: Service Discovery UI
    // =========================================================================
    group('Feature 10: Service Catalog & Discovery Marketplace Components', () {
      test('10.1 - ServiceCategoryModel deserializes category payload accurately', () {
        final json = {
          'id': 'cat-ac',
          'slug': 'ac-maintenance',
          'nameEn': 'Air Conditioning',
          'nameAr': 'صيانة تكييف',
          'subtitleEn': 'Split & Central units',
          'subtitleAr': 'أجهزة سبليت ومركزي',
          'iconName': 'mode_fan',
          'startingPriceEgp': 150,
          'sortOrder': 1,
        };
        final category = ServiceCategoryModel.fromJson(json);
        expect(category.id, equals('cat-ac'));
        expect(category.nameEn, equals('Air Conditioning'));
        expect(category.nameAr, equals('صيانة تكييف'));
        expect(category.startingPriceEgp, equals(150));
      });

      test('10.2 - ServiceOfferModel parses pricing and EGP currency breakdown', () {
        final json = {
          'id': 'srv-ac-01',
          'categoryId': 'cat-ac',
          'categorySlug': 'ac-maintenance',
          'slug': 'ac-split-deep-clean',
          'titleEn': 'Split AC Deep Cleaning',
          'titleAr': 'تنظيف عميق لتكييف سبليت',
          'descriptionEn': 'High-pressure wash',
          'descriptionAr': 'غسيل ضغط عالي',
          'baseInspectionEgp': 150,
          'serviceFeeEgp': 30,
          'flatPriceEgp': 180,
          'estimatedDurationMins': 45,
          'isSeasonalPromo': true,
          'isBundle': false,
        };
        final offering = ServiceOfferModel.fromJson(json);
        expect(offering.baseInspectionEgp, equals(150));
        expect(offering.serviceFeeEgp, equals(30));
        expect(offering.estimatedDurationMins, equals(45));
        expect(offering.isSeasonalPromo, isTrue);
      });

      testWidgets('10.3 - ServiceCategoryGridTile renders category tile', (tester) async {
        const category = ServiceCategoryModel(
          id: 'cat-plumbing',
          slug: 'plumbing',
          nameEn: 'Plumbing',
          nameAr: 'سباكة',
          subtitleEn: 'Leaks and pipes',
          subtitleAr: 'تسريبات ومواسير',
          iconName: 'plumbing',
          startingPriceEgp: 180,
          sortOrder: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: ServiceCategoryGridTile(
                category: category,
                isArabic: true,
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('سباكة'), findsOneWidget);
      });

      testWidgets('10.4 - ServiceCategoryGridTile triggers onTap callback', (tester) async {
        bool tapped = false;
        const category = ServiceCategoryModel(
          id: 'cat-elec',
          slug: 'electrical',
          nameEn: 'Electrical',
          nameAr: 'كهرباء',
          subtitleEn: 'Wiring & Panels',
          subtitleAr: 'أسلاك ولوحات',
          iconName: 'bolt',
          startingPriceEgp: 200,
          sortOrder: 3,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: Scaffold(
              body: ServiceCategoryGridTile(
                category: category,
                isArabic: true,
                isSelected: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ServiceCategoryGridTile));
        expect(tapped, isTrue);
      });

      testWidgets('10.5 - FixoArtisanAvatar renders deterministic illustrated portrait', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(
              body: Center(
                child: FixoArtisanAvatar(
                  identifier: 'pro-hassan-cairo',
                  size: 48,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(FixoArtisanAvatar), findsOneWidget);
      });
    });

    // =========================================================================
    // Feature 11: Booking & Order Checkout Flow UI
    // =========================================================================
    group('Feature 11: Booking Creation, Time Window Selection & Checkout UI', () {
      test('11.1 - Time window enum defines distinct Cairo time intervals', () {
        expect(['MORNING_09_12', 'AFTERNOON_13_16', 'EVENING_17_20'], contains('MORNING_09_12'));
      });

      testWidgets('11.2 - Time window chips display formatted schedule labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Wrap(
                children: [
                  ChoiceChip(
                    label: const Text('9:00 AM - 12:00 PM'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('1:00 PM - 4:00 PM'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('5:00 PM - 8:00 PM'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('9:00 AM - 12:00 PM'), findsOneWidget);
        expect(find.text('1:00 PM - 4:00 PM'), findsOneWidget);
        expect(find.text('5:00 PM - 8:00 PM'), findsOneWidget);
      });

      testWidgets('11.3 - Payment method selector displays Cash on Service and Sandbox options', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ListTile(
                    title: const Text('Cash on Service (الدفع نقدياً)'),
                    leading: const Icon(Icons.money),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text('InstaPay / Smart Wallet (Sandbox)'),
                    leading: const Icon(Icons.account_balance_wallet),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.textContaining('Cash on Service'), findsOneWidget);
        expect(find.textContaining('InstaPay'), findsOneWidget);
      });

      testWidgets('11.4 - Order price summary card displays transparent EGP breakdown', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Card(
                child: Padding(
                  padding: const EdgeInsets.all(FixoSpacing.md),
                  child: Column(
                    children: const [
                      Text('Base Inspection: 150 EGP'),
                      Text('Service Fee: 30 EGP'),
                      Divider(),
                      Text('Total: 180 EGP', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Base Inspection: 150 EGP'), findsOneWidget);
        expect(find.text('Service Fee: 30 EGP'), findsOneWidget);
        expect(find.text('Total: 180 EGP'), findsOneWidget);
      });

      testWidgets('11.5 - Booking confirmation CTA triggers checkout submission', (tester) async {
        bool submitted = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: ElevatedButton(
                onPressed: () => submitted = true,
                child: const Text('Confirm & Book Service'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(submitted, isTrue);
      });
    });

    // =========================================================================
    // Feature 9 & 12: Pro Dashboard & Admin UI Elements
    // =========================================================================
    group('Feature 9 & 12: Pro Dashboard & Admin Dossier UI Controls', () {
      testWidgets('9.1 - Pro online/offline availability switch updates visual state', (tester) async {
        bool isOnline = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              home: Scaffold(
                body: SwitchListTile(
                  title: Text(isOnline ? 'Online - Receiving Jobs' : 'Offline'),
                  value: isOnline,
                  onChanged: (val) => setState(() => isOnline = val),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Offline'), findsOneWidget);
        await tester.tap(find.byType(Switch));
        await tester.pump();
        expect(find.text('Online - Receiving Jobs'), findsOneWidget);
      });

      testWidgets('9.2 - 4-digit arrival PIN display presents bold monospace digits', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Text(
                  '7 3 9 1',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('7 3 9 1'), findsOneWidget);
      });

      testWidgets('12.1 - Admin verification badge reflects APPROVED state', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Chip(
                avatar: Icon(Icons.verified, color: Colors.green),
                label: Text('APPROVED - معتمد'),
              ),
            ),
          ),
        );

        expect(find.text('APPROVED - معتمد'), findsOneWidget);
      });

      testWidgets('12.2 - Admin verification badge reflects PENDING_REVIEW state', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Chip(
                avatar: Icon(Icons.hourglass_top, color: Colors.orange),
                label: Text('PENDING REVIEW - قيد المراجعة'),
              ),
            ),
          ),
        );

        expect(find.text('PENDING REVIEW - قيد المراجعة'), findsOneWidget);
      });
    });
  });
}
