import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'admin_catalog_models.dart';
import 'admin_professional_models.dart';
import 'admin_booking_models.dart';
import 'dart:typed_data';

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
  Future<AdminBookingPage> bookings({
    int page = 1,
    String? status,
    String? search,
    CancelToken? cancelToken,
  }) async => AdminBookingPage(
    (await _dio.get<Map<String, dynamic>>(
      '/admin/bookings',
      options: _options,
      cancelToken: cancelToken,
      queryParameters: {
        'page': page,
        if (status?.isNotEmpty == true) 'status': status,
        if (search?.isNotEmpty == true) 'search': search,
      },
    )).data!,
  );
  Future<AdminBookingDetail> booking(
    String id, {
    CancelToken? cancelToken,
  }) async => AdminBookingDetail(
    (await _dio.get<Map<String, dynamic>>(
      '/admin/bookings/${Uri.encodeComponent(id)}',
      options: _options,
      cancelToken: cancelToken,
    )).data!,
  );
  Future<AdminCandidatePage> bookingCandidates(
    String id, {
    int page = 1,
    CancelToken? cancelToken,
  }) async => AdminCandidatePage(
    (await _dio.get<Map<String, dynamic>>(
      '/admin/bookings/${Uri.encodeComponent(id)}/candidates',
      options: _options,
      cancelToken: cancelToken,
      queryParameters: {'page': page},
    )).data!,
  );
  Future<void> cancelBooking(
    AdminBookingDetail detail,
    String reason, {
    CancelToken? cancelToken,
  }) async {
    await _dio.post<void>(
      '/admin/bookings/${Uri.encodeComponent(detail.summary.id)}/cancel',
      options: _options,
      cancelToken: cancelToken,
      data: {'version': detail.version, 'reason': reason.trim()},
    );
  }

  Future<void> offerBooking(
    AdminBookingDetail detail,
    String proId, {
    CancelToken? cancelToken,
  }) async {
    await _dio.post<void>(
      '/admin/bookings/${Uri.encodeComponent(detail.summary.id)}/offer',
      options: _options,
      cancelToken: cancelToken,
      data: {'version': detail.version, 'proProfileId': proId},
    );
  }

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

  Future<AdminCatalogPageModel> catalog({
    int page = 1,
    String? search,
    String? category,
    CancelToken? cancelToken,
  }) async => AdminCatalogPageModel.fromJson(
    (await _dio.get<Map<String, dynamic>>(
      '/admin/catalog',
      options: _options,
      cancelToken: cancelToken,
      queryParameters: {
        'page': page,
        if (search?.isNotEmpty == true) 'search': search,
        if (category?.isNotEmpty == true) 'category': category,
      },
    )).data!,
  );
  Future<AdminCatalogDraft> saveDraft(
    AdminCatalogDraft draft,
    Map<String, dynamic> fields,
  ) async => AdminCatalogDraft.fromJson(
    (await _dio.put<Map<String, dynamic>>(
      '/admin/catalog/${Uri.encodeComponent(draft.id)}',
      options: _options,
      data: {...fields, 'version': draft.version},
    )).data!,
  );
  Future<void> publishDraft(AdminCatalogDraft draft) async {
    await _dio.post<void>(
      '/admin/catalog/${Uri.encodeComponent(draft.id)}/publish',
      options: _options,
      data: {'version': draft.version},
    );
  }

  Future<AdminProfessionalPage> professionals({
    int page = 1,
    String? status,
    String? search,
    CancelToken? cancelToken,
  }) async => AdminProfessionalPage.fromJson(
    (await _dio.get<Map<String, dynamic>>(
      '/admin/professionals',
      options: _options,
      cancelToken: cancelToken,
      queryParameters: {
        'page': page,
        if (status?.isNotEmpty == true) 'status': status,
        if (search?.isNotEmpty == true) 'search': search,
      },
    )).data!,
  );
  Future<AdminProfessionalDetail> professional(
    String id, {
    CancelToken? cancelToken,
  }) async => AdminProfessionalDetail.fromJson(
    (await _dio.get<Map<String, dynamic>>(
      '/admin/professionals/${Uri.encodeComponent(id)}',
      options: _options,
      cancelToken: cancelToken,
    )).data!,
  );
  Future<AdminPrivateDocument> professionalDocument(
    String profileId,
    String docId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<List<int>>(
      '/admin/professionals/${Uri.encodeComponent(profileId)}/documents/${Uri.encodeComponent(docId)}/content',
      options: _options.copyWith(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
    );
    final bytes = response.data;
    final mime = response.headers
        .value('content-type')
        ?.split(';')
        .first
        .trim();
    if (bytes == null ||
        bytes.isEmpty ||
        bytes.length > 2 * 1024 * 1024 ||
        ![
          'image/jpeg',
          'image/png',
          'image/webp',
          'application/pdf',
        ].contains(mime)) {
      throw const FormatException('Private document unavailable.');
    }
    return AdminPrivateDocument(Uint8List.fromList(bytes), mime!);
  }

  Future<void> reviewProfessional(
    AdminProfessionalDetail detail,
    String status,
    String note, {
    required bool confirmed,
    List<String> rejectedTypes = const [],
  }) async {
    await _dio.patch<void>(
      '/admin/professionals/${Uri.encodeComponent(detail.summary.id)}/review',
      options: _options,
      data: {
        'status': status,
        'reviewVersion': detail.reviewVersion,
        'confirmDocumentsReviewed': confirmed,
        if (note.trim().isNotEmpty) 'reviewerNote': note.trim(),
        if (rejectedTypes.isNotEmpty)
          'documentDecisions': [
            for (final type in rejectedTypes)
              {'docType': type, 'status': 'REJECTED'},
          ],
      },
    );
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

final adminCatalogRevisionProvider = StateProvider.autoDispose<int>((ref) => 0);
final adminBookingsRevisionProvider = StateProvider.autoDispose<int>(
  (ref) => 0,
);
final adminProfessionalsRevisionProvider = StateProvider.autoDispose<int>(
  (ref) => 0,
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
