import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/uploads/device_media_picker.dart';

class _RecoveryPicker extends ImagePicker {
  LostDataResponse lost = LostDataResponse.empty();
  XFile? selected;
  Future<XFile?>? pendingPick;
  Future<LostDataResponse>? pendingRecovery;
  void Function()? onPick;
  int recoveryCalls = 0;
  int pickCalls = 0;
  @override
  Future<LostDataResponse> retrieveLostData() async {
    recoveryCalls++;
    return pendingRecovery ?? lost;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    pickCalls++;
    onPick?.call();
    return pendingPick ?? selected;
  }
}

class _OversizeFile extends XFile {
  _OversizeFile() : super('unread-fixture');
  bool bytesRead = false;
  @override
  Future<int> length() async => 2 * 1024 * 1024 + 1;
  @override
  Future<Uint8List> readAsBytes() async {
    bytesRead = true;
    throw StateError('Oversized input must not be allocated');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'fixo.photo-pick.intent.v1';
  final started = DateTime.utc(2026, 11, 3, 10);
  final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);
  late SharedPreferences prefs;
  late _RecoveryPicker picker;
  String? owner;
  late DateTime now;
  Map<String, dynamic> intent({
    String scope = 'avatar',
    String account = 'owner-a',
  }) => {
    'nonce': 'fixture-pick',
    'owner': account,
    'scope': scope,
    'source': 'gallery',
    'createdAt': started.toIso8601String(),
  };
  DeviceMediaPicker service() => DeviceMediaPicker.recoverable(
    picker: picker,
    preferences: prefs,
    owner: () => owner,
    now: () => now,
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({key: jsonEncode(intent())});
    prefs = await SharedPreferences.getInstance();
    owner = 'owner-a';
    now = started;
    picker = _RecoveryPicker()
      ..lost = LostDataResponse(
        type: RetrieveType.image,
        files: [XFile.fromData(bytes, name: 'fixture.png')],
      );
  });
  test(
    'startup recovers into memory; only the matching form can explicitly consume it once',
    () async {
      final media = service();
      await media.prepareRecovery();
      expect(prefs.getString(key), isNull);
      expect(picker.recoveryCalls, 1);
      expect(await media.recoveredFor('review:booking-b'), isNull);
      final preview = await media.recoveredFor('avatar');
      expect(base64Decode(preview!.contentBase64), bytes);
      expect(await media.recoveredFor('avatar'), isNotNull);
      expect(await media.takeRecovered('avatar'), isNotNull);
      expect(await media.takeRecovered('avatar'), isNull);
      expect(picker.recoveryCalls, 1);
    },
  );
  test(
    'another account, no account, expired or malformed intent never receives recovered bytes',
    () async {
      for (final invalid in ['owner-b', null, 'expired', 'malformed']) {
        await prefs.setString(
          key,
          invalid == 'malformed' ? 'invalid-json' : jsonEncode(intent()),
        );
        owner = invalid == 'expired' || invalid == 'malformed'
            ? 'owner-a'
            : invalid;
        now = invalid == 'expired'
            ? started.add(const Duration(minutes: 31))
            : started;
        expect(await service().recoveredFor('avatar'), isNull);
        expect(prefs.getString(key), isNull);
      }
    },
  );
  test(
    'logging out invalidates recovered media even if the same account returns',
    () async {
      final media = service();
      expect(await media.recoveredFor('avatar'), isNotNull);
      owner = null;
      await media.invalidateRecovery();
      owner = 'owner-a';
      expect(await media.takeRecovered('avatar'), isNull);
    },
  );
  test(
    'ordinary selection records only bounded ownership/scope metadata then removes it',
    () async {
      await prefs.remove(key);
      picker.selected = XFile.fromData(bytes, name: 'fixture.png');
      picker.onPick = () {
        final raw = prefs.getString(key)!;
        final record = jsonDecode(raw) as Map;
        expect(record['owner'], 'owner-a');
        expect(record['scope'], 'review:booking-a');
        expect(record['source'], 'camera');
        expect(raw.length, lessThan(1024));
        expect(raw, isNot(contains(base64Encode(bytes))));
      };
      expect(
        await service().pickFor(ImageSource.camera, scope: 'review:booking-a'),
        isNotNull,
      );
      expect(prefs.getString(key), isNull);
    },
  );
  test('a late picker result cannot cross account changes', () async {
    await prefs.remove(key);
    final pending = Completer<XFile?>();
    picker.pendingPick = pending.future;
    final began = Completer<void>();
    picker.onPick = () => began.complete();
    final media = service();
    final result = media.pickFor(ImageSource.gallery, scope: 'avatar');
    await began.future;
    owner = 'owner-b';
    await media.invalidateRecovery();
    pending.complete(XFile.fromData(bytes, name: 'fixture.png'));
    expect(await result, isNull);
    expect(prefs.getString(key), isNull);
  });
  test(
    'platform recovery errors and unsupported media never create substitute photos',
    () async {
      picker.lost = LostDataResponse(
        exception: PlatformException(code: 'photo_access_denied'),
      );
      final media = service();
      await media.prepareRecovery();
      await expectLater(
        media.recoveredFor('avatar'),
        throwsA(isA<PlatformException>()),
      );
      expect(prefs.getString(key), isNull);
    },
  );
  test(
    'account changes during recovery preparation do not launch a new picker',
    () async {
      final recovery = Completer<LostDataResponse>();
      picker.pendingRecovery = recovery.future;
      final media = service();
      final selected = media.pickFor(ImageSource.gallery, scope: 'avatar');
      await Future<void>.delayed(Duration.zero);
      owner = 'owner-b';
      await media.invalidateRecovery();
      recovery.complete(LostDataResponse.empty());
      expect(await selected, isNull);
      expect(picker.pickCalls, 0);
    },
  );
  test('file length is bounded before reading photo bytes', () async {
    final file = _OversizeFile();
    picker.selected = file;
    await expectLater(
      DeviceMediaPicker(picker).pick(ImageSource.gallery),
      throwsFormatException,
    );
    expect(file.bytesRead, isFalse);
  });
  test(
    'video, multiple results and invalid image bytes are rejected after process recovery',
    () async {
      final file = XFile.fromData(bytes, name: 'fixture.png');
      for (final result in [
        LostDataResponse(type: RetrieveType.video, files: [file]),
        LostDataResponse(type: RetrieveType.image, files: [file, file]),
        LostDataResponse(
          type: RetrieveType.image,
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode('<svg/>')),
              name: 'fake.png',
            ),
          ],
        ),
      ]) {
        await prefs.setString(key, jsonEncode(intent()));
        picker.lost = result;
        await expectLater(
          service().recoveredFor('avatar'),
          throwsFormatException,
        );
        expect(prefs.getString(key), isNull);
      }
    },
  );
}
