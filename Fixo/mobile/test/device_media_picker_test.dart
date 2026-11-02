import 'dart:convert';
import 'package:fixo_mobile/core/uploads/device_media_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _Picker extends ImagePicker {
  XFile? result;
  bool denied = false;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (denied) throw PlatformException(code: 'photo_access_denied');
    return result;
  }
}

void main() {
  test('uses selected image bytes and cancellation produces no file', () async {
    final picker = _Picker();
    final service = DeviceMediaPicker(picker);
    expect(await service.pick(ImageSource.gallery), isNull);
    final bytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      1,
      2,
      3,
    ]);
    picker.result = XFile.fromData(
      bytes,
      name: 'chosen.png',
      mimeType: 'image/png',
    );
    final selected = await service.pick(ImageSource.gallery);
    expect(base64Decode(selected!.contentBase64), bytes);
    expect(selected.mimeType, 'image/png');
  });
  test(
    'denial, unsupported content and size limits never fabricate a substitute',
    () async {
      final picker = _Picker()..denied = true;
      final service = DeviceMediaPicker(picker);
      await expectLater(
        service.pick(ImageSource.gallery),
        throwsA(isA<PlatformException>()),
      );
      picker.denied = false;
      picker.result = XFile.fromData(
        Uint8List.fromList(utf8.encode('<svg/>')),
        name: 'fake.png',
      );
      await expectLater(
        service.pick(ImageSource.gallery),
        throwsFormatException,
      );
      picker.result = XFile.fromData(
        Uint8List(2 * 1024 * 1024 + 1),
        name: 'large.png',
      );
      await expectLater(
        service.pick(ImageSource.gallery),
        throwsFormatException,
      );
    },
  );
}
