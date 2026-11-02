import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../data/pro_repository.dart';
import '../../domain/pro_models.dart';

/// Screen 16: Incoming Job Request (`16 — Incoming Job Request`)
class IncomingJobPage extends ConsumerStatefulWidget {
  const IncomingJobPage({super.key, required this.jobOfferId});

  final String jobOfferId;

  @override
  ConsumerState<IncomingJobPage> createState() => _IncomingJobPageState();
}

class _IncomingJobPageState extends ConsumerState<IncomingJobPage> {
  bool _loading = true;
  bool _acting = false;
  String? _errorMessage;
  JobOfferModel? _offer;
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOffer() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      final offer = await repo.getJobOfferById(widget.jobOfferId);
      if (!mounted) return;
      setState(() {
        _offer = offer;
        _secondsLeft = offer.remainingSeconds;
        _loading = false;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_secondsLeft <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _acceptJob(bool ar) async {
    if (_secondsLeft <= 0) return;
    setState(() {
      _acting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(proRepositoryProvider);
      await repo.acceptJobOffer(widget.jobOfferId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'تم قبول الطلب بنجاح وإسناده لجدولك!' : 'Job accepted and added to your schedule!',
          ),
        ),
      );
      context.go(AppRoutes.proDashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _acting = false;
      });
    }
  }

