import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/fixo_colors.dart';
import '../../core/theme/fixo_spacing.dart';
import '../../core/theme/fixo_typography.dart';
import '../../core/widgets/fixo_brand_mark.dart';
import '../../core/widgets/fixo_buttons.dart';
import '../../core/widgets/fixo_cards.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import 'app_routes.dart';

/// Provides the central `GoRouter` instance for the FIXO mobile app.
///
/// In Phase 1, Screen 01 (`OnboardingPage`) is fully implemented, and the
/// initial flow routes to `/auth/phone` as a clearly labeled demo route target
/// ready for Phase 2 implementation.
final appRouterProvider = Provider<GoRouter>((ref) {
  return createAppRouter();
});

GoRouter createAppRouter({String initialLocation = AppRoutes.onboarding}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        name: 'phoneAuth',
        builder: (context, state) {
          final entryIntent = state.uri.queryParameters['intent'] ?? 'signup';
          return PhaseTwoRoutePlaceholderPage(entryIntent: entryIntent);
        },
      ),
    ],
  );
}

/// Explicit demo-only destination for `/auth/phone` in Phase 1.
///
/// Will be replaced in Phase 2 by the full `PhoneAuthPage` (`02_phone_auth_otp`).
class PhaseTwoRoutePlaceholderPage extends StatelessWidget {
  const PhaseTwoRoutePlaceholderPage({super.key, required this.entryIntent});

  final String entryIntent;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isSignIn = entryIntent == 'signin';

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        title: const Text('Welcome to FIXO'),
        leading: IconButton(
          key: const Key('btn-back-to-onboarding'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Onboarding',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.onboarding);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FixoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FixoBrandMark(),
              const SizedBox(height: FixoSpacing.lg),
              FixoSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FixoStatusBadge(
                      label: isSignIn
                          ? 'Demo Navigation: Sign In Flow'
                          : 'Demo Navigation: Get Started Flow',
                      leadingIcon: Icons.smartphone_rounded,
                    ),
                    const SizedBox(height: FixoSpacing.md),
                    Text(
                      'Screen 02: Phone Auth & OTP',
                      style: FixoTypography.headlineMd(
                        color: palette.deepForest,
                      ),
                    ),
                    const SizedBox(height: FixoSpacing.sm),
                    Text(
                      'Route `${AppRoutes.phoneAuth}` reached from Screen 01 Onboarding '
                      '(${isSignIn ? "I already have an account" : "Get Started"}). '
                      'Full Screen 02 implementation is scheduled for Phase 2.',
                      style: FixoTypography.bodyMd(color: palette.mutedText),
                    ),
                    const SizedBox(height: FixoSpacing.md),
                    FixoSecondaryButton(
                      label: 'Back to Screen 01 (Onboarding)',
                      leadingIcon: Icons.arrow_back_rounded,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.onboarding);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
