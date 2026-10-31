/// Egyptian phone validation and authentication domain models for Screen 02.
abstract final class EgyptPhoneValidator {
  static final RegExp _e164Regex = RegExp(r'^\+201[0125]\d{8}$');

  /// Normalizes user input (`010 2345 6789`, `1023456789`, `+201023456789`)
  /// into canonical Egyptian E.164 (`+201XXXXXXXXX`), or returns `null` if invalid.
  static String? tryNormalize(String rawInput) {
    final compact = rawInput.replaceAll(RegExp(r'[\s\-().]'), '');
    if (compact.isEmpty) {
      return null;
    }

    String candidate = compact;
    if (candidate.startsWith('0020')) {
      candidate = '+20${candidate.substring(4)}';
    } else if (candidate.startsWith('+2001')) {
      candidate = '+201${candidate.substring(5)}';
    } else if (candidate.startsWith('201') && candidate.length == 12) {
      candidate = '+$candidate';
    } else if (candidate.startsWith('01') && candidate.length == 11) {
      candidate = '+20${candidate.substring(1)}';
    } else if (candidate.startsWith('1') && candidate.length == 10) {
      candidate = '+20$candidate';
    }

    if (!_e164Regex.hasMatch(candidate)) {
      return null;
    }
    return candidate;
  }

  /// Formats an E.164 Egyptian number (`+201023456789`) for display (`+20 102 345 6789`).
  static String formatForDisplay(String rawOrNormalized) {
    final normalized = tryNormalize(rawOrNormalized);
    if (normalized == null || normalized.length != 13) {
      return rawOrNormalized.trim().isEmpty
          ? '+20 102 345 6789'
          : rawOrNormalized;
    }
    final subscriber = normalized.substring(3); // 10 digits e.g. 1023456789
    return '+20 ${subscriber.substring(0, 3)} ${subscriber.substring(3, 6)} ${subscriber.substring(6)}';
  }

  /// Validates an Egyptian mobile number and returns a localized error message or `null`.
  static String? validate(String rawInput, {bool isArabic = false}) {
    if (rawInput.trim().isEmpty) {
      return isArabic
          ? 'يرجى إدخال رقم الموبايل المصري (+20).'
          : 'Please enter your Egyptian mobile number (+20).';
    }
    final normalized = tryNormalize(rawInput);
    if (normalized == null) {
      return isArabic
          ? 'رقم موبايل مصري غير صحيح. يجب أن يبدأ بـ 010 أو 011 أو 012 أو 015 ويتكون من 11 رقماً.'
          : 'Enter a valid Egyptian mobile number starting with 010, 011, 012, or 015.';
    }
    return null;
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    this.email,
    this.preferredLocale = 'en',
    this.rewardPoints = 0,
  });

  final String id;
  final String phone;
  final String fullName;
  final String role;
  final String? email;
  final String preferredLocale;
  final int rewardPoints;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? 'u-unknown',
      phone: json['phone'] as String? ?? '+201023456789',
      fullName: (json['fullName'] as String?)?.trim().isNotEmpty == true
          ? json['fullName'] as String
          : 'Cairo Homeowner',
      role: json['role'] as String? ?? 'CUSTOMER',
      email: json['email'] as String?,
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

class OtpChallengeResult {
  const OtpChallengeResult({
    required this.challengeId,
    required this.phone,
    required this.resendAvailableInSec,
    required this.expiresInSec,
    this.demoHint,
  });

  final String challengeId;
  final String phone;
  final int resendAvailableInSec;
  final int expiresInSec;
  final String? demoHint;

  factory OtpChallengeResult.fromJson(Map<String, dynamic> json) {
    return OtpChallengeResult(
      challengeId: json['challengeId'] as String? ?? '',
      phone: json['phone'] as String? ?? '+201023456789',
      resendAvailableInSec:
          (json['resendAvailableInSec'] as num?)?.toInt() ?? 45,
      expiresInSec: (json['expiresInSec'] as num?)?.toInt() ?? 300,
      demoHint: json['demoHint'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: AuthUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
    );
  }
}

