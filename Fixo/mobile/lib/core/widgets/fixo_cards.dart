import 'package:flutter/material.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_spacing.dart';
import '../theme/fixo_typography.dart';

/// Standard elevated card container using FIXO's botanical Level 1 shadow.
class FixoSurfaceCard extends StatelessWidget {
  const FixoSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FixoSpacing.md),
    this.backgroundColor,
    this.borderRadius = FixoRadius.borderRadiusLg,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.cardSurface,
        borderRadius: borderRadius,
        border: showBorder
            ? Border.all(color: palette.subtleBorder, width: 1)
            : null,
        boxShadow: FixoShadows.level1CardResting,
      ),
      child: child,
    );
  }
}

/// Trust value pillar chip (used on Screen 01 Onboarding for value props).
class FixoTrustPillarChip extends StatelessWidget {
  const FixoTrustPillarChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusSm,
        border: Border.all(color: palette.subtleBorder, width: 1),
        boxShadow: FixoShadows.level1CardResting,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: FixoColors.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: FixoTypography.labelMd(
                color: palette.inkText,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded status pill badge (e.g. "Cairo & Giza Coverage", "THE STANDARD IN HOME CARE").
class FixoStatusBadge extends StatelessWidget {
  const FixoStatusBadge({
    super.key,
    required this.label,
    this.leadingIcon,
    this.showStatusDot = false,
    this.uppercase = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? leadingIcon;
  final bool showStatusDot;
  final bool uppercase;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final fg = foregroundColor ?? palette.deepForest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surfaceHigh,
        borderRadius: FixoRadius.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStatusDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: FixoColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FixoTypography.labelMd(color: fg).copyWith(
                fontSize: uppercase ? 11 : 12,
                letterSpacing: uppercase ? 0.6 : 0.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

