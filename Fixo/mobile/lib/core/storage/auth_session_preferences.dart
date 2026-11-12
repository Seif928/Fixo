import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_locale_controller.dart';
import '../../features/auth/domain/auth_models.dart';
import 'secure_token_storage.dart';

/// Keys used in [SharedPreferences] for authentication persistence.
abstract final class AuthPreferenceKeys {
  static const String isLoggedIn = 'fixo.auth.is_logged_in';
  static const String session = 'fixo.auth.session';
  static const String tokens = 'fixo.auth.tokens';
  static const String userId = 'fixo.auth.user_id';
  static const String userRole = 'fixo.auth.user_role';
  static const String userPhone = 'fixo.auth.user_phone';
  static const String onboardingCompleted = 'fixo.onboarding.completed';
}

/// Manages [SharedPreferences] persistence for authentication state and cached session.
///
/// Ensures the user stays logged in across app launches and restarts until they
/// explicitly perform a logout or their session is revoked by the server.
class AuthSessionPreferences {
  AuthSessionPreferences(this._prefs);

  final SharedPreferences? _prefs;

  /// Whether a user is currently considered logged in via preferences.
  bool get isLoggedIn {
    return _prefs?.getBool(AuthPreferenceKeys.isLoggedIn) == true;
  }

  /// Whether onboarding has already been completed or passed by the user.
  bool get isOnboardingCompleted {
    return _prefs?.getBool(AuthPreferenceKeys.onboardingCompleted) == true;
  }

  /// Sets whether onboarding has been completed.
  Future<bool> setOnboardingCompleted([bool completed = true]) async {
    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.setBool(AuthPreferenceKeys.onboardingCompleted, completed);
  }

  /// Returns the cached [AuthSession] from [SharedPreferences], or null if none exists.
  AuthSession? getSavedSession() {
    final prefs = _prefs;
    if (prefs == null) return null;
    if (!isLoggedIn) return null;
    final rawJson = prefs.getString(AuthPreferenceKeys.session);
    if (rawJson == null || rawJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return AuthSession.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt or unparseable cached session
    }
    return null;
  }

  /// Returns the cached [StoredAuthTokens] from [SharedPreferences], or null.
  StoredAuthTokens? getSavedTokens() {
    final prefs = _prefs;
    if (prefs == null) return null;
    final rawJson = prefs.getString(AuthPreferenceKeys.tokens);
    if (rawJson == null || rawJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return StoredAuthTokens.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt or unparseable cached tokens
    }
    return null;
  }

  /// Saves the active authenticated session and sets [isLoggedIn] to true.
  Future<void> saveSession(AuthSession session) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final tokens = StoredAuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.user.id,
      phone: session.user.phone,
      role: session.user.role,
    );

    await Future.wait([
      prefs.setBool(AuthPreferenceKeys.isLoggedIn, true),
      prefs.setString(AuthPreferenceKeys.session, jsonEncode(session.toJson())),
      prefs.setString(AuthPreferenceKeys.tokens, jsonEncode(tokens.toJson())),
      prefs.setString(AuthPreferenceKeys.userId, session.user.id),
      prefs.setString(AuthPreferenceKeys.userRole, session.user.role),
      prefs.setString(AuthPreferenceKeys.userPhone, session.user.phone),
      prefs.setBool(AuthPreferenceKeys.onboardingCompleted, true),
    ]);
  }

  /// Updates cached tokens when session is refreshed.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final existingSession = getSavedSession();
    if (existingSession != null) {
      final updated = AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: existingSession.user,
      );
      await saveSession(updated);
    }
  }

  /// Updates the cached user profile while preserving tokens.
  Future<void> updateProfile(AuthUser user) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final existingSession = getSavedSession();
    if (existingSession != null) {
      final updated = AuthSession(
        accessToken: existingSession.accessToken,
        refreshToken: existingSession.refreshToken,
        user: user,
      );
      await saveSession(updated);
    }
  }

  /// Clears the login flag and cached credentials from [SharedPreferences].
  ///
  /// Called ONLY on explicit user logout or server-confirmed 401/403 revocation.
  Future<void> clearSession() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await Future.wait([
      prefs.setBool(AuthPreferenceKeys.isLoggedIn, false),
      prefs.remove(AuthPreferenceKeys.session),
      prefs.remove(AuthPreferenceKeys.tokens),
      prefs.remove(AuthPreferenceKeys.userId),
      prefs.remove(AuthPreferenceKeys.userRole),
      prefs.remove(AuthPreferenceKeys.userPhone),
    ]);
  }
}

/// Provider exposing [AuthSessionPreferences] backed by the app's [SharedPreferences].
final authSessionPreferencesProvider = Provider<AuthSessionPreferences>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  return AuthSessionPreferences(prefs);
});

