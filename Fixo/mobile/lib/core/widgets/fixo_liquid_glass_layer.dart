import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/fixo_spacing.dart';
import '../motion/fixo_motion.dart';

/// Apple-style Liquid Glass Layer (VisionOS & iOS 18 fluid frosted glass).
///
/// Features:
/// - Multi-stage optical blur ([BackdropFilter] with customizable Gaussian sigma).
/// - Dynamic liquid caustic reflection with light-tapered perimeter rim (specular bevel).
/// - Convex liquid dome sheen simulating natural light refraction across optical glass.
/// - Fluid pointer/hover tracking for Web and touch drag for iPhone/Android.
/// - True dark and light mode calibrated translucency.
/// - Test-safe: Disables animation loops during automated golden snapshot tests.
class LiquidGlassLayer extends StatefulWidget {
  const LiquidGlassLayer({
    super.key,
    required this.child,
    this.borderRadius = FixoRadius.borderRadiusLg,
    this.blurSigma = 26.0,
    this.tintOpacity,
    this.specularIntensity = 0.48,
    this.borderWidth = 1.25,
    this.enableInteractiveCaustics = true,
    this.enableBlur = true,
    this.padding,
    this.margin,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double? tintOpacity;
  final double specularIntensity;
  final double borderWidth;
  final bool enableInteractiveCaustics;
  final bool enableBlur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  State<LiquidGlassLayer> createState() => _LiquidGlassLayerState();
}

class _LiquidGlassLayerState extends State<LiquidGlassLayer> {
  Offset _pointerNorm = const Offset(
    -0.35,
    -0.65,
  ); // Default top-left light source

  void _onPointerMove(Offset localPos) {
    if (!widget.enableInteractiveCaustics) return;
    final size = context.size;
    if (size == null || size.isEmpty) return;

    final norm = Offset(
      (localPos.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      (localPos.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
    );

    setState(() {
      _pointerNorm = norm;
    });
  }

  void _onPointerExit() {
    if (!widget.enableInteractiveCaustics) return;
    setState(() {
      _pointerNorm = const Offset(-0.35, -0.65);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final interactive =
        widget.enableInteractiveCaustics &&
        FixoMotion.expensiveEffects(context);
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );

    // Apple VisionOS Reflective Glass substrate tint:
    // Light: crystalline milky frosted white with 74% opacity.
    // Dark: True Black obsidian smoked glass with 68% opacity.
    final defaultOpacity = isDark ? 0.68 : 0.74;
    final opacity = widget.tintOpacity ?? defaultOpacity;

    final substrateColor = isDark
        ? const Color(0xFF0C1210).withValues(alpha: opacity)
        : const Color(0xFFFCFBFA).withValues(alpha: opacity);

    final rimTopColor = isDark
        ? Colors.white.withValues(
            alpha: (0.42 * widget.specularIntensity + 0.16).clamp(0.0, 1.0),
          )
        : Colors.white.withValues(
            alpha: (0.82 * widget.specularIntensity + 0.22).clamp(0.0, 1.0),
          );
    final rimBottomColor = isDark
        ? const Color(0xFFD8BC90).withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);

    final Widget paintedBody = CustomPaint(
      foregroundPainter: _AppleGlassBevelPainter(
        borderRadius: widget.borderRadius,
        borderWidth: widget.borderWidth,
        topColor: rimTopColor,
        bottomColor: rimBottomColor,
        lightDirection: _pointerNorm,
      ),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: substrateColor,
          borderRadius: widget.borderRadius,
          // Convex Liquid Dome Gradient (Upper lens meniscus catches light)
          gradient: LinearGradient(
            begin: Alignment(-_pointerNorm.dx, -_pointerNorm.dy),
            end: Alignment(_pointerNorm.dx, _pointerNorm.dy),
            colors: isDark
                ? [
                    Colors.white.withValues(
                      alpha: (0.14 * widget.specularIntensity).clamp(0.0, 1.0),
                    ),
                    Colors.white.withValues(alpha: 0.03),
                    const Color(0xFF080D0B).withValues(alpha: 0.55),
                  ]
                : [
                    Colors.white.withValues(
                      alpha: (0.78 * widget.specularIntensity + 0.15).clamp(
                        0.0,
                        1.0,
                      ),
                    ),
                    Colors.white.withValues(alpha: 0.38),
                    const Color(0xFFEBE8DF).withValues(alpha: 0.22),
                  ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
        child: Stack(
          children: [
            RepaintBoundary(child: widget.child),
            // Liquid Caustic Specular Glare Overlay
            if (interactive && !isTest)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: widget.borderRadius,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(_pointerNorm.dx, _pointerNorm.dy),
                          radius: 1.3,
                          colors: [
                            Colors.white.withValues(
                              alpha:
                                  ((isDark ? 0.18 : 0.28) *
                                          widget.specularIntensity)
                                      .clamp(0.0, 1.0),
                            ),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.75],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    Widget glassContainer = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: [
          // Apple Ambient Volumetric Depth Shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.65)
                : const Color(0xFF24262B).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          // Sharp Contact Shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF24262B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: widget.enableBlur
            ? BackdropFilter(
                enabled: FixoMotion.expensiveEffects(context),
                filter: ImageFilter.blur(
                  sigmaX: isTest ? 0.1 : widget.blurSigma,
                  sigmaY: isTest ? 0.1 : widget.blurSigma,
                ),
                child: paintedBody,
              )
            : paintedBody,
      ),
    );

    if (!interactive || isTest) {
      return glassContainer;
    }

    return MouseRegion(
      onHover: (e) => _onPointerMove(e.localPosition),
      onExit: (_) => _onPointerExit(),
      child: Listener(
        onPointerDown: (e) => _onPointerMove(e.localPosition),
        onPointerMove: (e) => _onPointerMove(e.localPosition),
        onPointerUp: (_) => _onPointerExit(),
        onPointerCancel: (_) => _onPointerExit(),
        child: glassContainer,
      ),
    );
  }
}

/// Custom painter for Apple VisionOS-calibrated specular bevel rim.
class _AppleGlassBevelPainter extends CustomPainter {
  const _AppleGlassBevelPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.topColor,
    required this.bottomColor,
    required this.lightDirection,
  });

  final BorderRadius borderRadius;
  final double borderWidth;
  final Color topColor;
  final Color bottomColor;
  final Offset lightDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0 || size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = LinearGradient(
        begin: Alignment(lightDirection.dx, lightDirection.dy),
        end: Alignment(-lightDirection.dx, -lightDirection.dy),
        colors: [topColor, bottomColor],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AppleGlassBevelPainter oldDelegate) {
    return oldDelegate.borderWidth != borderWidth ||
        oldDelegate.topColor != topColor ||
        oldDelegate.bottomColor != bottomColor ||
        oldDelegate.lightDirection != lightDirection ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Standalone Liquid Glass Card pre-packaged with padding and optional tap callback.
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FixoSpacing.md),
    this.margin,
    this.borderRadius = FixoRadius.borderRadiusLg,
    this.blurSigma = 26.0,
    this.tintOpacity,
    this.specularIntensity = 0.48,
    this.enableBlur = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double? tintOpacity;
  final double specularIntensity;
  final bool enableBlur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return LiquidGlassLayer(
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      tintOpacity: tintOpacity,
      specularIntensity: specularIntensity,
      enableBlur: enableBlur,
      enableInteractiveCaustics: enableBlur,
      padding: padding,
      margin: margin,
      child: content,
    );
  }
}
