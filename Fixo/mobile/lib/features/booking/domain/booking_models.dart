import 'package:flutter/material.dart';
import '../../customer_home/domain/marketplace_models.dart';

/// Represents a customer's saved service delivery address in Cairo / Giza.
class CustomerAddressModel {
  const CustomerAddressModel({
    required this.id,
    required this.userId,
    required this.zoneId,
    required this.label,
    required this.buildingLine,
    required this.districtLine,
    this.gateNotes,
    this.zone,
    this.isDefault = false,
  });

  final String id;
  final String userId;
  final String zoneId;
  final String label;
  final String buildingLine;
  final String districtLine;
  final String? gateNotes;
  final CoverageZoneModel? zone;
  final bool isDefault;

  String get fullAddress => '$buildingLine, $districtLine';

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    return CustomerAddressModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      zoneId: json['zoneId'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      buildingLine: json['buildingLine'] as String? ?? '',
      districtLine: json['districtLine'] as String? ?? '',
      gateNotes: json['gateNotes'] as String?,
      zone: json['zone'] != null
          ? CoverageZoneModel.fromJson(json['zone'] as Map<String, dynamic>)
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'zoneId': zoneId,
        'label': label,
        'buildingLine': buildingLine,
        'districtLine': districtLine,
        'gateNotes': gateNotes,
        'isDefault': isDefault,
      };
}

/// EGP pricing breakdown returned by the FIXO backend.
class BookingPricingModel {
  const BookingPricingModel({
    required this.baseInspectionEgp,
    required this.serviceFeeEgp,
    required this.transportFeeEgp,
    required this.totalEgp,
    this.platformFeeEgp,
    this.netArtisanEgp,
    this.currency = 'EGP',
  });

  final int baseInspectionEgp;
  final int serviceFeeEgp;
  final int transportFeeEgp;
  final int totalEgp;

  /// Internal artisan platform fee (10%). Note: NOT charged to customer on Screen 04.
  final int? platformFeeEgp;

  /// Internal artisan net pay.
  final int? netArtisanEgp;

  final String currency;

