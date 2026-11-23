// Run from mobile: flutter test tool/export_brand_assets.dart
// Regenerates launcher/browser assets directly from the shared Flutter logo.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/widgets/fixo_brand_mark.dart';

void main() {
  testWidgets('export the shared FIXO crest for every platform', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(512, 512);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: RepaintBoundary(
            key: key,
            child: const ColoredBox(
              color: Color(0xFF17191C),
              child: Center(
                child: FixoBrandMark(iconOnly: true, iconBoxSize: 400),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final targets = <String, int>{
      'web/favicon.png': 32,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      for (final entry in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries)
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png':
            entry.value,
    };
    const iconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final manifest =
        jsonDecode(File('$iconDir/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final item in manifest['images'] as List) {
      final row = item as Map<String, dynamic>;
      targets['$iconDir/${row['filename']}'] =
          (double.parse((row['size'] as String).split('x').first) *
                  double.parse((row['scale'] as String).replaceAll('x', '')))
              .round();
    }
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      for (final entry in targets.entries) {
        final image = await boundary.toImage(pixelRatio: entry.value / 512);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(entry.key).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }
    });
  });
}
