import 'package:material_ui/material_ui.dart';
import '../../../../core/widgets/fixo_buttons.dart';

enum BookingHelpAction { services, location }

class BookingHelpSheet extends StatelessWidget {
  const BookingHelpSheet({super.key, required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic;
    final steps = [
      (
        Icons.home_repair_service_outlined,
        ar ? 'اختار الخدمة' : 'Choose your service',
        ar
            ? 'افتح القسم وشوف الخدمات المتاحة وتفاصيل أسعارها.'
            : 'Browse a category and review available services and prices.',
      ),
      (
        Icons.location_on_outlined,
        ar ? 'حدد مكان الخدمة' : 'Set the service location',
        ar
            ? 'اختار المحافظة والمنطقة، أو استخدم موقعك الحالي، وضيف عنوانك بالتفصيل.'
            : 'Choose your governorate and area, or use your current location, then add your full address.',
      ),
      (
        Icons.calendar_month_outlined,
        ar ? 'اختار اليوم والساعة' : 'Choose your date and time',
        ar
            ? 'حدد الميعاد المناسب من التقويم وراجع تفاصيل الحجز.'
            : 'Select a suitable appointment in the calendar and review your booking.',
      ),
      (
        Icons.payments_outlined,
        ar ? 'راجع الإجمالي وأكد الحجز' : 'Review the total and confirm',
        ar
            ? 'الدفع النقدي بعد تنفيذ الخدمة. تابع حالة طلبك من «طلباتي».'
            : 'Pay cash after the service. Follow your request in Orders.',
      ),
    ];
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ar ? 'إزاي تحجز خدمتك؟' : 'How does booking work?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: ar ? 'إغلاق' : 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final (icon, title, description) in steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              FixoPrimaryButton(
                key: const Key('booking-help-start'),
                label: ar
                    ? 'اختار الخدمة وابدأ الحجز'
                    : 'Choose a service and start',
                onPressed: () =>
                    Navigator.pop(context, BookingHelpAction.services),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('booking-help-location'),
                icon: const Icon(Icons.my_location),
                label: Text(ar ? 'حدد مكانك الأول' : 'Choose your area first'),
                onPressed: () =>
                    Navigator.pop(context, BookingHelpAction.location),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
