import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/uploads/device_media_picker.dart';
import 'package:fixo_mobile/core/uploads/private_media_picker_sheet.dart';

class _Recovery extends DeviceMediaPicker {
  PickedPrivateMedia? photo;
  Future<PickedPrivateMedia?>? waiting;
  Future<PickedPrivateMedia?>? selectedPhoto;
  int consumed = 0, discarded = 0;
  final scopes = <String>[];
  @override
  Future<PickedPrivateMedia?> pick(ImageSource source) async => selectedPhoto;
  @override
  Future<PickedPrivateMedia?> recoveredFor(String scope) async {
    scopes.add(scope);
    return waiting ?? photo;
  }

  @override
  Future<PickedPrivateMedia?> takeRecovered(String scope) async {
    consumed++;
    return photo;
  }

  @override
  Future<void> discardRecovered(String scope) async {
    discarded++;
    photo = null;
  }
}

void main() {
  late PickedPrivateMedia photo;
  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 32, 32),
      ui.Paint()..color = const ui.Color(0xff173f35),
    );
    final rendered = await recorder.endRecording().toImage(32, 32);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();
    photo = PickedPrivateMedia(
      fileName: 'fixture.png',
      mimeType: 'image/png',
      contentBase64: base64Encode(bytes!.buffer.asUint8List()),
      sourceLabelEn: 'Photo library',
      sourceLabelAr: 'الصور',
    );
  });
  PickedPrivateMedia? selected;
  Future<ProviderContainer> mount(
    WidgetTester tester,
    _Recovery recovery,
  ) async {
    selected = null;
    final container = ProviderContainer(
      overrides: [deviceMediaPickerProvider.overrideWithValue(recovery)],
    );
    container.read(activeSessionOwnerProvider.notifier).state = 'owner-a';
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FixoTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await PrivateMediaPickerSheet.show(
                    context,
                    isArabic: false,
                    titleEn: 'Photo',
                    titleAr: 'الصورة',
                    rationaleEn: 'Choose a photo',
                    rationaleAr: 'اختار صورتك',
                    defaultFilePrefix: 'review:booking-a',
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
    return container;
  }

  Future<void> decode(WidgetTester tester, {bool corrupt = false}) async {
    final image = find.byType(Image).last;
    await tester.runAsync(
      () => precacheImage(
        tester.widget<Image>(image).image,
        tester.element(image),
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 5)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'recovered photo is previewed but returned only after explicit use',
    (tester) async {
      final recovery = _Recovery()..photo = photo;
      await mount(tester, recovery);
      expect(find.byKey(const Key('recovered-photo-preview')), findsOneWidget);
      expect(selected, isNull);
      expect(recovery.consumed, 0);
      expect(recovery.scopes, ['review:booking-a']);
      await decode(tester);
      await tester.tap(find.byKey(const Key('use-recovered-photo')));
      await tester.pumpAndSettle();
      expect(selected, photo);
      expect(recovery.consumed, 1);
    },
  );
  testWidgets(
    'discard never attaches a recovered photo and keeps ordinary source choices',
    (tester) async {
      final recovery = _Recovery()..photo = photo;
      await mount(tester, recovery);
      await tester.tap(find.byKey(const Key('discard-recovered-photo')));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(recovery.discarded, 1);
      expect(recovery.consumed, 0);
      expect(find.byKey(const Key('recovered-photo-preview')), findsNothing);
      expect(find.byKey(const Key('pick-gallery-btn')), findsOneWidget);
    },
  );
  testWidgets(
    'logout clears the preview and a new login cannot revive the old form',
    (tester) async {
      final recovery = _Recovery()..photo = photo;
      final container = await mount(tester, recovery);
      await decode(tester);
      container.read(activeSessionOwnerProvider.notifier).state = null;
      await tester.pumpAndSettle();
      container.read(activeSessionOwnerProvider.notifier).state = 'owner-a';
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recovered-photo-preview')), findsNothing);
      expect(find.byKey(const Key('use-recovered-photo')), findsNothing);
      expect(find.byKey(const Key('pick-gallery-btn')), findsNothing);
      expect(selected, isNull);
    },
  );
  testWidgets(
    'a late ordinary picker result cannot return after logout and restoration',
    (tester) async {
      final pending = Completer<PickedPrivateMedia?>();
      final recovery = _Recovery()..selectedPhoto = pending.future;
      final container = await mount(tester, recovery);
      await tester.tap(find.byKey(const Key('pick-gallery-btn')));
      await tester.pump();
      container.read(activeSessionOwnerProvider.notifier).state = null;
      await tester.pumpAndSettle();
      container.read(activeSessionOwnerProvider.notifier).state = 'owner-a';
      await tester.pumpAndSettle();
      pending.complete(photo);
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.textContaining('Session changed'), findsOneWidget);
    },
  );
  testWidgets('corrupt recovered content never enables the use action', (
    tester,
  ) async {
    final recovery = _Recovery()
      ..photo = PickedPrivateMedia(
        fileName: 'bad.png',
        mimeType: 'image/png',
        contentBase64: base64Encode([1, 2, 3]),
        sourceLabelEn: 'Photo',
        sourceLabelAr: 'صورة',
      );
    await mount(tester, recovery);
    await decode(tester, corrupt: true);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('use-recovered-photo')))
          .onPressed,
      isNull,
    );
    expect(recovery.consumed, 0);
    expect(selected, isNull);
  });
}
