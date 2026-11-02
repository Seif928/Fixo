import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class PickedPrivateMedia {
  const PickedPrivateMedia({
    required this.fileName,
    required this.mimeType,
    required this.contentBase64,
    required this.sourceLabelEn,
    required this.sourceLabelAr,
  });
  final String fileName, mimeType, contentBase64, sourceLabelEn, sourceLabelAr;
}

class DeviceMediaPicker {
  DeviceMediaPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  bool get supportsCamera =>
      kIsWeb ||
      const [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);

  Future<PickedPrivateMedia?> pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
      throw const FormatException('Choose a photo up to 2 MB.');
    }
    final String mime, extension;
    if (bytes.length >= 8 &&
        listEquals(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10])) {
      mime = 'image/png';
      extension = 'png';
    } else if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      mime = 'image/jpeg';
      extension = 'jpg';
    } else if (bytes.length >= 12 &&
        ascii.decode(bytes.take(4).toList(), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      mime = 'image/webp';
      extension = 'webp';
    } else {
      throw const FormatException('Choose a JPEG, PNG or WebP photo.');
    }
    final camera = source == ImageSource.camera;
    return PickedPrivateMedia(
      fileName: 'photo.$extension',
      mimeType: mime,
      contentBase64: base64Encode(bytes),
      sourceLabelEn: camera ? 'Camera' : 'Photo library',
      sourceLabelAr: camera ? 'الكاميرا' : 'معرض الصور',
    );
  }
}

final deviceMediaPickerProvider = Provider<DeviceMediaPicker>(
  (ref) => DeviceMediaPicker(),
);
