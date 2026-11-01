import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../customer_home/domain/marketplace_models.dart';
import '../../domain/booking_models.dart';
import '../controllers/create_booking_controller.dart';
import '../widgets/create_booking_widgets.dart';

/// Screen 04: Create Booking (`04 — Create Booking`)
///
/// Implements the customer booking flow matching the official Stitch MCP design.
class CreateBookingPage extends ConsumerStatefulWidget {
  const CreateBookingPage({
    super.key,
    this.initialOffering,
    this.initialPreferredPro,
  });

  final ServiceOfferModel? initialOffering;
  final ProfessionalCardModel? initialPreferredPro;

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  late final TextEditingController _issueDescriptionController;

  static const ServiceOfferModel _fallbackOffering = ServiceOfferModel(
    id: 'off-summer-ac',
    categoryId: 'cat-ac',
    categorySlug: 'ac-maintenance',
    slug: 'summer-ac-deep-clean-gas-refill',
    titleEn: 'Split AC Deep Cleaning & Chemical Wash',
    titleAr: 'غسيل تكييف سبليت عميق ومواد كيميائية',
    descriptionEn: 'Complete coil flush, antibacterial mist, and pressure test.',
    descriptionAr: 'تنظيف شامل للوحدة الداخلية وتعقيم الفلاتر واختبار ضغط الغاز.',
    baseInspectionEgp: 150,
    serviceFeeEgp: 250,
    flatPriceEgp: 400,
    estimatedDurationMins: 60,
    isSeasonalPromo: true,
    isBundle: false,
    badgeEn: 'SEASONAL PEAK',
    badgeAr: 'الأكثر طلباً',
  );

  @override
  void initState() {
    super.initState();
    _issueDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _issueDescriptionController.dispose();
    super.dispose();
  }

