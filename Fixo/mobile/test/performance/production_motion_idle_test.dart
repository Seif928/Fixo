import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/widgets/fixo_brand_mark.dart';
import 'package:fixo_mobile/core/widgets/fixo_glass_card.dart';
import 'package:fixo_mobile/core/widgets/fixo_holographic_pro_badge.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/interactive_3d_home_scene.dart';

void main() {
  testWidgets(
    'reduced motion glass avoids GPU blur and retains the child controls',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: FixoTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Column(
                children: [
                  LiquidGlassLayer(
                    child: TextButton(
                      onPressed: () => taps++,
                      child: const Text('Liquid action'),
                    ),
                  ),
                  FixoGlassCard(
                    child: TextButton(
                      onPressed: () => taps++,
                      child: const Text('Card action'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      for (final filter in tester.widgetList<BackdropFilter>(
        find.byType(BackdropFilter),
      )) {
        expect(filter.enabled, isFalse);
      }
      await tester.tap(find.text('Liquid action'));
      await tester.tap(find.text('Card action'));
      expect(taps, 2);
    },
  );
  final surfaces = <String, Widget>{
    'brand crest': const FixoBrandMark(),
    'professional badge': const FixoHolographicProBadge(isArabic: false),
    'home scene': Interactive3DHomeScene(
      isArabic: false,
      onSelectCategory: (_) {},
    ),
  };
  for (final entry in surfaces.entries) {
    testWidgets('${entry.key} stops scheduling decorative frames at rest', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FixoTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 400, child: entry.value),
            ),
          ),
        ),
      );
      // Visibility becomes measurable after layout; start that next-frame ticker
      // before advancing its clock.
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason:
            'A settled page must not continuously repaint decorative content.',
      );
    });
  }
}