  factory BookingPricingModel.fromJson(Map<String, dynamic> json) {
    return BookingPricingModel(
      baseInspectionEgp: (json['baseInspectionEgp'] as num?)?.toInt() ?? 150,
      serviceFeeEgp: (json['serviceFeeEgp'] as num?)?.toInt() ?? 250,
      transportFeeEgp: (json['transportFeeEgp'] as num?)?.toInt() ?? 0,
      totalEgp: (json['totalEgp'] as num?)?.toInt() ?? 400,
      platformFeeEgp: (json['platformFeeEgp'] as num?)?.toInt(),
      netArtisanEgp: (json['netArtisanEgp'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'EGP',
    );
  }

  Map<String, dynamic> toJson() => {
        'baseInspectionEgp': baseInspectionEgp,
        'serviceFeeEgp': serviceFeeEgp,
        'transportFeeEgp': transportFeeEgp,
        'totalEgp': totalEgp,
        'platformFeeEgp': platformFeeEgp,
        'netArtisanEgp': netArtisanEgp,
        'currency': currency,
      };
}

/// Full details of a persisted customer booking.
class BookingDetailModel {
  const BookingDetailModel({
    required this.id,
    required this.orderCode,
    required this.customerId,
    this.proProfileId,
    required this.offeringId,
    required this.addressId,
    required this.status,
    required this.scheduledDate,
    required this.timeWindow,
    this.issueDescription,
    this.issuePhotoUrls = const [],
    required this.pricing,
    this.arrivalPinCode,
    this.offering = const {},
    this.address = const {},
    this.proProfile,
    this.statusEvents = const [],
    required this.createdAt,
  });

  final String id;
  final String orderCode;
  final String customerId;
  final String? proProfileId;
  final String offeringId;
  final String addressId;
  final String status;
  final String scheduledDate;
  final String timeWindow;
  final String? issueDescription;
  final List<String> issuePhotoUrls;
  final BookingPricingModel pricing;

  /// Sensitive 4-digit artisan arrival PIN.
  /// Note: Exposed strictly on Screen 06 (Order Tracking), NOT displayed on Screen 04.
  final String? arrivalPinCode;

  final Map<String, dynamic> offering;
  final Map<String, dynamic> address;
  final Map<String, dynamic>? proProfile;
  final List<dynamic> statusEvents;
  final String createdAt;

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      id: json['id'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      proProfileId: json['proProfileId'] as String?,
      offeringId: json['offeringId'] as String? ?? '',
      addressId: json['addressId'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      scheduledDate: json['scheduledDate'] as String? ?? '',
      timeWindow: json['timeWindow'] as String? ?? 'AFTERNOON_13_16',
      issueDescription: json['issueDescription'] as String?,
      issuePhotoUrls: (json['issuePhotoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pricing: json['pricing'] != null
          ? BookingPricingModel.fromJson(json['pricing'] as Map<String, dynamic>)
          : BookingPricingModel.fromJson(json),
      arrivalPinCode: json['arrivalPinCode'] as String?,
      offering: (json['offering'] as Map<String, dynamic>?) ?? const {},
      address: (json['address'] as Map<String, dynamic>?) ?? const {},
      proProfile: json['proProfile'] as Map<String, dynamic>?,
      statusEvents: (json['statusEvents'] as List<dynamic>?) ?? const [],
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Payload sent to `POST /api/v1/bookings` to create a booking draft.
class CreateBookingRequest {
  const CreateBookingRequest({
    required this.offeringId,
    required this.addressId,
    this.preferredProId,
    required this.scheduledDate,
    required this.timeWindow,
    this.issueDescription,
    this.issuePhotoUrls = const [],
  });

  final String offeringId;
  final String addressId;
  final String? preferredProId;
  final String scheduledDate;
  final String timeWindow;
  final String? issueDescription;
  final List<String> issuePhotoUrls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'offeringId': offeringId,
      'addressId': addressId,
      'scheduledDate': scheduledDate,
      'timeWindow': timeWindow,
    };
    if (preferredProId != null && preferredProId!.isNotEmpty) {
      map['preferredProId'] = preferredProId;
    }
    if (issueDescription != null && issueDescription!.trim().isNotEmpty) {
      map['issueDescription'] = issueDescription!.trim();
    }
    if (issuePhotoUrls.isNotEmpty) {
      map['issuePhotoUrls'] = issuePhotoUrls;
    }
    return map;
  }
}

/// Representation of the 3 canonical time slots for Screen 04.
class TimeWindowSlot {
  const TimeWindowSlot({
    required this.key,
    required this.titleEn,
    required this.titleAr,
    required this.timeRangeEn,
    required this.timeRangeAr,
    required this.icon,
  });

  final String key;
  final String titleEn;
  final String titleAr;
  final String timeRangeEn;
  final String timeRangeAr;
  final IconData icon;

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String localizedTimeRange(bool isArabic) => isArabic ? timeRangeAr : timeRangeEn;

  static const List<TimeWindowSlot> all = [
    TimeWindowSlot(
      key: 'MORNING_09_12',
      titleEn: 'Morning Window',
      titleAr: 'الفترة الصباحية',
      timeRangeEn: '09:00 AM – 12:00 PM',
      timeRangeAr: '٠٩:٠٠ ص – ١٢:٠٠ م',
      icon: Icons.wb_twilight_rounded,
    ),
    TimeWindowSlot(
      key: 'AFTERNOON_13_16',
      titleEn: 'Afternoon Window',
      titleAr: 'فترة بعد الظهر',
      timeRangeEn: '01:00 PM – 04:00 PM',
      timeRangeAr: '٠١:٠٠ م – ٠٤:٠٠ م',
      icon: Icons.wb_sunny_rounded,
    ),
    TimeWindowSlot(
      key: 'EVENING_17_20',
      titleEn: 'Evening Window',
      titleAr: 'الفترة المسائية',
      timeRangeEn: '05:00 PM – 08:00 PM',
      timeRangeAr: '٠٥:٠٠ م – ٠٨:٠٠ م',
      icon: Icons.bedtime_rounded,
    ),
  ];
}

