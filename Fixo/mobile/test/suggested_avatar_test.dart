import 'dart:convert';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/uploads/private_media_picker_sheet.dart';
import 'package:fixo_mobile/core/uploads/suggested_avatar.dart';
import 'package:fixo_mobile/core/uploads/device_media_picker.dart';
import 'package:image_picker/image_picker.dart';

class _Sources extends DeviceMediaPicker {
  final sources = <ImageSource>[];
  @override
  bool get supportsCamera => true;
  @override
  Future<PickedPrivateMedia?> pick(ImageSource source) async {
    sources.add(source);
    return const PickedPrivateMedia(
      fileName: 'fixture.png',
      mimeType: 'image/png',
      contentBase64: 'TEST_BYTES',
      sourceLabelEn: 'Fixture',
      sourceLabelAr: 'اختبار',
    );
  }
}

void main() {
  for (final source in ImageSource.values) {
    testWidgets(
      'photo sheet passes the explicit $source choice to the device picker',
      (tester) async {
        final picker = _Sources();
        PickedPrivateMedia? selected;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [deviceMediaPickerProvider.overrideWithValue(picker)],
            child: MaterialApp(
              theme: FixoTheme.light(),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      selected = await PrivateMediaPickerSheet.show(
                        context,
                        isArabic: true,
                        titleEn: 'Photo',
                        titleAr: 'الصورة',
                        rationaleEn: 'Choose your photo',
                        rationaleAr: 'اختار صورتك',
                        defaultFilePrefix: 'avatar',
                        allowSuggestedAvatars: true,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            Key(
              source == ImageSource.camera
                  ? 'pick-camera-btn'
                  : 'pick-gallery-btn',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(picker.sources, [source]);
        expect(selected?.fileName, 'fixture.png');
      },
    );
  }
  testWidgets(
    'local illustrations encode distinct valid bounded PNG portraits',
    (tester) async {
      final encoded = <String>{};
      for (final index in [0, 12, 23]) {
        final media = await tester.runAsync(() => renderSuggestedAvatar(index));
        expect(media!.mimeType, 'image/png');
        final bytes = base64Decode(media.contentBase64);
        expect(bytes.length, lessThan(2 * 1024 * 1024));
        final codec = await tester.runAsync(
          () => ui.instantiateImageCodec(bytes),
        );
        final frame = await tester.runAsync(() => codec!.getNextFrame());
        expect(frame!.image.width, 256);
        expect(frame.image.height, 256);
        frame.image.dispose();
        codec!.dispose();
        encoded.add(media.contentBase64);
      }
      expect(encoded.length, 3);
      await expectLater(renderSuggestedAvatar(24), throwsRangeError);
    },
  );

  testWidgets('identity evidence picker never offers suggested identities', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: FixoTheme.light(),
          home: const Scaffold(
            body: PrivateMediaPickerSheet(
              isArabic: false,
              titleEn: 'Identity document',
              titleAr: 'بطاقة',
              rationaleEn: 'Choose your own document',
              rationaleAr: 'مستندك',
              defaultFilePrefix: 'identity',
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('choose-suggested-avatar')), findsNothing);
    expect(find.byKey(const Key('pick-gallery-btn')), findsOneWidget);
  });
}
