import '../../../../core/location/free_map_picker.dart';
import '../../../../core/location/address_maps_actions.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../customer_home/domain/marketplace_models.dart';
import '../../domain/booking_models.dart';

/// Progress Header Meta: "1 Schedule Service" + "Step 1 of 2" pill
class BookingProgressHeader extends StatelessWidget {
  const BookingProgressHeader({super.key, required this.isArabic});

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
                    color: palette.deepForest,
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
                  color: palette.deepForest,
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

    return Container(
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(color: palette.subtleBorder),
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
              // Provider / Service Avatar box
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
                        preferredPro != null
                            ? Icons.handyman_rounded
                            : Icons.home_repair_service_rounded,
                        color: palette.limeAccent,
                        size: 28,
                      ),
                    ),
                  ),
                  if (preferredPro != null)
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
                    if (preferredPro != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFE29500),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            preferredPro!.ratingAvg.toStringAsFixed(2),
                            style: FixoTypography.labelMd(
                              color: palette.deepForest,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${preferredPro!.reviewsCount} jobs)',
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        isArabic
                            ? 'لم يتم تعيين فني بعد'
                            : 'No professional assigned yet',
                        style: FixoTypography.labelMd(
                          color: palette.mutedText,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      offering.localizedTitle(isArabic),
                      style: FixoTypography.labelLg(
                        color: palette.deepForest,
                      ).copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preferredPro != null
                          ? '${isArabic ? "الفني المسؤول: " : "Lead Pro: "}${preferredPro!.localizedName(isArabic)}'
                          : (isArabic
                                ? 'الفني: لم يتم التعيين بعد'
                                : 'Professional: Not yet assigned'),
                      style: FixoTypography.bodySm(color: palette.mutedText),
                      maxLines: 2,
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
                          preferredPro != null
                              ? (isArabic
                                    ? 'فني مسجل ومعتمد'
                                    : 'Registered Pro')
                              : (isArabic
                                    ? 'خدمة منزلية معلنة'
                                    : 'Catalog Home Service'),
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
                    isArabic ? 'تسعير قياسي' : 'Standard Rate',
                    style: FixoTypography.labelMd(color: palette.mutedText),
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
    this.onAddNewAddress,
    required this.isArabic,
  });

  final CustomerAddressModel? selectedAddress;
  final bool hasAddresses;
  final VoidCallback? onChangeAddress;
  final VoidCallback? onAddNewAddress;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(color: palette.subtleBorder),
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
                      color: palette.deepForest,
                      size: 20,
                    ),
                    const SizedBox(width: FixoSpacing.xs),
                    Expanded(
                      child: Text(
                        isArabic ? 'موقع تقديم الخدمة' : 'Service Location',
                        style: FixoTypography.headlineSm(
                          color: palette.deepForest,
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
              ] else if (onAddNewAddress != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('add-address-header-btn'),
                  onPressed: onAddNewAddress,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isArabic ? '+ إضافة' : '+ Add',
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
            Text(
              selectedAddress!.label,
              style: FixoTypography.labelLg(color: palette.deepForest),
            ),
            if (selectedAddress!.latitude != null &&
                selectedAddress!.longitude != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SavedLocationMap(
                  point: ServiceMapPoint(
                    selectedAddress!.latitude!,
                    selectedAddress!.longitude!,
                  ),
                  isArabic: isArabic,
                ),
              )
            else
              Text(
                isArabic
                    ? 'لا توجد نقطة محفوظة لهذا العنوان.'
                    : 'No map pin saved for this address.',
                style: FixoTypography.bodySm(color: palette.mutedText),
              ),
            const SizedBox(height: 10),
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
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        selectedAddress!.districtLine,
                        style: FixoTypography.bodySm(color: palette.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AddressMapsActions(
              address: [
                selectedAddress!.buildingLine,
                selectedAddress!.districtLine,
                if (selectedAddress!.zone != null)
                  selectedAddress!.zone!.governorate,
                'Egypt',
              ].join(', '),
              isArabic: isArabic,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                                color: palette.deepForest,
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
                  if (onAddNewAddress != null) ...[
                    const SizedBox(height: FixoSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('add-first-address-btn'),
                        onPressed: onAddNewAddress,
                        icon: const Icon(
                          Icons.add_location_alt_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isArabic ? 'إضافة عنوان جديد' : 'Add New Address',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
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

  static const List<String> _daysEn = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _daysAr = [
    'إثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
    'أحد',
  ];
  static const List<String> _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
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
        border: Border.all(color: palette.subtleBorder),
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
                      color: palette.deepForest,
                      size: 20,
                    ),
                    const SizedBox(width: FixoSpacing.xs),
                    Expanded(
                      child: Text(
                        isArabic ? 'تحديد اليوم' : 'Select Date',
                        style: FixoTypography.headlineSm(
                          color: palette.deepForest,
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
                style: FixoTypography.labelMd(color: palette.mutedText),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Row(
            children: dates.map((d) {
              final isSelected =
                  d.year == selectedDate.year &&
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
                                    : palette.deepForest,
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
        border: Border.all(color: palette.subtleBorder),
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
              Icon(Icons.schedule_rounded, color: palette.deepForest, size: 20),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  isArabic ? 'الفترة الزمنية المفضلة' : 'Preferred Time Window',
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
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
                  color: isSelected ? palette.primaryBrand : palette.surfaceLow,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot.localizedTitle(isArabic),
                                        style: FixoTypography.labelLg(
                                          color: isSelected
                                              ? Colors.white
                                              : palette.deepForest,
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
        border: Border.all(color: palette.subtleBorder),
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
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FixoColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic ? 'تسعير قياسي' : 'Standard Rate',
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
                  color: palette.deepForest,
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
                  color: palette.deepForest,
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
                          color: FixoColors.onTertiaryFixed,
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
                          color: palette.deepForest,
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
                        color: palette.deepForest,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EGP',
                      style: FixoTypography.labelMd(
                        color: palette.deepForest,
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

/// Responsive Address Creation Modal / Bottom Sheet (Screen 04)
class AddressCreationBottomSheet extends StatefulWidget {
  const AddressCreationBottomSheet({
    super.key,
    required this.zones,
    required this.isLoadingZones,
    required this.isSubmitting,
    this.errorMessage,
    required this.onSave,
    this.onRetryZones,
    required this.isArabic,
  });

  final List<CoverageZoneModel> zones;
  final bool isLoadingZones;
  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<CreateAddressRequest> onSave;
  final VoidCallback? onRetryZones;
  final bool isArabic;

  @override
  State<AddressCreationBottomSheet> createState() =>
      _AddressCreationBottomSheetState();
}

class _AddressCreationBottomSheetState
    extends State<AddressCreationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _buildingController;
  late final TextEditingController _districtController;
  late final TextEditingController _gateNotesController;

  String? _selectedZoneId;
  bool _isDefault = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.isArabic ? 'المنزل' : 'Home',
    );
    _buildingController = TextEditingController();
    _districtController = TextEditingController();
    _gateNotesController = TextEditingController();

    if (widget.zones.isNotEmpty) {
      _selectedZoneId = widget.zones.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant AddressCreationBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedZoneId == null && widget.zones.isNotEmpty) {
      setState(() {
        _selectedZoneId = widget.zones.first.id;
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _buildingController.dispose();
    _districtController.dispose();
    _gateNotesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _localError = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedZoneId == null || _selectedZoneId!.isEmpty) {
      setState(() {
        _localError = widget.isArabic
            ? 'يرجى اختيار منطقة التغطية'
            : 'Please select a valid coverage zone';
      });
      return;
    }

    final request = CreateAddressRequest(
      zoneId: _selectedZoneId!,
      label: _labelController.text.trim(),
      buildingLine: _buildingController.text.trim(),
      districtLine: _districtController.text.trim(),
      gateNotes: _gateNotesController.text.trim().isNotEmpty
          ? _gateNotesController.text.trim()
          : null,
      isDefault: _isDefault,
    );

    widget.onSave(request);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final colorScheme = Theme.of(context).colorScheme;
    final displayError = _localError ?? widget.errorMessage;

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: palette.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: FixoSpacing.md,
          right: FixoSpacing.md,
          top: FixoSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + FixoSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_location_alt_rounded,
                          color: palette.deepForest,
                          size: 22,
                        ),
                        const SizedBox(width: FixoSpacing.xs),
                        Text(
                          widget.isArabic
                              ? 'إضافة عنوان جديد'
                              : 'Add New Address',
                          style: FixoTypography.headlineSm(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: palette.mutedText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: FixoSpacing.sm),

                // Error Banner if present
                if (displayError != null) ...[
                  Container(
                    key: const Key('address-error-banner'),
                    padding: const EdgeInsets.all(FixoSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: FixoSpacing.xs),
                        Expanded(
                          child: Text(
                            displayError,
                            style: FixoTypography.bodySm(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FixoSpacing.sm),
                ],

                // Label Input
                Text(
                  widget.isArabic
                      ? 'اسم العنوان (مثال: المنزل، العمل)'
                      : 'Address Label (e.g. Home, Work)',
                  style: FixoTypography.labelMd(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  key: const Key('address-label-input'),
                  controller: _labelController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return widget.isArabic
                          ? 'يرجى إدخال اسم العنوان'
                          : 'Address label is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: widget.isArabic ? 'المنزل' : 'Home',
                    filled: true,
                    fillColor: palette.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: FixoSpacing.sm),

                // Coverage Zone Dropdown
                Text(
                  widget.isArabic ? 'منطقة التغطية' : 'Coverage Zone',
                  style: FixoTypography.labelMd(
                    color: palette.primaryBrand,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (widget.isLoadingZones) ...[
                  Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.surfaceLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ] else if (widget.zones.isEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.isArabic
                              ? 'تعذر تحميل مناطق التغطية'
                              : 'Could not load coverage zones',
                          style: FixoTypography.bodySm(
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ),
                      if (widget.onRetryZones != null)
                        TextButton(
                          key: const Key('retry-zones-btn'),
                          onPressed: widget.onRetryZones,
                          child: Text(
                            widget.isArabic ? 'إعادة المحاولة' : 'Retry',
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    key: const Key('address-zone-dropdown'),
                    initialValue:
                        widget.zones.any((z) => z.id == _selectedZoneId)
                        ? _selectedZoneId
                        : widget.zones.first.id,
                    items: widget.zones.map((zone) {
                      return DropdownMenuItem<String>(
                        value: zone.id,
                        child: Text(
                          zone.localizedName(widget.isArabic),
                          style: FixoTypography.bodyMd(color: palette.inkText),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedZoneId = val);
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: palette.surfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: FixoSpacing.sm),

                // Building & Street Line
                Text(
                  widget.isArabic
                      ? 'تفاصيل المبنى والشارع'
                      : 'Building & Street Details',
                  style: FixoTypography.labelMd(
                    color: palette.primaryBrand,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  key: const Key('address-building-input'),
                  controller: _buildingController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return widget.isArabic
                          ? 'يرجى إدخال تفاصيل المبنى'
                          : 'Building details are required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: widget.isArabic
                        ? 'عمارة ١٤، شقة ٤ب، شارع التسعين'
                        : 'Building 14, Apt 4B, 90th Street',
                    filled: true,
                    fillColor: palette.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: FixoSpacing.sm),

                // District & Area Line
                Text(
                  widget.isArabic ? 'الحي / المنطقة' : 'District / Area',
                  style: FixoTypography.labelMd(
                    color: palette.primaryBrand,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  key: const Key('address-district-input'),
                  controller: _districtController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return widget.isArabic
                          ? 'يرجى إدخال اسم المنطقة'
                          : 'District details are required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: widget.isArabic
                        ? 'التجمع الخامس، القاهرة الجديدة'
                        : '5th Settlement, New Cairo',
                    filled: true,
                    fillColor: palette.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: FixoSpacing.sm),

                // Optional Gate Notes
                Text(
                  widget.isArabic
                      ? 'ملاحظات البوابة أو الأمن (اختياري)'
                      : 'Gate Notes / Security (Optional)',
                  style: FixoTypography.labelMd(
                    color: palette.primaryBrand,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  key: const Key('address-gate-notes-input'),
                  controller: _gateNotesController,
                  decoration: InputDecoration(
                    hintText: widget.isArabic ? 'بوابة رقم ٣' : 'Gate 3',
                    filled: true,
                    fillColor: palette.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: FixoSpacing.xs),

                // Default Switch
                SwitchListTile.adaptive(
                  key: const Key('address-default-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    widget.isArabic
                        ? 'تعيين كعنوان افتراضي'
                        : 'Set as default address',
                    style: FixoTypography.bodyMd(color: palette.inkText),
                  ),
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val),
                  activeTrackColor: FixoColors.secondary,
                ),
                const SizedBox(height: FixoSpacing.sm),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    key: const Key('save-address-btn'),
                    onPressed: widget.isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primaryBrand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: widget.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.isArabic
                                ? 'حفظ واختيار العنوان'
                                : 'Save & Select Address',
                            style: FixoTypography.labelLg(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
