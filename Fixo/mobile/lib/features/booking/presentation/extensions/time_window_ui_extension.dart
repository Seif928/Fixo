import 'package:material_ui/material_ui.dart';
import '../../domain/booking_models.dart';

/// Presentation-layer extension mapping pure domain [TimeWindowSlot] to Flutter UI [IconData].
extension TimeWindowSlotUiExtension on TimeWindowSlot {
  /// Returns the canonical Flutter Material icon representing this time window.
  IconData get icon {
    return switch (key) {
      'MORNING_09_12' => Icons.wb_twilight_rounded,
      'AFTERNOON_13_16' => Icons.wb_sunny_rounded,
      'EVENING_17_20' => Icons.bedtime_rounded,
      _ => Icons.schedule_rounded,
    };
  }
}

/// Convenience extension for mapping raw time window key strings to UI icons.
extension TimeWindowKeyUiExtension on String {
  /// Returns the corresponding Flutter Material icon for a time window wire key.
  IconData get timeWindowIcon {
    return switch (this) {
      'MORNING_09_12' => Icons.wb_twilight_rounded,
      'AFTERNOON_13_16' => Icons.wb_sunny_rounded,
      'EVENING_17_20' => Icons.bedtime_rounded,
      _ => Icons.schedule_rounded,
    };
  }
}

/// Type alias providing compatibility if referenced as TimeWindowOption.
typedef TimeWindowOption = TimeWindowSlot;
