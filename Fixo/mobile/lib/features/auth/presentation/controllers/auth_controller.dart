import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../../../core/storage/auth_session_preferences.dart';
import '../../../../core/session/session_providers.dart';
import '../../../../core/notifications/device_push_service.dart';
import '../../data/auth_repository.dart';
import '../../data/email_access_service.dart';
import '../../domain/auth_models.dart';

/// Represents the two visual states of Screen 02 (`02 — Phone Auth & OTP`).
enum PhoneAuthStep { phoneInput, otpCode }

class AuthState {
  const AuthState({
    this.step = PhoneAuthStep.phoneInput,
    this.phoneInput = '',
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
  int _sessionEpoch = 0;
  bool _disposed = false;
  Future<void>? _restoring;
  Completer<void>? _localLogout;

  @override
  AuthState build() {
    ref.listen(sessionExpiredProvider, (_, _) {
      if (_localLogout != null) return;
      _sessionEpoch++;
      _countdownTimer?.cancel();
      ref.read(activeSessionOwnerProvider.notifier).state = null;
      ref.read(sessionProvider.notifier).state = null;
      state = const AuthState();
      unawaited(ref.read(authSessionPreferencesProvider).clearSession());
      unawaited(ref.read(devicePushProvider).invalidateLocalSession());
    });
    ref.onDispose(() {
      _disposed = true;
      _countdownTimer?.cancel();
    });

    final authPrefs = ref.read(authSessionPreferencesProvider);
    final savedSession = authPrefs.getSavedSession();
    if (savedSession != null && authPrefs.isLoggedIn) {
      return AuthState(session: savedSession);
    }

    return const AuthState();
  }

  @override
  set state(AuthState value) {
    super.state = value;
    final session = value.session;
    if (ref.read(sessionProvider) != session) {
      ref.read(sessionProvider.notifier).state = session;
      ref.read(activeSessionOwnerProvider.notifier).state = session?.user.id;
    }
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

      await acceptVerifiedSession(session);
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
    if (_localLogout != null) {
      await _localLogout!.future;
      return;
    }
    final localDone = Completer<void>();
    _localLogout = localDone;
    _sessionEpoch++;
    final tokenStorage = ref.read(secureTokenStorageProvider);
    final repository = ref.read(authRepositoryProvider);
    final email = ref.read(emailAccessProvider);
    final userId = state.session?.user.id;
    final userEmail = state.session?.user.email;
    String? tokenToRevoke;
    try {
      try {
        await ref.read(devicePushProvider).disable();
      } catch (_) {
        /* Sign-out works offline. */
      }
      final latest = await tokenStorage.readTokens();
      if (latest != null && (userId == null || latest.userId == userId)) {
        tokenToRevoke = latest.refreshToken;
        await tokenStorage.replaceTokensIfCurrent(latest, null);
      }
      await ref.read(authSessionPreferencesProvider).clearSession();
      await email.signOutIfCurrent(userEmail);
    } finally {
      _countdownTimer?.cancel();
      if (!_disposed) {
        ref.read(activeSessionOwnerProvider.notifier).state = null;
        ref.read(sessionProvider.notifier).state = null;
        state = const AuthState();
      }
      _localLogout = null;
      localDone.complete();
    }
    // Nothing after the local transition may clear tokens or sign out a newer identity.
    if (tokenToRevoke != null && tokenToRevoke.isNotEmpty) {
      await repository.logout(refreshToken: tokenToRevoke);
    }
  }

  /// Cached profile data never establishes identity; the server refresh does.
  Future<void> restoreSession() => _restoring ??= _restoreSession(
    _sessionEpoch,
  ).whenComplete(() => _restoring = null);

  Future<void> _restoreSession(int epoch) async {
    final storage = ref.read(secureTokenStorageProvider);
    final authPrefs = ref.read(authSessionPreferencesProvider);
    StoredAuthTokens? restoringTokens;
    try {
      var tokens = await storage.readTokens();
      tokens ??= authPrefs.getSavedTokens();
      if (tokens == null || tokens.refreshToken.isEmpty) return;
      restoringTokens = tokens;
      final session = await ref
          .read(authRepositoryProvider)
          .refreshSession(refreshToken: tokens.refreshToken);
      if (_disposed || epoch != _sessionEpoch) return;
      if (session.user.id != tokens.userId) {
        await storage.replaceTokensIfCurrent(tokens, null);
        await authPrefs.clearSession();
        return;
      }
      final replaced = await storage.replaceTokensIfCurrent(
        tokens,
        _storedSession(session),
      );
      if (!replaced || _disposed || epoch != _sessionEpoch) return;
      await authPrefs.saveSession(session);
      _sessionEpoch++;
      _publishSession(session);
    } on AuthApiException catch (error) {
      if (!_disposed &&
          epoch == _sessionEpoch &&
          [400, 401, 403].contains(error.statusCode)) {
        await storage.replaceTokensIfCurrent(restoringTokens, null);
        await authPrefs.clearSession();
        if (state.isAuthenticated) {
          state = const AuthState();
          ref.read(sessionProvider.notifier).state = null;
          ref.read(activeSessionOwnerProvider.notifier).state = null;
        }
      }
    } on FormatException {
      if (!_disposed && epoch == _sessionEpoch) {
        await storage.replaceTokensIfCurrent(restoringTokens, null);
        await authPrefs.clearSession();
        if (state.isAuthenticated) {
          state = const AuthState();
          ref.read(sessionProvider.notifier).state = null;
          ref.read(activeSessionOwnerProvider.notifier).state = null;
        }
      }
    } catch (_) {
      // Offline or network error: if the user was already logged in via preferences,
      // preserve their authenticated session so they stay logged in!
      if (!_disposed && epoch == _sessionEpoch) {
        if (!state.isAuthenticated && authPrefs.isLoggedIn) {
          final cached = authPrefs.getSavedSession();
          if (cached != null) {
            _publishSession(cached);
          }
        }
      }
    }
  }

  Future<void> acceptVerifiedSession(AuthSession session) async {
    if (_disposed || _localLogout != null) {
      throw StateError('Sign-out is still completing.');
    }
    final epoch = ++_sessionEpoch;
    await ref
        .read(secureTokenStorageProvider)
        .saveTokens(_storedSession(session));
    await ref.read(authSessionPreferencesProvider).saveSession(session);
    if (_disposed || epoch != _sessionEpoch) {
      throw StateError('The account changed before sign-in completed.');
    }
    _publishSession(session);
    if (_restoring == null) unawaited(ref.read(devicePushProvider).resume());
  }

  StoredAuthTokens _storedSession(AuthSession session) => StoredAuthTokens(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    userId: session.user.id,
    phone: session.user.phone,
    role: session.user.role,
  );

  void _publishSession(AuthSession session) {
    _countdownTimer?.cancel();
    ref.read(activeSessionOwnerProvider.notifier).state = session.user.id;
    ref.read(sessionProvider.notifier).state = session;
    state = state.copyWith(
      isLoading: false,
      session: session,
      clearError: true,
    );
  }

  /// Profile requests may rotate tokens; never replace them with a stale pair.
  Future<void> acceptUpdatedProfile(AuthUser user) async {
    final epoch = ++_sessionEpoch;
    final tokens = await ref.read(secureTokenStorageProvider).readTokens();
    if (_disposed ||
        _localLogout != null ||
        epoch != _sessionEpoch ||
        tokens == null ||
        tokens.userId != user.id ||
        state.session?.user.id != user.id) {
      throw const FormatException('The account session has ended.');
    }
    final updated = StoredAuthTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userId: user.id,
      phone: user.phone,
      role: user.role,
    );
    if (!await ref
            .read(secureTokenStorageProvider)
            .replaceTokensIfCurrent(tokens, updated) ||
        _disposed ||
        epoch != _sessionEpoch) {
      throw const FormatException('The account session has changed.');
    }
    final updatedSession = AuthSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: user,
    );
    await ref.read(authSessionPreferencesProvider).saveSession(updatedSession);
    ref.read(sessionProvider.notifier).state = updatedSession;
    state = state.copyWith(session: updatedSession);
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
