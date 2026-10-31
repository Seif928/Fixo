import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_models.dart';

/// Exception thrown by authentication API operations with user-readable message.
class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<OtpChallengeResult> requestOtp({required String phone});

  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? challengeId,
  });

  Future<AuthSession> refreshSession({required String refreshToken});

  Future<void> logout({required String refreshToken});

  Future<AuthUser> fetchCurrentUser();
}

/// Real Dio-backed implementation of `AuthRepository` talking to NestJS `/api/v1`.
class DioAuthRepository implements AuthRepository {
  const DioAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<OtpChallengeResult> requestOtp({required String phone}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/otp/request',
        data: <String, dynamic>{'phone': phone},
      );
      return OtpChallengeResult.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallback: 'Unable to send SMS verification code. Please check your connection.',
      );
    }
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? challengeId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/otp/verify',
        data: <String, dynamic>{
          'phone': phone,
          'code': code,
          if (challengeId != null && challengeId.isNotEmpty)
            'challengeId': challengeId,
        },
      );
      return AuthSession.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallback: 'Invalid or expired verification code. Please try again.',
      );
    }
  }

  @override
  Future<AuthSession> refreshSession({required String refreshToken}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      return AuthSession.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallback: 'Session expired. Please sign in again.',
      );
    }
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/logout',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
    } on DioException {
      // Always allow local token cleanup even if server is unreachable during logout
    }
  }

  @override
  Future<AuthUser> fetchCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      final data = response.data ?? const <String, dynamic>{};
      final userJson =
          (data['user'] as Map<String, dynamic>?) ?? data;
      return AuthUser.fromJson(userJson);
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallback: 'Failed to load user profile.',
      );
    }
  }

  AuthApiException _mapDioException(
    DioException error, {
    required String fallback,
  }) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        return AuthApiException(rawMessage, statusCode: statusCode);
      }
      if (rawMessage is List && rawMessage.isNotEmpty) {
        return AuthApiException(
          rawMessage.first.toString(),
          statusCode: statusCode,
        );
      }
    }
    return AuthApiException(fallback, statusCode: statusCode);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DioAuthRepository(dio);
});