  void _showAddressSelectionModal(
    BuildContext context,
    List<CustomerAddressModel> addresses,
    CustomerAddressModel? currentSelected,
    bool isArabic,
  ) {
    final palette = context.fixoPalette;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(FixoSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'اختر عنوان الخدمة' : 'Select Service Address',
                style: FixoTypography.headlineSm(
                  color: palette.primaryBrand,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: FixoSpacing.sm),
              ...addresses.map((addr) {
                final isSelected = addr.id == currentSelected?.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.location_on_rounded,
                    color: isSelected ? palette.primaryBrand : palette.mutedText,
                  ),
                  title: Text(
                    addr.label,
                    style: FixoTypography.labelLg(
                      color: palette.primaryBrand,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${addr.buildingLine}, ${addr.districtLine}',
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: FixoColors.secondary)
                      : null,
                  onTap: () {
                    ref
                        .read(createBookingControllerProvider.notifier)
                        .selectAddress(addr);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isArabic = ref.watch(appLocaleProvider).languageCode == 'ar';
    final state = ref.watch(createBookingControllerProvider);
    final controller = ref.read(createBookingControllerProvider.notifier);

    final offering = widget.initialOffering ?? _fallbackOffering;
    final preferredPro = widget.initialPreferredPro;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.canvasBackground,
        appBar: AppBar(
          backgroundColor: palette.cardSurface.withValues(alpha: 0.9),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: palette.primaryBrand,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.customerHome);
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const FixoBrandMark(iconBoxSize: 26, showSubtitle: false),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  isArabic ? 'إنشاء حجز' : 'Create Booking',
                  style: FixoTypography.headlineSm(
                    color: palette.primaryBrand,
                  ).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.help_outline_rounded,
                color: palette.mutedText,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'فريق دعم عملاء فيكسو متاح على مدار الساعة.'
                          : 'FIXO Cairo Support is available 24/7.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: FixoSpacing.md,
                  vertical: FixoSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Progress Header
                    BookingProgressHeader(isArabic: isArabic),
                    const SizedBox(height: FixoSpacing.sm),

                    // Selected Service & Lead Provider Card
                    SelectedServiceCard(
                      offering: offering,
                      preferredPro: preferredPro,
                      isArabic: isArabic,
                    ),
                    const SizedBox(height: FixoSpacing.sm),

                    // Service Location Card with Map Preview
                    ServiceLocationCard(
                      selectedAddress: state.selectedAddress,
                      hasAddresses: state.hasSavedAddresses,
                      isArabic: isArabic,
                      onChangeAddress: state.addresses.length > 1
                          ? () => _showAddressSelectionModal(
                                context,
                                state.addresses,
                                state.selectedAddress,
                                isArabic,
                              )
                          : null,
                    ),
                    const SizedBox(height: FixoSpacing.sm),

                    // Date Picker Group
                    BookingDateSelector(
                      selectedDate: state.selectedDate,
                      onSelectDate: controller.selectDate,
                      isArabic: isArabic,
                    ),
                    const SizedBox(height: FixoSpacing.sm),

                    // Preferred Time Window Group
                    BookingTimeWindowSelector(
                      selectedWindow: state.selectedTimeWindow,
                      onSelectWindow: controller.selectTimeWindow,
                      isArabic: isArabic,
                    ),
                    const SizedBox(height: FixoSpacing.sm),

                    // Issue Description Card
                    Container(
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
                                      Icons.edit_note_rounded,
                                      color: palette.primaryBrand,
                                      size: 20,
                                    ),
                                    const SizedBox(width: FixoSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        isArabic ? 'وصف المشكلة' : 'Issue Description',
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
                                isArabic ? 'اختياري' : 'Optional',
                                style: FixoTypography.labelMd(
                                  color: palette.mutedText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: FixoSpacing.xs),
                          TextField(
                            key: const Key('booking-issue-description-input'),
                            controller: _issueDescriptionController,
                            maxLines: 3,
                            onChanged: controller.setIssueDescription,
                            style: FixoTypography.bodyMd(color: palette.inkText),
                            decoration: InputDecoration(
                              hintText: isArabic
                                  ? 'صف الأعطال (تسريب مياه، صوت غير معتاد، توقف التبريد)...'
                                  : 'Describe symptoms (leaks, noise, odors)...',
                              hintStyle: FixoTypography.bodyMd(
                                color: palette.mutedText.withValues(alpha: 0.7),
                              ),
                              filled: true,
                              fillColor: palette.surfaceLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.sm),
                          Text(
                            isArabic
                                ? 'صور توضيحية للعطل (تساعد الفني في تجهيز المعدات)'
                                : 'Photos of Issue (Helps pro prep equipment)',
                            style: FixoTypography.labelMd(
                              color: palette.primaryBrand,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: palette.mutedText,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isArabic
                                        ? 'سيتم تفعيل رفع الصور فور تفعيل التخزين السحابي الآمن.'
                                        : 'Photo uploads will be enabled once cloud media storage is activated.',
                                    style: FixoTypography.bodySm(
                                      color: palette.mutedText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FixoSpacing.sm),

                    // Fare Breakdown
                    BookingFareBreakdownCard(
                      offering: offering,
                      isArabic: isArabic,
                    ),

                    // Error Message Notice
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: FixoSpacing.sm),
                      Container(
                        key: const Key('booking-error-banner'),
                        padding: const EdgeInsets.all(FixoSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE57373),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFC62828),
                              size: 20,
                            ),
                            const SizedBox(width: FixoSpacing.xs),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: FixoTypography.bodySm(
                                  color: const Color(0xFFC62828),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom CTA Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FixoSpacing.md,
                vertical: FixoSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Bookmark icon button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.bookmark_border_rounded,
                          color: palette.mutedText,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? 'تم حفظ الخدمة للمفضلة.'
                                    : 'Service saved for later.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: FixoSpacing.sm),

                    // Primary Proceed to Payment Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('proceed-to-payment-btn'),
                          onPressed: state.isSubmitting
                              ? null
                              : () async {
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);

                                  final success = await controller.submitBooking(
                                    offering: offering,
                                    preferredPro: preferredPro,
                                  );
                                  if (success) {
                                    final booking = ref
                                        .read(createBookingControllerProvider)
                                        .successBooking;
                                    final orderCode =
                                        booking?.orderCode ?? 'FX-XXXX';

                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: palette.primaryBrand,
                                        content: Text(
                                          isArabic
                                              ? 'تم تسجيل طلب الحجز #$orderCode بنجاح (مسودة).'
                                              : 'Booking #$orderCode created in DRAFT status.',
                                          style: FixoTypography.bodySm(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );

                                    // Return to caller or pop
                                    if (navigator.canPop()) {
                                      navigator.pop(booking);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primaryBrand,
                            disabledBackgroundColor:
                                palette.primaryBrand.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isArabic
                                            ? 'المتابعة للدفع'
                                            : 'Proceed to Payment',
                                        style: FixoTypography.labelLg(
                                          color: Colors.white,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.limeAccent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${offering.flatPriceEgp} EGP',
                                        style: FixoTypography.labelMd(
                                          color: palette.primaryBrand,
                                        ).copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
