import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';

class SupportRepository {
  SupportRepository(this.dio);
  final Dio dio;
  String root(bool admin) =>
      admin ? '/support/admin/threads' : '/support/threads';
  Future<List<Map<String, dynamic>>> list({
    bool admin = false,
    String? thread,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '${root(admin)}${thread == null ? '' : '/${Uri.encodeComponent(thread)}/messages'}',
    );
    return (response.data!['items'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<void> send(String thread, String body, {bool admin = false}) async {
    await dio.post(
      '${root(admin)}/${Uri.encodeComponent(thread)}/messages',
      data: {'body': body},
    );
  }

  Future<void> close(String thread) async {
    await dio.patch('${root(true)}/${Uri.encodeComponent(thread)}/close');
  }

  Future<String> create(String subject, String body) async {
    final result = await dio.post<Map<String, dynamic>>(
      root(false),
      data: {'subject': subject, 'body': body},
    );
    return result.data!['id'] as String;
  }
}

final supportRepositoryProvider = Provider(
  (ref) => SupportRepository(ref.watch(dioClientProvider)),
);
