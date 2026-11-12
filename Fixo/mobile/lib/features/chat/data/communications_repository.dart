import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../core/uploads/device_media_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.hasAttachment = false,
  });
  final String id;
  final String senderUserId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool hasAttachment;
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        senderUserId: json['senderUserId'] as String,
        body: json['body'] as String,
        hasAttachment: json['hasAttachment'] == true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
      );
}

class MessagePage {
  const MessagePage(this.items, this.nextCursor);
  final List<ChatMessageModel> items;
  final String? nextCursor;
}

class CommunicationsRepository {
  const CommunicationsRepository(this.dio);
  final Dio dio;
  Future<ChatMessageModel> sendPhoto(
    String bookingId,
    PickedPrivateMedia photo,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/bookings/${Uri.encodeComponent(bookingId)}/messages/photo',
      data: FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          base64Decode(photo.contentBase64),
          filename: photo.fileName,
          contentType: DioMediaType.parse(photo.mimeType),
        ),
      }),
    );
    return ChatMessageModel.fromJson(response.data!);
  }

  Future<Uint8List> photo(String bookingId, String messageId) async {
    final response = await dio.get<List<int>>(
      '/bookings/${Uri.encodeComponent(bookingId)}/messages/${Uri.encodeComponent(messageId)}/photo',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
      throw const FormatException('Photo unavailable.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<MessagePage> messages(String bookingId, {String? before}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/bookings/${Uri.encodeComponent(bookingId)}/messages',
      queryParameters: {'limit': 30, 'before': ?before},
    );
    final data = response.data!;
    return MessagePage(
      (data['items'] as List)
          .map(
            (item) => ChatMessageModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      data['nextCursor'] as String?,
    );
  }

  Future<ChatMessageModel> send(String bookingId, String body) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/bookings/${Uri.encodeComponent(bookingId)}/messages',
      data: {'body': body.trim()},
    );
    return ChatMessageModel.fromJson(response.data!);
  }

  Future<void> markRead(String bookingId, String messageId) async {
    await dio.patch(
      '/bookings/${Uri.encodeComponent(bookingId)}/messages/${Uri.encodeComponent(messageId)}/read',
    );
  }

  Future<List<Map<String, dynamic>>> notifications() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/users/me/notifications',
    );
    return (response.data!['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}

final communicationsRepositoryProvider = Provider<CommunicationsRepository>(
  (ref) => CommunicationsRepository(ref.watch(dioClientProvider)),
);
