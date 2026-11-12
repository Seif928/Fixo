import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
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

/// Payment options section with active Cash on Service, Apple Pay, and Visa / Mastercard 3D Flip Card.
class CheckoutPaymentMethodsSection extends StatefulWidget {
  const CheckoutPaymentMethodsSection({
    super.key,
    this.selectedMethod = 'CASH_ON_SERVICE',
    this.onSelectMethod,
    this.onQuickPay,
    this.totalEgp = 400,
  });

  final String selectedMethod;
  final ValueChanged<String>? onSelectMethod;
  final ValueChanged<String>? onQuickPay;
  final int totalEgp;

  @override
  State<CheckoutPaymentMethodsSection> createState() =>
      _CheckoutPaymentMethodsSectionState();
}

class _CheckoutPaymentMethodsSectionState
    extends State<CheckoutPaymentMethodsSection> {
  final TextEditingController _cardNumberCtrl = TextEditingController(
    text: '4532 8891 0421 9048',
  );
  final TextEditingController _cardHolderCtrl = TextEditingController(
    text: 'AHMED AL-MANSOUR',
  );
  final TextEditingController _expiryCtrl = TextEditingController(
    text: '09/29',
  );
  final TextEditingController _cvvCtrl = TextEditingController(text: '792');
  final FocusNode _cvvFocusNode = FocusNode();
  bool _isCardFlipped = false;

  @override
  void initState() {
    super.initState();
    _cvvFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isCardFlipped = _cvvFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardHolderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  void _select(String method) {
    HapticFeedback.selectionClick();
    widget.onSelectMethod?.call(method);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCashSelected = widget.selectedMethod == 'CASH_ON_SERVICE';
    final isApplePaySelected = widget.selectedMethod == 'SMART_WALLET_SANDBOX';
    final isCardSelected = widget.selectedMethod == 'CARD_MEEZA_SANDBOX';

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

          // Option 1: Cash on Service (Active & Default Selected)
          GestureDetector(
            onTap: () => _select('CASH_ON_SERVICE'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              key: const Key('payment-method-cash-on-service'),
              padding: const EdgeInsets.all(FixoSpacing.md),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                borderRadius: BorderRadius.circular(FixoRadius.lg),
                border: Border.all(
                  color: isCashSelected
                      ? (isDark ? palette.limeAccent : FixoColors.primaryForest)
                      : palette.subtleBorder,
                  width: isCashSelected ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: FixoColors.primaryForest.withValues(
                      alpha: isCashSelected ? 0.06 : 0.02,
                    ),
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
                      _buildSelectionRadio(isSelected: isCashSelected, palette: palette),
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
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 2: Apple Pay (Active & Interactive)
          GestureDetector(
            key: const Key('payment-method-apple-pay'),
            onTap: () => _select('SMART_WALLET_SANDBOX'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(FixoSpacing.md),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                borderRadius: BorderRadius.circular(FixoRadius.lg),
                border: Border.all(
                  color: isApplePaySelected
                      ? (isDark ? palette.limeAccent : FixoColors.primaryForest)
                      : palette.subtleBorder,
                  width: isApplePaySelected ? 1.6 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(FixoRadius.md),
                        ),
                        child: Icon(
                          Icons.apple_rounded,
                          color: isDark ? Colors.black : Colors.white,
                          size: 24,
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
                                  isArabic ? 'الدفع عبر Apple Pay' : 'Apple Pay',
                                  style: FixoTypography.labelLg(
                                    color: palette.inkText,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.14)
                                        : Colors.black.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(
                                      FixoRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    isArabic ? 'فوري • Face ID' : 'Instant • Face ID',
                                    style: FixoTypography.labelMd(
                                      color: palette.inkText,
                                    ).copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isArabic
                                  ? 'دفع فوري مشفّر بلمسة واحدة عبر محفظة Apple'
                                  : 'One-touch encrypted biometric checkout via Apple Wallet',
                              style: FixoTypography.bodySm(
                                color: palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSelectionRadio(
                        isSelected: isApplePaySelected,
                        palette: palette,
                      ),
                    ],
                  ),
                  if (isApplePaySelected) ...[
                    const SizedBox(height: 12),
                    Container(
                      key: const Key('apple-pay-vault-panel'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF101513)
                            : palette.surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: palette.limeAccent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 28,
                            color: palette.deepForest,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'جاهز للمصادقة عبر Face ID / Touch ID بمبلغ ${widget.totalEgp} ج.م بدون أي رسوم إضافية.'
                                  : 'Ready for Face ID / Touch ID authorization of ${widget.totalEgp} EGP with 0% extra fee.',
                              style: FixoTypography.bodySm(
                                color: palette.inkText,
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
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 3: Visa / Mastercard Credit Card with Interactive 3D Flip Card
          GestureDetector(
            key: const Key('payment-method-credit-card'),
            onTap: () => _select('CARD_MEEZA_SANDBOX'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(FixoSpacing.md),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                borderRadius: BorderRadius.circular(FixoRadius.lg),
                border: Border.all(
                  color: isCardSelected
                      ? (isDark ? palette.limeAccent : FixoColors.primaryForest)
                      : palette.subtleBorder,
                  width: isCardSelected ? 1.6 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF173F35), Color(0xFF0A1D18)],
                          ),
                          borderRadius: BorderRadius.circular(FixoRadius.md),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFFD7F078),
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
                                      ? 'بطاقة فيزا / ماستركارد الائتمانية'
                                      : 'Visa & Mastercard Credit Card',
                                  style: FixoTypography.labelLg(
                                    color: palette.inkText,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FixoColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      FixoRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    isArabic ? '3D Secure • متاح' : '3D Secure • Active',
                                    style: FixoTypography.labelMd(
                                      color: FixoColors.onSecondaryContainer,
                                    ).copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isArabic
                                  ? 'بطاقات الائتمان والخصم المباشر (Visa • Mastercard • Meeza)'
                                  : 'Credit & Debit Cards with 3D Interactive Vault',
                              style: FixoTypography.bodySm(
                                color: palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSelectionRadio(
                        isSelected: isCardSelected,
                        palette: palette,
                      ),
                    ],
                  ),
                  if (isCardSelected) ...[
                    const SizedBox(height: 14),
                    Interactive3DCreditCard(
                      cardNumber: _cardNumberCtrl.text,
                      cardHolder: _cardHolderCtrl.text,
                      expiryDate: _expiryCtrl.text,
                      cvvCode: _cvvCtrl.text,
                      isFlipped: _isCardFlipped,
                      isArabic: isArabic,
                      onFlipToggle: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isCardFlipped = !_isCardFlipped);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('credit-card-number-input'),
                      controller: _cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: isArabic ? 'رقم البطاقة (16 رقم)' : 'Card Number',
                        prefixIcon: Icon(
                          Icons.credit_card_rounded,
                          color: palette.mutedText,
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('credit-card-holder-input'),
                      controller: _cardHolderCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: isArabic ? 'اسم حامل البطاقة' : 'Cardholder Name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: palette.mutedText,
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('credit-card-expiry-input'),
                            controller: _expiryCtrl,
                            textDirection: TextDirection.ltr,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: isArabic ? 'تاريخ الانتهاء' : 'Expiry (MM/YY)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            key: const Key('credit-card-cvv-input'),
                            controller: _cvvCtrl,
                            focusNode: _cvvFocusNode,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            maxLength: 4,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              counterText: '',
                              labelText: isArabic ? 'رمز الأمان CVV' : 'CVV Security',
                              isDense: true,
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
          const SizedBox(height: FixoSpacing.sm),

          // Option 4: InstaPay (Local Rail Preview)
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

          // Option 5: Smart Wallets (Tapping activates Apple Pay / Smart Wallet)
          GestureDetector(
            onTap: () => _select('SMART_WALLET_SANDBOX'),
            child: _buildDisabledPaymentOption(
              palette: palette,
              key: const Key('payment-method-wallets'),
              icon: Icons.account_balance_wallet_outlined,
              title: isArabic ? 'المحافظ الإلكترونية' : 'Smart Wallets',
              subtitle: isArabic
                  ? 'فودافون كاش، أورنج، اتصالات، وي'
                  : 'Vodafone Cash, Orange, Etisalat & WE',
              badge: isArabic ? 'قريباً' : 'Coming Soon',
            ),
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 6: Cards & Meeza (Tapping activates 3D Credit Card)
          GestureDetector(
            onTap: () => _select('CARD_MEEZA_SANDBOX'),
            child: _buildDisabledPaymentOption(
              palette: palette,
              key: const Key('payment-method-cards'),
              icon: Icons.credit_card_outlined,
              title: isArabic ? 'البطاقات وكارت ميزة' : 'Cards & Meeza',
              subtitle: isArabic
                  ? 'فيزا، ماستركارد، وميزة الوطنية'
                  : 'Visa, Mastercard, & National Meeza Card',
              badge: isArabic ? 'قريباً' : 'Coming Soon',
            ),
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Option 7: Fawry Pay
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

  Widget _buildSelectionRadio({
    required bool isSelected,
    required FixoPaletteExtension palette,
  }) {
    if (isSelected) {
      return Container(
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
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: palette.subtleBorder, width: 1.5),
        shape: BoxShape.circle,
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

/// Interactive 3D Flip Credit Card widget that rotates 180 degrees in 3D space
/// when tapped or when the CVV input is focused.
class Interactive3DCreditCard extends StatelessWidget {
  const Interactive3DCreditCard({
    super.key,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvvCode,
    required this.isFlipped,
    required this.isArabic,
    required this.onFlipToggle,
  });

  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvvCode;
  final bool isFlipped;
  final bool isArabic;
  final VoidCallback onFlipToggle;

  String get _brandLabel {
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.startsWith('5')) return 'MASTERCARD';
    if (clean.startsWith('5078')) return 'MEEZA';
    return 'VISA PLATINUM';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('interactive-3d-credit-card'),
      onTap: onFlipToggle,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isFlipped ? math.pi : 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, angle, _) {
          final showingBack = angle > (math.pi / 2);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: Container(
              height: 184,
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A211B),
                    Color(0xFF173F35),
                    Color(0xFF050807),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFC9A96E).withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: showingBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildBackSide(),
                    )
                  : _buildFrontSide(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Metallic Gold EMV Chip
                Container(
                  width: 38,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE5C88F), Color(0xFFB38E4C)],
                    ),
                  ),
                  child: const Icon(
                    Icons.memory_rounded,
                    size: 18,
                    color: Color(0xFF2B200B),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.wifi_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
              ],
            ),
            Text(
              _brandLabel,
              style: const TextStyle(
                color: Color(0xFFD7F078),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Text(
          cardNumber.trim().isEmpty ? '4532 •••• •••• 9048' : cardNumber,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'حامل البطاقة' : 'CARDHOLDER',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9.5,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    cardHolder.trim().isEmpty ? 'FIXO VIP MEMBER' : cardHolder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isArabic ? 'الانتهاء' : 'EXPIRES',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9.5,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  expiryDate.trim().isEmpty ? '09/29' : expiryDate,
                  style: const TextStyle(
                    color: Color(0xFFD7F078),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FIXO 3D SECURE VAULT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD7F078),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'CVV ${cvvCode.trim().isEmpty ? "792" : cvvCode}',
                style: const TextStyle(
                  color: Color(0xFF0A211B),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        Text(
          isArabic
              ? 'اضغط على البطاقة لقلبها للوجه الأمامي • تشفير بنكي 256-bit'
              : 'Tap card to flip back • 256-bit CBE Tokenized Security',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10.5,
          ),
        ),
      ],
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
          // Track Order 3D CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('checkout-track-order-3d-btn'),
              onPressed: () => context.push(
                AppRoutes.orderTracking.replaceFirst(
                  ':orderId',
                  Uri.encodeComponent(booking.id),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: FixoColors.primaryForest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.view_in_ar_rounded,
                size: 20,
                color: FixoColors.limeAccent,
              ),
              label: Text(
                isArabic ? 'تتبع الفني والطلب 3D' : 'Live 3D Order Tracking',
                style: FixoTypography.labelLg(
                  color: Colors.white,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Return to Home CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              key: const Key('checkout-return-home-btn'),
              onPressed: onReturnHome,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.deepForest,
                side: BorderSide(color: palette.subtleBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isArabic ? 'العودة للرئيسية' : 'Return to Home',
                style: FixoTypography.labelLg(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
