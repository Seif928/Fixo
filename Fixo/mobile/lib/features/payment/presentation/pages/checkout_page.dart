import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/checkout_widgets.dart';

/// Screen 05: Official Stitch Payment / Checkout Page.
/// Route: `/customer/bookings/:bookingId/checkout`
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutControllerProvider(bookingId));
    final controller = ref.read(checkoutControllerProvider(bookingId).notifier);

    final palette =
        Theme.of(context).extension<FixoPaletteExtension>() ??
            FixoPaletteExtension.light;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: FixoColors.surfaceBotanical,
      appBar: AppBar(
        backgroundColor: FixoColors.surfaceBotanical,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: palette.primaryBrand,
          ),
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
            color: palette.primaryBrand,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: FixoColors.onSurfaceVariant,
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
          child: Container(
            color: FixoColors.surfaceContainer,
            height: 1.0,
          ),
        ),
      ),
      body: _buildBody(context, ref, state, controller, palette, isArabic),
      bottomNavigationBar: state.checkoutSuccess || state.isLoading || state.booking == null
          ? null
          : _buildStickyBottomCTA(context, state, controller, palette, isArabic),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CheckoutState state,
    CheckoutController controller,
    FixoPaletteExtension palette,
    bool isArabic,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(FixoColors.primaryForest),
        ),
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
                  color: FixoColors.onSurfaceVariant,
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
      );
    }

    final booking = state.booking!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.errorMessage != null)
            Container(
              margin: const EdgeInsets.all(FixoSpacing.md),
              padding: const EdgeInsets.all(FixoSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(FixoRadius.md),
                border: Border.all(color: const Color(0xFFBA1A1A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFBA1A1A),
                    size: 20,
                  ),
                  const SizedBox(width: FixoSpacing.xs),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: FixoTypography.bodySm(
                        color: const Color(0xFF410002),
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
          const SizedBox(height: 100), // Spacing for sticky bottom CTA
        ],
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

    return Container(
      padding: EdgeInsets.only(
        left: FixoSpacing.md,
        right: FixoSpacing.md,
        top: FixoSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + FixoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: FixoColors.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: FixoColors.surfaceContainer, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'يستحق بعد التنفيذ' : 'Due Upon Completion',
                  style: FixoTypography.labelMd(
                    color: FixoColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${booking.pricing.totalEgp} ${booking.pricing.currency}',
                  style: FixoTypography.priceDisplay(
                    color: FixoColors.deepestForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: FixoSpacing.sm),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('confirm-checkout-btn'),
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        await controller.submitCheckout();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primaryBrand,
                  disabledBackgroundColor:
                      palette.primaryBrand.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isArabic
                                  ? 'تأكيد الحجز (دفع نقدي لاحقاً)'
                                  : 'Confirm Booking (Pay Cash Later)',
                              style: FixoTypography.labelLg(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
