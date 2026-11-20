import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_tilt_3d.dart';

/// Native Flutter Ultra-Luxury Architectural Penthouse Hero Card for Screen 01 (`01_onboarding`).
///
/// Renders a bespoke contemporary Cairo luxury villa interior with double-height
/// arched panoramic glass, warm gold chandelier lighting, herringbone parquet &
/// marble flooring, designer lounge seating, and reflective glassmorphic HUD badges.
class CairoInteriorHeroCard extends StatelessWidget {
  const CairoInteriorHeroCard({super.key, this.isArabic = false});

  final bool isArabic;

  @override
  Widget build(BuildContext context) => FixoTilt3D(
    maxTilt: 0.06,
    glareOpacity: 0.16,
    borderRadius: FixoRadius.borderRadiusLg,
    child: _card(context),
  );

  Widget _card(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = isArabic ? const Locale('ar') : const Locale('en');

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: palette.surfaceLow,
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? FixoColors.goldAccent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: FixoShadows.level2Interactive,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Bespoke Ultra-Luxury Cairo Penthouse Interior Illustration
          Positioned.fill(
            child: CustomPaint(
              painter: _LuxuryCairoPenthousePainter(isDark: isDark),
            ),
          ),

          // 2. Ambient Architectural Scrim
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.50, 1.0],
                  colors: [
                    const Color(0xFF04120E).withValues(alpha: 0.88),
                    const Color(0xFF0A241D).withValues(alpha: 0.26),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Content overlay using intrinsic height so large text scales never clip
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 280),
            child: Padding(
              padding: const EdgeInsets.all(FixoSpacing.gutterMobile),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Luxury Craftsman Pill + 3D Verified Crest Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FixoSpacing.gutterMobile,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0C1411).withValues(alpha: 0.88)
                                : Colors.white.withValues(alpha: 0.94),
                            borderRadius: FixoRadius.borderRadiusPill,
                            border: Border.all(
                              color: isDark
                                  ? FixoColors.goldAccent.withValues(alpha: 0.40)
                                  : Colors.white,
                            ),
                            boxShadow: FixoShadows.level1CardResting,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.home_repair_service_rounded,
                                size: 16,
                                color: isDark
                                    ? FixoColors.goldAccent
                                    : FixoColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isArabic
                                      ? 'خدمات للمنزل'
                                      : 'Services for Your Home',
                                  style: FixoTypography.labelMd(
                                    color: isDark
                                        ? FixoColors.darkOnSurface
                                        : FixoColors.deepestForest,
                                    locale: locale,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: FixoSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1B16).withValues(alpha: 0.82),
                          borderRadius: FixoRadius.borderRadiusPill,
                          border: Border.all(
                            color: FixoColors.goldAccent.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: FixoColors.goldBright,
                            ),
                            const SizedBox(width: FixoSpacing.xs),
                            Text(
                              isArabic ? 'نخبة معتمدة' : 'VIP Curated',
                              style: FixoTypography.labelSm(
                                color: FixoColors.goldBright,
                                locale: locale,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 136),

                  // Bottom active district live indicator card (Reflective Glass style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(FixoSpacing.gutterMobile),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D1512).withValues(alpha: 0.94)
                          : Colors.white.withValues(alpha: 0.96),
                      borderRadius: FixoRadius.borderRadiusMd,
                      border: Border.all(
                        color: isDark
                            ? FixoColors.darkBorder
                            : Colors.white.withValues(alpha: 0.85),
                      ),
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
                                  color: isDark
                                      ? FixoColors.darkOnSurface
                                      : FixoColors.onSurface,
                                  locale: locale,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: FixoSpacing.xxs),
                              Text(
                                isArabic
                                    ? 'المعادي • القاهرة الجديدة • الزمالك • زايد'
                                    : 'Maadi • New Cairo • Zamalek • Zayed',
                                style: FixoTypography.bodySm(
                                  color: isDark
                                      ? FixoColors.darkOnSurfaceVariant
                                      : FixoColors.onSurfaceVariant,
                                  locale: locale,
                                ).copyWith(fontSize: 11, height: 1.25),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: FixoSpacing.sm),
                        // Estimated response time pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FixoColors.primaryForest
                                : FixoColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(FixoRadius.sm),
                            border: isDark
                                ? Border.all(
                                    color: FixoColors.amberDark.withValues(
                                      alpha: 0.45,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: isDark
                                    ? FixoColors.amberDark
                                    : FixoColors.deepestForest,
                              ),
                              const SizedBox(width: FixoSpacing.xxs),
                              Text(
                                isArabic ? 'نقداً' : 'Cash',
                                style: FixoTypography.labelMd(
                                  color: isDark
                                      ? FixoColors.amberDark
                                      : FixoColors.deepestForest,
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

/// Custom painter rendering an ultra-luxury Cairo architectural villa interior
/// with arched panoramic windows, warm brass chandelier lighting, marble wall
/// paneling, designer emerald-and-gold lounge seating, and botanical accents.
class _LuxuryCairoPenthousePainter extends CustomPainter {
  const _LuxuryCairoPenthousePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Architectural fluted limestone & emerald-slate wall backdrop
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF172822), Color(0xFF0E1B16), Color(0xFF08110E)]
            : const [Color(0xFF234238), Color(0xFF163028), Color(0xFF0E221C)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wallPaint);

    // Subtle vertical fluted wall panelling lines on the right wall
    final flutePaint = Paint()
      ..color = FixoColors.goldAccent.withValues(alpha: 0.10)
      ..strokeWidth = 1.2;
    for (double x = w * 0.58; x < w * 0.96; x += w * 0.035) {
      canvas.drawLine(Offset(x, h * 0.06), Offset(x, h * 0.72), flutePaint);
    }

    // 2. Grand Arched Cairo Terrace Window (left-center)
    final archRect = Rect.fromLTWH(w * 0.07, h * 0.10, w * 0.46, h * 0.64);
    final archPath = Path()
      ..moveTo(archRect.left, archRect.bottom)
      ..lineTo(archRect.left, archRect.top + archRect.width * 0.42)
      ..arcToPoint(
        Offset(archRect.right, archRect.top + archRect.width * 0.42),
        radius: Radius.circular(archRect.width * 0.5),
      )
      ..lineTo(archRect.right, archRect.bottom)
      ..close();

    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF6E6C2),
          Color(0xFFD5E6DA),
          Color(0xFF83B19B),
        ],
      ).createShader(archRect);
    canvas.drawPath(archPath, skyPaint);

    // Distant Nile / Zamalek skyline & lush botanical silhouettes inside arch
    canvas.save();
    canvas.clipPath(archPath);
    canvas.drawCircle(
      Offset(w * 0.38, h * 0.26),
      w * 0.065,
      Paint()..color = const Color(0xFFFFF4D2).withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.19, h * 0.55),
      w * 0.15,
      Paint()..color = const Color(0xFF2E5A49),
    );
    canvas.drawCircle(
      Offset(w * 0.39, h * 0.52),
      w * 0.17,
      Paint()..color = const Color(0xFF1E4436),
    );
    canvas.restore();

    // Brushed brass window mullions
    final brassStroke = Paint()
      ..color = FixoColors.goldAccent.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(archPath, brassStroke);
    canvas.drawLine(
      Offset(archRect.center.dx, archRect.top + 4),
      Offset(archRect.center.dx, archRect.bottom),
      brassStroke,
    );
    canvas.drawLine(
      Offset(archRect.left, archRect.top + archRect.height * 0.48),
      Offset(archRect.right, archRect.top + archRect.height * 0.48),
      brassStroke,
    );

    // 3. Polished Calacatta Marble & Dark Walnut Floor
    final floorRect = Rect.fromLTWH(0, h * 0.72, w, h * 0.28);
    final floorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1B312A),
          Color(0xFF0A1612),
        ],
      ).createShader(floorRect);
    canvas.drawRect(floorRect, floorPaint);

    // Subtle perspective floor grid lines
    final floorGridPaint = Paint()
      ..color = FixoColors.goldAccent.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    for (var i = 1; i <= 5; i++) {
      final xTop = w * (0.15 * i);
      final xBot = w * (-0.1 + 0.24 * i);
      canvas.drawLine(
        Offset(xTop, h * 0.72),
        Offset(xBot, h),
        floorGridPaint,
      );
    }

    // 4. Designer Ring Chandelier & Warm Halo Glow (Top-Right)
    final chandelierCenter = Offset(w * 0.74, h * 0.26);
    canvas.drawCircle(
      chandelierCenter,
      w * 0.18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            FixoColors.goldBright.withValues(alpha: 0.34),
            FixoColors.limeHighlight.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: chandelierCenter, radius: w * 0.18),
        ),
    );
    canvas.drawLine(
      Offset(chandelierCenter.dx, 0),
      Offset(chandelierCenter.dx, chandelierCenter.dy - h * 0.04),
      Paint()
        ..color = FixoColors.goldAccent
        ..strokeWidth = 1.8,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: chandelierCenter,
        width: w * 0.18,
        height: h * 0.065,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = FixoColors.goldBright,
    );

    // 5. Bespoke Curved Velvet Lounge Sofa & Brass Coffee Table (Right-Center)
    final sofaBase = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.56, h * 0.54, w * 0.34, h * 0.16),
      const Radius.circular(14),
    );
    final sofaBack = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.59, h * 0.44, w * 0.28, h * 0.13),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      sofaBack,
      Paint()..color = const Color(0xFFD9C7A7),
    );
    canvas.drawRRect(
      sofaBase,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDE2CE), Color(0xFFC8B28E)],
        ).createShader(sofaBase.outerRect),
    );
    // Gold accent pillow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.63, h * 0.48, w * 0.08, h * 0.07),
        const Radius.circular(6),
      ),
      Paint()..color = FixoColors.goldAccent,
    );

    // 6. Sculptural Brass Planter with Architectural Botanical Canopy
    final potRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.44, h * 0.55, w * 0.09, h * 0.17),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      potRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FixoColors.goldBright, Color(0xFF9E7B32)],
        ).createShader(potRect.outerRect),
    );

    final leafCenters = <Offset>[
      Offset(w * 0.485, h * 0.45),
      Offset(w * 0.44, h * 0.39),
      Offset(w * 0.53, h * 0.38),
      Offset(w * 0.485, h * 0.31),
    ];
    for (var i = 0; i < leafCenters.length; i++) {
      canvas.save();
      canvas.translate(leafCenters[i].dx, leafCenters[i].dy);
      canvas.rotate((i.isEven ? -1 : 1) * math.pi / 10);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * 0.11,
          height: h * 0.07,
        ),
        Paint()
          ..color = i.isEven
              ? FixoColors.secondaryForest
              : FixoColors.limeHighlight.withValues(alpha: 0.85),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LuxuryCairoPenthousePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
