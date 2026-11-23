import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_models.dart';
import '../storage/secure_token_storage.dart';

/// Pure domain/core session provider holding the active authenticated [AuthSession].
///
/// Clean Architecture role: Core Infrastructure / Session State.
/// Data layer repositories and domain services can freely read or watch this
/// provider without depending on Presentation layer UI controllers.
final sessionProvider = StateProvider<AuthSession?>((ref) => null);

/// Exposes the active JWT access token for authorized requests and token-invalidation listeners.
final sessionTokenProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider)?.accessToken;
});

/// Exposes the currently authenticated [AuthUser] entity.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(sessionProvider)?.user;
});

/// Exposes the active user ID, aligning [sessionProvider] with [activeSessionOwnerProvider].
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider)?.user.id ??
      ref.watch(activeSessionOwnerProvider);
});

/// Convenience provider indicating whether a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider) != null;
});