  Future<void> _showDeclineSheet(bool ar) async {
    final reasons = ar
        ? [
            'المنطقة بعيدة جداً عن موقعي الحالي',
            'زحام مروري يعيق الالتزام بالموعد',
            'جدول المواعيد ممتلئ اليوم',
            'غير متاح لحالات الطوارئ الآن',
          ]
        : [
            'Distance too far from my current location',
            'Heavy traffic prevents on-time arrival',
            'Schedule fully booked today',
            'Currently unavailable for emergency calls',
          ];

    String selectedReason = reasons.first;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final palette = sheetContext.fixoPalette;
            return Padding(
              padding: const EdgeInsets.all(FixoSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ar ? 'سبب الاعتذار عن الطلب' : 'Reason for Declining',
                        style: FixoTypography.headlineSm().copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) {
                    final isSel = selectedReason == r;
                    return InkWell(
                      onTap: () => setSheetState(() => selectedReason = r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              isSel
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSel
                                  ? FixoColors.primaryForest
                                  : palette.mutedText,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(r, style: FixoTypography.bodyMd()),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: FixoColors.error,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      setState(() => _acting = true);
                      try {
                        final repo = ref.read(proRepositoryProvider);
                        await repo.declineJobOffer(
                          widget.jobOfferId,
                          reason: selectedReason,
                        );
                        if (!mounted) return;
                        context.go(AppRoutes.proDashboard);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _errorMessage = e.toString();
                          _acting = false;
                        });
                      }
                    },
                    child: Text(ar ? 'تأكيد الاعتذار' : 'Confirm Decline'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;
    final offer = _offer;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.canvasBackground,
        appBar: AppBar(
          backgroundColor: palette.cardSurface.withValues(alpha: 0.95),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
            onPressed: () => context.go(AppRoutes.proDashboard),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const FixoBrandMark(iconBoxSize: 26, showSubtitle: false),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  ar ? 'طلب خدمة وارد' : 'Incoming Job Request',
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: FixoSpacing.md),
                            padding: const EdgeInsets.all(FixoSpacing.sm),
                            decoration: BoxDecoration(
                              color: FixoColors.errorContainer,
                              borderRadius: FixoRadius.borderRadiusMd,
                            ),
                            child: Text(
                              _errorMessage!,
                              style: FixoTypography.bodySm(
                                color: FixoColors.onErrorContainer,
                              ),
                            ),
                          ),

                        if (offer != null) ...[
                          // Countdown Banner
                          Container(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            decoration: BoxDecoration(
                              color: _secondsLeft > 0
                                  ? FixoColors.secondaryContainer
                                  : FixoColors.errorContainer,
                              borderRadius: FixoRadius.borderRadiusLg,
                              border: Border.all(
                                color: _secondsLeft > 0
                                    ? FixoColors.secondary
                                    : FixoColors.error,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _secondsLeft > 0
                                      ? Icons.timer_outlined
                                      : Icons.timer_off_outlined,
                                  color: _secondsLeft > 0
                                      ? FixoColors.primaryForest
                                      : FixoColors.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _secondsLeft > 0
                                      ? '${ar ? 'الوقت المتبقي للقبول:' : 'Time remaining to accept:'} $_secondsLeft ${ar ? 'ثانية' : 'sec'}'
                                      : (ar ? 'انتهت صلاحية هذا الطلب' : 'Offer has expired'),
                                  style: FixoTypography.headlineSm(
                                    color: _secondsLeft > 0
                                        ? FixoColors.primaryForest
                                        : FixoColors.error,
                                    tabularFigures: true,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.md),

                          // Job Summary Card
                          FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            borderRadius: FixoRadius.borderRadiusLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.surfaceLow,
                                        borderRadius: FixoRadius.borderRadiusPill,
                                        border: Border.all(color: palette.subtleBorder),
                                      ),
                                      child: Text(
                                        '#${offer.orderCode}',
                                        style: FixoTypography.labelMd(
                                          color: palette.deepForest,
                                        ).copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      ar ? offer.categoryNameAr : offer.categoryNameEn,
                                      style: FixoTypography.labelSm(
                                        color: palette.mutedText,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ar ? offer.serviceTitleAr : offer.serviceTitleEn,
                                  style: FixoTypography.headlineLgMobile(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, color: palette.subtleBorder),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 18, color: palette.mutedText),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${offer.districtLine} • ${ar ? offer.zoneNameAr : offer.zoneNameEn}',
                                        style: FixoTypography.bodyMd(
                                          color: palette.deepForest,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 18, color: palette.mutedText),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${offer.customerName} (${offer.customerPhoneMasked})',
                                      style: FixoTypography.bodyMd(
                                        color: palette.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 18, color: palette.mutedText),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${offer.scheduledDate} • ${offer.timeWindow}',
                                      style: FixoTypography.bodyMd(
                                        color: palette.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.md),

                          // Cash service net breakdown
                          FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            borderRadius: FixoRadius.borderRadiusLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  ar ? 'تفاصيل مستحقاتك وأرباحك' : 'Artisan Earnings Breakdown',
                                  style: FixoTypography.headlineSm(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ar ? 'إجمالي قيمة الحجز من العميل' : 'Customer Booking Total',
                                      style: FixoTypography.bodyMd(color: palette.mutedText),
                                    ),
                                    Text(
                                      '${offer.grossEgp} ${ar ? 'ج.م' : 'EGP'}',
                                      style: FixoTypography.labelMd(
                                        color: palette.deepForest,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ar ? 'رسوم منصة فيكسو (١٥٪)' : 'FIXO Platform Fee (15%)',
                                      style: FixoTypography.bodyMd(color: palette.mutedText),
                                    ),
                                    Text(
                                      '- ${offer.platformFeeEgp} ${ar ? 'ج.م' : 'EGP'}',
                                      style: FixoTypography.labelMd(
                                        color: FixoColors.error,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ar ? 'الصافي بعد رسوم المنصة' : 'Net after platform fee',
                                      style: FixoTypography.headlineSm(
                                        color: FixoColors.primaryForest,
                                      ).copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      '${offer.netArtisanEgp} ${ar ? 'ج.م' : 'EGP'}',
                                      style: FixoTypography.headlineLgMobile(
                                        color: FixoColors.primaryForest,
                                      ).copyWith(fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.lg),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    foregroundColor: FixoColors.error,
                                    side: const BorderSide(color: FixoColors.error),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: FixoRadius.borderRadiusMd,
                                    ),
                                  ),
                                  onPressed: _acting ? null : () => _showDeclineSheet(ar),
                                  child: Text(
                                    ar ? 'اعتذار' : 'Decline',
                                    style: FixoTypography.labelLg(
                                      color: FixoColors.error,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    backgroundColor: _secondsLeft > 0
                                        ? FixoColors.primaryForest
                                        : palette.surfaceHigh,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: FixoRadius.borderRadiusMd,
                                    ),
                                  ),
                                  onPressed: (_secondsLeft > 0 && !_acting)
                                      ? () => _acceptJob(ar)
                                      : null,
                                  icon: _acting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.check_circle_rounded),
                                  label: Text(
                                    ar ? 'قبول الطلب والتوجه للعميل' : 'Accept Job Offer',
                                    style: FixoTypography.labelLg(
                                      color: Colors.white,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
