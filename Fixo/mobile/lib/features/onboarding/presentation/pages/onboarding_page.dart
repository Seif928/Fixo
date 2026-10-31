import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
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
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _activeStepIndex = 0;

  static const List<_OnboardingStepData> _steps = [
    _OnboardingStepData(
      stepTitle: 'Step 1 of 3: Verification Overview',
      durationLabel: '30 sec onboarding',
    ),
    _OnboardingStepData(
      stepTitle: 'Step 2 of 3: Upfront EGP Pricing',
      durationLabel: 'Cash on service ready',
    ),
    _OnboardingStepData(
      stepTitle: 'Step 3 of 3: Fast Cairo & Giza Dispatch',
      durationLabel: 'Ready to book',
    ),
  ];

  void _navigateToPhoneAuth({required String intent}) {
    context.push('${AppRoutes.phoneAuth}?intent=$intent');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final currentStep = _steps[_activeStepIndex];

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
                  // 1. Brand Header & Geographic Coverage
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
                          const FixoBrandMark(
                            subtitle: 'Better Homes. Better Everyday.',
                          ),
                          FixoStatusBadge(
                            label: 'Cairo & Giza Active',
                            showStatusDot: true,
                            backgroundColor: palette.surfaceHigh,
                            foregroundColor: palette.mutedText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: FixoSpacing.sm),

                  // 2. Hero Visual Showcase
                  const CairoInteriorHeroCard(),
                  const SizedBox(height: FixoSpacing.lg),

                  // 3. Editorial Headline & Copy
                  FixoStatusBadge(
                    label: 'The Standard in Home Care',
                    leadingIcon: Icons.shield_outlined,
                    uppercase: true,
                    backgroundColor: palette.surfaceHigh,
                    foregroundColor: palette.deepForest,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your home, in better hands.',
                    style: FixoTypography.headlineLgMobile(
                      color: palette.deepForest,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connect in minutes with identity-reviewed Egyptian technicians, '
                    'plumbers, and home specialists with upfront EGP pricing.',
                    style: FixoTypography.bodyMd(
                      color: palette.mutedText,
                    ).copyWith(height: 1.48),
                  ),
                  const SizedBox(height: 20),

                  // 4. Trust Value Pillars (Neutral MVP-accurate wording per STITCH_AUDIT.md)
                  const Wrap(
                    spacing: FixoSpacing.sm,
                    runSpacing: FixoSpacing.sm,
                    children: [
                      FixoTrustPillarChip(
                        icon: Icons.verified_user_outlined,
                        label: 'Identity-Reviewed Pros',
                      ),
                      FixoTrustPillarChip(
                        icon: Icons.payments_outlined,
                        label: 'Fixed EGP Quotes',
                      ),
                      FixoTrustPillarChip(
                        icon: Icons.near_me_outlined,
                        label: 'Live Arrival Tracking',
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
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              currentStep.durationLabel,
                              style:
                                  FixoTypography.labelMd(
                                    color: palette.mutedText,
                                  ).copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(_steps.length, (index) {
                            final isCompletedOrActive =
                                index <= _activeStepIndex;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  end: index < _steps.length - 1 ? 6.0 : 0.0,
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
                                      duration: const Duration(
                                        milliseconds: 200,
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
                    label: 'Get Started',
                    showCircularLimeBadge: true,
                    onPressed: () => _navigateToPhoneAuth(intent: 'signup'),
                  ),
                  const SizedBox(height: 12),
                  FixoSecondaryButton(
                    key: const Key('btn-sign-in'),
                    label: 'I already have an account',
                    onPressed: () => _navigateToPhoneAuth(intent: 'signin'),
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
                          'Upfront EGP quotes • Cash on service available in Cairo & Giza',
                          textAlign: TextAlign.center,
                          style: FixoTypography.bodySm(
                            color: palette.mutedText,
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
