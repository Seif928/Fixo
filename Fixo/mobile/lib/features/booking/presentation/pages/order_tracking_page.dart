import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/location/free_map_picker.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../../customer_home/presentation/widgets/customer_home_widgets.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';
import '../widgets/booking_receipt_sheet.dart';

/// Screen 06: Live Order Tracking (`06 — Live Order Tracking`)
///
/// Displays actual booking status, saved service address map pin (when coordinates exist),
/// assigned professional card, 5-step milestone progression timeline bound to real
/// `BookingStatusEvent` records, and the customer's 4-digit Artisan Arrival Code.
/// Never fabricates live GPS vehicle telemetry, speed, or fake arrival countdowns.
class OrderTrackingPage extends ConsumerStatefulWidget {
  const OrderTrackingPage({
    super.key,
    required this.orderId,
    this.initialTracking,
  });

  final String orderId;
  final BookingTrackingModel? initialTracking;

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  BookingTrackingModel? _tracking;
  bool _loading = true;
  bool _cancelling = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialTracking != null) {
      _tracking = widget.initialTracking;
      _loading = false;
    } else {
      _loadTracking();
      _startBoundedPolling();
    }
  }

  void _startBoundedPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      final status = _tracking?.booking.status;
      if (status == 'COMPLETED' || status == 'CANCELLED') {
        _pollTimer?.cancel();
        return;
      }
      _loadTracking(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTracking({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await ref
          .read(bookingRepositoryProvider)
          .getBookingTracking(widget.orderId);
      if (!mounted) return;
      setState(() {
        _tracking = result;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = 'FAILED';
      });
    }
  }

  Future<void> _confirmAndCancelBooking(bool ar) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(ar ? 'إلغاء طلب الخدمة؟' : 'Cancel Service Booking?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ar
                    ? 'يمكنك إلغاء الطلب مجاناً قبل بدء الخدمة.'
                    : 'You can cancel this booking before service work begins.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: ar ? 'سبب الإلغاء (اختياري)' : 'Reason (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ar ? 'تراجع' : 'Keep Booking'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: FixoColors.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ar ? 'تأكيد الإلغاء' : 'Confirm Cancel'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }

    final reasonText = reasonController.text.trim();
    reasonController.dispose();

    setState(() => _cancelling = true);
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(
            widget.orderId,
            reason: reasonText.isEmpty ? null : reasonText,
          );
      await _loadTracking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'تم إلغاء الطلب بنجاح.' : 'Booking cancelled.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تعذّر إلغاء الطلب. حاول مرة أخرى.'
                  : 'Could not cancel booking. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _statusHeadline(String status, bool ar) => switch (status) {
        'DRAFT' => ar ? 'مسودة — بانتظار تأكيد الدفع' : 'Draft — Awaiting Checkout',
        'PENDING_DISPATCH' || 'OFFERED_TO_PRO' => ar
            ? 'جارٍ إسناد الطلب لفني معتمد'
            : 'Matching with Verified Pro',
        'CONFIRMED' => ar ? 'تم تعيين الفني وتأكيد الموعد' : 'Professional Assigned & Confirmed',
        'PRO_EN_ROUTE' => ar ? 'الفني في الطريق إلى عنوانك' : 'Professional En Route to Address',
        'ARRIVED' => ar ? 'وصل الفني إلى موقع الخدمة' : 'Professional Arrived at Location',
        'IN_PROGRESS' => ar ? 'الخدمة قيد التنفيذ حالياً' : 'Service Work In Progress',
        'COMPLETED' => ar ? 'اكتملت الخدمة بنجاح' : 'Service Completed Successfully',
        'CANCELLED' => ar ? 'تم إلغاء الطلب' : 'Booking Cancelled',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;
    final horizontal = (MediaQuery.sizeOf(context).width - 680) / 2;
    final inset = horizontal > 16 ? horizontal : 16.0;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.canvasBackground,
        appBar: AppBar(
          backgroundColor: palette.cardSurface.withValues(alpha: 0.94),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            key: const Key('tracking-back-btn'),
            icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.myOrders);
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const FixoBrandMark(showSubtitle: false, iconBoxSize: 26),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  ar ? 'متابعة حالة الطلب' : 'Order Status & Tracking',
                  overflow: TextOverflow.ellipsis,
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const Key('tracking-refresh-btn'),
              tooltip: ar ? 'تحديث' : 'Refresh',
              onPressed: _loading ? null : () => _loadTracking(),
              icon: Icon(
                Icons.refresh_rounded,
                color: palette.deepForest,
                size: 20,
              ),
            ),
            const SizedBox(width: FixoSpacing.xs),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: palette.subtleBorder, height: 1.0),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null || _tracking == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(FixoSpacing.lg),
                        child: FixoSurfaceCard(
                          padding: const EdgeInsets.all(FixoSpacing.lg),
                          borderRadius: FixoRadius.borderRadiusLg,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: FixoColors.error,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ar
                                    ? 'تعذّر تحميل بيانات متابعة الطلب.'
                                    : 'Could not load order tracking details.',
                                textAlign: TextAlign.center,
                                style: FixoTypography.bodyMd(
                                  color: palette.inkText,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _loadTracking(),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _buildContent(context, _tracking!, ar, inset),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BookingTrackingModel tracking,
    bool ar,
    double inset,
  ) {
    final palette = context.fixoPalette;
    final booking = tracking.booking;
    final addr = booking.address;
    final lat = (addr['latitude'] as num?)?.toDouble();
    final lng = (addr['longitude'] as num?)?.toDouble();
    final hasValidCoords =
        lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat.abs() <= 90 &&
        lng.abs() <= 180;

    final pinDigits = (booking.arrivalPinCode ?? '----')
        .padRight(4, '-')
        .substring(0, 4)
        .split('');

    return ListView(
      padding: EdgeInsets.fromLTRB(inset, FixoSpacing.md, inset, FixoSpacing.xl),
      children: [
        // 1. Order Status & Saved Location Card (Screen 06 Hero)
        FixoSurfaceCard(
          padding: EdgeInsets.zero,
          borderRadius: FixoRadius.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(FixoSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FixoColors.deepestForest,
                      FixoColors.primaryForest,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FixoColors.limeAccent,
                            borderRadius: FixoRadius.borderRadiusPill,
                          ),
                          child: Text(
                            '#${booking.orderCode}',
                            key: const Key('tracking-order-code-badge'),
                            style: FixoTypography.labelSm(
                              color: FixoColors.deepestForest,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: FixoRadius.borderRadiusPill,
                          ),
                          child: Text(
                            booking.status,
                            key: const Key('tracking-status-badge'),
                            style: FixoTypography.labelSm(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusHeadline(booking.status, ar),
                      style: FixoTypography.headlineSm(
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ar
                          ? tracking.trackingAccuracyNoteAr
                          : tracking.trackingAccuracyNoteEn,
                      style: FixoTypography.bodySm(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasValidCoords)
                ClipRRect(
                  child: SavedLocationMap(
                    point: ServiceMapPoint(lat, lng),
                    isArabic: ar,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: palette.deepForest,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (addr['label'] as String?) ??
                                (ar ? 'عنوان الخدمة' : 'Service Address'),
                            style: FixoTypography.labelLg(
                              color: palette.deepForest,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${addr['buildingLine'] ?? ''}, ${addr['districtLine'] ?? ''}',
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
          ),
        ),
        const SizedBox(height: FixoSpacing.md),

        // 2. Assigned Professional Card (or Awaiting Assignment Card)
        _buildProfessionalCard(context, booking, tracking, ar),
        const SizedBox(height: FixoSpacing.md),

        // 3. 4-Digit Artisan Arrival Code Security Card (Screen 06)
        if (booking.arrivalPinCode != null &&
            booking.arrivalPinCode != '****' &&
            booking.status != 'CANCELLED') ...[
          FixoSurfaceCard(
            key: const Key('tracking-arrival-pin-card'),
            padding: const EdgeInsets.all(FixoSpacing.md),
            borderRadius: FixoRadius.borderRadiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.surfaceLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.subtleBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: FixoColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'كود وصول الفني (٤ أرقام)' : 'Artisan Arrival Code',
                            style: FixoTypography.labelLg(
                              color: palette.deepForest,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            ar
                                ? 'شارك هذا الكود مع الفني عند وصوله لباب منزلك لبدء الخدمة.'
                                : 'Share this 4-digit code with your pro upon arrival to start service.',
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pinDigits.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 48,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.surfaceLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: palette.primaryBrand.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              pinDigits[i],
                              style: FixoTypography.headlineMd(
                                color: palette.deepForest,
                              ).copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FixoSpacing.md),
        ],

        // 4. 5-Step Service Milestone Vertical Timeline (Screen 06)
        FixoSurfaceCard(
          key: const Key('tracking-milestones-card'),
          padding: const EdgeInsets.all(FixoSpacing.md),
          borderRadius: FixoRadius.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'مراحل تنفيذ الخدمة' : 'Service Milestones',
                style: FixoTypography.headlineSm(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: FixoSpacing.md),
              for (var i = 0; i < tracking.milestones.length; i++)
                _buildMilestoneRow(
                  context,
                  tracking.milestones[i],
                  isLast: i == tracking.milestones.length - 1,
                  ar: ar,
                ),
            ],
          ),
        ),
        const SizedBox(height: FixoSpacing.md),

        // 5. Payment, Receipt, Review & Cancellation Actions
        FixoSurfaceCard(
          padding: const EdgeInsets.all(FixoSpacing.md),
          borderRadius: FixoRadius.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    ar ? 'إجمالي قيمة الخدمة' : 'Service Total (Cash on Service)',
                    style: FixoTypography.bodyMd(
                      color: palette.mutedText,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${booking.pricing.totalEgp} ${ar ? 'ج.م' : 'EGP'}',
                    style: FixoTypography.headlineSm(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    key: const Key('tracking-view-receipt-btn'),
                    onPressed: () => BookingReceiptSheet.show(
                      context,
                      bookingId: booking.id,
                      isArabic: ar,
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text(ar ? 'عرض الإيصال' : 'View Receipt'),
                  ),
                  if (tracking.canReview)
                    FilledButton.icon(
                      key: const Key('tracking-rate-review-btn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: FixoColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await context.push(
                          AppRoutes.rateReview.replaceFirst(
                            ':orderId',
                            Uri.encodeComponent(booking.id),
                          ),
                        );
                        if (mounted) _loadTracking();
                      },
                      icon: const Icon(Icons.star_rate_rounded, size: 18),
                      label: Text(ar ? 'تقييم الخدمة' : 'Rate & Review'),
                    ),
                  if (tracking.canCancel)
                    TextButton.icon(
                      key: const Key('tracking-cancel-booking-btn'),
                      style: TextButton.styleFrom(
                        foregroundColor: FixoColors.error,
                      ),
                      onPressed: _cancelling
                          ? null
                          : () => _confirmAndCancelBooking(ar),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(ar ? 'إلغاء الطلب' : 'Cancel Booking'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalCard(
    BuildContext context,
    BookingDetailModel booking,
    BookingTrackingModel tracking,
    bool ar,
  ) {
    final palette = context.fixoPalette;
    final pro = booking.proProfile;

    if (pro == null) {
      return FixoSurfaceCard(
        padding: const EdgeInsets.all(FixoSpacing.md),
        borderRadius: FixoRadius.borderRadiusLg,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.surfaceLow,
                shape: BoxShape.circle,
                border: Border.all(color: palette.subtleBorder),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_search_rounded,
                color: palette.deepForest,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar
                        ? 'بانتظار قبول أحد الفنيين المعتمدين'
                        : 'Awaiting Verified Professional Assignment',
                    style: FixoTypography.labelLg(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ar
                        ? 'يظهر اسم الفني وبيانات المركبة فور قبوله للطلب.'
                        : 'Assigned pro details and chat unlock as soon as a professional accepts your order.',
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final userMap = pro['user'] as Map<String, dynamic>?;
    final proName =
        (userMap?['fullName'] as String?) ??
        (ar ? 'فني فيكسو المعتمد' : 'Verified FIXO Pro');
    final dossierCode = (pro['dossierCode'] as String?) ?? 'FX-PRO';
    final specialty =
        (pro[ar ? 'specialtyAr' : 'specialtyEn'] as String?) ??
        (ar ? 'أخصائي صيانة منزلية' : 'Home Services Specialist');
    final ratingAvg = (pro['ratingAvg'] as num?)?.toDouble() ?? 5.0;
    final vehicleDesc = pro['vehicleDescription'] as String?;
    final vehiclePlate = pro['vehiclePlateAr'] as String?;

    return FixoSurfaceCard(
      key: const Key('tracking-assigned-pro-card'),
      padding: const EdgeInsets.all(FixoSpacing.md),
      borderRadius: FixoRadius.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FixoArtisanAvatar(identifier: proName, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          proName,
                          style: FixoTypography.labelLg(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceLow,
                            borderRadius: FixoRadius.borderRadiusPill,
                            border: Border.all(color: palette.subtleBorder),
                          ),
                          child: Text(
                            dossierCode,
                            style: FixoTypography.labelSm(
                              color: palette.deepForest,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: FixoTypography.bodySm(color: palette.mutedText),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ratingAvg.toStringAsFixed(1),
                          style: FixoTypography.labelMd(
                            color: palette.inkText,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (vehicleDesc != null && vehicleDesc.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              '• $vehicleDesc ${vehiclePlate ?? ''}',
                              overflow: TextOverflow.ellipsis,
                              style: FixoTypography.bodySm(
                                color: palette.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tracking.canChat) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('tracking-open-chat-btn'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primaryBrand,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () => context.push(
                AppRoutes.customerChat.replaceFirst(
                  ':orderId',
                  Uri.encodeComponent(booking.id),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(ar ? 'محادثة الفني' : 'Message Professional'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(
    BuildContext context,
    BookingTrackingMilestoneModel milestone, {
    required bool isLast,
    required bool ar,
  }) {
    final palette = context.fixoPalette;
    final isCompleted = milestone.state == 'COMPLETED';
    final isCurrent = milestone.state == 'CURRENT';
    final isCancelled = milestone.state == 'CANCELLED';

    final Color dotColor = isCompleted
        ? FixoColors.secondary
        : isCurrent
            ? palette.primaryBrand
            : isCancelled
                ? FixoColors.error
                : palette.surfaceHigh;

    final IconData iconData = isCompleted
        ? Icons.check_rounded
        : isCurrent
            ? Icons.radio_button_checked_rounded
            : isCancelled
                ? Icons.close_rounded
                : Icons.circle_outlined;

    DateTime? parsedTime;
    if (milestone.timestamp != null) {
      parsedTime = DateTime.tryParse(milestone.timestamp!);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  size: 16,
                  color: (isCompleted || isCurrent || isCancelled)
                      ? Colors.white
                      : palette.mutedText,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? FixoColors.secondary.withValues(alpha: 0.5)
                        : palette.subtleBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        ar ? milestone.titleAr : milestone.titleEn,
                        style: FixoTypography.labelLg(
                          color: isCompleted || isCurrent
                              ? palette.deepForest
                              : palette.mutedText,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (parsedTime != null)
                        Text(
                          DateFormat.jm(ar ? 'ar' : 'en').format(
                            parsedTime.toLocal(),
                          ),
                          style: FixoTypography.bodySm(
                            color: palette.mutedText,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ar ? milestone.subtitleAr : milestone.subtitleEn,
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

