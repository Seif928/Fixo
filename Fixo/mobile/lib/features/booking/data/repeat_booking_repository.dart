import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../customer_home/domain/marketplace_models.dart';

class RepeatBookingException implements Exception {
  const RepeatBookingException({
    required this.code,
    required this.messageEn,
    required this.messageAr,
  });

  final String code;
  final String messageEn;
  final String messageAr;

  String localizedMessage(bool isArabic) => isArabic ? messageAr : messageEn;

  @override
  String toString() => 'RepeatBookingException($code: $messageEn)';
}

class RepeatBookingQuote {
  const RepeatBookingQuote({
    required this.originalBookingId,
    required this.orderCode,
    required this.offeringId,
    required this.offeringSlug,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.baseInspectionEgp,
    required this.serviceFeeEgp,
    required this.flatPriceEgp,
    required this.estimatedDurationMins,
    required this.categorySlug,
    required this.categoryNameEn,
    required this.categoryNameAr,
    required this.categoryIcon,
    required this.isOfferingActive,
    this.preferredPro,
    this.defaultAddressId,
  });

  final String originalBookingId;
  final String orderCode;
  final String offeringId;
  final String offeringSlug;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final int baseInspectionEgp;
  final int serviceFeeEgp;
  final int flatPriceEgp;
  final int estimatedDurationMins;
  final String categorySlug;
  final String categoryNameEn;
  final String categoryNameAr;
  final String categoryIcon;
  final bool isOfferingActive;
  final Map<String, dynamic>? preferredPro;
  final String? defaultAddressId;

  ServiceOfferModel toServiceOfferModel() {
    return ServiceOfferModel(
      id: offeringId,
      categoryId: categorySlug,
      categorySlug: categorySlug,
      slug: offeringSlug,
      titleEn: titleEn,
      titleAr: titleAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      baseInspectionEgp: baseInspectionEgp,
      serviceFeeEgp: serviceFeeEgp,
      flatPriceEgp: flatPriceEgp,
      estimatedDurationMins: estimatedDurationMins,
      isSeasonalPromo: false,
      isBundle: false,
    );
  }

  ProfessionalCardModel? toProfessionalCardModel() {
    if (preferredPro == null) return null;
    return ProfessionalCardModel(
      id: preferredPro!['id'] as String? ?? '',
      fullNameEn: preferredPro!['fullNameEn'] as String? ?? 'FIXO technician',
      fullNameAr: preferredPro!['fullNameAr'] as String? ?? 'فني معتمد',
      primaryCategoryId: categorySlug,
      primaryCategorySlug: categorySlug,
      primaryZoneSlug: '',
      specialtyEn: preferredPro!['specialtyEn'] as String? ?? '',
      specialtyAr: preferredPro!['specialtyAr'] as String? ?? '',
      zonesLabelEn: '',
      zonesLabelAr: '',
      ratingAvg: (preferredPro!['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: 1,
      estimatedPriceEgp: flatPriceEgp,
      badgeEn: 'Preferred Pro',
      badgeAr: 'الفني السابق',
      badgeVariant: 'preferred',
      isOnline: preferredPro!['isOnline'] as bool? ?? false,
    );
  }

  factory RepeatBookingQuote.fromJson(Map<String, dynamic> json) {
    final off = (json['offering'] as Map<String, dynamic>?) ?? {};
    final base = (off['baseInspectionEgp'] as num?)?.toInt() ?? 150;
    final fee = (off['serviceFeeEgp'] as num?)?.toInt() ?? 50;
    final addr = (json['defaultAddress'] as Map<String, dynamic>?);
    return RepeatBookingQuote(
      originalBookingId: json['originalBookingId'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      offeringId: off['id'] as String? ?? '',
      offeringSlug: off['slug'] as String? ?? '',
      titleEn: off['titleEn'] as String? ?? '',
      titleAr: off['titleAr'] as String? ?? '',
      descriptionEn: off['descriptionEn'] as String? ?? '',
      descriptionAr: off['descriptionAr'] as String? ?? '',
      baseInspectionEgp: base,
      serviceFeeEgp: fee,
      flatPriceEgp: (off['flatPriceEgp'] as num?)?.toInt() ?? (base + fee),
      estimatedDurationMins:
          (off['estimatedDurationMins'] as num?)?.toInt() ?? 60,
      categorySlug: off['categorySlug'] as String? ?? '',
      categoryNameEn: off['categoryNameEn'] as String? ?? '',
      categoryNameAr: off['categoryNameAr'] as String? ?? '',
      categoryIcon: off['categoryIcon'] as String? ?? 'handyman',
      isOfferingActive: off['isActive'] as bool? ?? true,
      preferredPro: json['preferredPro'] as Map<String, dynamic>?,
      defaultAddressId: addr?['id'] as String?,
    );
  }
}

class RepeatBookingRepository {
  const RepeatBookingRepository(this._dio);

  final Dio _dio;

  Future<RepeatBookingQuote> getRepeatQuote(String bookingId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/bookings/$bookingId/repeat-quote',
      );
      return RepeatBookingQuote.fromJson(response.data ?? {});
    } on DioException catch (e) {
      final respData = e.response?.data;
      String? code;
      if (respData is Map<String, dynamic>) {
        if (respData['message'] is Map) {
          code = (respData['message'] as Map)['code'] as String?;
        }
        code ??= respData['code'] as String? ?? respData['message'] as String?;
      }
      if (code == 'SERVICE_DEACTIVATED') {
        throw const RepeatBookingException(
          code: 'SERVICE_DEACTIVATED',
          messageEn:
              'This service is currently unavailable or deactivated and cannot be rebooked.',
          messageAr: 'هذه الخدمة غير متاحة حالياً أو معطلة ولا يمكن إعادة حجزها.',
        );
      }
      if (code == 'CATEGORY_DEACTIVATED') {
        throw const RepeatBookingException(
          code: 'CATEGORY_DEACTIVATED',
          messageEn:
              'This service category is currently inactive and cannot be rebooked.',
          messageAr: 'قسم هذه الخدمة معطل حالياً ولا يمكن إعادة حجزها.',
        );
      }
      rethrow;
    }
  }
}

final repeatBookingRepositoryProvider = Provider<RepeatBookingRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return RepeatBookingRepository(dio);
});
