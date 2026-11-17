import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/complaints/data/complaints_models.dart';
import 'package:fixo_mobile/features/complaints/presentation/extensions/complaint_ui_extensions.dart';

void main() {
  group('ComplaintCategoryUiExtension', () {
    test('maps all complaint categories to distinct Material icons', () {
      expect(ComplaintCategory.serviceQuality.icon, Icons.handyman_outlined);
      expect(ComplaintCategory.behavior.icon, Icons.person_off_outlined);
      expect(ComplaintCategory.delay.icon, Icons.schedule_outlined);
      expect(ComplaintCategory.overcharging.icon, Icons.price_change_outlined);
      expect(ComplaintCategory.propertyDamage.icon, Icons.home_repair_service_outlined);
      expect(ComplaintCategory.other.icon, Icons.help_outline_rounded);
    });

    test('all enum values have non-null icon mapping', () {
      for (final cat in ComplaintCategory.values) {
        expect(cat.icon, isA<IconData>());
      }
    });
  });
}
