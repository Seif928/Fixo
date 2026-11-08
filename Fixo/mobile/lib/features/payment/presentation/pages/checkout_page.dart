import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_liquid_glass_layer.dart';
import '../../../../core/widgets/fixo_skeleton.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/checkout_widgets.dart';

/// Screen 05: Official Stitch Payment / Checkout Page.
/// Route: `/customer/bookings/:bookingId/checkout`
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutControllerProvider(bookingId));
    final controller = ref.read(checkoutControllerProvider(bookingId).notifier);

    final palette = context.fixoPalette;
    final colorScheme = Theme.of(context).colorScheme;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        backgroundColor: palette.canvasBackground,
        surfaceTintColor: Colors.transparent,
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
        title: Text(
          isArabic ? 'الدفع' : 'Payment',
          style: FixoTypography.headlineSm(
            color: palette.deepForest,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: palette.mutedText,
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic
                        ? 'الدعم الفني متاح للمساعدة طوال أيام الأسبوع.'
                        : 'Customer support is available to assist you 7 days a week.',
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(end: FixoSpacing.md),
            child: FixoBrandMark(iconBoxSize: 28, showSubtitle: false),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: palette.subtleBorder, height: 1.0),
        ),
      ),
      body: _buildBody(
        context,
        ref,
        state,
        controller,
        palette,
        colorScheme,
        isArabic,
      ),
      bottomNavigationBar:
          state.checkoutSuccess || state.isLoading || state.booking == null
          ? null
          : _buildStickyBottomCTA(
              context,
              state,
              controller,
              palette,
              isArabic,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CheckoutState state,
    CheckoutController controller,
    FixoPaletteExtension palette,
    ColorScheme colorScheme,
    bool isArabic,
  ) {
    if (state.isLoading) {
      return const FixoListSkeleton(
        itemCount: 3,
        showHeaderBanner: true,
      );
    }

    if (state.booking == null && state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(FixoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: FixoColors.coral,
              ),
              const SizedBox(height: FixoSpacing.sm),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: FixoTypography.bodyMd(
                  color: palette.mutedText,
                ),
              ),
              const SizedBox(height: FixoSpacing.md),
              ElevatedButton.icon(
                onPressed: () => controller.loadBooking(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primaryBrand,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.checkoutSuccess && state.booking != null) {
      return CheckoutConfirmationView(
        booking: state.booking!,
        onReturnHome: () => context.go(AppRoutes.customerHome),
        onOpenChat: () =>
            context.push('/customer/orders/${state.booking!.id}/chat'),
      );
    }

    final booking = state.booking!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(FixoSpacing.md),
                  padding: const EdgeInsets.all(FixoSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(FixoRadius.md),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
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
              const CheckoutReassuranceBanner(),
              CheckoutOrderSummaryCard(booking: booking),
              const SizedBox(height: FixoSpacing.sm),
              const CheckoutPaymentMethodsSection(),
              CheckoutReceiptCard(pricing: booking.pricing),
              const CheckoutTrustFootnote(),
              const SizedBox(height: 120), // Spacing for sticky bottom CTA
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyBottomCTA(
    BuildContext context,
    CheckoutState state,
    CheckoutController controller,
    FixoPaletteExtension palette,
    bool isArabic,
  ) {
    final booking = state.booking!;

    return LiquidGlassLayer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      blurSigma: 28.0,
      specularIntensity: 0.65,
      borderWidth: 1.4,
      padding: EdgeInsets.only(
        left: FixoSpacing.md,
        right: FixoSpacing.md,
        top: FixoSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + FixoSpacing.sm,
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      isArabic ? 'يستحق بعد التنفيذ' : 'Due Upon Completion',
                      style: FixoTypography.labelMd(
                        color: palette.mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: FixoSpacing.sm),
                  Text(
                    '${booking.pricing.totalEgp} ${booking.pricing.currency}',
                    style: FixoTypography.priceDisplay(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: FixoSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: ElevatedButton(
                  key: const Key('confirm-checkout-btn'),
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          await controller.submitCheckout();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primaryBrand,
                    disabledBackgroundColor: palette.primaryBrand.withValues(
                      alpha: 0.4,
                    ),
                    side: Theme.of(context).brightness == Brightness.dark
                        ? BorderSide(
                            color: palette.limeAccent.withValues(alpha: 0.4),
                          )
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isArabic
                                    ? 'تأكيد الحجز (دفع نقدي لاحقاً)'
                                    : 'Confirm Booking (Pay Cash Later)',
                                textAlign: TextAlign.center,
                                style: FixoTypography.labelLg(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
