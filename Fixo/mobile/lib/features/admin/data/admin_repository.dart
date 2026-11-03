import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class AdminAccess {
  const AdminAccess(this.role, this.needsConfirmation);
  final String role;
  final bool needsConfirmation;
  bool get isOwner => role == 'OWNER';
  factory AdminAccess.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    if (!['OWNER', 'ADMIN'].contains(role) ||
        json['canManageMembers'] != (role == 'OWNER') ||
        json['needsConfirmation'] is! bool) {
      throw const FormatException('Invalid administration access.');
    }
    return AdminAccess(role as String, json['needsConfirmation'] as bool);
  }
}

class AdminSummary {
  const AdminSummary(
    this.users,
    this.professionals,
    this.pendingReviews,
    this.activeBookings,
    this.collectedCashEgp,
  );
  final int users,
      professionals,
      pendingReviews,
      activeBookings,
      collectedCashEgp;
  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw const FormatException('Invalid administration statistics.');
      }
      return value;
    }

    return AdminSummary(
      count('users'),
      count('professionals'),
      count('pendingReviews'),
      count('activeBookings'),
      count('collectedCashEgp'),
    );
  }
}

class AdminMember {
  const AdminMember(
    this.email,
    this.role,
    this.active,
    this.bound,
    this.expiresAt,
  );
  final String email, role;
  final bool active, bound;
  final DateTime? expiresAt;
  factory AdminMember.fromJson(Map<String, dynamic> json) {
    if (json['email'] is! String ||
        !['OWNER', 'ADMIN'].contains(json['role']) ||
        json['isActive'] is! bool) {
      throw const FormatException('Invalid administration member.');
    }
    return AdminMember(
      json['email'] as String,
      json['role'] as String,
      json['isActive'] as bool,
      json['userId'] != null,
      json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class AdminAuditEvent {
  const AdminAuditEvent(this.action, this.createdAt);
  final String action;
  final DateTime createdAt;
  factory AdminAuditEvent.fromJson(Map<String, dynamic> json) =>
      AdminAuditEvent(
        json['action'] as String,
        DateTime.parse(json['createdAt'] as String),
      );
}

bool needsAdminConfirmation(Object error) =>
    error is DioException &&
    error.response?.data is Map &&
    (error.response!.data as Map)['code'] == 'ADMIN_REAUTH_REQUIRED';

class AdminRepository {
  AdminRepository(this._dio, {String? account}) : _account = account;
  final Dio _dio;
  final String? _account;
  Options get _options =>
      Options(extra: {if (_account != null) 'fixo_session_user': _account});
  Future<AdminAccess> access({CancelToken? cancelToken}) async =>
      AdminAccess.fromJson(
        (await _dio.get<Map<String, dynamic>>(
          '/admin/me',
          options: _options,
          cancelToken: cancelToken,
        )).data!,
      );
  Future<AdminSummary> summary({CancelToken? cancelToken}) async =>
      AdminSummary.fromJson(
        (await _dio.get<Map<String, dynamic>>(
          '/admin/summary',
          options: _options,
          cancelToken: cancelToken,
        )).data!,
      );
  Future<List<AdminMember>> members({CancelToken? cancelToken}) async =>
      (await _dio.get<List<dynamic>>(
            '/admin/members',
            options: _options,
            cancelToken: cancelToken,
          )).data!
          .map(
            (item) =>
                AdminMember.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
  Future<List<AdminAuditEvent>> audit({CancelToken? cancelToken}) async =>
      ((await _dio.get<Map<String, dynamic>>(
                '/admin/audit',
                options: _options,
                cancelToken: cancelToken,
              )).data!['items']
              as List)
          .map(
            (item) => AdminAuditEvent.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
  Future<void> invite(String email) async {
    await _dio.put<void>(
      '/admin/member',
      data: {'email': email.trim().toLowerCase()},
      options: _options,
    );
  }

  Future<void> revoke() async {
    await _dio.delete<void>('/admin/member', options: _options);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(
    ref.watch(dioClientProvider),
    account: ref.watch(
      authControllerProvider.select((s) => s.session?.user.id),
    ),
  ),
);

// Token changes also invalidate permissions after account confirmation/refresh.
final adminAccessProvider = FutureProvider.autoDispose<AdminAccess>((
  ref,
) async {
  final token = ref.watch(
    authControllerProvider.select((s) => s.session?.accessToken),
  );
  if (token == null) throw StateError('Sign in first.');
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  return ref.watch(adminRepositoryProvider).access(cancelToken: cancel);
});
final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((
  ref,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  await ref.watch(adminAccessProvider.future);
  if (cancel.isCancelled) throw cancel.cancelError!;
  return repository.summary(cancelToken: cancel);
});
final adminMembersProvider = FutureProvider.autoDispose<List<AdminMember>>((
  ref,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  final access = await ref.watch(adminAccessProvider.future);
  if (!access.isOwner) throw StateError('Owner access required.');
  if (cancel.isCancelled) throw cancel.cancelError!;
  return repository.members(cancelToken: cancel);
});
final adminAuditProvider = FutureProvider.autoDispose<List<AdminAuditEvent>>((
  ref,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  await ref.watch(adminAccessProvider.future);
  if (cancel.isCancelled) throw cancel.cancelError!;
  return repository.audit(cancelToken: cancel);
});
