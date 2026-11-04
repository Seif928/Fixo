import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AccountDeletionRepository {
  const AccountDeletionRepository(this._dio);
  final Dio _dio;

  Future<void> deleteAccount() async {
    try {
      await _dio.post('/users/me/delete-account');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 && data is Map<String, dynamic>) {
        throw AccountDeletionException(
          data['message'] as String? ??
              'Cannot delete account with active or ongoing bookings.',
          code: data['code'] as String? ?? 'ACTIVE_BOOKINGS_EXIST',
        );
      }
      if (e.response?.statusCode == 403 && data is Map<String, dynamic>) {
        throw AccountDeletionException(
          data['message'] as String? ?? 'Admin accounts cannot be self-deleted.',
          code: data['code'] as String? ?? 'ADMIN_ACCOUNT_PROTECTED',
        );
      }
      rethrow;
    }
  }
}

final accountDeletionRepositoryProvider =
    Provider<AccountDeletionRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AccountDeletionRepository(dio);
});

