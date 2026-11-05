import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_tilt_3d.dart';
/// Native Flutter hero showcase card for Screen 01 (`01_onboarding`).
///
/// Replaces the external hotlinked Google image from `01_onboarding/code.html`
/// with a deterministic, local architectural Cairo interior illustration
/// layered with the Stitch scrim, top craftsman pill, and bottom live
/// neighborhood availability card.
class CairoInteriorHeroCard extends StatelessWidget {
  const CairoInteriorHeroCard({super.key, this.isArabic = false});

  final bool isArabic;

  @override
  Widget build(BuildContext context) => FixoTilt3D(
    maxTilt: 0.06,
    glareOpacity: 0.15,
    borderRadius: FixoRadius.borderRadiusLg,
    child: _card(context),
  );


  Widget _card(BuildContext context) {
    final palette = context.fixoPalette;
    final locale = isArabic ? const Locale('ar') : const Locale('en');

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 276),
      decoration: BoxDecoration(
        color: palette.surfaceLow,
        borderRadius: FixoRadius.borderRadiusLg,
        boxShadow: FixoShadows.level2Interactive,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Base sunlit Cairo apartment architectural illustration (288dp min)
          Positioned.fill(
            child: CustomPaint(painter: _CairoApartmentPainter()),
          ),

          // Ambient Gradient Scrim: from-primary/80 via-primary/20 to-transparent
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.52, 1.0],
                  colors: [
                    FixoColors.deepestForest.withValues(alpha: 0.82),
                    FixoColors.deepestForest.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content overlay using intrinsic height so large text scales never clip
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 276),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top-left floating craftsman tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: FixoRadius.borderRadiusPill,
                      boxShadow: FixoShadows.level1CardResting,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.home_repair_service_rounded,
                          size: 16,
                          color: FixoColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isArabic
                                ? 'خدمات للمنزل'
                                : 'Services for Your Home',
                            style: FixoTypography.labelMd(
                              color: FixoColors.deepestForest,
                              locale: locale,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 140),

                  // Bottom active district live indicator card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: FixoRadius.borderRadiusMd,
                      boxShadow: FixoShadows.level1CardResting,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Pulsing lime indicator dot
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: FixoColors.limeAccent.withValues(
                                    alpha: 0.45,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: FixoColors.limeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isArabic
                                    ? 'القاهرة والجيزة'
                                    : 'Cairo & Giza',
                                style: FixoTypography.labelMd(
                                  color: FixoColors.onSurface,
                                  locale: locale,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isArabic
                                    ? 'المعادي • القاهرة الجديدة • الزمالك • زايد'
                                    : 'Maadi • New Cairo • Zamalek • Zayed',
                                style: FixoTypography.bodySm(
                                  color: FixoColors.onSurfaceVariant,
                                  locale: locale,
                                ).copyWith(fontSize: 11, height: 1.25),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Estimated response time pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: FixoColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: FixoColors.deepestForest,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                isArabic ? 'نقداً' : 'Cash',
                                style: FixoTypography.labelMd(
                                  color: FixoColors.deepestForest,
                                  locale: locale,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a warm sunlit Cairo contemporary apartment scene
/// inspired by `01_onboarding/screen.png` (travertine walls, wood beam ceiling,
/// balcony greenery, mid-century armchair, and indoor ficus tree).
class _CairoApartmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Warm travertine limestone background gradient
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE9DEC9), Color(0xFFD8C6A8), Color(0xFFB59E7D)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wallPaint);

    // 2. Sunlit Zamalek balcony window opening (left-center)
    final windowRect = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.12,
      size.width * 0.52,
      size.height * 0.68,
    );
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDFF0E6), Color(0xFFBBD8C5), Color(0xFF7FA98F)],
      ).createShader(windowRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(6)),
      skyPaint,
    );

    // Distant garden foliage silhouette inside balcony view
    final foliagePaint = Paint()..color = const Color(0xFF476F5B);
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.52),
      size.width * 0.14,
      foliagePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.48),
      size.width * 0.16,
      Paint()..color = const Color(0xFF355947),
    );

    // Architectural wooden ceiling beams (top right)
    final woodPaint = Paint()..color = const Color(0xFF8C5832);
    final beamPath = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.28)
      ..lineTo(size.width * 0.65, size.height * 0.18)
      ..close();
    canvas.drawPath(beamPath, woodPaint);

    // Window frame mullions
    final framePaint = Paint()
      ..color = const Color(0xFF5C4938)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(windowRect, framePaint);
    canvas.drawLine(
      Offset(windowRect.center.dx, windowRect.top),
      Offset(windowRect.center.dx, windowRect.bottom),
      framePaint,
    );

    // Polished marble floor reflection at bottom
    final floorRect = Rect.fromLTWH(
      0,
      size.height * 0.75,
      size.width,
      size.height * 0.25,
    );
    canvas.drawRect(floorRect, Paint()..color = const Color(0xFF6B6556));

    // Mid-century warm ochre armchair silhouette (right side)
    final chairRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.66,
        size.height * 0.54,
        size.width * 0.20,
        size.height * 0.18,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(chairRect, Paint()..color = const Color(0xFFC48F4B));

    // Indoor ficus plant in ceramic planter (center-left)
    final potRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.58,
        size.width * 0.12,
        size.height * 0.16,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(potRect, Paint()..color = const Color(0xFFD9D2C5));

    // Ficus canopy leaves in FIXO forest tones
    final leafPaintDark = Paint()..color = FixoColors.primaryForest;
    final leafPaintMid = Paint()..color = FixoColors.secondaryForest;
    final leafCenters = <Offset>[
      Offset(size.width * 0.28, size.height * 0.44),
      Offset(size.width * 0.23, size.height * 0.36),
      Offset(size.width * 0.33, size.height * 0.34),
      Offset(size.width * 0.28, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.18),
    ];
    for (var i = 0; i < leafCenters.length; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: leafCenters[i],
          width: size.width * 0.14,
          height: size.height * 0.09,
        ),
        i.isEven ? leafPaintDark : leafPaintMid,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
