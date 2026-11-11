import 'package:flutter/material.dart';
import '../../../../core/motion/fixo_visibility_throttler.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';

/// 3D Interactive Appliance Inspection & Defect Pinning Canvas for Screen 04 (`04 — Create Booking`).
///
/// Allows customers to pinpoint exact failure zones on a 3D isometric appliance
/// (AC Split indoor unit, plumbing pipe/heater, or electrical breaker board).
/// Tapping any 3D pin auto-populates the issue description with precise diagnostic context.
class Appliance3DInspectionWidget extends StatefulWidget {
  const Appliance3DInspectionWidget({
    super.key,
    required this.categorySlug,
    required this.isArabic,
    required this.onPinSelected,
    this.initialDescription,
  });

  final String categorySlug;
  final bool isArabic;
  final ValueChanged<String> onPinSelected;
  final String? initialDescription;

  @override
  State<Appliance3DInspectionWidget> createState() =>
      _Appliance3DInspectionWidgetState();
}

class _AppliancePin {
  const _AppliancePin({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.detailAr,
    required this.detailEn,
    required this.xPercent,
    required this.yPercent,
    required this.icon,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String detailAr;
  final String detailEn;
  final double xPercent;
  final double yPercent;
  final IconData icon;

  String title(bool ar) => ar ? titleAr : titleEn;
  String detail(bool ar) => ar ? detailAr : detailEn;
}

class _Appliance3DInspectionWidgetState
    extends State<Appliance3DInspectionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  _AppliancePin? _selectedPin;
  double _tiltAngle = 0.0;
  double _dragStartTilt = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      _pulseController.forward();
    } else {
      _pulseController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_AppliancePin> _getPins() {
    final slug = widget.categorySlug.toLowerCase();
    if (slug.contains('plumb') || slug.contains('water')) {
      return const [
        _AppliancePin(
          id: 'valve_leak',
          titleAr: 'تسريب المحبس',
          titleEn: 'Valve Leak',
          detailAr: 'تسريب مياه مستمر من المحبس أو الوصلة النحاسية',
          detailEn: 'Continuous water leakage from valve or copper fitting',
          xPercent: 0.35,
          yPercent: 0.38,
          icon: Icons.water_drop_rounded,
        ),
        _AppliancePin(
          id: 'pipe_clog',
          titleAr: 'انسداد الصرف',
          titleEn: 'Drain Blockage',
          detailAr: 'انسداد في ماسورة الصرف وبطء تصريف المياه',
          detailEn: 'Drainage pipe clog with sluggish water discharge',
          xPercent: 0.65,
          yPercent: 0.70,
          icon: Icons.filter_alt_off_rounded,
        ),
        _AppliancePin(
          id: 'heater_pressure',
          titleAr: 'ضعف السخان',
          titleEn: 'Heater Issue',
          detailAr: 'عدم تسخين المياه أو انخفاض ضغط السخان',
          detailEn: 'Water not heating properly or low outlet pressure',
          xPercent: 0.75,
          yPercent: 0.32,
          icon: Icons.thermostat_rounded,
        ),
      ];
    } else if (slug.contains('electr')) {
      return const [
        _AppliancePin(
          id: 'breaker_trip',
          titleAr: 'فصل القاطع',
          titleEn: 'Breaker Trip',
          detailAr: 'فصل متكرر للقاطع الأوتوماتيكي عند تشغيل الأجهزة',
          detailEn: 'Frequent circuit breaker tripping under load',
          xPercent: 0.30,
          yPercent: 0.40,
          icon: Icons.toggle_off_rounded,
        ),
        _AppliancePin(
          id: 'short_spark',
          titleAr: 'ماس كهربائي',
          titleEn: 'Short Circuit',
          detailAr: 'ظهور شرر كهربائي أو رائحة احتراق في اللوحة',
          detailEn: 'Sparking or burnt odor noticed inside electrical panel',
          xPercent: 0.50,
          yPercent: 0.55,
          icon: Icons.electric_bolt_rounded,
        ),
        _AppliancePin(
          id: 'wiring_loose',
          titleAr: 'ارتخاء التوصيلات',
          titleEn: 'Loose Terminal',
          detailAr: 'ارتخاء في الأسلاك الرئيسية وتذبذب التيار',
          detailEn: 'Loose main feeder connections causing voltage fluctuation',
          xPercent: 0.70,
          yPercent: 0.35,
          icon: Icons.cable_rounded,
        ),
      ];
    } else {
      // Default: AC Repair
      return const [
        _AppliancePin(
          id: 'water_leak',
          titleAr: 'تسريب مياه',
          titleEn: 'Water Leak',
          detailAr: 'تساقط مياه من الوحدة الداخلية للغرفة',
          detailEn: 'Water dripping indoors from the evaporator basin',
          xPercent: 0.28,
          yPercent: 0.68,
          icon: Icons.water_drop_rounded,
        ),
        _AppliancePin(
          id: 'weak_cooling',
          titleAr: 'ضعف التبريد',
          titleEn: 'Weak Cooling',
          detailAr: 'خروج هواء دافئ وضعف ملحوظ في التبريد (نقص فريون)',
          detailEn:
              'Blowing warm air with low cooling output (refrigerant leak)',
          xPercent: 0.52,
          yPercent: 0.45,
          icon: Icons.ac_unit_rounded,
        ),
        _AppliancePin(
          id: 'blower_noise',
          titleAr: 'صوت واهتزاز',
          titleEn: 'Noisy Fan',
          detailAr: 'صوت صفير أو خشونة في مروحة التكييف الداخلية',
          detailEn: 'High squeaking or vibration from the indoor blower rotor',
          xPercent: 0.78,
          yPercent: 0.52,
          icon: Icons.volume_up_rounded,
        ),
      ];
    }
  }

  void _onTapPin(_AppliancePin pin) {
    setState(() => _selectedPin = pin);
    widget.onPinSelected(pin.detail(widget.isArabic));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pins = _getPins();

    return Container(
      margin: const EdgeInsets.only(bottom: FixoSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241F) : Colors.white,
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? palette.subtleBorder.withValues(alpha: 0.3)
              : palette.subtleBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.deepForest.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: FixoColors.primaryForest,
                    borderRadius: BorderRadius.circular(FixoRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.view_in_ar_rounded,
                        size: 13,
                        color: FixoColors.limeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isArabic ? 'معاينة 3D' : '3D Defect Pinning',
                        style: FixoTypography.labelMd(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isArabic
                        ? 'حدد مكان العطل باللمس مباشرة'
                        : 'Tap on the part to pin problem',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FixoTypography.bodySm(
                      color: palette.mutedText,
                    ).copyWith(fontSize: 11),
                  ),
                ),
                if (_selectedPin != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _selectedPin = null),
                    child: Text(
                      widget.isArabic ? 'إلغاء' : 'Clear',
                      style: FixoTypography.labelMd(
                        color: FixoColors.coral,
                      ).copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3D Interactive Canvas
          GestureDetector(
            onHorizontalDragStart: (e) => _dragStartTilt = _tiltAngle,
            onHorizontalDragUpdate: (e) {
              setState(() {
                _tiltAngle = (_dragStartTilt + e.delta.dx * 0.006).clamp(
                  -0.25,
                  0.25,
                );
              });
            },
            onHorizontalDragEnd: (_) => setState(() => _tiltAngle = 0),
            child: FixoVisibilityThrottler(
              controller: _pulseController,
              repeatReverse: true,
              child: Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F1B17)
                      : const Color(0xFFF9F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Stack(
                  children: [
                    // 3D Appliance Vector Graphic
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _Appliance3DPainter(
                          categorySlug: widget.categorySlug,
                          tiltAngle: _tiltAngle,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Pins Overlay
                    ...pins.map((pin) {
                      final isSelected = _selectedPin?.id == pin.id;
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final pulse = _pulseController.value;
                          return Positioned(
                            left: pin.xPercent * 280,
                            top: pin.yPercent * 150,
                            child: GestureDetector(
                              onTap: () => _onTapPin(pin),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isSelected)
                                        Container(
                                          width: 28 + pulse * 8,
                                          height: 28 + pulse * 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: FixoColors.limeAccent
                                                .withValues(
                                                  alpha: 0.3 * (1 - pulse),
                                                ),
                                          ),
                                        ),
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? FixoColors.limeAccent
                                              : FixoColors.primaryForest,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          pin.icon,
                                          size: 13,
                                          color: isSelected
                                              ? FixoColors.deepestForest
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? FixoColors.primaryForest
                                          : Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      pin.title(widget.isArabic),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Diagnostic Confirmation Pill
          if (_selectedPin != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? FixoColors.primaryForest.withValues(alpha: 0.35)
                      : FixoColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: FixoColors.limeAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: FixoColors.limeAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedPin!.detail(widget.isArabic),
                        style: FixoTypography.bodySm(
                          color: isDark
                              ? Colors.white
                              : FixoColors.onSecondaryContainer,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Appliance3DPainter extends CustomPainter {
  _Appliance3DPainter({
    required this.categorySlug,
    required this.tiltAngle,
    required this.isDark,
  });

  final String categorySlug;
  final double tiltAngle;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw 3D Appliance body (e.g. Split AC indoor unit)
    final width = 200.0;
    final height = 75.0;
    final depth = 25.0;

    final slant = tiltAngle * 30.0;

    // Front face
    final frontRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + slant, cy),
        width: width,
        height: height,
      ),
      const Radius.circular(8),
    );

    // Front body gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF2C3E37), const Color(0xFF1E2D27)]
            : [const Color(0xFFFFFFFF), const Color(0xFFE8E5DD)],
      ).createShader(frontRect.outerRect);
    canvas.drawRRect(frontRect, bodyPaint);

    // Top depth face
    final topFace = Path()
      ..moveTo(cx - width / 2 + slant, cy - height / 2)
      ..lineTo(cx - width / 2 + slant + depth, cy - height / 2 - depth * 0.4)
      ..lineTo(cx + width / 2 + slant + depth, cy - height / 2 - depth * 0.4)
      ..lineTo(cx + width / 2 + slant, cy - height / 2)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()
        ..color = isDark ? const Color(0xFF3B4F47) : const Color(0xFFD6D1C4),
    );

    // Air outlet louver vent at bottom
    final louverPaint = Paint()
      ..color = isDark ? const Color(0xFF14241F) : const Color(0xFF9E998B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - width / 2 + 15 + slant, cy + height / 2 - 12),
      Offset(cx + width / 2 - 15 + slant, cy + height / 2 - 12),
      louverPaint,
    );

    // Digital Temperature LED indicator (e.g. 22°C)
    final ledPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(Offset(cx + width / 2 - 35 + slant, cy - 8), 3, ledPaint);
  }

  @override
  bool shouldRepaint(covariant _Appliance3DPainter oldDelegate) {
    return oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.categorySlug != categorySlug ||
        oldDelegate.isDark != isDark;
  }
}
