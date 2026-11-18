import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/location/service_area_picker.dart';
import 'package:fixo_mobile/core/location/egypt_places.dart';
import 'package:fixo_mobile/features/customer_home/presentation/widgets/booking_help_sheet.dart';

void main() {
  for (final width in [360.0, 390.0, 412.0, 1280.0]) {
    for (final ar in [false, true]) {
      for (final dark in [false, true]) {
        testWidgets(
          'booking guide fits $width ar=$ar dark=$dark at 1.35 scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? FixoTheme.dark() : FixoTheme.light(),
                home: Scaffold(
                  body: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 800),
                      textScaler: const TextScaler.linear(1.35),
                    ),
                    child: BookingHelpSheet(isArabic: ar),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.byKey(const Key('booking-help-location')),
            );
            expect(find.byKey(const Key('booking-help-start')), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'location sources stay accessible without long credits in picker',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            egyptPlacesProvider.overrideWith((ref) async => EgyptPlaces([])),
          ],
          child: MaterialApp(
            theme: FixoTheme.light(),
            home: const Scaffold(body: ServiceAreaPicker(isArabic: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('© OpenStreetMap contributors'), findsNothing);
      expect(find.text('Open Admin Data · CC BY 4.0'), findsNothing);
      await tester.tap(find.byKey(const Key('location-data-sources')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(find.text('Open Admin Data'), findsOneWidget);
      expect(find.text('CC BY 4.0'), findsOneWidget);
      await tester.tap(find.text('إغلاق').last);
      await tester.pumpAndSettle();
      expect(find.byType(ServiceAreaPicker), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
