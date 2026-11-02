import 'package:flutter/material.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_spacing.dart';
import '../theme/fixo_typography.dart';

/// Local vector/icon brand mark for FIXO.
///
/// Replaces broken hotlinked `<img>` brand logo assets across the Stitch export
/// (`docs/STITCH_AUDIT.md` P0 finding).
class FixoBrandMark extends StatelessWidget {
  const FixoBrandMark({
    super.key,
    this.subtitle = 'Better Homes. Better Everyday.',
    this.showSubtitle = true,
    this.iconBoxSize = 32.0,
  });

  final String subtitle;
  final bool showSubtitle;
  final double iconBoxSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: palette.primaryBrand,
            borderRadius: FixoRadius.borderRadiusSm,
            boxShadow: FixoShadows.level1CardResting,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.handyman_rounded,
            size: iconBoxSize * 0.625,
            color: palette.limeAccent,
          ),
        ),
        const SizedBox(width: FixoSpacing.sm),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIXO',
                style: FixoTypography.headlineSm(color: palette.deepForest)
                    .copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -0.4,
                    ),
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FixoTypography.bodySm(
                    color: palette.mutedText,
                  ).copyWith(fontSize: 10.5, height: 1.2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
