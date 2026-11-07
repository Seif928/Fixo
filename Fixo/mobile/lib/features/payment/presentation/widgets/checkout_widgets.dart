import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../booking/domain/booking_models.dart';
import 'holographic_receipt_card.dart';

/// Top micro-banner providing cash-on-service order reassurance.
class CheckoutReassuranceBanner extends StatelessWidget {
  const CheckoutReassuranceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FixoSpacing.md,
        vertical: FixoSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: FixoColors.secondary,
                ),
                const SizedBox(width: FixoSpacing.xs),
                Flexible(
                  child: Text(
                    isArabic
                        ? 'تأكيد الدفع نقداً عند التنفيذ'
                        : 'Cash on Service Checkout',
                    style: FixoTypography.labelMd(
                      color: palette.mutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.surfaceHigh,
              borderRadius: BorderRadius.circular(FixoRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: FixoColors.secondaryFixedDim,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isArabic ? 'نقداً' : 'Cash',
                  style: FixoTypography.labelMd(
                    color: palette.deepForest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Order summary card displaying real service title, order code, schedule, and location.
class CheckoutOrderSummaryCard extends StatelessWidget {
  const CheckoutOrderSummaryCard({super.key, required this.booking});

  final BookingDetailModel booking;

  String _formatTimeWindow(String window, bool isArabic) {
    switch (window) {
      case 'MORNING_09_12':
        return isArabic ? 'صباحاً (09:00 - 12:00)' : 'Morning (09:00 - 12:00)';
      case 'AFTERNOON_13_16':
        return isArabic ? 'ظهراً (13:00 - 16:00)' : 'Afternoon (13:00 - 16:00)';
      case 'EVENING_17_20':
        return isArabic ? 'مساءً (17:00 - 20:00)' : 'Evening (17:00 - 20:00)';
      default:
        return window;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;
    final offeringTitle = isArabic
        ? (booking.offering['titleAr'] as String? ??
              booking.offering['titleEn'] as String? ??
              'خدمة منزلية')
        : (booking.offering['titleEn'] as String? ??
              booking.offering['titleAr'] as String? ??
              'Home Service');

    final addressLabel = booking.address['label'] as String? ?? 'Home';
    final districtLine = booking.address['districtLine'] as String? ?? '';
    final addressDisplay = districtLine.isNotEmpty
        ? '$addressLabel, $districtLine'
        : addressLabel;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: FixoSpacing.md,
        vertical: FixoSpacing.xs,
      ),
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(FixoRadius.lg),
        border: Border.all(
          color: palette.subtleBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.surfaceLow,
                  borderRadius: BorderRadius.circular(FixoRadius.md),
                ),
                child: Icon(
                  Icons.handyman_outlined,
                  color: palette.deepForest,
                  size: 28,
                ),
              ),
              const SizedBox(width: FixoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceHigh,
                            borderRadius: BorderRadius.circular(
                              FixoRadius.pill,
                            ),
                          ),
                          child: Text(
                            isArabic ? 'خدمة مجدولة' : 'Scheduled Service',
                            style: FixoTypography.labelMd(
                              color: palette.deepForest,
                            ),
                          ),
                        ),
                        Text(
                          '${booking.pricing.totalEgp} ${booking.pricing.currency}',
                          style: FixoTypography.headlineSm(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offeringTitle,
                      style: FixoTypography.headlineSm(
                        color: palette.inkText,
                      ).copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.tag_rounded,
                          size: 14,
                          color: FixoColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${booking.orderCode}',
                          style: FixoTypography.bodySm(
                            color: palette.mutedText,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: FixoColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${booking.scheduledDate} • ${_formatTimeWindow(booking.timeWindow, isArabic)}',
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: FixoColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            addressDisplay,
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.surfaceLow,
              borderRadius: BorderRadius.circular(FixoRadius.md),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  size: 16,
                  color: FixoColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'تحصيل نقدي بعد اكتمال الخدمة'
                        : 'Cash Collection After Service',
                    style: FixoTypography.labelMd(
                      color: palette.deepForest,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment options section with active Cash on Service and disabled alternative options.
class CheckoutPaymentMethodsSection extends StatelessWidget {
  const CheckoutPaymentMethodsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  isArabic ? 'طريقة الدفع' : 'Payment Method',
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  isArabic ? 'وسائل الدفع المحلية' : 'Egypt Local Rail',
                  style: FixoTypography.labelMd(
                    color: palette.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 1: Cash on Service (Active & Selected)
          Container(
            key: const Key('payment-method-cash-on-service'),
            padding: const EdgeInsets.all(FixoSpacing.md),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(FixoRadius.lg),
              border: Border.all(
                color: isDark ? palette.limeAccent : FixoColors.primaryForest,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: FixoColors.primaryForest.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surfaceHigh,
                        borderRadius: BorderRadius.circular(FixoRadius.md),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        color: palette.deepForest,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: FixoSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                isArabic
                                    ? 'الدفع نقداً للفني'
                                    : 'Cash to Artisan',
                                style: FixoTypography.labelLg(
                                  color: palette.inkText,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: FixoColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    FixoRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'مفعل حالياً' : 'Active in MVP',
                                  style: FixoTypography.labelMd(
                                    color: FixoColors.onSecondaryContainer,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic
                                ? 'ادفع نقداً بالجنيه المصري فقط بعد إتمام الخدمة ومعاينتها'
                                : 'Hand cash in EGP only after job completed & inspected',
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: FixoColors.primaryForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: FixoColors.limeAccent,
                        size: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FixoSpacing.sm),
                // Reassurance notice inside Cash option
                Container(
                  padding: const EdgeInsets.all(FixoSpacing.sm),
                  decoration: BoxDecoration(
                    color: palette.surfaceLow,
                    borderRadius: BorderRadius.circular(FixoRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: FixoColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'يتم تحصيل المبلغ نقداً بواسطة الفني فقط بعد تقديم الخدمة ومعاينتها. لا يوجد أي خصم مسبق.'
                              : 'Cash is collected in person by the technician only after service is performed and inspected. No upfront charge.',
                          style: FixoTypography.bodySm(
                            color: palette.inkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 2: InstaPay (Disabled)
          _buildDisabledPaymentOption(
            palette: palette,
            key: const Key('payment-method-instapay'),
            icon: Icons.bolt_rounded,
            title: isArabic ? 'انستاباي مصر' : 'InstaPay Egypt',
            subtitle: isArabic
                ? 'تحويل بنكي لحظي / محفظة إلكترونية'
                : 'Direct Bank Transfer / Mobile Wallet',
            badge: isArabic ? 'قريباً' : 'Coming Soon',
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 3: Smart Wallets (Disabled)
          _buildDisabledPaymentOption(
            palette: palette,
            key: const Key('payment-method-wallets'),
            icon: Icons.account_balance_wallet_outlined,
            title: isArabic ? 'المحافظ الإلكترونية' : 'Smart Wallets',
            subtitle: isArabic
                ? 'فودافون كاش، أورنج، اتصالات، وي'
                : 'Vodafone Cash, Orange, Etisalat & WE',
            badge: isArabic ? 'قريباً' : 'Coming Soon',
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 4: Cards & Meeza (Disabled)
          _buildDisabledPaymentOption(
            palette: palette,
            key: const Key('payment-method-cards'),
            icon: Icons.credit_card_outlined,
            title: isArabic ? 'البطاقات وكارت ميزة' : 'Cards & Meeza',
            subtitle: isArabic
                ? 'فيزا، ماستركارد، وميزة الوطنية'
                : 'Visa, Mastercard, & National Meeza Card',
            badge: isArabic ? 'قريباً' : 'Coming Soon',
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 5: Fawry Pay (Disabled)
          _buildDisabledPaymentOption(
            palette: palette,
            key: const Key('payment-method-fawry'),
            icon: Icons.storefront_outlined,
            title: isArabic ? 'منافذ فوري' : 'Fawry Pay Kiosk',
            subtitle: isArabic
                ? 'الدفع عبر أكثر من 190,000 منفذ تجزئة'
                : 'Pay in cash at 190,000+ local retail outlets',
            badge: isArabic ? 'قريباً' : 'Coming Soon',
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledPaymentOption({
    required FixoPaletteExtension palette,
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(FixoRadius.lg),
        border: Border.all(
          color: palette.subtleBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.surfaceContainer,
              borderRadius: BorderRadius.circular(FixoRadius.md),
            ),
            child: Icon(icon, color: palette.mutedText, size: 22),
          ),
          const SizedBox(width: FixoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: FixoTypography.labelLg(
                        color: palette.mutedText,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceHigh,
                        borderRadius: BorderRadius.circular(FixoRadius.pill),
                      ),
                      child: Text(
                        badge,
                        style: FixoTypography.labelMd(
                          color: palette.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: FixoTypography.bodySm(color: palette.mutedText),
                ),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: palette.subtleBorder, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Receipt fare breakdown card showing transparent fees in EGP.
class CheckoutReceiptCard extends StatelessWidget {
  const CheckoutReceiptCard({super.key, required this.pricing});

  final BookingPricingModel pricing;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: FixoSpacing.md,
        vertical: FixoSpacing.sm,
      ),
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(FixoRadius.lg),
        border: Border.all(
          color: palette.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تفاصيل الفاتورة' : 'Receipt Breakdown',
            style: FixoTypography.labelLg(
              color: palette.deepForest,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: FixoSpacing.sm),
          _buildRow(
            palette: palette,
            label: isArabic ? 'أجرة الفحص والمعاينة' : 'Base Inspection Fee',
            value: '${pricing.baseInspectionEgp} ${pricing.currency}',
            isBold: false,
          ),
          const SizedBox(height: 6),
          _buildRow(
            palette: palette,
            label: isArabic ? 'أجرة الخدمة والصيانة' : 'Service Fee',
            value: '${pricing.serviceFeeEgp} ${pricing.currency}',
            isBold: false,
          ),
          const SizedBox(height: 6),
          _buildRow(
            palette: palette,
            label: isArabic ? 'رسوم الانتقال والتوصيل' : 'Transport Fee',
            value: pricing.transportFeeEgp == 0
                ? (isArabic ? 'مجاناً' : 'FREE')
                : '${pricing.transportFeeEgp} ${pricing.currency}',
            isSecondary: pricing.transportFeeEgp == 0,
            isBold: pricing.transportFeeEgp > 0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FixoSpacing.sm),
            child: Divider(color: palette.subtleBorder, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الإجمالي المستحق' : 'Total Amount Due',
                      style: FixoTypography.labelLg(
                        color: palette.deepForest,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isArabic
                          ? 'شامل كافة الرسوم المقررة'
                          : 'All stated fees inclusive',
                      style: FixoTypography.bodySm(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FixoSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${pricing.totalEgp} ${pricing.currency}',
                    style: FixoTypography.priceDisplay(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surfaceLow,
              borderRadius: BorderRadius.circular(FixoRadius.sm),
              border: Border.all(
                color: palette.subtleBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: FixoColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'المستحق الآن: 0 ج.م' : 'Due now: 0 EGP',
                        style: FixoTypography.labelMd(
                          color: FixoColors.secondary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: palette.deepForest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'المستحق بعد الخدمة: ${pricing.totalEgp} ج.م'
                            : 'Due after service: ${pricing.totalEgp} EGP',
                        style: FixoTypography.labelMd(
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required FixoPaletteExtension palette,
    required String label,
    required String value,
    bool isBold = false,
    bool isSecondary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: FixoTypography.bodySm(color: palette.mutedText),
          ),
        ),
        Text(
          value,
          style:
              FixoTypography.bodySm(
                color: isSecondary
                    ? FixoColors.secondary
                    : palette.deepForest,
              ).copyWith(
                fontWeight: isBold || isSecondary
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

/// Cash on service policy footnote at the bottom of the checkout flow.
class CheckoutTrustFootnote extends StatelessWidget {
  const CheckoutTrustFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FixoSpacing.lg,
        vertical: FixoSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 15,
                color: FixoColors.secondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isArabic
                      ? 'سياسة الدفع نقداً عند التنفيذ'
                      : 'Cash on Service Policy',
                  style: FixoTypography.labelMd(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'الدفع نقداً يتم بالكامل في يد الفني فقط بعد انتهاء ومعاينة الخدمة.'
                : 'Cash payment is collected entirely in person only after service is completed and inspected.',
            style: FixoTypography.bodySm(color: palette.mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Confirmation View displayed once checkout succeeds (or when reopened).
/// Strictly complies with security & business invariants:
/// 1. Status must be PENDING_DISPATCH with CASH_ON_SERVICE PENDING.
/// 2. Explains clearly that cash is collected in person after service.
/// 3. Never displays arrival PIN, payment settled claims, or technician assigned claims.
class CheckoutConfirmationView extends StatelessWidget {
  const CheckoutConfirmationView({
    super.key,
    required this.booking,
    required this.onReturnHome,
    this.onOpenChat,
  });

  final BookingDetailModel booking;
  final VoidCallback onReturnHome;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;

    return SingleChildScrollView(
      key: const Key('checkout-confirmation-view'),
      padding: const EdgeInsets.all(FixoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: FixoSpacing.lg),

          // Success Checkmark Container
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: FixoColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: FixoColors.primaryForest,
              size: 44,
            ),
          ),
          const SizedBox(height: FixoSpacing.md),

          // Title
          Text(
            isArabic
                ? 'تم تأكيد الحجز — قيد التعيين'
                : 'Booking Confirmed — Pending Dispatch',
            style: FixoTypography.headlineSm(
              color: palette.deepForest,
            ).copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Order Code Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: palette.surfaceLow,
              borderRadius: BorderRadius.circular(FixoRadius.pill),
              border: Border.all(
                color: palette.subtleBorder,
              ),
            ),
            child: Text(
              key: const Key('checkout-order-code-text'),
              isArabic
                  ? 'رقم الطلب: #${booking.orderCode}'
                  : 'Order Code: #${booking.orderCode}',
              style: FixoTypography.labelLg(
                color: palette.deepForest,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: FixoSpacing.md),

          // 3D Holographic Celebratory Booking Receipt Card
          Holographic3DReceiptCard(
            key: const Key('holographic-3d-receipt-card'),
            booking: booking,
            isArabic: isArabic,
          ),
          const SizedBox(height: FixoSpacing.lg),

          // Cash Collection Invariant Explanation Card
          Container(
            padding: const EdgeInsets.all(FixoSpacing.md),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(FixoRadius.lg),
              border: Border.all(
                color: palette.subtleBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surfaceLow,
                        borderRadius: BorderRadius.circular(FixoRadius.md),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        color: palette.deepForest,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: FixoSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'الدفع نقداً بعد التنفيذ'
                                : 'Cash to Artisan',
                            style: FixoTypography.labelLg(
                              color: palette.deepForest,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'سيتم تحصيل المبلغ (${booking.pricing.totalEgp} ج.م) نقداً من قِبل الفني فقط بعد إتمام الخدمة ومعاينتها.'
                                : 'Cash of ${booking.pricing.totalEgp} EGP will be collected in person by the technician only after service is completed and inspected.',
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: FixoSpacing.sm),
                  child: Divider(color: palette.subtleBorder, height: 1),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surfaceLow,
                        borderRadius: BorderRadius.circular(FixoRadius.md),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_outlined,
                        color: FixoColors.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: FixoSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'حالة التعيين' : 'Technician Matching',
                            style: FixoTypography.labelLg(
                              color: palette.deepForest,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'تم إدراج طلبك في قائمة التعيين. سيتم إشعارك فور قبول أحد الفنيين لطلبك.'
                                : 'Your request is in the dispatch queue. You will be notified as soon as a qualified artisan accepts your request.',
                            style: FixoTypography.bodySm(
                              color: palette.mutedText,
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
          const SizedBox(height: FixoSpacing.xl),

          // Return to Home CTA
          if (onOpenChat != null) ...[
            TextButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(isArabic ? 'محادثة الحجز' : 'Booking conversation'),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('checkout-return-home-btn'),
              onPressed: onReturnHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: FixoColors.primaryForest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isArabic ? 'العودة للرئيسية' : 'Return to Home',
                style: FixoTypography.labelLg(
                  color: Colors.white,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
