import '../../booking/domain/booking_models.dart';

const adminBookingStatuses = [
  'DRAFT',
  'PENDING_DISPATCH',
  'OFFERED_TO_PRO',
  'CONFIRMED',
  'PRO_EN_ROUTE',
  'ARRIVED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
];
String adminBookingStatusLabel(String status, bool ar) => switch (status) {
  'DRAFT' => ar ? 'مسودة' : 'Draft',
  'PENDING_DISPATCH' => ar ? 'بانتظار فني' : 'Awaiting a professional',
  'OFFERED_TO_PRO' => ar ? 'معروض على فني' : 'Offered to a professional',
  'CONFIRMED' => ar ? 'مؤكد' : 'Confirmed',
  'PRO_EN_ROUTE' => ar ? 'الفني في الطريق' : 'Professional en route',
  'ARRIVED' => ar ? 'الفني وصل' : 'Arrived',
  'IN_PROGRESS' => ar ? 'الخدمة بدأت' : 'In progress',
  'COMPLETED' => ar ? 'مكتمل' : 'Completed',
  'CANCELLED' => ar ? 'ملغي' : 'Cancelled',
  _ => throw const FormatException('Unknown booking status.'),
};
String adminTimeWindowLabel(String value, bool ar) => switch (value) {
  'MORNING_09_12' => ar ? 'صباحًا ٩–١٢' : 'Morning 09–12',
  'AFTERNOON_13_16' => ar ? 'ظهرًا ١٣–١٦' : 'Afternoon 13–16',
  'EVENING_17_20' => ar ? 'مساءً ١٧–٢٠' : 'Evening 17–20',
  _ => throw const FormatException('Unknown time window.'),
};
int _money(dynamic n) {
  if (n is! int || n < 0) {
    throw const FormatException('Invalid booking amount.');
  }
  return n;
}

class AdminPageMeta {
  AdminPageMeta(Map json)
    : page = json['page'] as int,
      total = json['total'] as int,
      totalPages = json['totalPages'] as int {
    if (page < 1 || total < 0 || totalPages < 1) {
      throw const FormatException('Invalid pagination.');
    }
  }
  final int page, total, totalPages;
}

class AdminBookingSummary {
  AdminBookingSummary(Map<String, dynamic> json)
    : id = json['id'] as String,
      code = json['orderCode'] as String,
      status = json['status'] as String,
      date = DateTime.parse(json['scheduledDate'] as String),
      timeWindow = json['timeWindow'] as String,
      total = _money(json['totalEgp']),
      titleEn = (json['offering'] as Map)['titleEn'] as String,
      titleAr = (json['offering'] as Map)['titleAr'] as String {
    if (!adminBookingStatuses.contains(status)) {
      throw const FormatException('Invalid booking status.');
    }
    adminTimeWindowLabel(timeWindow, false);
  }
  final String id, code, status, timeWindow, titleEn, titleAr;
  final DateTime date;
  final int total;
}

class AdminBookingPage {
  AdminBookingPage(Map<String, dynamic> json)
    : items = (json['items'] as List)
          .map((e) => AdminBookingSummary(Map<String, dynamic>.from(e as Map)))
          .toList(),
      meta = AdminPageMeta(json['meta'] as Map);
  final List<AdminBookingSummary> items;
  final AdminPageMeta meta;
}

class AdminBookingPayment {
  AdminBookingPayment(Map json)
    : method = json['method'] as String,
      status = json['status'] as String,
      amount = _money(json['amountEgp']),
      tip = _money(json['tipEgp']),
      paidAt = json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String) {
    if (!['PENDING', 'PAID', 'FAILED', 'REFUNDED'].contains(status)) {
      throw const FormatException('Invalid payment status.');
    }
  }
  final String method, status;
  final int amount, tip;
  final DateTime? paidAt;
  String label(bool ar) => switch (status) {
    'PENDING' => ar ? 'بانتظار التحصيل' : 'Pending collection',
    'PAID' => ar ? 'مدفوع' : 'Paid',
    'FAILED' => ar ? 'غير محصّل' : 'Not collected',
    _ => ar ? 'مسترد' : 'Refunded',
  };
}

class AdminBookingEvent {
  AdminBookingEvent(Map json)
    : status = json['toStatus'] as String,
      note = json['note'] as String?,
      date = DateTime.parse(json['createdAt'] as String) {
    if (!adminBookingStatuses.contains(status)) {
      throw const FormatException('Invalid booking history.');
    }
  }
  final String status;
  final String? note;
  final DateTime date;
}

class AdminBookingDetail {
  AdminBookingDetail(Map<String, dynamic> json)
    : summary = AdminBookingSummary({
        ...json,
        'totalEgp': (json['pricing'] as Map)['totalEgp'],
      }),
      version = json['version'] as String,
      pricing = BookingPricingModel.fromJson(
        Map<String, dynamic>.from(json['pricing'] as Map),
      ),
      customerName = (json['customer'] as Map)['fullName'] as String?,
      customerPhone = (json['customer'] as Map)['phone'] as String?,
      proName = json['proProfile'] == null
          ? null
          : (json['proProfile']['user'] as Map)['fullName'] as String?,
      proPhone = json['proProfile'] == null
          ? null
          : (json['proProfile']['user'] as Map)['phone'] as String?,
      address = [
        for (final key in [
          'label',
          'buildingLine',
          'districtLine',
          'gateNotes',
        ])
          if ((json['address'] as Map)[key] != null)
            (json['address'] as Map)[key] as String,
      ],
      payment = json['payment'] == null
          ? null
          : AdminBookingPayment(json['payment'] as Map),
      issue = json['issueDescription'] as String?,
      cancellationReason = json['cancellationReason'] as String?,
      history = (json['history'] as List)
          .map((e) => AdminBookingEvent(e as Map))
          .toList(),
      hasOlderHistory = json['hasOlderHistory'] as bool,
      canCancel = json['canCancel'] as bool,
      canOffer = json['canOffer'] as bool {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(version)) {
      throw const FormatException('Invalid booking version.');
    }
    for (final key in [
      'baseInspectionEgp',
      'serviceFeeEgp',
      'transportFeeEgp',
      'totalEgp',
    ]) {
      _money((json['pricing'] as Map)[key]);
    }
  }
  final AdminBookingSummary summary;
  final String version;
  final BookingPricingModel pricing;
  final String? customerName,
      customerPhone,
      proName,
      proPhone,
      issue,
      cancellationReason;
  final List<String> address;
  final AdminBookingPayment? payment;
  final List<AdminBookingEvent> history;
  final bool hasOlderHistory, canCancel, canOffer;
}

class AdminBookingCandidate {
  AdminBookingCandidate(Map json)
    : id = json['id'] as String,
      code = json['dossierCode'] as String,
      name = (json['user'] as Map)['fullName'] as String?;
  final String id, code;
  final String? name;
}

class AdminCandidatePage {
  AdminCandidatePage(Map<String, dynamic> json)
    : items = (json['items'] as List)
          .map((e) => AdminBookingCandidate(e as Map))
          .toList(),
      meta = AdminPageMeta(json['meta'] as Map);
  final List<AdminBookingCandidate> items;
  final AdminPageMeta meta;
}
