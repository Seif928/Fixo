import 'package:flutter/material.dart';
import '../theme/fixo_colors.dart';
import '../motion/fixo_motion.dart';
import '../theme/fixo_spacing.dart';
import '../theme/fixo_typography.dart';

/// Primary forest-green action button (`#173F35` fill, `#FFFFFF` text).
///
/// Supports either a trailing circular lime badge (as in Screen 01 "Get Started")
/// or a standard inline trailing icon.
class FixoPrimaryButton extends StatelessWidget {
  const FixoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.showCircularLimeBadge = false,
    this.leadingIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool showCircularLimeBadge;
  final IconData? leadingIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return FixoPressFeedback(
      enabled: onPressed != null && !isLoading,
      builder: (onHighlightChanged) => Semantics(
        container: true,
        button: true,
        enabled: onPressed != null && !isLoading,
        label: label,
        onTap: isLoading ? null : onPressed,
        child: Material(
          color: palette.primaryBrand,
          borderRadius: FixoRadius.borderRadiusSm,
          elevation: 0,
          child: InkWell(
            onHighlightChanged: onHighlightChanged,
            onTap: isLoading ? null : onPressed,
            borderRadius: FixoRadius.borderRadiusSm,
            splashColor: palette.secondaryForest.withValues(alpha: 0.4),
            highlightColor: palette.secondaryForest.withValues(alpha: 0.25),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FixoSpacing.minTouchTarget,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: FixoSpacing.sm,
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: FixoColors.limeAccent,
                          ),
                        ),
                      )
                    : showCircularLimeBadge
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: FixoTypography.labelLg(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: FixoSpacing.sm),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: palette.limeAccent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              trailingIcon ?? Icons.arrow_forward_rounded,
                              size: 19,
                              color: palette.primaryBrand,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(leadingIcon, size: 18, color: Colors.white),
                            const SizedBox(width: FixoSpacing.sm),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: FixoTypography.labelLg(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: FixoSpacing.sm),
                            Icon(trailingIcon, size: 18, color: Colors.white),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// High-energy lime accent button (`#D5EE76` / `#D7F078` fill, `#173F35` text).
class FixoAccentButton extends StatelessWidget {
  const FixoAccentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return FixoPressFeedback(
      enabled: onPressed != null,
      builder: (onHighlightChanged) => Semantics(
        container: true,
        button: true,
        enabled: onPressed != null,
        label: label,
        onTap: onPressed,
        child: Material(
          color: palette.limeAccent,
          borderRadius: FixoRadius.borderRadiusSm,
          child: InkWell(
            onHighlightChanged: onHighlightChanged,
            onTap: onPressed,
            borderRadius: FixoRadius.borderRadiusSm,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FixoSpacing.minTouchTarget,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FixoSpacing.md,
                  vertical: FixoSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 20, color: palette.primaryBrand),
                      const SizedBox(width: FixoSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: FixoTypography.labelLg(
                          color: palette.primaryBrand,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: FixoSpacing.sm),
                      Icon(trailingIcon, size: 20, color: palette.primaryBrand),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary / Ghost white surface button (`#FFFFFF` fill, `#E7E8DF` border).
class FixoSecondaryButton extends StatelessWidget {
  const FixoSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return FixoPressFeedback(
      enabled: onPressed != null,
      builder: (onHighlightChanged) => Semantics(
        container: true,
        button: true,
        enabled: onPressed != null,
        label: label,
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: palette.cardSurface,
            borderRadius: FixoRadius.borderRadiusSm,
            border: Border.all(color: palette.subtleBorder, width: 1),
            boxShadow: FixoShadows.level1CardResting,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: FixoRadius.borderRadiusSm,
            child: InkWell(
              onHighlightChanged: onHighlightChanged,
              onTap: onPressed,
              borderRadius: FixoRadius.borderRadiusSm,
              splashColor: palette.surfaceContainer,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: FixoSpacing.minTouchTarget,
                  minWidth: double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: FixoSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leadingIcon != null) ...[
                        Icon(leadingIcon, size: 18, color: palette.deepForest),
                        const SizedBox(width: FixoSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: FixoTypography.labelLg(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
