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
    this.latitude,
    this.longitude,
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
  final double? latitude, longitude;

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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Payload sent to `POST /api/v1/users/me/addresses` to persist a new customer address.
/// Note: userId is derived exclusively by the backend from the authenticated JWT session.
/// No GPS coordinates are fabricated.
class CreateAddressRequest {
  const CreateAddressRequest({
    required this.zoneId,
    required this.label,
    required this.buildingLine,
    required this.districtLine,
    this.gateNotes,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  final String zoneId;
  final String label;
  final String buildingLine;
  final String districtLine;
  final String? gateNotes;
  final bool isDefault;
  final double? latitude, longitude;

  CreateAddressRequest withCoordinates(double latitude, double longitude) =>
      CreateAddressRequest(
        zoneId: zoneId,
        label: label,
        buildingLine: buildingLine,
        districtLine: districtLine,
        gateNotes: gateNotes,
        isDefault: isDefault,
        latitude: latitude,
        longitude: longitude,
      );

  Map<String, dynamic> toJson() {
    if ((latitude == null) != (longitude == null) ||
        (latitude != null &&
            (!latitude!.isFinite ||
                latitude!.abs() > 90 ||
                !longitude!.isFinite ||
                longitude!.abs() > 180))) {
      throw ArgumentError('Both valid coordinates are required for a map pin.');
    }
    final map = <String, dynamic>{
      'zoneId': zoneId,
      'label': label.trim(),
      'buildingLine': buildingLine.trim(),
      'districtLine': districtLine.trim(),
      'isDefault': isDefault,
    };
    if (gateNotes != null && gateNotes!.trim().isNotEmpty) {
      map['gateNotes'] = gateNotes!.trim();
    }
    if (latitude != null) {
      map['latitude'] = latitude;
      map['longitude'] = longitude;
    }
    return map;
  }
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
    final baseInspection = (json['baseInspectionEgp'] as num?)?.toInt();
    final serviceFee = (json['serviceFeeEgp'] as num?)?.toInt();
    final transportFee = (json['transportFeeEgp'] as num?)?.toInt();
    final total = (json['totalEgp'] as num?)?.toInt();

    if (baseInspection == null || baseInspection < 0) {
      throw const FormatException(
        'Missing or invalid required price: baseInspectionEgp',
      );
    }
    if (serviceFee == null || serviceFee < 0) {
      throw const FormatException(
        'Missing or invalid required price: serviceFeeEgp',
      );
    }
    if (transportFee == null || transportFee < 0) {
      throw const FormatException(
        'Missing or invalid required price: transportFeeEgp',
      );
    }
    if (total == null || total < 0) {
      throw const FormatException(
        'Missing or invalid required price: totalEgp',
      );
    }

    return BookingPricingModel(
      baseInspectionEgp: baseInspection,
      serviceFeeEgp: serviceFee,
      transportFeeEgp: transportFee,
      totalEgp: total,
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

/// Details of an associated payment record.
class PaymentRecordModel {
  const PaymentRecordModel({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.status,
    required this.amountEgp,
    this.tipEgp = 0,
    this.externalReference,
    this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String method;
  final String status;
  final int amountEgp;
  final int tipEgp;
  final String? externalReference;
  final String? paidAt;
  final String createdAt;

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      method: json['method'] as String? ?? 'CASH_ON_SERVICE',
      status: json['status'] as String? ?? 'PENDING',
      amountEgp: (json['amountEgp'] as num?)?.toInt() ?? 0,
      tipEgp: (json['tipEgp'] as num?)?.toInt() ?? 0,
      externalReference: json['externalReference'] as String?,
      paidAt: json['paidAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'method': method,
    'status': status,
    'amountEgp': amountEgp,
    'tipEgp': tipEgp,
    'externalReference': externalReference,
    'paidAt': paidAt,
    'createdAt': createdAt,
  };
}

/// Details of a customer review submitted for a completed booking.
class BookingReviewModel {
  const BookingReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.proProfileId,
    required this.rating,
    this.tags = const [],
    this.comment,
    this.photoUrls = const [],
    this.tipAmountEgp = 0,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String proProfileId;
  final int rating;
  final List<String> tags;
  final String? comment;
  final List<String> photoUrls;
  final int tipAmountEgp;
  final String createdAt;

  factory BookingReviewModel.fromJson(Map<String, dynamic> json) {
    return BookingReviewModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      proProfileId: json['proProfileId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      comment: json['comment'] as String?,
      photoUrls:
          (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tipAmountEgp: (json['tipAmountEgp'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'customerId': customerId,
    'proProfileId': proProfileId,
    'rating': rating,
    'tags': tags,
    'comment': comment,
    'photoUrls': photoUrls,
    'tipAmountEgp': tipAmountEgp,
    'createdAt': createdAt,
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
    this.cancellationReason,
    required this.scheduledDate,
    required this.timeWindow,
    this.scheduledTime,
    this.issueDescription,
    this.issuePhotoUrls = const [],
    required this.pricing,
    this.arrivalPinCode,
    this.offering = const {},
    this.address = const {},
    this.proProfile,
    this.payment,
    this.review,
    this.statusEvents = const [],
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String orderCode;
  final String customerId;
  final String? proProfileId;
  final String offeringId;
  final String addressId;
  final String status;
  final String? cancellationReason;
  final String scheduledDate;
  final String timeWindow;
  final String? scheduledTime;
  final String? issueDescription;
  final List<String> issuePhotoUrls;
  final BookingPricingModel pricing;

  /// Sensitive 4-digit artisan arrival PIN.
  /// Note: Exposed strictly on Screen 06 (Order Tracking), NOT displayed on Screen 04.
  final String? arrivalPinCode;

  final Map<String, dynamic> offering;
  final Map<String, dynamic> address;
  final Map<String, dynamic>? proProfile;
  final PaymentRecordModel? payment;
  final BookingReviewModel? review;
  final List<dynamic> statusEvents;
  final String createdAt;
  final String? completedAt;

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      id: json['id'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      proProfileId: json['proProfileId'] as String?,
      offeringId: json['offeringId'] as String? ?? '',
      addressId: json['addressId'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      cancellationReason: json['cancellationReason'] as String?,
      scheduledDate: json['scheduledDate'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String?,
      timeWindow: json['timeWindow'] as String? ?? 'AFTERNOON_13_16',
      issueDescription: json['issueDescription'] as String?,
      issuePhotoUrls:
          (json['issuePhotoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pricing: json['pricing'] is Map<String, dynamic>
          ? BookingPricingModel.fromJson(
              json['pricing'] as Map<String, dynamic>,
            )
          : (json['baseInspectionEgp'] != null
                ? BookingPricingModel.fromJson(json)
                : throw const FormatException(
                    'Missing required pricing data in booking',
                  )),
      arrivalPinCode: json['arrivalPinCode'] as String?,
      offering: (json['offering'] as Map<String, dynamic>?) ?? const {},
      address: (json['address'] as Map<String, dynamic>?) ?? const {},
      proProfile: json['proProfile'] as Map<String, dynamic>?,
      payment: json['payment'] != null
          ? PaymentRecordModel.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      review: json['review'] is Map<String, dynamic>
          ? BookingReviewModel.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      statusEvents: (json['statusEvents'] as List<dynamic>?) ?? const [],
      createdAt: json['createdAt'] as String? ?? '',
      completedAt: json['completedAt'] as String?,
    );
  }
}

/// Milestone item on Screen 06 (Live Order Tracking).
class BookingTrackingMilestoneModel {
  const BookingTrackingMilestoneModel({
    required this.key,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.state,
    this.timestamp,
  });

  final String key;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final String state; // COMPLETED | CURRENT | UPCOMING | CANCELLED
  final String? timestamp;

  factory BookingTrackingMilestoneModel.fromJson(Map<String, dynamic> json) {
    return BookingTrackingMilestoneModel(
      key: json['key'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      subtitleEn: json['subtitleEn'] as String? ?? '',
      subtitleAr: json['subtitleAr'] as String? ?? '',
      state: json['state'] as String? ?? 'UPCOMING',
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// Complete tracking response for Screen 06 (`GET /bookings/:id/tracking`).
class BookingTrackingModel {
  const BookingTrackingModel({
    required this.booking,
    required this.milestones,
    required this.canCancel,
    required this.canChat,
    required this.canReview,
    required this.trackingAccuracyNoteEn,
    required this.trackingAccuracyNoteAr,
  });

  final BookingDetailModel booking;
  final List<BookingTrackingMilestoneModel> milestones;
  final bool canCancel;
  final bool canChat;
  final bool canReview;
  final String trackingAccuracyNoteEn;
  final String trackingAccuracyNoteAr;

  factory BookingTrackingModel.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as List<dynamic>? ?? const [];
    return BookingTrackingModel(
      booking: BookingDetailModel.fromJson(
        json['booking'] as Map<String, dynamic>,
      ),
      milestones: rawMilestones
          .map(
            (e) => BookingTrackingMilestoneModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      canCancel: json['canCancel'] as bool? ?? false,
      canChat: json['canChat'] as bool? ?? false,
      canReview: json['canReview'] as bool? ?? false,
      trackingAccuracyNoteEn:
          json['trackingAccuracyNoteEn'] as String? ??
          'Map displays your saved service address.',
      trackingAccuracyNoteAr:
          json['trackingAccuracyNoteAr'] as String? ??
          'تعرض الخريطة عنوان الخدمة المحفوظ.',
    );
  }
}

/// Line item in a booking receipt (`GET /bookings/:id/receipt`).
class BookingReceiptLineItemModel {
  const BookingReceiptLineItemModel({
    required this.key,
    required this.labelEn,
    required this.labelAr,
    required this.amountEgp,
  });

  final String key;
  final String labelEn;
  final String labelAr;
  final int amountEgp;

  factory BookingReceiptLineItemModel.fromJson(Map<String, dynamic> json) {
    return BookingReceiptLineItemModel(
      key: json['key'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      labelAr: json['labelAr'] as String? ?? '',
      amountEgp: (json['amountEgp'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Structured receipt generated from actual Booking, PaymentRecord, and Review rows.
class BookingReceiptModel {
  const BookingReceiptModel({
    required this.receiptNumber,
    required this.bookingId,
    required this.orderCode,
    required this.status,
    required this.issuedAt,
    required this.scheduledDate,
    required this.timeWindow,
    this.scheduledTime,
    this.completedAt,
    required this.customerName,
    required this.serviceTitleEn,
    required this.serviceTitleAr,
    required this.categoryNameEn,
    required this.categoryNameAr,
    this.proName,
    this.proDossierCode,
    required this.addressSummary,
    required this.lineItems,
    required this.subtotalEgp,
    required this.tipEgp,
    required this.grandTotalEgp,
    required this.platformFeeEgp,
    required this.netArtisanEgp,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paidAt,
  });

  final String receiptNumber;
  final String bookingId;
  final String orderCode;
  final String status;
  final String issuedAt;
  final String scheduledDate;
  final String timeWindow;
  final String? scheduledTime;
  final String? completedAt;
  final String customerName;
  final String serviceTitleEn;
  final String serviceTitleAr;
  final String categoryNameEn;
  final String categoryNameAr;
  final String? proName;
  final String? proDossierCode;
  final String addressSummary;
  final List<BookingReceiptLineItemModel> lineItems;
  final int subtotalEgp;
  final int tipEgp;
  final int grandTotalEgp;
  final int platformFeeEgp;
  final int netArtisanEgp;
  final String paymentMethod;
  final String paymentStatus;
  final String? paidAt;

  factory BookingReceiptModel.fromJson(Map<String, dynamic> json) {
    final items = json['lineItems'] as List<dynamic>? ?? const [];
    return BookingReceiptModel(
      receiptNumber: json['receiptNumber'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      status: json['status'] as String? ?? '',
      issuedAt: json['issuedAt'] as String? ?? '',
      scheduledDate: json['scheduledDate'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String?,
      timeWindow: json['timeWindow'] as String? ?? '',
      completedAt: json['completedAt'] as String?,
      customerName: json['customerName'] as String? ?? '',
      serviceTitleEn: json['serviceTitleEn'] as String? ?? '',
      serviceTitleAr: json['serviceTitleAr'] as String? ?? '',
      categoryNameEn: json['categoryNameEn'] as String? ?? '',
      categoryNameAr: json['categoryNameAr'] as String? ?? '',
      proName: json['proName'] as String?,
      proDossierCode: json['proDossierCode'] as String?,
      addressSummary: json['addressSummary'] as String? ?? '',
      lineItems: items
          .map(
            (e) =>
                BookingReceiptLineItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      subtotalEgp: (json['subtotalEgp'] as num?)?.toInt() ?? 0,
      tipEgp: (json['tipEgp'] as num?)?.toInt() ?? 0,
      grandTotalEgp: (json['grandTotalEgp'] as num?)?.toInt() ?? 0,
      platformFeeEgp: (json['platformFeeEgp'] as num?)?.toInt() ?? 0,
      netArtisanEgp: (json['netArtisanEgp'] as num?)?.toInt() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH_ON_SERVICE',
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      paidAt: json['paidAt'] as String?,
    );
  }
}

/// Result of a validated private media upload (`POST /uploads/private`).
class PrivateUploadResultModel {
  const PrivateUploadResultModel({
    required this.uploadId,
    required this.purpose,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.sha256,
    required this.accessToken,
    required this.expiresAt,
    required this.privateDataUri,
  });

  final String uploadId;
  final String purpose;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String sha256;
  final String accessToken;
  final String expiresAt;
  final String privateDataUri;

  String get accessUrl => privateDataUri;

  factory PrivateUploadResultModel.fromJson(Map<String, dynamic> json) {
    return PrivateUploadResultModel(
      uploadId: json['uploadId'] as String? ?? '',
      purpose: json['purpose'] as String? ?? 'BOOKING_ISSUE',
      fileName: json['fileName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'image/png',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      sha256: json['sha256'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
      privateDataUri: json['privateDataUri'] as String? ?? '',
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
    this.scheduledTime,
    this.issueDescription,
    this.issuePhotoUrls = const [],
  });

  final String offeringId;
  final String addressId;
  final String? preferredProId;
  final String scheduledDate;
  final String timeWindow;
  final String? scheduledTime;
  final String? issueDescription;
  final List<String> issuePhotoUrls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'offeringId': offeringId,
      'addressId': addressId,
      'scheduledDate': scheduledDate,
      'timeWindow': timeWindow,
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
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
  });

  final String key;
  final String titleEn;
  final String titleAr;
  final String timeRangeEn;
  final String timeRangeAr;

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String localizedTimeRange(bool isArabic) =>
      isArabic ? timeRangeAr : timeRangeEn;

  static const List<TimeWindowSlot> all = [
    TimeWindowSlot(
      key: 'MORNING_09_12',
      titleEn: 'Morning Window',
      titleAr: 'الفترة الصباحية',
      timeRangeEn: '09:00 AM – 12:00 PM',
      timeRangeAr: '٠٩:٠٠ ص – ١٢:٠٠ م',
    ),
    TimeWindowSlot(
      key: 'AFTERNOON_13_16',
      titleEn: 'Afternoon Window',
      titleAr: 'فترة بعد الظهر',
      timeRangeEn: '01:00 PM – 04:00 PM',
      timeRangeAr: '٠١:٠٠ م – ٠٤:٠٠ م',
    ),
    TimeWindowSlot(
      key: 'EVENING_17_20',
      titleEn: 'Evening Window',
      titleAr: 'الفترة المسائية',
      timeRangeEn: '05:00 PM – 08:00 PM',
      timeRangeAr: '٠٥:٠٠ م – ٠٨:٠٠ م',
    ),
  ];
}
