import '../../auth/domain/auth_models.dart';
import 'profile_models.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(this.message, {this.statusCode, this.code});

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
