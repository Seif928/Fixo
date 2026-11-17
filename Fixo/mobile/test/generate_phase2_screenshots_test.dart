import 'dart:io';
import 'dart:ui' as ui;
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/auth/data/auth_repository.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fixo_mobile/features/auth/presentation/pages/phone_auth_page.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/customer_home/presentation/pages/customer_home_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phase2_auth_and_home_test.dart';

Future<void> _captureWidgetToFile({
  required WidgetTester tester,
  required GlobalKey repaintKey,
  required String outputPath,
}) async {
  await tester.runAsync(() async {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('RepaintBoundary not found for $outputPath');
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode image to PNG for $outputPath');
    }
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(byteData.buffer.asUint8List());
  });
}

void main() {
  const outputDir =
      r'C:\Users\HP\.gemini\antigravity\brain\964c0559-6900-4459-bd45-bbcf3a54801d\scratch\rendered_screenshots';

  testWidgets('Capture Screen 02 (State 1: Phone Input) Screenshot', (
    WidgetTester tester,
  ) async {
    final repaintKey = GlobalKey();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          marketplaceRepositoryProvider.overrideWithValue(
            FakeMarketplaceRepository(),
          ),
        ],
        child: RepaintBoundary(
          key: repaintKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: FixoTheme.light(),
            home: const PhoneAuthPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _captureWidgetToFile(
      tester: tester,
      repaintKey: repaintKey,
      outputPath: '$outputDir\\flutter_screen_02_phone_input.png',
    );
  });

  testWidgets('Capture Screen 02 (State 2: OTP Code) Screenshot', (
    WidgetTester tester,
  ) async {
    final repaintKey = GlobalKey();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        marketplaceRepositoryProvider.overrideWithValue(
          FakeMarketplaceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Set initial state to OTP Code with '482' entered (active Box 4) matching live Stitch Screen 02
    container.read(authControllerProvider.notifier).switchStep(PhoneAuthStep.otpCode);
    container.read(authControllerProvider.notifier).setOtpCode('482');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: repaintKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: FixoTheme.light(),
            home: const PhoneAuthPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await _captureWidgetToFile(
      tester: tester,
      repaintKey: repaintKey,
      outputPath: '$outputDir\\flutter_screen_02_otp_code.png',
    );
  });

  testWidgets('Capture Screen 03 (Customer Home) Screenshot', (
    WidgetTester tester,
  ) async {
    final repaintKey = GlobalKey();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(
            FakeMarketplaceRepository(),
          ),
        ],
        child: RepaintBoundary(
          key: repaintKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: FixoTheme.light(),
            home: const CustomerHomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await _captureWidgetToFile(
      tester: tester,
      repaintKey: repaintKey,
      outputPath: '$outputDir\\flutter_screen_03_customer_home.png',
    );
  });
}
