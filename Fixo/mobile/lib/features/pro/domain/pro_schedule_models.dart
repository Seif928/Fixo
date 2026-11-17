enum ProDayOfWeek {
  sunday('SUNDAY', 'Sunday', 'الأحد'),
  monday('MONDAY', 'Monday', 'الإثنين'),
  tuesday('TUESDAY', 'Tuesday', 'الثلاثاء'),
  wednesday('WEDNESDAY', 'Wednesday', 'الأربعاء'),
  thursday('THURSDAY', 'Thursday', 'الخميس'),
  friday('FRIDAY', 'Friday', 'الجمعة'),
  saturday('SATURDAY', 'Saturday', 'السبت');

  const ProDayOfWeek(this.wireValue, this.nameEn, this.nameAr);
  final String wireValue;
  final String nameEn;
  final String nameAr;

  String localizedName(bool isAr) => isAr ? nameAr : nameEn;

  static ProDayOfWeek fromWire(String value) {
    return ProDayOfWeek.values.firstWhere(
      (d) => d.wireValue == value.toUpperCase(),
      orElse: () => ProDayOfWeek.sunday,
    );
  }
}

enum ProLeaveReason {
  vacation('VACATION', 'Vacation', 'إجازة سنوية'),
  sick('SICK', 'Sick Leave', 'إجازة مرضية'),
  emergency('EMERGENCY', 'Emergency', 'ظرف طارئ'),
  personal('PERSONAL', 'Personal', 'شؤون شخصية');

  const ProLeaveReason(this.wireValue, this.nameEn, this.nameAr);
  final String wireValue;
  final String nameEn;
  final String nameAr;

  String localizedName(bool isAr) => isAr ? nameAr : nameEn;

  static ProLeaveReason fromWire(String value) {
    return ProLeaveReason.values.firstWhere(
      (r) => r.wireValue == value.toUpperCase(),
      orElse: () => ProLeaveReason.personal,
    );
  }
}

enum ProLeaveStatus {
  pending('PENDING', 'Pending', 'قيد المراجعة'),
  approved('APPROVED', 'Approved', 'مقبولة'),
  rejected('REJECTED', 'Rejected', 'مرفوضة'),
  cancelled('CANCELLED', 'Cancelled', 'ملغاة');

  const ProLeaveStatus(this.wireValue, this.nameEn, this.nameAr);
  final String wireValue;
  final String nameEn;
  final String nameAr;

  String localizedName(bool isAr) => isAr ? nameAr : nameEn;

  static ProLeaveStatus fromWire(String value) {
    return ProLeaveStatus.values.firstWhere(
      (s) => s.wireValue == value.toUpperCase(),
      orElse: () => ProLeaveStatus.approved,
    );
  }
}

class ProDaySchedule {
  const ProDaySchedule({
    required this.dayOfWeek,
    required this.startMinute,
    required this.endMinute,
    required this.isActive,
  });

  final ProDayOfWeek dayOfWeek;
  final int startMinute;
  final int endMinute;
  final bool isActive;

  ProDaySchedule copyWith({
    ProDayOfWeek? dayOfWeek,
    int? startMinute,
    int? endMinute,
    bool? isActive,
  }) {
    return ProDaySchedule(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      isActive: isActive ?? this.isActive,
    );
  }

  static String formatMinuteTime(int minutes, bool isAr) {
    final clamped = minutes.clamp(0, 1439);
    final hour24 = clamped ~/ 60;
    final min = clamped % 60;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final hourStr = hour12.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? (isAr ? 'م' : 'PM') : (isAr ? 'ص' : 'AM');
    final minStr = min.toString().padLeft(2, '0');
    return '$hourStr:$minStr $period';
  }

  factory ProDaySchedule.fromJson(Map<String, dynamic> json) {
    return ProDaySchedule(
      dayOfWeek: ProDayOfWeek.fromWire(json['dayOfWeek'] as String? ?? 'SUNDAY'),
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 540,
      endMinute: (json['endMinute'] as num?)?.toInt() ?? 1080,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek.wireValue,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'isActive': isActive,
  };
}

class ProLeaveItem {
  const ProLeaveItem({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.notes,
  });

  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final ProLeaveReason reason;
  final ProLeaveStatus status;
  final String? notes;

  factory ProLeaveItem.fromJson(Map<String, dynamic> json) {
    return ProLeaveItem(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      reason: ProLeaveReason.fromWire(json['reason'] as String? ?? 'PERSONAL'),
      status: ProLeaveStatus.fromWire(json['status'] as String? ?? 'APPROVED'),
      notes: json['notes'] as String?,
    );
  }
}

class ProScheduleData {
  const ProScheduleData({
    required this.weeklySchedule,
    required this.leaves,
  });

  final List<ProDaySchedule> weeklySchedule;
  final List<ProLeaveItem> leaves;

  factory ProScheduleData.fromJson(Map<String, dynamic> json) {
    final days = (json['weeklySchedule'] as List<dynamic>? ?? [])
        .map((e) => ProDaySchedule.fromJson(e as Map<String, dynamic>))
        .toList();
    final leaves = (json['leaves'] as List<dynamic>? ?? [])
        .map((e) => ProLeaveItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProScheduleData(weeklySchedule: days, leaves: leaves);
  }
}
