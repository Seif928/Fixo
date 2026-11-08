import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/profile_models.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

abstract class ProfileRepository {
  Future<UserProfile> getProfile();

  Future<UserProfile> updateProfile({
    String? fullName,
    String? phone,
    String? password,
  });

  Future<AuthSession> updatePhoneAlias({
    required String phone,
    required String password,
  });

  Future<void> updateNotificationPreferences({
    required bool arrivalAlertsEnabled,
  });
}

class DioProfileRepository implements ProfileRepository {
  const DioProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      final data = response.data;
      if (data == null) {
        throw const ProfileApiException('User profile data is missing.');
      }
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not load profile. Please retry.');
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? fullName,
    String? phone,
    String? password,
  }) async {
    if (phone != null && password != null) {
      final session = await updatePhoneAlias(phone: phone, password: password);
      return UserProfile.fromAuthUser(session.user);
    }
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/me/profile',
        data: <String, dynamic>{
          if (fullName != null) 'fullName': fullName.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ProfileApiException('Failed to update profile.');
      }
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not update profile. Please retry.');
    }
  }

  @override
  Future<AuthSession> updatePhoneAlias({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/phone-alias',
        data: <String, dynamic>{
          'phone': phone,
          'password': password,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ProfileApiException('Invalid phone update response.');
      }
      return AuthSession.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(
        e,
        fallback:
            'This phone cannot be used for this account. Check it or retry.',
      );
    }
  }

  @override
  Future<void> updateNotificationPreferences({
    required bool arrivalAlertsEnabled,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/users/me/notification-preferences',
        data: <String, dynamic>{
          'arrivalAlertsEnabled': arrivalAlertsEnabled,
        },
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        fallback: 'Could not save notification preferences.',
      );
    }
  }

  ProfileApiException _mapError(
    DioException error, {
    required String fallback,
  }) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'];
      final code = data['errorCode'] ?? data['code'];
      if (msg is String && msg.trim().isNotEmpty) {
        return ProfileApiException(
          msg,
          statusCode: statusCode,
          code: code is String ? code : null,
        );
      }
    }
    return ProfileApiException(fallback, statusCode: statusCode);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DioProfileRepository(dio);
});
