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

/// Screen 15: Pro Dashboard (`15 — Pro Dashboard`)
class ProDashboardPage extends ConsumerStatefulWidget {
  const ProDashboardPage({super.key});

  @override
  ConsumerState<ProDashboardPage> createState() => _ProDashboardPageState();
}

class _ProDashboardPageState extends ConsumerState<ProDashboardPage> {
  bool _loading = true;
  bool _togglingOnline = false;
  String? _errorMessage;
  ProDashboardModel? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      final data = await repo.getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _togglingOnline = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      final newStatus = await repo.updateAvailability(value);
      if (!mounted) return;
      setState(() {
        if (_dashboard != null) {
          _dashboard = ProDashboardModel(
            isOnline: newStatus,
            todayEarningsEgp: _dashboard!.todayEarningsEgp,
            weekEarningsEgp: _dashboard!.weekEarningsEgp,
            completedJobsCount: _dashboard!.completedJobsCount,
            ratingAvg: _dashboard!.ratingAvg,
            reviewsCount: _dashboard!.reviewsCount,
            dailyTrajectory: _dashboard!.dailyTrajectory,
            activeOffers: _dashboard!.activeOffers,
            todaySchedule: _dashboard!.todaySchedule,
          );
        }
        _togglingOnline = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _togglingOnline = false;
      });
    }
  }

  Future<void> _showArrivalPinDialog(
    BuildContext context,
    String bookingId,
    bool ar,
  ) async {
    final pinController = TextEditingController();
    String? pinError;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: FixoRadius.borderRadiusLg,
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.pin_rounded,
                    color: FixoColors.primaryForest,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ar
                        ? 'كود بدء الخدمة (٤ أرقام)'
                        : 'Artisan Arrival PIN (4 digits)',
                    style: FixoTypography.headlineSm().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar
                        ? 'اطلب كود بدء الخدمة من العميل لإثبات الحضور وبدء العمل.'
                        : 'Ask customer for their 4-digit arrival code to start service.',
                    style: FixoTypography.bodySm(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: FixoTypography.headlineLg(tabularFigures: true),
                    decoration: InputDecoration(
                      hintText: '••••',
                      errorText: pinError,
                      counterText: '',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(ar ? 'إلغاء' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                      setDialogState(() {
                        pinError = ar
                            ? 'الكود يجب أن يتكون من ٤ أرقام'
                            : 'PIN must be 4 digits';
                      });
                      return;
                    }
                    try {
                      final repo = ref.read(proRepositoryProvider);
                      await repo.advanceBookingStatus(
                        bookingId,
                        toStatus: 'IN_PROGRESS',
                        arrivalPinCode: pin,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _loadDashboard();
                    } catch (e) {
                      setDialogState(() {
                        pinError = e.toString();
                      });
                    }
                  },
                  child: Text(ar ? 'تحقق وبدء الخدمة' : 'Verify & Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _advanceStatus(
    String bookingId,
    String toStatus,
    bool ar,
  ) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      await repo.advanceBookingStatus(bookingId, toStatus: toStatus);
      _loadDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;
    final dashboard = _dashboard;

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
            onPressed: () => context.go(AppRoutes.customerHome),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const FixoBrandMark(iconBoxSize: 26, showSubtitle: false),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  ar ? 'لوحة الفني' : 'FIXO Pro Dashboard',
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            if (dashboard != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Text(
                      dashboard.isOnline
                          ? (ar ? 'متاح' : 'Online')
                          : (ar ? 'غير متاح' : 'Offline'),
                      style: FixoTypography.labelSm(
                        color: dashboard.isOnline
                            ? FixoColors.primaryForest
                            : palette.mutedText,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: dashboard.isOnline,
                      onChanged: _togglingOnline ? null : _toggleAvailability,
                      activeTrackColor: FixoColors.primaryForest,
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
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

                        if (dashboard != null) ...[
                          // Active Job Offer Banner
                          if (dashboard.activeOffers.isNotEmpty) ...[
                            ...dashboard.activeOffers.map((offer) {
                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: FixoSpacing.md,
                                ),
                                padding: const EdgeInsets.all(FixoSpacing.md),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      FixoColors.deepestForest,
                                      FixoColors.primaryForest,
                                    ],
                                  ),
                                  borderRadius: FixoRadius.borderRadiusLg,
                                  boxShadow: FixoShadows.level2Interactive,
                                ),
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
                                            color: FixoColors.limeAccent,
                                            borderRadius:
                                                FixoRadius.borderRadiusPill,
                                          ),
                                          child: Text(
                                            ar
                                                ? 'طلب خدمة جديد!'
                                                : 'NEW JOB OFFER!',
                                            style:
                                                FixoTypography.labelSm(
                                                  color:
                                                      FixoColors.deepestForest,
                                                ).copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 16,
                                          color: FixoColors.limeAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${offer.remainingSeconds}s',
                                          style:
                                              FixoTypography.labelMd(
                                                color: FixoColors.limeAccent,
                                                tabularFigures: true,
                                              ).copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ar
                                          ? offer.serviceTitleAr
                                          : offer.serviceTitleEn,
                                      style: FixoTypography.headlineSm(
                                        color: Colors.white,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${offer.districtLine} • ${ar ? offer.zoneNameAr : offer.zoneNameEn}',
                                      style: FixoTypography.bodySm(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Text(
                                          '${offer.netArtisanEgp} ${ar ? 'ج.م صافي أرباحك' : 'EGP Net payout'}',
                                          style:
                                              FixoTypography.labelLg(
                                                color: FixoColors.limeAccent,
                                              ).copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size(0, 38),
                                            backgroundColor:
                                                FixoColors.limeAccent,
                                            foregroundColor:
                                                FixoColors.deepestForest,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  FixoRadius.borderRadiusMd,
                                            ),
                                          ),
                                          onPressed: () => context.push(
                                            AppRoutes.incomingJobRequest
                                                .replaceFirst(
                                                  ':jobId',
                                                  offer.id,
                                                ),
                                          ),
                                          icon: const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            ar ? 'تفاصيل الطلب' : 'View Job',
                                            style:
                                                FixoTypography.labelSm(
                                                  color:
                                                      FixoColors.deepestForest,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          // Earnings Hero Card
                          FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            borderRadius: FixoRadius.borderRadiusLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  ar
                                      ? 'صافي أرباح اليوم'
                                      : "Today's Net Earnings",
                                  style: FixoTypography.labelMd(
                                    color: palette.mutedText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${dashboard.todayEarningsEgp}',
                                          style:
                                              FixoTypography.displayMobile(
                                                color: FixoColors.primaryForest,
                                              ).copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          ar ? 'ج.م' : 'EGP',
                                          style:
                                              FixoTypography.labelLg(
                                                color: palette.deepForest,
                                              ).copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: FixoColors.secondaryContainer,
                                        borderRadius:
                                            FixoRadius.borderRadiusPill,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFD97706),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            dashboard.reviewsCount == 0
                                                ? (ar
                                                      ? 'لا توجد تقييمات بعد'
                                                      : 'No reviews yet')
                                                : '${dashboard.ratingAvg.toStringAsFixed(1)} (${dashboard.reviewsCount})',
                                            style:
                                                FixoTypography.labelSm(
                                                  color:
                                                      FixoColors.deepestForest,
                                                ).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: palette.subtleBorder),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ar
                                                ? 'أرباح الأسبوع'
                                                : 'Weekly Total',
                                            style: FixoTypography.bodySm(
                                              color: palette.mutedText,
                                            ),
                                          ),
                                          Text(
                                            '${dashboard.weekEarningsEgp} ${ar ? 'ج.م' : 'EGP'}',
                                            style:
                                                FixoTypography.labelLg(
                                                  color: palette.deepForest,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: palette.subtleBorder,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ar
                                                ? 'الطلبات المكتملة'
                                                : 'Completed Jobs',
                                            style: FixoTypography.bodySm(
                                              color: palette.mutedText,
                                            ),
                                          ),
                                          Text(
                                            '${dashboard.completedJobsCount}',
                                            style:
                                                FixoTypography.labelLg(
                                                  color: palette.deepForest,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.md),

                          // Weekly Daily Trajectory Chart
                          if (dashboard.dailyTrajectory.isNotEmpty) ...[
                            FixoSurfaceCard(
                              padding: const EdgeInsets.all(FixoSpacing.md),
                              borderRadius: FixoRadius.borderRadiusLg,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ar
                                        ? 'مؤشر أرباح الأسبوع'
                                        : '7-Day Net Trajectory',
                                    style: FixoTypography.headlineSm(
                                      color: palette.deepForest,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: dashboard.dailyTrajectory.map((
                                      d,
                                    ) {
                                      final maxEgp = dashboard.dailyTrajectory
                                          .map((e) => e.netEgp)
                                          .reduce((a, b) => a > b ? a : b);
                                      final ratio = maxEgp > 0
                                          ? (d.netEgp / maxEgp)
                                                .toDouble()
                                                .clamp(0.12, 1.0)
                                          : 0.12;
                                      final isToday = d.netEgp > 0;

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${d.netEgp}',
                                            style:
                                                FixoTypography.labelSm(
                                                  color: isToday
                                                      ? FixoColors.primaryForest
                                                      : palette.mutedText,
                                                  tabularFigures: true,
                                                ).copyWith(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 22,
                                            height: 60 * ratio,
                                            decoration: BoxDecoration(
                                              color: isToday
                                                  ? FixoColors.primaryForest
                                                  : palette.surfaceHigh,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            ar ? d.dayLabelAr : d.dayLabelEn,
                                            style:
                                                FixoTypography.labelSm(
                                                  color: isToday
                                                      ? palette.deepForest
                                                      : palette.mutedText,
                                                ).copyWith(
                                                  fontSize: 10,
                                                  fontWeight: isToday
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: FixoSpacing.md),
                          ],

                          // Working Hours & Leaves Entry Card
                          Padding(
                            padding: const EdgeInsets.only(bottom: FixoSpacing.md),
                            child: FixoSurfaceCard(
                              padding: const EdgeInsets.all(FixoSpacing.md),
                              borderRadius: FixoRadius.borderRadiusLg,
                              child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: palette.primaryBrand.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_outlined,
                                    color: palette.primaryBrand,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: FixoSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ar
                                            ? 'مواعيد العمل والإجازات'
                                            : 'Working Hours & Leaves',
                                        style: FixoTypography.bodyLg(
                                          color: palette.deepForest,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ar
                                            ? 'ضبط أوقات الدوام الأسبوعية وتثبيت الإجازات'
                                            : 'Manage weekly working shifts & leave periods',
                                        style: FixoTypography.labelSm(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    ar ? Icons.chevron_left : Icons.chevron_right,
                                    color: palette.primaryBrand,
                                  ),
                                  onPressed: () => context.push(AppRoutes.proSchedule),
                                ),
                              ],
                            ),
                          ),
                        ),

                          // Assigned Jobs Schedule
                          FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            borderRadius: FixoRadius.borderRadiusLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ar
                                          ? 'جدول طلبات اليوم'
                                          : "Today's Schedule",
                                      style: FixoTypography.headlineSm(
                                        color: palette.deepForest,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${dashboard.todaySchedule.length} ${ar ? 'مهام' : 'jobs'}',
                                      style: FixoTypography.labelSm(
                                        color: palette.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (dashboard.todaySchedule.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            color: palette.mutedText,
                                            size: 32,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            ar
                                                ? 'لا توجد طلبات جارية مسندة لك اليوم.'
                                                : 'No active jobs assigned today.',
                                            style: FixoTypography.bodySm(
                                              color: palette.mutedText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...dashboard.todaySchedule.map((job) {
                                    return _scheduledJobCard(job, ar);
                                  }),
                              ],
                            ),
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

  Widget _scheduledJobCard(ProScheduledJobModel job, bool ar) {
    final palette = context.fixoPalette;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceLow,
        borderRadius: FixoRadius.borderRadiusMd,
        border: Border.all(color: palette.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${job.orderCode}',
                style: FixoTypography.labelMd(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FixoColors.secondaryContainer,
                  borderRadius: FixoRadius.borderRadiusPill,
                ),
                child: Text(
                  job.status,
                  style: FixoTypography.labelSm(
                    color: FixoColors.primaryForest,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ar ? job.serviceTitleAr : job.serviceTitleEn,
            style: FixoTypography.labelMd(
              color: palette.deepForest,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: palette.mutedText,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${job.districtLine}, ${job.addressLine}',
                  style: FixoTypography.bodySm(color: palette.mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: palette.mutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.customerName,
                  style: FixoTypography.bodySm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${job.netArtisanEgp} ${ar ? 'ج.م صافي' : 'EGP Net'}',
                style: FixoTypography.labelMd(
                  color: FixoColors.primaryForest,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Action button based on status
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => context.push(
                  AppRoutes.customerChat.replaceFirst(
                    ':orderId',
                    job.bookingId,
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(ar ? 'المحادثة' : 'Chat'),
              ),
              if (job.status == 'CONFIRMED')
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    backgroundColor: FixoColors.primaryForest,
                  ),
                  onPressed: () =>
                      _advanceStatus(job.bookingId, 'PRO_EN_ROUTE', ar),
                  icon: const Icon(Icons.directions_bike_outlined, size: 16),
                  label: Text(ar ? 'التحرك للعميل' : 'Start En Route'),
                ),
              if (job.status == 'PRO_EN_ROUTE')
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    backgroundColor: FixoColors.primaryForest,
                  ),
                  onPressed: () => _advanceStatus(job.bookingId, 'ARRIVED', ar),
                  icon: const Icon(Icons.pin_drop_outlined, size: 16),
                  label: Text(ar ? 'وصلت للموقع' : 'Mark Arrived'),
                ),
              if (job.status == 'ARRIVED')
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    backgroundColor: FixoColors.primaryForest,
                  ),
                  onPressed: () =>
                      _showArrivalPinDialog(context, job.bookingId, ar),
                  icon: const Icon(Icons.pin_outlined, size: 16),
                  label: Text(ar ? 'إدخال كود البدء' : 'Enter Arrival PIN'),
                ),
              if (job.status == 'IN_PROGRESS')
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    backgroundColor: FixoColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      _advanceStatus(job.bookingId, 'COMPLETED', ar),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    ar ? 'إتمام وتحصيل الكاش' : 'Complete & Collect Cash',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
