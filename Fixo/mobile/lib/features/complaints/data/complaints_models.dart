enum ComplaintCategory {
  serviceQuality('SERVICE_QUALITY'),
  behavior('BEHAVIOR'),
  delay('DELAY'),
  overcharging('OVERCHARGING'),
  propertyDamage('PROPERTY_DAMAGE'),
  other('OTHER');

  const ComplaintCategory(this.wireValue);
  final String wireValue;

  static ComplaintCategory fromWire(String value) {
    return ComplaintCategory.values.firstWhere(
      (c) => c.wireValue == value,
      orElse: () => ComplaintCategory.other,
    );
  }

  String localizedLabel(bool isArabic) {
    return switch (this) {
      ComplaintCategory.serviceQuality =>
        isArabic ? 'جودة الخدمة' : 'Service Quality',
      ComplaintCategory.behavior =>
        isArabic ? 'سلوك الفني' : 'Professional Behavior',
      ComplaintCategory.delay =>
        isArabic ? 'تأخير في الموعد' : 'Appointment Delay',
      ComplaintCategory.overcharging =>
        isArabic ? 'مبالغة في السعر' : 'Overcharging',
      ComplaintCategory.propertyDamage =>
        isArabic ? 'تلفيات أو أضرار' : 'Property Damage',
      ComplaintCategory.other => isArabic ? 'أخرى' : 'Other',
    };
  }
}

enum ComplaintStatus {
  open('OPEN'),
  inReview('IN_REVIEW'),
  resolved('RESOLVED'),
  rejected('REJECTED');

  const ComplaintStatus(this.wireValue);
  final String wireValue;

  static ComplaintStatus fromWire(String value) {
    return ComplaintStatus.values.firstWhere(
      (s) => s.wireValue == value,
      orElse: () => ComplaintStatus.open,
    );
  }

  String localizedLabel(bool isArabic) {
    return switch (this) {
      ComplaintStatus.open => isArabic ? 'قيد الانتظار' : 'Submitted',
      ComplaintStatus.inReview => isArabic ? 'قيد المراجعة' : 'Under Review',
      ComplaintStatus.resolved => isArabic ? 'تم الحل' : 'Resolved',
      ComplaintStatus.rejected => isArabic ? 'مرفوضة' : 'Rejected',
    };
  }
}

class ComplaintItemModel {
  const ComplaintItemModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.category,
    required this.description,
    this.photoUrls = const [],
    required this.status,
    this.adminNotes,
    this.resolvedAt,
    required this.createdAt,
    this.orderCode,
    this.serviceTitleEn,
    this.serviceTitleAr,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final ComplaintCategory category;
  final String description;
  final List<String> photoUrls;
  final ComplaintStatus status;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final String? orderCode;
  final String? serviceTitleEn;
  final String? serviceTitleAr;

  String localizedServiceTitle(bool isArabic) {
    final title = isArabic ? serviceTitleAr : serviceTitleEn;
    if (title != null && title.trim().isNotEmpty) return title;
    return isArabic ? 'خدمة منزلية' : 'Home Service';
  }

  factory ComplaintItemModel.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>?;
    final offering = booking?['offering'] as Map<String, dynamic>?;

    return ComplaintItemModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      customerId: json['customerId'] as String,
      category: ComplaintCategory.fromWire(json['category'] as String? ?? ''),
      description: json['description'] as String? ?? '',
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: ComplaintStatus.fromWire(json['status'] as String? ?? ''),
      adminNotes: json['adminNotes'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      orderCode: booking?['orderCode'] as String?,
      serviceTitleEn: offering?['titleEn'] as String?,
      serviceTitleAr: offering?['titleAr'] as String?,
    );
  }
}

