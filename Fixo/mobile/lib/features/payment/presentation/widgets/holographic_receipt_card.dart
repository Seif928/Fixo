import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/motion/fixo_visibility_throttler.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_tilt_3d.dart';
import '../../../booking/domain/booking_models.dart';

/// 3D Holographic Celebratory Booking Receipt Card for Screen 05 Success.
///
/// Features:
/// - Floating 3D perspective tilt with specular highlight.
/// - Holographic foil header reflecting ambient light.
/// - Perforated ticket receipt geometry with security barcode.
/// - Micro-celebratory sparkles.
class Holographic3DReceiptCard extends StatefulWidget {
  const Holographic3DReceiptCard({
    super.key,
    required this.booking,
    required this.isArabic,
  });

  final BookingDetailModel booking;
  final bool isArabic;

  @override
  State<Holographic3DReceiptCard> createState() =>
      _Holographic3DReceiptCardState();
}

class _Holographic3DReceiptCardState extends State<Holographic3DReceiptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _foilController;

  @override
  void initState() {
    super.initState();
    _foilController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _foilController.repeat();
    } else {
      _foilController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _foilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booking = widget.booking;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: FixoTilt3D(
          maxTilt: 0.08,
          glareOpacity: 0.25,
          borderRadius: BorderRadius.circular(20),
          child: FixoVisibilityThrottler(
            controller: _foilController,
            child: AnimatedBuilder(
              animation: _foilController,
              builder: (context, _) {
              final shimmer = _foilController.value;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14241F) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : palette.subtleBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.deepForest.withValues(
                        alpha: isDark ? 0.45 : 0.12,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Holographic Header Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + shimmer * 2.0, -0.6),
                          end: Alignment(1.0 + shimmer * 2.0, 0.6),
                          colors: const [
                            Color(0xFF173F35),
                            Color(0xFF225C4D),
                            Color(0xFF2DD4BF),
                            Color(0xFFD7F078),
                            Color(0xFF173F35),
                          ],
                          stops: const [0.0, 0.35, 0.55, 0.75, 1.0],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: FixoColors.primaryForest,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.isArabic
                                    ? 'تذكرة حجز رقمية معتمدة'
                                    : 'Certified Digital Ticket',
                                style: FixoTypography.labelLg(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(FixoRadius.pill),
                            ),
                            child: Text(
                              'FIXO-3D',
                              style: FixoTypography.labelMd(
                                color: FixoColors.limeAccent,
                              ).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Receipt Body Content
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Service Title & Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  (booking.offering[widget.isArabic ? 'titleAr' : 'titleEn'] as String?) ??
                                      (booking.offering['titleAr'] as String?) ??
                                      (booking.offering['titleEn'] as String?) ??
                                      (widget.isArabic ? 'خدمة منزلية معتمدة' : 'Verified Home Service'),
                                  style: FixoTypography.headlineSm(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${booking.pricing.totalEgp} ${booking.pricing.currency}',
                                style: FixoTypography.priceDisplay(
                                  color: palette.deepForest,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Booking ID & Time metadata
                          _receiptRow(
                            widget.isArabic ? 'رقم الحجز المرجعي' : 'Booking Ref',
                            '#${booking.id.substring(0, math.min(8, booking.id.length)).toUpperCase()}',
                            palette,
                          ),
                          const SizedBox(height: 6),
                          _receiptRow(
                            widget.isArabic ? 'تاريخ الخدمة' : 'Service Date',
                            '${booking.scheduledDate} (${booking.timeWindow})',
                            palette,
                          ),
                          const SizedBox(height: 6),
                          _receiptRow(
                            widget.isArabic ? 'طريقة التحصيل' : 'Payment Mode',
                            widget.isArabic ? 'نقداً بعد المعاينة (0 ج.م الآن)' : 'Cash on Service (0 EGP now)',
                            palette,
                            isHighlight: true,
                          ),

                          const SizedBox(height: 16),
                          // Perforated Divider
                          Row(
                            children: List.generate(
                              26,
                              (i) => Expanded(
                                child: Container(
                                  height: 1.5,
                                  color: i.isEven
                                      ? (isDark
                                          ? Colors.white24
                                          : palette.subtleBorder)
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Simulated Security Barcode
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(36, (i) {
                                final w = (i % 3 == 0) ? 2.5 : 1.2;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  width: w,
                                  height: 24,
                                  color: isDark ? Colors.white60 : Colors.black87,
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'VERIFIED • SECURE CASH TRANSACTION • FIXO EG',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: palette.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value,
    FixoPaletteExtension palette, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FixoTypography.bodySm(color: palette.mutedText),
        ),
        Text(
          value,
          style: FixoTypography.bodySm(
            color: isHighlight ? FixoColors.primaryForest : palette.deepForest,
          ).copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

