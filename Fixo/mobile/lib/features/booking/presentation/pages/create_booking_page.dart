import '../../../customer_home/presentation/controllers/customer_home_controller.dart';
import 'package:flutter/material.dart';
import '../../../../core/time/app_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/location/free_map_picker.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/uploads/private_media_picker_sheet.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../customer_home/domain/marketplace_models.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';
import '../controllers/create_booking_controller.dart';
import '../widgets/create_booking_widgets.dart';
import '../widgets/appliance_3d_inspection_widget.dart';

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
  bool _isUploadingPhoto = false;

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

  Future<void> _pickAndUploadPhoto(bool isArabic) async {
    if (widget.initialOffering == null) return;
    final picked = await PrivateMediaPickerSheet.show(
      context,
      isArabic: isArabic,
      titleEn: 'Attach Issue Photo',
      titleAr: 'إرفاق صورة للعطل',
      rationaleEn:
          'Issue photos are stored securely and only accessible to assigned technicians for equipment preparation.',
      rationaleAr:
          'يتم تخزين صور الأعطال بشكل آمن وخاص ومشاركتها مع الفني المعتمد فقط لتجهيز المعدات وقطع الغيار.',
      defaultFilePrefix: 'fixo_issue:${widget.initialOffering!.id}',
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final res = await ref
          .read(bookingRepositoryProvider)
          .uploadPrivateMedia(
            purpose: 'BOOKING_ISSUE',
            fileName: picked.fileName,
            mimeType: picked.mimeType,
            contentBase64: picked.contentBase64,
          );
      if (!mounted) return;
      ref
          .read(createBookingControllerProvider.notifier)
          .addPhotoUrl(res.accessUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر رفع الصورة. تأكد من حجم الملف والاتصال.'
                : 'Failed to upload photo. Check file size and network.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showCreateAddressSheet(BuildContext context) {
    final isArabic = ref.read(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, refWatch, _) {
            final state = refWatch.watch(createBookingControllerProvider);
            final controller = refWatch.read(
              createBookingControllerProvider.notifier,
            );

            return AddressMapWrapper(
              isArabic: isArabic,
              builder: (point, clearPoint) => AddressCreationBottomSheet(
                onAreaChanged: clearPoint,
                zones: state.coverageZones,
                initialArea: refWatch
                    .read(customerHomeControllerProvider)
                    .selectedArea,
                isLoadingZones: state.isLoadingZones,
                isSubmitting: state.isCreatingAddress,
                errorMessage: state.addressCreationError,
                isArabic: isArabic,
                onRetryZones: controller.loadCoverageZones,
                onSave: (request) async {
                  final selectedRequest = point == null
                      ? request
                      : request.withCoordinates(
                          point.latitude,
                          point.longitude,
                        );
                  final created = await controller.createAddress(
                    selectedRequest,
                  );
                  if (created != null && sheetCtx.mounted) {
                    Navigator.of(sheetCtx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: palette.primaryBrand,
                          content: Text(
                            isArabic
                                ? 'تم حفظ العنوان وتحديده بنجاح.'
                                : 'Address saved and selected.',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'اختر عنوان الخدمة' : 'Select Service Address',
                    style: FixoTypography.headlineSm(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.mutedText),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: FixoSpacing.xs),
              ...addresses.map((addr) {
                final isSelected = addr.id == currentSelected?.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.location_on_rounded,
                    color: isSelected ? palette.deepForest : palette.mutedText,
                  ),
                  title: Text(
                    addr.label,
                    style: FixoTypography.labelLg(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${addr.buildingLine}, ${addr.districtLine}',
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: FixoColors.secondary,
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(createBookingControllerProvider.notifier)
                        .selectAddress(addr);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const Divider(height: 24),
              ListTile(
                key: const Key('add-address-modal-btn'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: FixoColors.secondary,
                ),
                title: Text(
                  isArabic ? '+ إضافة عنوان جديد' : '+ Add New Address',
                  style: FixoTypography.labelLg(
                    color: FixoColors.secondary,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCreateAddressSheet(context);
                },
              ),
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

    // If no initial offering was supplied, show safe missing-selection state
    if (widget.initialOffering == null) {
      return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: palette.canvasBackground,
          appBar: AppBar(
            backgroundColor: palette.cardSurface.withValues(alpha: 0.9),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
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
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(FixoSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: palette.mutedText,
                  ),
                  const SizedBox(height: FixoSpacing.md),
                  Text(
                    isArabic ? 'لم يتم اختيار خدمة' : 'No service selected',
                    style: FixoTypography.headlineSm(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FixoSpacing.xs),
                  Text(
                    isArabic
                        ? 'يرجى اختيار خدمة من الصفحة الرئيسية للمتابعة وإنشاء الحجز.'
                        : 'Please select a service offering from the home catalog to create a booking.',
                    style: FixoTypography.bodyMd(color: palette.mutedText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FixoSpacing.lg),
                  ElevatedButton.icon(
                    key: const Key('missing-offering-home-btn'),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.customerHome);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(
                      isArabic ? 'العودة للرئيسية' : 'Return to Customer Home',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primaryBrand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FixoSpacing.lg,
                        vertical: FixoSpacing.sm,
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

    final offering = widget.initialOffering!;
    final preferredPro = widget.initialPreferredPro;
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.canvasBackground,
        appBar: AppBar(
          backgroundColor: palette.cardSurface.withValues(alpha: 0.9),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
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
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline_rounded, color: palette.mutedText),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'اختر العنوان واليوم والفترة الزمنية لإنشاء مسودة الحجز.'
                          : 'Select your address, date, and preferred time window to create a booking draft.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
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

                  // Selected Service & Provider Card
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
                    onChangeAddress: state.hasSavedAddresses
                        ? () => _showAddressSelectionModal(
                            context,
                            state.addresses,
                            state.selectedAddress,
                            isArabic,
                          )
                        : null,
                    onAddNewAddress: () => _showCreateAddressSheet(context),
                  ),
                  const SizedBox(height: FixoSpacing.sm),

                  // Date Picker Group
                  BookingDateSelector(
                    selectedDate: state.selectedDate,
                    today: ref.read(appNowProvider)(),
                    onSelectDate: controller.selectDate,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: FixoSpacing.sm),

                  // Preferred Time Window Group
                  OutlinedButton.icon(
                    key: const Key('booking-exact-time'),
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      '${isArabic ? 'الساعة' : 'Time'}: ${state.scheduledTime}',
                    ),
                    onPressed: () async {
                      final parts = state.scheduledTime.split(':');
                      final time = await showTimePicker(
                        context: context,
                        builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                        initialTime: TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        ),
                      );
                      if (time != null) {
                        controller.selectExactTime(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: FixoSpacing.sm),

                  // Issue Description Card
                  Container(
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
                                    Icons.edit_note_rounded,
                                    color: palette.deepForest,
                                    size: 20,
                                  ),
                                  const SizedBox(width: FixoSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      isArabic
                                          ? 'وصف المشكلة'
                                          : 'Issue Description',
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
                              isArabic ? 'اختياري' : 'Optional',
                              style: FixoTypography.labelMd(
                                color: palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: FixoSpacing.xs),
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceLow,
                            borderRadius: BorderRadius.circular(
                              FixoRadius.pill,
                            ),
                            border: Border.all(color: palette.subtleBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.view_in_ar_rounded,
                                size: 14,
                                color: FixoColors.primaryForest,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isArabic
                                      ? 'مجسم 3D تفاعلي: حدد مكان العطل بالضغط على النقطة'
                                      : 'Interactive 3D: Tap a pin to diagnose the issue',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FixoTypography.labelSm(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 3D Interactive Defect Pinning Canvas
                        Appliance3DInspectionWidget(
                          key: const Key('appliance-3d-inspection'),
                          categorySlug: offering.categorySlug,
                          isArabic: isArabic,
                          onPinSelected: (diagnosticDetail) {
                            final currentText = _issueDescriptionController.text
                                .trim();
                            final newText = currentText.isEmpty
                                ? diagnosticDetail
                                : '$currentText - $diagnosticDetail';
                            _issueDescriptionController.text = newText;
                            controller.setIssueDescription(newText);
                          },
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
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            InkWell(
                              onTap: _isUploadingPhoto
                                  ? null
                                  : () => _pickAndUploadPhoto(isArabic),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 68,
                                  minHeight: 64,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceLow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: FixoColors.primaryForest.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isUploadingPhoto)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            FixoColors.primaryForest,
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 20,
                                        color: FixoColors.primaryForest,
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isArabic ? '+ صورة' : '+ Add',
                                      style:
                                          FixoTypography.bodySm(
                                            color: FixoColors.primaryForest,
                                          ).copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...state.issuePhotoUrls.map((url) {
                              return Container(
                                height: 64,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceLow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: palette.subtleBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image_rounded,
                                      size: 24,
                                      color: palette.deepForest,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isArabic ? 'صورة مرفقة' : 'Attached',
                                      style: FixoTypography.labelMd(
                                        color: palette.deepForest,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: FixoColors.error,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => ref
                                          .read(
                                            createBookingControllerProvider
                                                .notifier,
                                          )
                                          .removePhotoUrl(url),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
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
                              state.errorMessage!,
                              style: FixoTypography.bodySm(
                                color: colorScheme.onErrorContainer,
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
        ),

        // Scaffold reserves this space so snackbars cannot cover confirmation.
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FixoSpacing.md,
            vertical: FixoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: palette.cardSurface,
            border: Border(top: BorderSide(color: palette.subtleBorder)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Center(
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
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
                                    ? 'ميزة حفظ الخدمات ستتوفر في تحديث قادم.'
                                    : 'Saved services feature will be available in an upcoming update.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: FixoSpacing.sm),

                    // Primary Confirm Booking Draft Button
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              key: const Key('confirm-booking-draft-btn'),
                              onPressed:
                                  (state.isSubmitting ||
                                      state.selectedAddress == null)
                                  ? null
                                  : () async {
                                      final scaffoldMessenger =
                                          ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(context);

                                      final success = await controller
                                          .submitBooking(
                                            offering: offering,
                                            preferredPro: preferredPro,
                                          );
                                      if (success) {
                                        final booking = ref
                                            .read(
                                              createBookingControllerProvider,
                                            )
                                            .successBooking;
                                        final orderCode =
                                            booking?.orderCode ?? 'FX-XXXX';

                                        if (!context.mounted) return;
                                        if (booking != null &&
                                            booking.id.isNotEmpty) {
                                          try {
                                            context.go(
                                              '/customer/bookings/${booking.id}/checkout',
                                            );
                                            return;
                                          } catch (_) {
                                            // Standalone callers without the app router can still pop.
                                          }
                                        }
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                palette.primaryBrand,
                                            content: Text(
                                              key: const Key(
                                                'booking-draft-success-snackbar-text',
                                              ),
                                              isArabic
                                                  ? 'تم تسجيل طلب الحجز #$orderCode بنجاح (مسودة).'
                                                  : 'Booking #$orderCode created in DRAFT status.',
                                              style: FixoTypography.bodySm(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );

                                        if (navigator.canPop()) {
                                          navigator.pop(booking);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: palette.primaryBrand,
                                disabledBackgroundColor: palette.primaryBrand
                                    .withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: state.isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                                                ? 'تأكيد مسودة الحجز'
                                                : 'Confirm Booking Draft',
                                            style:
                                                FixoTypography.labelLg(
                                                  color: Colors.white,
                                                ).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${offering.flatPriceEgp} EGP',
                                            style:
                                                FixoTypography.labelMd(
                                                  color: FixoColors
                                                      .onTertiaryFixed,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'يتم إنشاء مسودة حجز. سيتم إتاحة الدفع وتعيين الفني في المراحل التالية.'
                                : 'Creates a booking draft. Payment and technician assignment follow in subsequent steps.',
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
                            ).copyWith(fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
