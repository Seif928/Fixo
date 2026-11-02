import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/uploads/device_media_picker.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class AvatarRepository {
  const AvatarRepository(this._dio);
  final Dio _dio;
  Future<String> upload(PickedPrivateMedia photo) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/me/avatar',
      data: FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          base64Decode(photo.contentBase64),
          filename: photo.fileName,
          contentType: DioMediaType.parse(photo.mimeType),
        ),
      }),
    );
    final version = response.data?['avatarVersion'];
    if (response.data?['hasAvatar'] != true ||
        version is! String ||
        version.isEmpty) {
      throw const FormatException('Profile photo was not saved.');
    }
    return version;
  }

  Future<Uint8List> read() async {
    final response = await _dio.get<List<int>>(
      '/users/me/avatar',
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null) {
      throw const FormatException('Profile photo is unavailable.');
    }
    return Uint8List.fromList(response.data!);
  }
}

final avatarRepositoryProvider = Provider<AvatarRepository>(
  (ref) => AvatarRepository(ref.watch(dioClientProvider)),
);
final privateAvatarProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, key) async {
      bool active = true;
      ref.onDispose(() => active = false);
      final userId = key.split(':').first;
      if (ref.watch(authControllerProvider).session?.user.id != userId) {
        return null;
      }
      final bytes = await ref.read(avatarRepositoryProvider).read();
      if (!active ||
          ref.read(authControllerProvider).session?.user.id != userId) {
        return null;
      }
      return bytes;
    });
