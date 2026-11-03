import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../booking/domain/booking_models.dart';
import '../domain/pro_models.dart';

/// Central repository for Professional Partner Onboarding, Verification, Dispatch, and Execution.
class ProRepository {
  const ProRepository(this._dio);

  final Dio _dio;

  /// Fetches trade categories, sub-skills, zones, transport modes, and experience tiers.
  Future<ProCatalogOptionsModel> getCatalogOptions() async {
    final response = await _dio.get('/pro/catalog-options');
    final data = response.data as Map<String, dynamic>;
    return ProCatalogOptionsModel.fromJson(data);
  }

  /// Fetches current professional profile details via `GET /api/v1/pro/me`.
  Future<ProProfileModel?> getMyProfile() async {
    try {
      final response = await _dio.get('/pro/me');
      final data = response.data as Map<String, dynamic>;
      if (!data.containsKey('profile')) {
        throw const FormatException('Professional profile is unavailable.');
      }
      if (data['profile'] == null) return null;
      final profile = data['profile'];
      if (profile is! Map<String, dynamic> ||
          profile['id'] is! String ||
          (profile['id'] as String).isEmpty ||
          profile['userId'] is! String ||
          (profile['userId'] as String).isEmpty ||
          !const [
            'DRAFT',
            'PENDING_REVIEW',
            'APPROVED',
            'ACTION_REQUIRED',
            'SUSPENDED',
          ].contains(profile['verificationStatus'])) {
        throw const FormatException('Professional profile is unavailable.');
      }
      return ProProfileModel.fromJson(profile);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Saves Step 1: name and National ID. Legacy optional transport is supported.
  Future<ProProfileModel> savePersonalDetails({
    String? fullName,
    required String nationalIdSynthetic,
    String? primaryZoneId,
    String? transportMode,
    String? vehicleDescription,
    String? vehiclePlateAr,
  }) async {
    final response = await _dio.post(
      '/pro/onboarding/personal',
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'fullName': fullName.trim(),
        'nationalIdSynthetic': nationalIdSynthetic.trim(),
        'primaryZoneId': ?primaryZoneId,
        'transportMode': ?transportMode,
        if (vehicleDescription != null && vehicleDescription.trim().isNotEmpty)
          'vehicleDescription': vehicleDescription.trim(),
        if (vehiclePlateAr != null && vehiclePlateAr.trim().isNotEmpty)
          'vehiclePlateAr': vehiclePlateAr.trim(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ProProfileModel.fromJson(data);
  }

  /// Saves Step 2: Trade Skills & Greater Cairo Coverage (`PUT /api/v1/pro/onboarding/skills`).
  Future<ProProfileModel> saveSkillsAndCoverage({
    required String primaryCategoryId,
    List<String> subSkillIds = const [],
    required String experienceTier,
    required List<String> coverageZoneIds,
    required bool acceptsStandardRateCard,
    required bool toolkitCommitmentConfirmed,
    String? specialtyEn,
    String? specialtyAr,
    int? estimatedPriceEgp,
  }) async {
    final response = await _dio.put(
      '/pro/onboarding/skills',
      data: {
        'primaryCategoryId': primaryCategoryId,
        if (subSkillIds.isNotEmpty) 'subSkillIds': subSkillIds,
        'experienceTier': experienceTier,
        'coverageZoneIds': coverageZoneIds,
        'acceptsStandardRateCard': acceptsStandardRateCard,
        'toolkitCommitmentConfirmed': toolkitCommitmentConfirmed,
        if (specialtyEn != null && specialtyEn.trim().isNotEmpty)
          'specialtyEn': specialtyEn.trim(),
        if (specialtyAr != null && specialtyAr.trim().isNotEmpty)
          'specialtyAr': specialtyAr.trim(),
        if (estimatedPriceEgp != null && estimatedPriceEgp > 0)
          'estimatedPriceEgp': estimatedPriceEgp,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ProProfileModel.fromJson(data);
  }

  /// Saves Step 3: Verification Document Upload (`POST /api/v1/pro/onboarding/documents`).
  Future<ProDocumentModel> uploadVerificationDocument({
    required String docType,
    required String fileName,
    required String mimeType,
    required String contentBase64,
  }) async {
    final response = await _dio.post(
      '/pro/onboarding/documents',
      data: {
        'docType': docType,
        'fileName': fileName,
        'mimeType': mimeType,
        'contentBase64': contentBase64,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ProDocumentModel.fromJson(data);
  }

  /// Submits Dossier for Verification (`POST /api/v1/pro/onboarding/submit`).
  Future<ProVerificationStatusModel> submitForVerification() async {
    final response = await _dio.post('/pro/onboarding/submit');
    final data = response.data as Map<String, dynamic>;
    return ProVerificationStatusModel.fromJson(data);
  }

  /// Fetches real verification status & review notes (`GET /api/v1/pro/onboarding/status`).
  Future<ProVerificationStatusModel> getVerificationStatus() async {
    final response = await _dio.get('/pro/onboarding/status');
    final data = response.data as Map<String, dynamic>;
    return ProVerificationStatusModel.fromJson(data);
  }

  /// Toggles online/offline availability for dispatch (`PATCH /api/v1/pro/availability`).
  Future<bool> updateAvailability(bool isOnline) async {
    final response = await _dio.patch(
      '/pro/availability',
      data: {'isOnline': isOnline},
    );
    final data = response.data as Map<String, dynamic>;
    return data['isOnline'] as bool? ?? isOnline;
  }

  /// Fetches real professional dashboard metrics (`GET /api/v1/pro/dashboard`).
  Future<ProDashboardModel> getDashboard() async {
    final response = await _dio.get('/pro/dashboard');
    final data = response.data as Map<String, dynamic>;
    return ProDashboardModel.fromJson(data);
  }

  /// Fetches incoming job offer detail (`GET /api/v1/pro/job-offers/:id`).
  Future<JobOfferModel> getJobOfferById(String offerId) async {
    final response = await _dio.get('/pro/job-offers/$offerId');
    final data = response.data as Map<String, dynamic>;
    return JobOfferModel.fromJson(data);
  }

  /// Accepts a job offer with atomic row-level lock (`POST /api/v1/pro/job-offers/:id/accept`).
  Future<JobOfferModel> acceptJobOffer(String offerId) async {
    final response = await _dio.post('/pro/job-offers/$offerId/accept');
    final data = response.data as Map<String, dynamic>;
    return JobOfferModel.fromJson(data);
  }

  /// Declines an incoming job offer (`POST /api/v1/pro/job-offers/:id/decline`).
  Future<JobOfferModel> declineJobOffer(
    String offerId, {
    String? reason,
  }) async {
    final response = await _dio.post(
      '/pro/job-offers/$offerId/decline',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    return JobOfferModel.fromJson(data);
  }

  /// Advances booking status with server-verified arrival PIN (`POST /api/v1/pro/bookings/:id/status`).
  Future<BookingDetailModel> advanceBookingStatus(
    String bookingId, {
    required String toStatus,
    String? arrivalPinCode,
    String? note,
  }) async {
    final response = await _dio.post(
      '/pro/bookings/$bookingId/status',
      data: {
        'toStatus': toStatus,
        if (arrivalPinCode != null && arrivalPinCode.isNotEmpty)
          'arrivalPinCode': arrivalPinCode.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    return BookingDetailModel.fromJson(data);
  }
}

final proRepositoryProvider = Provider<ProRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProRepository(dio);
});
