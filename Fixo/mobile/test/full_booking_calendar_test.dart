import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/presentation/widgets/create_booking_widgets.dart';

void main() {
  testWidgets('calendar accepts a date beyond quick-date choices', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: FixoTheme.light(locale: const Locale('en')),
        home: Scaffold(
          body: BookingDateSelector(
            selectedDate: DateTime(2026, 11, 10),
            today: DateTime(2026, 11, 9),
            isArabic: false,
            onSelectDate: (d) => selected = d,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('booking-open-calendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '1/15/2040');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2040, 1, 15));
    expect(tester.takeException(), isNull);
  });
}
