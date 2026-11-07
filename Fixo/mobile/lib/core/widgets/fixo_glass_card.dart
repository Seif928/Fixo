import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_spacing.dart';
import 'fixo_tilt_3d.dart';

/// Premium floating glassmorphism card for FIXO.
///
/// Features:
/// - Realtime [BackdropFilter] Gaussian blur.
/// - Frosted translucent substrate adapting to Light/Dark modes.
/// - Beveled glass border with specular gradient reflection.
/// - Physical multi-layered depth shadow.
/// - Optional 3D tilt perspective integration.
class FixoGlassCard extends StatelessWidget {
  const FixoGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FixoSpacing.md),
    this.margin,
    this.borderRadius = FixoRadius.borderRadiusLg,
    this.blurSigma = 14.0,
    this.tintOpacity = 0.72,
    this.enableTilt = true,
    this.maxTilt = 0.08,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double tintOpacity;
  final bool enableTilt;
  final double maxTilt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF14241F).withValues(alpha: tintOpacity)
        : Colors.white.withValues(alpha: tintOpacity);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.65);

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          // Ambient diffuse depth
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : palette.deepForest.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
          // Directional contact shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : palette.deepForest.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.45),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: cardContent,
      );
    }

    if (enableTilt) {
      return FixoTilt3D(
        maxTilt: maxTilt,
        borderRadius: borderRadius,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

