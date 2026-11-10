import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/controllers/account_entry_controller.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/motion/fixo_motion.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_buttons.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../widgets/cairo_interior_hero_card.dart';

/// Screen 01: `OnboardingPage` (`01_onboarding`).
///
/// Faithfully implements the Stitch `01_onboarding` design using native Flutter
/// widgets and central `FixoTheme` tokens while resolving the `docs/STITCH_AUDIT.md`
/// P0 findings:
/// - Replaces hotlinked Google images with local vector/canvas graphics.
/// - Replaces unsupported regulatory, background-check, and 25,000 EGP insurance
///   claims with accurate MVP language.
/// - Adapts cleanly across 360dp, 390dp, and 412dp widths and scaled text.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _activeStepIndex = 0;

  void _showBookingInfo({required bool pricing, required bool isArabic}) {
    final title = pricing
        ? (isArabic ? 'تفاصيل سعر الحجز' : 'How booking pricing works')
        : (isArabic ? 'الدفع نقداً بعد الخدمة' : 'Cash on service');
    final message = pricing
        ? (isArabic
              ? 'تظهر رسوم المعاينة والخدمة والانتقال والإجمالي بالجنيه المصري للخدمة المختارة قبل تأكيد الحجز. رسوم الانتقال تكون مجانية فقط عندما تكون قيمتها صفراً. اختار الخدمة والعنوان والموعد لعرض السعر الفعلي؛ هذه الشاشة لا تعرض عرض سعر.'
              : 'Inspection, service and transport fees and the total are shown in EGP for your selected service before you confirm the booking. Transport is free only when its fee is zero. Choose your service, address and time to see actual pricing; this screen is not a quote.')
        : (isArabic
              ? 'لا يتم تحصيل أي مبلغ الآن عند اختيار الدفع النقدي. راجع إجمالي حجزك قبل التأكيد وادفع نقداً بعد إتمام الخدمة. إنشاء الحجز لا يعني أنه تم الدفع.'
              : 'No payment is collected now when you choose cash on service. Review your booking total before confirming and pay cash after the service is completed. Creating a booking does not mark it as paid.');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  static const List<_OnboardingStepData> _stepsEn = [
    _OnboardingStepData(
      stepTitle: 'Step 1 of 3: Connect Your Account',
      durationLabel: 'Google first sign-in',
    ),
    _OnboardingStepData(
      stepTitle: 'Step 2 of 3: Upfront EGP Pricing',
      durationLabel: 'Cash on service ready',
    ),
    _OnboardingStepData(
      stepTitle: 'Step 3 of 3: Choose Your Service Time',
      durationLabel: 'Ready to book',
    ),
  ];

  static const List<_OnboardingStepData> _stepsAr = [
    _OnboardingStepData(
      stepTitle: 'الخطوة ١ من ٣: ربط حسابك',
      durationLabel: 'جوجل لأول تسجيل',
    ),
    _OnboardingStepData(
      stepTitle: 'الخطوة ٢ من ٣: تسعير مسبق بالجنيه',
      durationLabel: 'دفع نقدي عند الخدمة',
    ),
    _OnboardingStepData(
      stepTitle: 'الخطوة ٣ من ٣: اختيار موعد الخدمة',
      durationLabel: 'جاهز للحجز',
    ),
  ];

  Future<void> _navigateToPhoneAuth({
    required String intent,
    bool professional = false,
  }) async {
    await ref
        .read(professionalEntryProvider.notifier)
        .selectProfessional(professional);
    if (mounted) {
      context.push(
        '${AppRoutes.phoneAuth}?intent=$intent&account=${professional ? 'pro' : 'customer'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final locale = ref.watch(appLocaleProvider);
    final isArabic = locale.languageCode == 'ar';
    final steps = isArabic ? _stepsAr : _stepsEn;
    final currentStep = steps[_activeStepIndex];

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                FixoSpacing.md,
                FixoSpacing.sm,
                FixoSpacing.md,
                FixoSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Brand Header, Geographic Coverage & Language Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: FixoSpacing.sm,
                        runSpacing: FixoSpacing.xs,
                        children: [
                          FixoBrandMark(
                            subtitle: isArabic
                                ? 'منازل أفضل. حياة يومية أفضل.'
                                : 'Better Homes. Better Everyday.',
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: FixoStatusBadge(
                                  label: isArabic
                                      ? 'القاهرة والجيزة نشط'
                                      : 'Cairo & Giza Active',
                                  showStatusDot: true,
                                  backgroundColor: palette.surfaceHigh,
                                  foregroundColor: palette.mutedText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                key: const Key('btn-onboarding-toggle-locale'),
                                onTap: () => ref
                                    .read(appLocaleProvider.notifier)
                                    .toggleLocale(),
                                borderRadius: FixoRadius.borderRadiusPill,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceContainer,
                                    borderRadius: FixoRadius.borderRadiusPill,
                                    border: Border.all(
                                      color: palette.subtleBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isArabic ? 'EN' : 'ع',
                                    style: FixoTypography.labelMd(
                                      color: palette.deepForest,
                                      locale: locale,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: FixoSpacing.sm),

                  // 2. Hero Visual Showcase
                  FixoEntrance(
                    child: CairoInteriorHeroCard(isArabic: isArabic),
                  ),
                  const SizedBox(height: FixoSpacing.lg),

                  // 3. Editorial Headline & Copy
                  FixoStatusBadge(
                    label: isArabic
                        ? 'المعيار الجديد لخدمات المنزل'
                        : 'The Standard in Home Care',
                    leadingIcon: Icons.shield_outlined,
                    uppercase: !isArabic,
                    backgroundColor: palette.surfaceHigh,
                    foregroundColor: palette.deepForest,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isArabic
                        ? 'منزلك، في أيدٍ أمينة.'
                        : 'Your home, in better hands.',
                    style: FixoTypography.headlineLgMobile(
                      color: palette.deepForest,
                      locale: locale,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isArabic
                        ? 'تصفح خدمات المنزل، واختار عنوانك وميعادك، وراجع تفاصيل السعر بالجنيه المصري قبل تأكيد الحجز.'
                        : 'Explore home services, choose your address and time, '
                              'and review EGP pricing before confirming your booking.',
                    style: FixoTypography.bodyMd(
                      color: palette.mutedText,
                      locale: locale,
                    ).copyWith(height: 1.48),
                  ),
                  const SizedBox(height: 20),

                  // 4. Trust Value Pillars (Neutral MVP-accurate wording per STITCH_AUDIT.md)
                  Wrap(
                    spacing: FixoSpacing.sm,
                    runSpacing: FixoSpacing.sm,
                    children: [
                      FixoTrustPillarChip(
                        icon: Icons.home_repair_service_outlined,
                        label: isArabic ? 'خدمات المنزل' : 'Home Services',
                      ),
                      FixoTrustPillarChip(
                        icon: Icons.payments_outlined,
                        onTap: () =>
                            _showBookingInfo(pricing: true, isArabic: isArabic),
                        label: isArabic
                            ? 'تفاصيل السعر بالجنيه'
                            : 'EGP Price Breakdown',
                      ),
                      FixoTrustPillarChip(
                        icon: Icons.near_me_outlined,
                        onTap: () => _showBookingInfo(
                          pricing: false,
                          isArabic: isArabic,
                        ),
                        label: isArabic
                            ? 'الدفع بعد الخدمة'
                            : 'Cash After Service',
                      ),
                    ],
                  ),
                  const SizedBox(height: FixoSpacing.lg),

                  // 5. Visual Step Milestone Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.surfaceContainer,
                      borderRadius: FixoRadius.borderRadiusMd,
                      boxShadow: FixoShadows.level1CardResting,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: FixoSpacing.sm,
                          runSpacing: 4,
                          children: [
                            Text(
                              currentStep.stepTitle,
                              style: FixoTypography.labelMd(
                                color: palette.deepForest,
                                locale: locale,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              currentStep.durationLabel,
                              style:
                                  FixoTypography.labelMd(
                                    color: palette.mutedText,
                                    locale: locale,
                                  ).copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(steps.length, (index) {
                            final isCompletedOrActive =
                                index <= _activeStepIndex;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  end: index < steps.length - 1 ? 6.0 : 0.0,
                                ),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      _activeStepIndex = index;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: AnimatedContainer(
                                      duration: Duration(
                                        milliseconds:
                                            FixoMotion.reduced(context)
                                            ? 0
                                            : 180,
                                      ),
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isCompletedOrActive
                                            ? palette.limeAccent
                                            : palette.surfaceHighest,
                                        borderRadius:
                                            FixoRadius.borderRadiusPill,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FixoSpacing.lg),

                  // 6. Interactive Action CTAs
                  FixoPrimaryButton(
                    key: const Key('btn-get-started'),
                    label: isArabic ? 'ابدأ الآن' : 'Get Started',
                    showCircularLimeBadge: true,
                    onPressed: () => _navigateToPhoneAuth(intent: 'signup'),
                  ),
                  const SizedBox(height: 12),
                  FixoSecondaryButton(
                    key: const Key('btn-sign-in'),
                    label: isArabic
                        ? 'لدي حساب بالفعل'
                        : 'I already have an account',
                    onPressed: () => _navigateToPhoneAuth(intent: 'signin'),
                  ),
                  const SizedBox(height: 20),

                  FixoSecondaryButton(
                    key: const Key('btn-professional-entry'),
                    label: isArabic
                        ? 'فني؟ سجل أو ادخل لحساب الشغل'
                        : 'Technician? Join or sign in to FIXO Pro',
                    leadingIcon: Icons.handyman_outlined,
                    onPressed: () => _navigateToPhoneAuth(
                      intent: 'signup',
                      professional: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7. Honest MVP Footer Note (replaces unsupported 25,000 EGP insurance claim)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: FixoColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isArabic
                              ? 'تسعير مسبق بالجنيه • الدفع نقداً عند الخدمة متاح في القاهرة والجيزة'
                              : 'Upfront EGP quotes • Cash on service available in Cairo & Giza',
                          textAlign: TextAlign.center,
                          style: FixoTypography.bodySm(
                            color: palette.mutedText,
                            locale: locale,
                          ).copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.stepTitle,
    required this.durationLabel,
  });

  final String stepTitle;
  final String durationLabel;
}
