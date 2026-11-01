import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../customer_home/domain/marketplace_models.dart';
import '../../domain/booking_models.dart';

/// Progress Header Meta: "1 Schedule Service" + "Step 1 of 2" pill
class BookingProgressHeader extends StatelessWidget {
  const BookingProgressHeader({
    super.key,
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primaryBrand,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '1',
                  style: FixoTypography.labelMd(
                    color: palette.limeAccent,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  isArabic ? 'تحديد موعد الخدمة' : 'Schedule Service',
                  style: FixoTypography.headlineSm(
                    color: palette.primaryBrand,
                  ).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FixoSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FixoSpacing.sm,
            vertical: FixoSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic ? 'الخطوة ١ من ٢' : 'Step 1 of 2',
                style: FixoTypography.labelMd(
                  color: palette.primaryBrand,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: FixoColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Selected Service & Provider Card
class SelectedServiceCard extends StatelessWidget {
  const SelectedServiceCard({
    super.key,
    required this.offering,
    this.preferredPro,
    required this.isArabic,
  });

  final ServiceOfferModel offering;
  final ProfessionalCardModel? preferredPro;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    final rating = preferredPro != null
        ? preferredPro!.ratingAvg.toStringAsFixed(2)
        : '4.95';
    final reviews = preferredPro != null
        ? '(${preferredPro!.reviewsCount} jobs)'
        : '(142 jobs)';
    final proName = preferredPro != null
        ? preferredPro!.localizedName(isArabic)
        : (isArabic ? 'م. حسن السيد' : 'Eng. Hassan El-Sayed');
    final leadProName =
        '${isArabic ? "الفني المسؤول: " : "Lead Pro: "}$proName';

    return Container(
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Avatar box with verified badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: palette.primaryBrand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.handyman_rounded,
                        color: palette.limeAccent,
                        size: 28,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: palette.cardSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: FixoColors.secondary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: FixoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFE29500),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: FixoTypography.labelMd(
                            color: palette.primaryBrand,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reviews,
                          style: FixoTypography.bodySm(
                            color: palette.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offering.localizedTitle(isArabic),
                      style: FixoTypography.labelLg(
                        color: palette.primaryBrand,
                      ).copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      leadProName,
                      style: FixoTypography.bodySm(
                        color: palette.mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FixoSpacing.sm,
              vertical: FixoSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: FixoColors.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'فني معتمد ومفحوص الهوية'
                              : 'Verified FIXO Master Pro',
                          style: FixoTypography.labelMd(
                            color: FixoColors.secondary,
                          ).copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isArabic ? 'ضمان فيكسو' : 'FIXO Assured',
                    style: FixoTypography.labelMd(
                      color: palette.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Service Address Selector with Map Preview Widget
class ServiceLocationCard extends StatelessWidget {
  const ServiceLocationCard({
    super.key,
    required this.selectedAddress,
    required this.hasAddresses,
    required this.onChangeAddress,
    required this.isArabic,
  });

  final CustomerAddressModel? selectedAddress;
  final bool hasAddresses;
  final VoidCallback? onChangeAddress;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: palette.primaryBrand,
                      size: 20,
                    ),
                    const SizedBox(width: FixoSpacing.xs),
                    Expanded(
                      child: Text(
                        isArabic ? 'موقع تقديم الخدمة' : 'Service Location',
                        style: FixoTypography.headlineSm(
                          color: palette.primaryBrand,
                        ).copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasAddresses) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onChangeAddress,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isArabic ? 'تغيير' : 'Change',
                    style: FixoTypography.labelMd(
                      color: FixoColors.secondary,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),

          if (selectedAddress != null) ...[
            // Mini Cairo map preview container
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.surfaceLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: FixoColors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle Cairo street grid representation
                  CustomPaint(
                    size: const Size(double.infinity, 100),
                    painter: _CairoMapPreviewPainter(
                      lineColor: FixoColors.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: palette.primaryBrand,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.home_work_rounded,
                          color: palette.limeAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primaryBrand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedAddress!.label,
                          style: FixoTypography.labelMd(
                            color: palette.limeAccent,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: FixoSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  color: palette.mutedText,
                  size: 18,
                ),
                const SizedBox(width: FixoSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAddress!.buildingLine,
                        style: FixoTypography.labelLg(
                          color: palette.primaryBrand,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        selectedAddress!.districtLine,
                        style: FixoTypography.bodySm(
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Empty state when customer has no saved address
            Container(
              padding: const EdgeInsets.all(FixoSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: FixoColors.outline.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    color: palette.mutedText,
                    size: 28,
                  ),
                  const SizedBox(width: FixoSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? 'لا يوجد عنوان محفوظ'
                              : 'No saved address found',
                          style: FixoTypography.labelLg(
                            color: palette.primaryBrand,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic
                              ? 'يرجى تسجيل عنوان في حسابك لطلب الخدمة.'
                              : 'A delivery address is required to book a service.',
                          style: FixoTypography.bodySm(
                            color: palette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CairoMapPreviewPainter extends CustomPainter {
  const _CairoMapPreviewPainter({required this.lineColor});
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Diagonal route representing 26th of July Corridor
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.45, size.height * 0.35)
      ..lineTo(size.width, size.height * 0.2);
    canvas.drawPath(path, paint);

    // Cross street
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.6, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dynamic 4-Day Horizontal Date Selector (Screen 04)
class BookingDateSelector extends StatelessWidget {
  const BookingDateSelector({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    required this.isArabic,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final bool isArabic;

  static const List<String> _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _daysAr = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
  static const List<String> _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const List<String> _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final now = DateTime.now();

    // Generate 4 consecutive days starting from tomorrow
    final dates = List.generate(
      4,
      (i) => DateTime(now.year, now.month, now.day + 1 + i),
    );

    final currentMonthName = isArabic
        ? _monthsAr[selectedDate.month - 1]
        : _monthsEn[selectedDate.month - 1];

    return Container(
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: palette.primaryBrand,
                      size: 20,
                    ),
                    const SizedBox(width: FixoSpacing.xs),
                    Expanded(
                      child: Text(
                        isArabic ? 'تحديد اليوم' : 'Select Date',
                        style: FixoTypography.headlineSm(
                          color: palette.primaryBrand,
                        ).copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currentMonthName ${selectedDate.year}',
                style: FixoTypography.labelMd(
                  color: palette.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Row(
            children: dates.map((d) {
              final isSelected = d.year == selectedDate.year &&
                  d.month == selectedDate.month &&
                  d.day == selectedDate.day;

              final dayName = isArabic
                  ? _daysAr[d.weekday - 1]
                  : _daysEn[d.weekday - 1];
              final monthName = isArabic
                  ? _monthsAr[d.month - 1]
                  : _monthsEn[d.month - 1];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: isSelected
                        ? palette.primaryBrand
                        : palette.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    elevation: isSelected ? 2 : 0,
                    child: InkWell(
                      onTap: () => onSelectDate(d),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: FixoTypography.labelMd(
                                color: isSelected
                                    ? palette.limeAccent
                                    : palette.mutedText,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.day}',
                              style: FixoTypography.priceDisplay(
                                color: isSelected
                                    ? palette.limeAccent
                                    : palette.primaryBrand,
                              ).copyWith(fontSize: 20, height: 1.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              monthName,
                              style: FixoTypography.bodySm(
                                color: isSelected
                                    ? palette.limeAccent
                                    : palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Preferred Time Window Selector Radio Cards (Screen 04)
class BookingTimeWindowSelector extends StatelessWidget {
  const BookingTimeWindowSelector({
    super.key,
    required this.selectedWindow,
    required this.onSelectWindow,
    required this.isArabic,
  });

  final String selectedWindow;
  final ValueChanged<String> onSelectWindow;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: palette.primaryBrand,
                size: 20,
              ),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  isArabic ? 'الفترة الزمنية المفضلة' : 'Preferred Time Window',
                  style: FixoTypography.headlineSm(
                    color: palette.primaryBrand,
                  ).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Column(
            children: TimeWindowSlot.all.map((slot) {
              final isSelected = slot.key == selectedWindow;

              return Padding(
                padding: const EdgeInsets.only(bottom: FixoSpacing.xs),
                child: Material(
                  color: isSelected
                      ? palette.primaryBrand
                      : palette.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  elevation: isSelected ? 1 : 0,
                  child: InkWell(
                    onTap: () => onSelectWindow(slot.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FixoSpacing.md,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  slot.icon,
                                  color: isSelected
                                      ? palette.limeAccent
                                      : palette.mutedText,
                                  size: 20,
                                ),
                                const SizedBox(width: FixoSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot.localizedTitle(isArabic),
                                        style: FixoTypography.labelLg(
                                          color: isSelected
                                              ? Colors.white
                                              : palette.primaryBrand,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        slot.localizedTimeRange(isArabic),
                                        style: FixoTypography.bodySm(
                                          color: isSelected
                                              ? palette.limeAccent
                                              : palette.mutedText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? palette.limeAccent
                                  : palette.surfaceContainer,
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: palette.primaryBrand,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Transparent Fare Breakdown Card (Screen 04)
class BookingFareBreakdownCard extends StatelessWidget {
  const BookingFareBreakdownCard({
    super.key,
    required this.offering,
    required this.isArabic,
  });

  final ServiceOfferModel offering;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    final baseInspection = offering.baseInspectionEgp;
    final serviceFee = offering.serviceFeeEgp;
    final total = offering.flatPriceEgp;

    return Container(
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceLow,
        borderRadius: FixoRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: FixoColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: FixoSpacing.xs),
                    Expanded(
                      child: Text(
                        isArabic ? 'تفاصيل السعر' : 'Fare Breakdown',
                        style: FixoTypography.headlineSm(
                          color: palette.primaryBrand,
                        ).copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: FixoColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic ? 'تسعير معتمد' : 'FIXO Guarantee',
                  style: FixoTypography.labelMd(
                    color: FixoColors.onSecondaryContainer,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'فحص ومعاينة الفني' : 'Service Base Inspection',
                  style: FixoTypography.bodyMd(color: palette.mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$baseInspection EGP',
                style: FixoTypography.labelLg(
                  color: palette.primaryBrand,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'أعمال الخدمة والصيانة' : 'Service & Labor Fee',
                  style: FixoTypography.bodyMd(color: palette.mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$serviceFee EGP',
                style: FixoTypography.labelLg(
                  color: palette.primaryBrand,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        isArabic
                            ? 'رسوم انتقال القاهرة والجيزة'
                            : 'Cairo/Giza Transport Fee',
                        style: FixoTypography.bodyMd(color: palette.mutedText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: palette.limeAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isArabic ? 'مجاناً' : 'WAIVED',
                        style: FixoTypography.labelMd(
                          color: palette.primaryBrand,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0 EGP',
                style: FixoTypography.labelLg(
                  color: FixoColors.secondary,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Container(
            padding: const EdgeInsets.all(FixoSpacing.sm),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'المجموع التقديري' : 'Estimated Total',
                        style: FixoTypography.labelLg(
                          color: palette.primaryBrand,
                        ).copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isArabic
                            ? 'شامل الضريبة والمعدات'
                            : 'VAT & equipment included',
                        style: FixoTypography.bodySm(color: palette.mutedText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$total',
                      style: FixoTypography.priceDisplay(
                        color: palette.primaryBrand,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EGP',
                      style: FixoTypography.labelMd(
                        color: palette.primaryBrand,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
