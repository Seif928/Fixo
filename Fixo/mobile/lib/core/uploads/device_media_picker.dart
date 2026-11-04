import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_locale_controller.dart';
import '../storage/secure_token_storage.dart';

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
  DeviceMediaPicker([ImagePicker? picker]) : this._(picker ?? ImagePicker());
  DeviceMediaPicker.recoverable({
    ImagePicker? picker,
    required SharedPreferences preferences,
    required String? Function() owner,
    DateTime Function()? now,
  }) : this._(
         picker ?? ImagePicker(),
         preferences: preferences,
         owner: owner,
         now: now,
       );
  DeviceMediaPicker._(
    this._picker, {
    SharedPreferences? preferences,
    String? Function()? owner,
    DateTime Function()? now,
  }) : _preferences = preferences,
       _owner = owner,
       _now = now ?? DateTime.now;
  final ImagePicker _picker;
  final SharedPreferences? _preferences;
  final String? Function()? _owner;
  final DateTime Function() _now;
  static const _intentKey = 'fixo.photo-pick.intent.v1';
  Future<void>? _preparation;
  _RecoveredPhoto? _recovered;
  Object? _recoveryError;
  int _generation = 0;
  bool _picking = false;

  Future<void> _clearIntent(String? raw) async {
    if (raw != null && _preferences?.getString(_intentKey) == raw) {
      if (!await _preferences!.remove(_intentKey)) {
        throw StateError('Could not clear interrupted photo metadata.');
      }
    }
  }

  /// Reads Android's one interrupted result once, without requesting permission
  /// or uploading anything. Only a short-lived owner/scope tag is persisted.
  Future<void> prepareRecovery() =>
      _preferences == null ? Future.value() : (_preparation ??= _recover());
  Future<void> _recover() async {
    final raw = _preferences!.getString(_intentKey), generation = _generation;
    final intent = _PhotoIntent.parse(raw);
    try {
      final result = await _picker.retrieveLostData().timeout(
        const Duration(seconds: 5),
      );
      if (generation != _generation ||
          intent == null ||
          !intent.valid(_owner?.call(), _now()) ||
          result.isEmpty) {
        return;
      }
      if (result.exception != null) throw result.exception!;
      final files = result.files ?? [if (result.file != null) result.file!];
      if (result.type != RetrieveType.image || files.length != 1) {
        throw const FormatException('Interrupted photo is unavailable.');
      }
      final photo = await _readPhoto(
        files.single,
        intent.source,
      ).timeout(const Duration(seconds: 10));
      if (generation == _generation && intent.valid(_owner?.call(), _now())) {
        _recovered = _RecoveredPhoto(intent, photo, generation);
      }
    } catch (error) {
      if (generation == _generation &&
          intent?.valid(_owner?.call(), _now()) == true) {
        _recoveryError = error;
      }
    } finally {
      try {
        await _clearIntent(raw);
      } catch (error) {
        _recovered = null;
        _recoveryError = error;
      }
    }
  }

  Future<PickedPrivateMedia?> recoveredFor(String scope) async {
    await prepareRecovery();
    if (_recoveryError != null) {
      final error = _recoveryError!;
      _recoveryError = null;
      throw error;
    }
    final cached = _recovered;
    if (cached == null) return null;
    if (cached.generation != _generation ||
        !cached.intent.valid(_owner?.call(), _now())) {
      _recovered = null;
      return null;
    }
    return cached.intent.scope == scope ? cached.photo : null;
  }

  Future<PickedPrivateMedia?> takeRecovered(String scope) async {
    final photo = await recoveredFor(scope);
    if (photo != null) _recovered = null;
    return photo;
  }

  Future<void> discardRecovered(String scope) async {
    if (_recovered?.intent.scope == scope) _recovered = null;
  }

  Future<void> invalidateRecovery() async {
    _generation++;
    _recovered = null;
    _recoveryError = null;
    await _clearIntent(_preferences?.getString(_intentKey));
  }

  Future<PickedPrivateMedia?> pickFor(
    ImageSource source, {
    required String scope,
  }) async {
    if (_preferences == null) return pick(source);
    if (_picking) throw StateError('A photo selection is already open.');
    _picking = true;
    String? raw;
    try {
      final owner = _owner?.call(), generation = _generation;
      await prepareRecovery();
      if (generation != _generation || owner != _owner?.call()) return null;
      _recovered = null;
      _recoveryError = null;
      if (!RegExp(r'^[A-Za-z0-9:_-]{1,200}$').hasMatch(scope)) {
        throw const FormatException('Invalid photo selection scope.');
      }
      if (owner != null) {
        raw = jsonEncode({
          'nonce':
              '${_now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
          'owner': owner,
          'scope': scope,
          'source': source.name,
          'createdAt': _now().toUtc().toIso8601String(),
        });
        if (!await _preferences.setString(_intentKey, raw)) {
          throw StateError('Could not prepare photo recovery.');
        }
      }
      if (generation != _generation || owner != _owner?.call()) return null;
      final photo = await pick(source);
      return generation == _generation && owner == _owner?.call()
          ? photo
          : null;
    } finally {
      _picking = false;
      await _clearIntent(raw);
    }
  }

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
    return _readPhoto(file, source);
  }

  Future<PickedPrivateMedia> _readPhoto(XFile file, ImageSource source) async {
    final length = await file.length();
    if (length <= 0 || length > 2 * 1024 * 1024) {
      throw const FormatException('Choose a photo up to 2 MB.');
    }
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

final deviceMediaPickerProvider = Provider<DeviceMediaPicker>((ref) {
  final preferences = ref.watch(appPreferencesProvider);
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      preferences == null) {
    return DeviceMediaPicker();
  }
  final picker = DeviceMediaPicker.recoverable(
    preferences: preferences,
    owner: () => ref.read(activeSessionOwnerProvider),
  );
  ref.listen(activeSessionOwnerProvider, (_, _) {
    picker.invalidateRecovery().catchError((Object _) {});
  });
  return picker;
});

class _PhotoIntent {
  const _PhotoIntent(this.owner, this.scope, this.source, this.createdAt);
  final String owner, scope;
  final ImageSource source;
  final DateTime createdAt;
  bool valid(String? current, DateTime now) =>
      current == owner &&
      now.difference(createdAt).inMilliseconds >= -60000 &&
      now.difference(createdAt) <= const Duration(minutes: 30);
  static _PhotoIntent? parse(String? raw) {
    try {
      if (raw == null || raw.length > 2048) return null;
      final value = jsonDecode(raw) as Map;
      final owner = value['owner'] as String,
          scope = value['scope'] as String,
          source = value['source'] as String,
          nonce = value['nonce'] as String;
      if (owner.isEmpty ||
          owner.length > 100 ||
          nonce.isEmpty ||
          nonce.length > 100 ||
          !RegExp(r'^[A-Za-z0-9:_-]{1,200}$').hasMatch(scope) ||
          !['camera', 'gallery'].contains(source)) {
        return null;
      }
      return _PhotoIntent(
        owner,
        scope,
        source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        DateTime.parse(value['createdAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

class _RecoveredPhoto {
  const _RecoveredPhoto(this.intent, this.photo, this.generation);
  final _PhotoIntent intent;
  final PickedPrivateMedia photo;
  final int generation;
}
