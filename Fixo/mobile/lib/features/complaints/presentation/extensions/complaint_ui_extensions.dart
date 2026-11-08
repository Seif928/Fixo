import 'package:flutter/material.dart';
import '../../data/complaints_models.dart';

/// Presentation-layer extension mapping domain [ComplaintCategory] to Flutter UI [IconData].
extension ComplaintCategoryUiExtension on ComplaintCategory {
  /// Returns the canonical Flutter Material icon representing this complaint category.
  IconData get icon {
    return switch (this) {
      ComplaintCategory.serviceQuality => Icons.handyman_outlined,
      ComplaintCategory.behavior => Icons.person_off_outlined,
      ComplaintCategory.delay => Icons.schedule_outlined,
      ComplaintCategory.overcharging => Icons.price_change_outlined,
      ComplaintCategory.propertyDamage => Icons.home_repair_service_outlined,
      ComplaintCategory.other => Icons.help_outline_rounded,
    };
  }
}
