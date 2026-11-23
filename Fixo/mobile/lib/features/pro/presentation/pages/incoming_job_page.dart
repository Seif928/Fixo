import 'dart:async';
import 'package:material_ui/material_ui.dart';
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
import '../../domain/server_offer_budget.dart';

final jobOfferClockProvider = Provider<Duration Function()>((ref) {
  final stopwatch = Stopwatch()..start();
  ref.onDispose(stopwatch.stop);
  return () => stopwatch.elapsed;
});

/// Screen 16: Incoming Job Request (`16 — Incoming Job Request`)
class IncomingJobPage extends ConsumerStatefulWidget {
  const IncomingJobPage({super.key, required this.jobOfferId});

  final String jobOfferId;

  @override
  ConsumerState<IncomingJobPage> createState() => _IncomingJobPageState();
}

class _IncomingJobPageState extends ConsumerState<IncomingJobPage>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _acting = false;
  String? _errorMessage;
  JobOfferModel? _offer;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  int _loadGeneration = 0;
  bool _inForeground = true;
  late final _clock = ref.read(jobOfferClockProvider);
  late final _budget = ServerOfferBudget(_clock);
  bool get _canRespond =>
      _inForeground &&
      _offer != null &&
      !_loading &&
      !_acting &&
      _budget.remainingSeconds > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOffer();
  }

  @override
  void didUpdateWidget(covariant IncomingJobPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobOfferId != widget.jobOfferId) _loadOffer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (!_inForeground) {
      _loadGeneration++;
      _countdownTimer?.cancel();
      if (mounted) setState(() {});
    } else {
      _loadOffer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _loadGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadOffer() async {
    final generation = ++_loadGeneration;
    final id = widget.jobOfferId;
    final requestStarted = _clock();
    _countdownTimer?.cancel();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(proRepositoryProvider);
      final offer = await repo.getJobOfferById(id);
      if (!mounted || !_inForeground || generation != _loadGeneration) return;
      if (offer.id != id || DateTime.tryParse(offer.expiresAt) == null) {
        throw const FormatException('Job offer identity or expiry is invalid.');
      }
      _budget.synchronize(
        revision: '${offer.id}:${offer.expiresAt}',
        remainingSeconds: offer.remainingSeconds,
        requestStarted: requestStarted,
        pending: const ['PENDING', 'OFFERED'].contains(offer.status),
      );
      setState(() {
        _offer = offer;
        _secondsLeft = _budget.remainingSeconds;
        _loading = false;
      });
      _startCountdown();
    } catch (_) {
      if (!mounted || !_inForeground || generation != _loadGeneration) return;
      final ar = ref.read(appLocaleProvider).languageCode == 'ar';
      setState(() {
        _offer = null;
        _secondsLeft = 0;
        _errorMessage = ar
            ? 'تعذر تحديث العرض. حاول تاني قبل اتخاذ أي إجراء.'
            : 'Could not refresh the offer. Retry before taking action.';
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
      final remaining = _budget.remainingSeconds;
      setState(() => _secondsLeft = remaining);
      if (remaining <= 0) timer.cancel();
    });
  }

  Future<void> _acceptJob(bool ar) async {
    if (!_canRespond) {
      setState(() => _secondsLeft = _budget.remainingSeconds);
      return;
    }
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
            ar
                ? 'تم قبول الطلب بنجاح وإسناده لجدولك!'
                : 'Job accepted and added to your schedule!',
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
    if (!_canRespond) return;
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
                        style: FixoTypography.headlineSm().copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                                  ? palette.primaryBrand
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
                      backgroundColor: palette.error,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? FixoColors.deepestForest
                          : Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      if (!_canRespond) return;
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
    final scheduledDate = DateTime.tryParse(offer?.scheduledDate ?? '');
    final window =
        offer?.scheduledTime ??
        switch (offer?.timeWindow) {
          'MORNING_09_12' => ar ? 'صباحًا ٩–١٢' : 'Morning 09:00–12:00',
          'AFTERNOON_13_16' => ar ? 'ظهرًا ١٣–١٦' : 'Afternoon 13:00–16:00',
          'EVENING_17_20' => ar ? 'مساءً ١٧–٢٠' : 'Evening 17:00–20:00',
          _ => ar ? 'الفترة غير متاحة' : 'Time window unavailable',
        };
    final inactiveLabel = switch (offer?.status) {
      'ACCEPTED' => ar ? 'تم قبول هذا العرض' : 'Offer already accepted',
      'DECLINED' => ar ? 'تم الاعتذار عن هذا العرض' : 'Offer already declined',
      _ => ar ? 'انتهت صلاحية هذا الطلب' : 'Offer has expired',
    };

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
                            margin: const EdgeInsets.only(
                              bottom: FixoSpacing.md,
                            ),
                            padding: const EdgeInsets.all(FixoSpacing.sm),
                            decoration: BoxDecoration(
                              color: palette.errorContainer,
                              borderRadius: FixoRadius.borderRadiusMd,
                            ),
                            child: Text(
                              _errorMessage!,
                              style: FixoTypography.bodySm(
                                color: palette.onErrorContainer,
                              ),
                            ),
                          ),

                        if (_errorMessage != null && offer == null)
                          TextButton.icon(
                            onPressed: _inForeground ? _loadOffer : null,
                            icon: const Icon(Icons.refresh),
                            label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                          ),

                        if (offer != null) ...[
                          // Countdown Banner
                          Container(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            decoration: BoxDecoration(
                              color: _secondsLeft > 0
                                  ? palette.warningContainer
                                  : palette.errorContainer,
                              borderRadius: FixoRadius.borderRadiusLg,
                              border: Border.all(
                                color: _secondsLeft > 0
                                    ? palette.warning
                                    : palette.error,
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
                                      ? palette.onWarningContainer
                                      : palette.onErrorContainer,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _secondsLeft > 0
                                        ? '${ar ? 'الوقت المتبقي للقبول:' : 'Time remaining to accept:'} $_secondsLeft ${ar ? 'ثانية' : 'sec'}'
                                        : inactiveLabel,
                                    textAlign: TextAlign.center,
                                    style: FixoTypography.headlineSm(
                                      color: _secondsLeft > 0
                                          ? palette.onWarningContainer
                                          : palette.onErrorContainer,
                                      tabularFigures: true,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
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
                                        borderRadius:
                                            FixoRadius.borderRadiusPill,
                                        border: Border.all(
                                          color: palette.subtleBorder,
                                        ),
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
                                      ar
                                          ? offer.categoryNameAr
                                          : offer.categoryNameEn,
                                      style: FixoTypography.labelSm(
                                        color: palette.mutedText,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ar
                                      ? offer.serviceTitleAr
                                      : offer.serviceTitleEn,
                                  style: FixoTypography.headlineLgMobile(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, color: palette.subtleBorder),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: palette.mutedText,
                                    ),
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
                                    Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: palette.mutedText,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${offer.customerName} (${offer.customerPhoneMasked})',
                                        style: FixoTypography.bodyMd(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: palette.mutedText,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${scheduledDate == null ? (ar ? 'التاريخ غير متاح' : 'Date unavailable') : MaterialLocalizations.of(context).formatMediumDate(scheduledDate)} • $window',
                                        style: FixoTypography.bodyMd(
                                          color: palette.mutedText,
                                        ),
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
                                  ar
                                      ? 'تفاصيل مستحقاتك وأرباحك'
                                      : 'Artisan Earnings Breakdown',
                                  style: FixoTypography.headlineSm(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ar
                                            ? 'إجمالي قيمة الحجز من العميل'
                                            : 'Customer Booking Total',
                                        style: FixoTypography.bodyMd(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ar
                                            ? 'رسوم منصة فيكسو'
                                            : 'FIXO Platform Fee',
                                        style: FixoTypography.bodyMd(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '- ${offer.platformFeeEgp} ${ar ? 'ج.م' : 'EGP'}',
                                      style: FixoTypography.labelMd(
                                        color: palette.error,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ar
                                            ? 'الصافي بعد رسوم المنصة'
                                            : 'Net after platform fee',
                                        style: FixoTypography.headlineSm(
                                          color: palette.deepForest,
                                        ).copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${offer.netArtisanEgp} ${ar ? 'ج.م' : 'EGP'}',
                                      style: FixoTypography.headlineLgMobile(
                                        color: palette.primaryBrand,
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
                                  key: const Key('pro-offer-decline'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    foregroundColor: palette.error,
                                    side: BorderSide(color: palette.error),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: FixoRadius.borderRadiusMd,
                                    ),
                                  ),
                                  onPressed: _canRespond
                                      ? () => _showDeclineSheet(ar)
                                      : null,
                                  child: Text(
                                    ar ? 'اعتذار' : 'Decline',
                                    style: FixoTypography.labelLg(
                                      color: palette.error,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  key: const Key('pro-offer-accept'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    backgroundColor: _secondsLeft > 0
                                        ? palette.primaryBrand
                                        : palette.surfaceHigh,
                                    foregroundColor: _secondsLeft > 0
                                        ? palette.onPrimary
                                        : palette.mutedText,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: FixoRadius.borderRadiusMd,
                                    ),
                                  ),
                                  onPressed: _canRespond
                                      ? () => _acceptJob(ar)
                                      : null,
                                  icon: _acting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              palette.onPrimary,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.check_circle_rounded),
                                  label: Text(
                                    ar
                                        ? 'قبول الطلب والتوجه للعميل'
                                        : 'Accept Job Offer',
                                    style: FixoTypography.labelLg(
                                      color: _secondsLeft > 0
                                          ? palette.onPrimary
                                          : palette.mutedText,
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
