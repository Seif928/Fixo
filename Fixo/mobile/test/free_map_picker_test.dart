import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/location/free_map_picker.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';

void main() {
  testWidgets('Cairo overview is not silently saved; an explicit map tap is required', (tester) async {
    ServiceMapPoint? saved;
    await tester.pumpWidget(ProviderScope(overrides: [
      freeMapReadyProvider.overrideWith((ref) async {}),
      freeMapSurfaceProvider.overrideWithValue((initial, onPick, dark) => Center(child: TextButton(
        onPressed: () => onPick(ServiceMapPoint(30.0131, 31.2089)), child: const Text('Tap real map coordinate')))),
    ], child: MaterialApp(theme: FixoTheme.dark(), home: Builder(builder: (context) => Scaffold(body: TextButton(
      child: const Text('Open map'), onPressed: () async { saved = await showModalBottomSheet<ServiceMapPoint>(context: context,
        isScrollControlled: true, builder: (_) => const FreeMapPicker(isArabic: false)); },
    ))))));
    await tester.tap(find.text('Open map')); await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('confirm-map-point'))).onPressed, isNull);
    expect(find.text('No point selected yet.'), findsOneWidget);
    await tester.tap(find.text('Tap real map coordinate')); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-map-point'))); await tester.pumpAndSettle();
    expect(saved?.latitude, 30.0131);
    expect(saved?.longitude, 31.2089);
    expect(tester.takeException(), isNull);
  });
}
