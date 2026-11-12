import 'dart:async';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/auth/data/email_access_service.dart';
import 'package:fixo_mobile/features/auth/presentation/widgets/google_sign_in_button.dart';

class PendingGoogleService extends EmailAccessService {
  PendingGoogleService() : super(Dio());
  final ready = Completer<void>();
  int preparations = 0;
  @override
  bool get requiresGooglePreparation => true;
  @override
  Future<void> prepareGoogle() {
    preparations++;
    return preparations == 1 ? ready.future : Future.value();
  }
}

void main() {
  testWidgets(
    'failed preparation offers a safe reconnect before a real sign-in click',
    (tester) async {
      final service = PendingGoogleService();
      var clicks = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [emailAccessProvider.overrideWithValue(service)],
          child: MaterialApp(
            home: Scaffold(
              body: GoogleSignInButton(
                isArabic: false,
                label: const Text('Continue with Google'),
                onPressed: () => clicks++,
              ),
            ),
          ),
        ),
      );
      service.ready.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Reconnect to Google'), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(clicks, 0);
      expect(service.preparations, 2);
      await tester.tap(find.byType(OutlinedButton));
      expect(clicks, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'first click is available only after background preparation and retains the official mark',
    (tester) async {
      final service = PendingGoogleService();
      var clicks = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [emailAccessProvider.overrideWithValue(service)],
          child: MaterialApp(
            home: Scaffold(
              body: GoogleSignInButton(
                isArabic: false,
                label: const Text('Continue with Google'),
                onPressed: () => clicks++,
              ),
            ),
          ),
        ),
      );
      expect(service.preparations, 1);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(find.text('Connecting to Google…'), findsOneWidget);
      service.ready.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OutlinedButton));
      expect(clicks, 1);
      expect(service.preparations, 1);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/brand/google-g.png',
      );
    },
  );
}
