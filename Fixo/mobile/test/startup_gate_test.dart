import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/app/startup_gate.dart';

void main() {
  testWidgets('failed restoration never releases routing or device recovery', (
    tester,
  ) async {
    final restore = Completer<void>();
    var ready = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: FixoStartupGate(
          restoration: restore.future,
          onReady: () => ready++,
          child: const MaterialApp(home: Text('protected-content')),
        ),
      ),
    );
    restore.completeError(StateError('restore unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('protected-content'), findsNothing);
    expect(
      find.text('Could not start the app. Reload and try again.'),
      findsOneWidget,
    );
    expect(ready, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'draws a first frame while session restoration is pending without exposing protected content',
    (tester) async {
      final restore = Completer<void>();
      var ready = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: FixoStartupGate(
            restoration: restore.future,
            onReady: () => ready++,
            child: const MaterialApp(home: Text('real-application')),
          ),
        ),
      );
      expect(find.text('FIXO'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('real-application'), findsNothing);
      expect(ready, 0);
      restore.complete();
      await tester.pumpAndSettle();
      expect(find.text('real-application'), findsOneWidget);
      expect(ready, 1);
    },
  );
}
