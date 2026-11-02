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

/// Screen 14: Verification Status (`14 — Verification Status`)
class ProVerificationStatusPage extends ConsumerStatefulWidget {
  const ProVerificationStatusPage({super.key});

  @override
  ConsumerState<ProVerificationStatusPage> createState() =>
      _ProVerificationStatusPageState();
}

class _ProVerificationStatusPageState
    extends ConsumerState<ProVerificationStatusPage> {
  bool _loading = true;
  String? _errorMessage;
  ProVerificationStatusModel? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      final status = await repo.getVerificationStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
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

  String _statusLabel(String status, bool ar) => switch (status) {
        'APPROVED' => ar ? 'معتمد ومفعل' : 'Approved & Activated',
        'PENDING_REVIEW' => ar ? 'قيد المراجعة والتدقيق' : 'Under Review',
        'ACTION_REQUIRED' => ar ? 'مطلوب استكمال مستندات' : 'Action Required',
        'SUSPENDED' => ar ? 'حساب موقوف مؤقتاً' : 'Suspended',
        _ => ar ? 'مسودة ملف' : 'Draft Dossier',
      };

  Color _statusColor(String status) => switch (status) {
        'APPROVED' => FixoColors.primaryForest,
        'PENDING_REVIEW' => const Color(0xFFC05621), // Warm Amber
        'ACTION_REQUIRED' => FixoColors.error,
        'SUSPENDED' => FixoColors.error,
        _ => FixoColors.onSurfaceVariant,
      };

  Color _statusBgColor(String status) => switch (status) {
        'APPROVED' => FixoColors.secondaryContainer,
        'PENDING_REVIEW' => const Color(0xFFFEEBC8),
        'ACTION_REQUIRED' => FixoColors.errorContainer,
        'SUSPENDED' => FixoColors.errorContainer,
        _ => const Color(0xFFE2E8F0),
      };

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;
    final status = _status;

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
                  ar ? 'حالة اعتماد الفني' : 'Pro Verification Status',
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: palette.deepForest),
              onPressed: _loadStatus,
            ),
          ],
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

                        if (status != null) ...[
                          // Main Status Card
                          FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.lg),
                            borderRadius: FixoRadius.borderRadiusLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(status.status),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    status.isApproved
                                        ? Icons.verified_rounded
                                        : status.isPendingReview
                                            ? Icons.hourglass_top_rounded
                                            : Icons.info_outline_rounded,
                                    color: _statusColor(status.status),
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: FixoSpacing.sm),
                                Text(
                                  _statusLabel(status.status, ar),
                                  style: FixoTypography.headlineLgMobile(
                                    color: _statusColor(status.status),
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceLow,
                                    borderRadius: FixoRadius.borderRadiusPill,
                                    border: Border.all(color: palette.subtleBorder),
                                  ),
                                  child: Text(
                                    '${ar ? 'رقم ملف الاعتماد:' : 'Dossier Code:'} #${status.dossierCode}',
                                    style: FixoTypography.labelMd(
                                      color: palette.deepForest,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (status.reviewerNote != null &&
                                    status.reviewerNote!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: palette.surfaceLow,
                                      borderRadius: FixoRadius.borderRadiusMd,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 18,
                                          color: palette.mutedText,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            status.reviewerNote!,
                                            style: FixoTypography.bodySm(
                                              color: palette.deepForest,
                                            ).copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.md),

                          // 4-step Vetting Milestones
                          FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            borderRadius: FixoRadius.borderRadiusLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ar ? 'مراحل التحقق والاعتماد' : 'Vetting & Verification Milestones',
                                  style: FixoTypography.headlineSm(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ...status.milestones.map((milestone) {
                                  final isDone = milestone.status == 'DONE';
                                  final isCurrent = milestone.status == 'CURRENT';
                                  final isRejected = milestone.status == 'REJECTED';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? FixoColors.primaryForest
                                                : isCurrent
                                                    ? FixoColors.secondaryContainer
                                                    : isRejected
                                                        ? FixoColors.errorContainer
                                                        : palette.surfaceLow,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDone
                                                  ? FixoColors.primaryForest
                                                  : isCurrent
                                                      ? FixoColors.secondary
                                                      : palette.subtleBorder,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: isDone
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  '${milestone.stepNumber}',
                                                  style: FixoTypography.labelSm(
                                                    color: isCurrent
                                                        ? FixoColors.primaryForest
                                                        : palette.mutedText,
                                                  ).copyWith(fontWeight: FontWeight.bold),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ar ? milestone.titleAr : milestone.titleEn,
                                                style: FixoTypography.labelMd(
                                                  color: palette.deepForest,
                                                ).copyWith(fontWeight: FontWeight.w700),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                ar ? milestone.descAr : milestone.descEn,
                                                style: FixoTypography.bodySm(
                                                  color: palette.mutedText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.lg),

                          // Action Buttons
                          if (status.isApproved)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: FixoColors.primaryForest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: FixoRadius.borderRadiusMd,
                                ),
                              ),
                              onPressed: () => context.go(AppRoutes.proDashboard),
                              icon: const Icon(Icons.dashboard_rounded),
                              label: Text(
                                ar ? 'الانتقال إلى لوحة الفني' : 'Go to Pro Dashboard',
                                style: FixoTypography.labelLg(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (status.isActionRequired)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: FixoColors.error,
                                shape: RoundedRectangleBorder(
                                  borderRadius: FixoRadius.borderRadiusMd,
                                ),
                              ),
                              onPressed: () =>
                                  context.push(AppRoutes.proVerificationDocs),
                              icon: const Icon(Icons.edit_document),
                              label: Text(
                                ar ? 'تعديل واستكمال المستندات' : 'Update Verification Documents',
                                style: FixoTypography.labelLg(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: FixoRadius.borderRadiusMd,
                                ),
                              ),
                              onPressed: () => context.go(AppRoutes.customerHome),
                              icon: const Icon(Icons.home_outlined),
                              label: Text(
                                ar ? 'العودة للرئيسية أثناء المراجعة' : 'Return to Home during review',
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
}
