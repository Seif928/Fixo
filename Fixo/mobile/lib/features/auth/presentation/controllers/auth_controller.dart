import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_models.dart';

/// Represents the two visual states of Screen 02 (`02 — Phone Auth & OTP`).
enum PhoneAuthStep { phoneInput, otpCode }

class AuthState {
  const AuthState({
    this.step = PhoneAuthStep.phoneInput,
    this.phoneInput = '010 9593 0009',
    this.otpCode = '',
    this.challenge,
    this.resendCountdownSec = 0,
    this.isLoading = false,
    this.errorMessage,
    this.session,
  });

  final PhoneAuthStep step;
  final String phoneInput;
  final String otpCode;
  final OtpChallengeResult? challenge;
  final int resendCountdownSec;
  final bool isLoading;
  final String? errorMessage;
  final AuthSession? session;

  bool get isAuthenticated => session != null;

  String get formattedPhoneForDisplay =>
      EgyptPhoneValidator.formatForDisplay(challenge?.phone ?? phoneInput);

  AuthState copyWith({
    PhoneAuthStep? step,
    String? phoneInput,
    String? otpCode,
    OtpChallengeResult? challenge,
    int? resendCountdownSec,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AuthSession? session,
    bool clearSession = false,
  }) {
    return AuthState(
      step: step ?? this.step,
      phoneInput: phoneInput ?? this.phoneInput,
      otpCode: otpCode ?? this.otpCode,
      challenge: challenge ?? this.challenge,
      resendCountdownSec: resendCountdownSec ?? this.resendCountdownSec,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      session: clearSession ? null : (session ?? this.session),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  Timer? _countdownTimer;

  @override
  AuthState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const AuthState();
  }

  void updatePhoneInput(String value) {
    state = state.copyWith(phoneInput: value, clearError: true);
  }

  void clearPhoneInput() {
    state = state.copyWith(phoneInput: '', clearError: true);
  }

  void switchStep(PhoneAuthStep targetStep) {
    state = state.copyWith(step: targetStep, clearError: true);
  }

  void setOtpCode(String code) {
    final digitsOnly = code.replaceAll(RegExp(r'\D'), '');
    final clipped = digitsOnly.length > 6
        ? digitsOnly.substring(0, 6)
        : digitsOnly;
    state = state.copyWith(otpCode: clipped, clearError: true);
  }

  void appendOtpDigit(String digit) {
    if (state.otpCode.length >= 6 || state.isLoading) {
      return;
    }
    final cleanDigit = digit.replaceAll(RegExp(r'\D'), '');
    if (cleanDigit.isEmpty) {
      return;
    }
    state = state.copyWith(
      otpCode: '${state.otpCode}${cleanDigit[0]}',
      clearError: true,
    );
  }

  void backspaceOtpDigit() {
    if (state.otpCode.isEmpty || state.isLoading) {
      return;
    }
    state = state.copyWith(
      otpCode: state.otpCode.substring(0, state.otpCode.length - 1),
      clearError: true,
    );
  }

  Future<bool> requestOtp({bool isArabic = false}) async {
    final validationError = EgyptPhoneValidator.validate(
      state.phoneInput,
      isArabic: isArabic,
    );
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError, isLoading: false);
      return false;
    }

    final normalizedPhone = EgyptPhoneValidator.tryNormalize(state.phoneInput)!;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final challenge = await repo.requestOtp(phone: normalizedPhone);

      _startResendCountdown(challenge.resendAvailableInSec);
      state = state.copyWith(
        isLoading: false,
        step: PhoneAuthStep.otpCode,
        challenge: challenge,
        resendCountdownSec: challenge.resendAvailableInSec,
        clearError: true,
      );
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: isArabic
            ? 'تعذر إرسال رمز التحقق حالياً. يرجى المحاولة مرة أخرى.'
            : 'Unable to request OTP code right now. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resendOtp({bool isArabic = false}) async {
    if (state.resendCountdownSec > 0 || state.isLoading) {
      return false;
    }
    return requestOtp(isArabic: isArabic);
  }

  Future<bool> verifyOtp({bool isArabic = false}) async {
    final validationError = EgyptPhoneValidator.validate(
      state.challenge?.phone ?? state.phoneInput,
      isArabic: isArabic,
    );
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError, isLoading: false);
      return false;
    }

    if (state.otpCode.length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(state.otpCode)) {
      state = state.copyWith(
        errorMessage: isArabic
            ? 'يرجى إدخال رمز التحقق المكون من 6 أرقام كاملاً.'
            : 'Please enter the complete 6-digit verification code.',
        isLoading: false,
      );
      return false;
    }

    final normalizedPhone = EgyptPhoneValidator.tryNormalize(
      state.challenge?.phone ?? state.phoneInput,
    )!;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.verifyOtp(
        phone: normalizedPhone,
        code: state.otpCode,
        challengeId: state.challenge?.challengeId,
      );

      final tokenStorage = ref.read(secureTokenStorageProvider);
      await tokenStorage.saveTokens(
        StoredAuthTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          userId: session.user.id,
          phone: session.user.phone,
          role: session.user.role,
        ),
      );

      _countdownTimer?.cancel();
      state = state.copyWith(
        isLoading: false,
        session: session,
        clearError: true,
      );
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: isArabic
            ? 'فشل التحقق من الرمز. يرجى التأكد من الرمز والمحاولة مجدداً.'
            : 'Failed to verify code. Please check the code and try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.session?.refreshToken;
    final tokenStorage = ref.read(secureTokenStorageProvider);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await ref.read(authRepositoryProvider).logout(refreshToken: refreshToken);
    }
    await tokenStorage.clearTokens();
    _countdownTimer?.cancel();
    state = const AuthState();
  }

  void _startResendCountdown(int initialSeconds) {
    _countdownTimer?.cancel();
    var remaining = initialSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(resendCountdownSec: 0);
      } else {
        state = state.copyWith(resendCountdownSec: remaining);
      }
    });
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
