import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/chat/data/communications_repository.dart';

class RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  dynamic response = {'items': [], 'nextCursor': null};
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      response is String ? response : '{"items":[],"nextCursor":null}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'message send contains text only and never a client supplied sender',
    () async {
      final adapter = RecordingAdapter()
        ..response =
            '{"id":"m1","bookingId":"b1","senderUserId":"server-user","body":"Hello","readAt":null,"createdAt":"2026-11-01T10:00:00Z"}';
      final repo = CommunicationsRepository(Dio()..httpClientAdapter = adapter);
      final message = await repo.send('b1', '  Hello  ');
      expect(adapter.request!.path, '/bookings/b1/messages');
      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.data, {'body': 'Hello'});
      expect(message.senderUserId, 'server-user');
    },
  );
  test(
    'history uses bounded server pagination and read acknowledgement uses PATCH',
    () async {
      final adapter = RecordingAdapter();
      final repo = CommunicationsRepository(Dio()..httpClientAdapter = adapter);
      await repo.messages('b1', before: 'cursor');
      expect(adapter.request!.queryParameters, {
        'limit': 30,
        'before': 'cursor',
      });
      await repo.markRead('b1', 'm1');
      expect(adapter.request!.method, 'PATCH');
      expect(adapter.request!.path, '/bookings/b1/messages/m1/read');
    },
  );
}
