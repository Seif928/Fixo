import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.profile,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final UserProfile? profile;
  final String? errorMessage;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProfileController extends Notifier<ProfileState> {
  int _requestEpoch = 0;
  bool _disposed = false;

  @override
  ProfileState build() {
    ref.onDispose(() {
      _disposed = true;
    });

    // Synchronize with auth session changes
    ref.listen(authControllerProvider, (previous, next) {
      if (next.session == null) {
        _requestEpoch++;
        state = const ProfileState();
      } else if (previous?.session?.user.id != next.session?.user.id) {
        loadProfile();
      }
    });

    final currentSession = ref.read(authControllerProvider).session;
    if (currentSession != null) {
      Future<void>.microtask(loadProfile);
      return const ProfileState(isLoading: true);
    }
    return const ProfileState();
  }

  Future<void> loadProfile() async {
    if (_disposed || state.isSaving) return;
    final initialSession = ref.read(authControllerProvider).session;
    if (initialSession == null) {
      state = const ProfileState();
      return;
    }

    final epoch = ++_requestEpoch;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(profileRepositoryProvider);
      final profile = await repository.getProfile();
      final activeSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          activeSession == null ||
          activeSession.user.id != initialSession.user.id) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        profile: profile,
        clearError: true,
      );
    } on ProfileApiException catch (e) {
      final activeSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          activeSession == null ||
          activeSession.user.id != initialSession.user.id) {
        return;
      }
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      final activeSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          activeSession == null ||
          activeSession.user.id != initialSession.user.id) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load profile. Please retry.',
      );
    }
  }

  Future<void> updateDisplayName(String fullName) async {
    final currentSession = ref.read(authControllerProvider).session;
    final ownerId = currentSession?.user.id;
    if (ownerId == null) throw StateError('No active account session.');

    state = state.copyWith(isSaving: true, clearError: true);
    final epoch = ++_requestEpoch;
    try {
      final repository = ref.read(profileRepositoryProvider);
      final updatedProfile = await repository.updateProfile(fullName: fullName);
      final activeSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          activeSession?.user.id != ownerId) {
        return;
      }

      // Propagate to AuthController
      await ref
          .read(authControllerProvider.notifier)
          .acceptUpdatedProfile(updatedProfile.toAuthUser());

      final finalSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          finalSession?.user.id != ownerId) {
        return;
      }

      state = state.copyWith(
        isSaving: false,
        profile: updatedProfile.copyWith(
          addresses: state.profile?.addresses ?? const [],
        ),
        clearError: true,
      );
    } catch (e) {
      final activeSession = ref.read(authControllerProvider).session;
      if (!_disposed &&
          epoch == _requestEpoch &&
          activeSession?.user.id == ownerId) {
        state = state.copyWith(isSaving: false);
      }
      rethrow;
    }
  }

  Future<void> updatePhone({
    required String phone,
    required String password,
  }) async {
    final currentSession = ref.read(authControllerProvider).session;
    final ownerId = currentSession?.user.id;
    if (ownerId == null) throw StateError('No active account session.');

    state = state.copyWith(isSaving: true, clearError: true);
    final epoch = ++_requestEpoch;
    try {
      final repository = ref.read(profileRepositoryProvider);
      final session = await repository.updatePhoneAlias(
        phone: phone,
        password: password,
      );
      final activeSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          activeSession?.user.id != ownerId) {
        return;
      }

      if (session.user.id != ownerId) {
        throw const FormatException('Account changed.');
      }

      // Propagate new verified session to AuthController
      await ref
          .read(authControllerProvider.notifier)
          .acceptVerifiedSession(session);

      final finalSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          finalSession?.user.id != ownerId) {
        return;
      }

      state = state.copyWith(
        isSaving: false,
        profile: UserProfile.fromAuthUser(
          session.user,
          arrivalAlertsEnabled: state.profile?.arrivalAlertsEnabled ?? false,
          addresses: state.profile?.addresses ?? const [],
        ),
        clearError: true,
      );
    } catch (e) {
      final activeSession = ref.read(authControllerProvider).session;
      if (!_disposed &&
          epoch == _requestEpoch &&
          activeSession?.user.id == ownerId) {
        state = state.copyWith(isSaving: false);
      }
      rethrow;
    }
  }

  Future<void> updateNotificationPreferences({
    required bool arrivalAlertsEnabled,
  }) async {
    final currentSession = ref.read(authControllerProvider).session;
    final ownerId = currentSession?.user.id;
    if (ownerId == null) throw StateError('No active account session.');

    state = state.copyWith(isSaving: true, clearError: true);
    final epoch = ++_requestEpoch;
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateNotificationPreferences(
        arrivalAlertsEnabled: arrivalAlertsEnabled,
      );
      final activeSession = ref.read(authControllerProvider).session;
      if (_disposed ||
          epoch != _requestEpoch ||
          activeSession?.user.id != ownerId) {
        return;
      }
      state = state.copyWith(
        isSaving: false,
        profile: state.profile?.copyWith(
          arrivalAlertsEnabled: arrivalAlertsEnabled,
        ),
        clearError: true,
      );
    } catch (e) {
      final activeSession = ref.read(authControllerProvider).session;
      if (!_disposed &&
          epoch == _requestEpoch &&
          activeSession?.user.id == ownerId) {
        state = state.copyWith(isSaving: false);
      }
      rethrow;
    }
  }

  void updateAvatarVersion(String version) {
    final activeSession = ref.read(authControllerProvider).session;
    if (_disposed || activeSession == null || state.profile == null) return;
    state = state.copyWith(
      profile: state.profile!.copyWith(hasAvatar: true, avatarVersion: version),
    );
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);
