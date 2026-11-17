import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/booking/presentation/extensions/time_window_ui_extension.dart';

void main() {
  group('TimeWindowSlotUiExtension', () {
    test('maps canonical slots to correct Material icons', () {
      final morning = TimeWindowSlot.all.firstWhere((s) => s.key == 'MORNING_09_12');
      final afternoon = TimeWindowSlot.all.firstWhere((s) => s.key == 'AFTERNOON_13_16');
      final evening = TimeWindowSlot.all.firstWhere((s) => s.key == 'EVENING_17_20');

      expect(morning.icon, Icons.wb_twilight_rounded);
      expect(afternoon.icon, Icons.wb_sunny_rounded);
      expect(evening.icon, Icons.bedtime_rounded);
    });

    test('fallback icon returned for custom or unknown slot key', () {
      const customSlot = TimeWindowSlot(
        key: 'CUSTOM_WINDOW',
        titleEn: 'Custom',
        titleAr: 'مخصص',
        timeRangeEn: '10:00 AM – 11:00 AM',
        timeRangeAr: '١٠:٠٠ ص – ١١:٠٠ ص',
      );

      expect(customSlot.icon, Icons.schedule_rounded);
    });

    test('TimeWindowKeyUiExtension maps string keys correctly', () {
      expect('MORNING_09_12'.timeWindowIcon, Icons.wb_twilight_rounded);
      expect('AFTERNOON_13_16'.timeWindowIcon, Icons.wb_sunny_rounded);
      expect('EVENING_17_20'.timeWindowIcon, Icons.bedtime_rounded);
      expect('UNKNOWN'.timeWindowIcon, Icons.schedule_rounded);
    });
  });
}
