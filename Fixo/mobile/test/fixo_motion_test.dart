import 'package:fixo_mobile/core/motion/fixo_motion.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/widgets/fixo_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {bool reduced = false}) => MaterialApp(
    theme: FixoTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    ),
  );

  testWidgets('entrance settles and does not replay on parent rebuild', (
    tester,
  ) async {
    VoidCallback rebuild = () {};
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = () => setState(() {});
            return const FixoEntrance(child: Text('Welcome'));
          },
        ),
      ),
    );
    final fade = find.descendant(
      of: find.byType(FixoEntrance),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    rebuild();
    await tester.pump();
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduced motion displays entrance immediately', (tester) async {
    await tester.pumpWidget(
      host(const FixoEntrance(child: Text('Welcome')), reduced: true),
    );
    expect(find.text('Welcome'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FixoEntrance),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('primary button presses, cancels cleanly and fires once', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(FixoPrimaryButton(label: 'Continue', onPressed: () => taps++)),
    );
    final button = find.byType(FixoPrimaryButton);
    final scale = find.descendant(
      of: button,
      matching: find.byType(AnimatedScale),
    );
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<AnimatedScale>(scale).scale, lessThan(1));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
    expect(taps, 0);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  });

  testWidgets('reduced motion keeps a pressed button still', (tester) async {
    await tester.pumpWidget(
      host(
        FixoPrimaryButton(label: 'Continue', onPressed: () {}),
        reduced: true,
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(InkWell)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('disabled and loading buttons cannot submit', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        FixoPrimaryButton(
          label: 'Continue',
          onPressed: () => taps++,
          isLoading: true,
        ),
      ),
    );
    await tester.tap(find.byType(InkWell));
    await tester.pump(const Duration(milliseconds: 150));
    expect(taps, 0);
    await tester.pumpWidget(
      host(const FixoPrimaryButton(label: 'Continue', onPressed: null)),
    );
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(taps, 0);
  });
}
