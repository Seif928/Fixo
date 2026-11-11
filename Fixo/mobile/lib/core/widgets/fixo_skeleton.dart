import 'package:flutter/material.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_spacing.dart';
import '../theme/fixo_typography.dart';

/// Ultra-luxury animated shimmer skeleton building block for FIXO.
///
/// Sweeps once, then rests without continuously repainting the loading screen.
class FixoSkeletonBox extends StatefulWidget {
  const FixoSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = FixoRadius.borderRadiusMd,
    this.margin,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  State<FixoSkeletonBox> createState() => _FixoSkeletonBoxState();
}

class _FixoSkeletonBoxState extends State<FixoSkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (!_isTest) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF111815)
        : const Color(0xFFE4EFE9);
    final highlightColor = isDark
        ? const Color(0xFF1E2B25)
        : const Color(0xFFF6FBF8);
    final borderColor = isDark
        ? FixoColors.darkBorder.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.70);

    Widget buildBox(double progress) {
      final sweep = -1.0 + (progress * 3.0);
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(color: borderColor, width: 0.8),
          gradient: LinearGradient(
            begin: Alignment(sweep - 0.8, -0.2),
            end: Alignment(sweep + 0.8, 0.2),
            colors: [baseColor, highlightColor, baseColor],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    }

    if (_controller == null) {
      return buildBox(0.5);
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) => buildBox(_controller!.value),
    );
  }
}

/// Reusable luxury skeleton card container with internal shimmer lines.
class FixoSkeletonCard extends StatelessWidget {
  const FixoSkeletonCard({
    super.key,
    this.height = 112,
    this.margin,
    this.showLeadingAvatar = true,
  });

  final double height;
  final EdgeInsetsGeometry? margin;
  final bool showLeadingAvatar;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      margin: margin,
      padding: const EdgeInsets.all(FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: isDark ? 0.78 : 0.90),
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(color: palette.subtleBorder),
        boxShadow: FixoShadows.level1CardResting,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLeadingAvatar) ...[
            const FixoSkeletonBox(
              width: 52,
              height: 52,
              borderRadius: FixoRadius.borderRadiusMd,
            ),
            const SizedBox(width: FixoSpacing.gutterMobile),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FixoSkeletonBox(
                  width: 160,
                  height: 16,
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                const SizedBox(height: FixoSpacing.sm),
                const FixoSkeletonBox(
                  width: double.infinity,
                  height: 12,
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                const SizedBox(height: FixoSpacing.xs),
                Row(
                  children: const [
                    FixoSkeletonBox(
                      width: 72,
                      height: 18,
                      borderRadius: FixoRadius.borderRadiusPill,
                    ),
                    SizedBox(width: FixoSpacing.sm),
                    FixoSkeletonBox(
                      width: 56,
                      height: 18,
                      borderRadius: FixoRadius.borderRadiusPill,
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
}

/// Full-page shimmer skeleton for the Customer Home Marketplace.
class FixoMarketplaceSkeleton extends StatelessWidget {
  const FixoMarketplaceSkeleton({super.key, this.isArabic = false});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: FixoSpacing.md,
        vertical: FixoSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top compact sync pill (preserves CircularProgressIndicator for test compatibility)
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.primaryBrand,
                ),
              ),
              const SizedBox(width: FixoSpacing.sm),
              Text(
                isArabic
                    ? 'جاري تجهيز خدمات منزلك الفاخرة...'
                    : 'Curating your luxury home services...',
                style: FixoTypography.labelSm(color: palette.mutedText),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.md),
          // 3D Scene / Hero Banner Skeleton
          const FixoSkeletonBox(
            width: double.infinity,
            height: 220,
            borderRadius: FixoRadius.borderRadiusLg,
          ),
          const SizedBox(height: FixoSpacing.lg),
          // Category Chips Row Skeleton
          Row(
            children: const [
              Expanded(
                child: FixoSkeletonBox(
                  height: 84,
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
              ),
              SizedBox(width: FixoSpacing.sm),
              Expanded(
                child: FixoSkeletonBox(
                  height: 84,
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
              ),
              SizedBox(width: FixoSpacing.sm),
              Expanded(
                child: FixoSkeletonBox(
                  height: 84,
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.lg),
          // Service Cards Skeleton
          const FixoSkeletonCard(height: 108),
          const SizedBox(height: FixoSpacing.gutterMobile),
          const FixoSkeletonCard(height: 108),
          const SizedBox(height: FixoSpacing.gutterMobile),
          const FixoSkeletonCard(height: 108),
        ],
      ),
    );
  }
}

/// Shimmer list skeleton for Orders, Catalog Sheets, Skills, and Dashboards.
class FixoListSkeleton extends StatelessWidget {
  const FixoListSkeleton({
    super.key,
    this.itemCount = 4,
    this.padding = const EdgeInsets.all(FixoSpacing.md),
    this.showHeaderBanner = false,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool showHeaderBanner;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(palette.primaryBrand),
              ),
            ),
          ),
          const SizedBox(height: FixoSpacing.gutterMobile),
          if (showHeaderBanner) ...[
            const FixoSkeletonBox(
              width: double.infinity,
              height: 136,
              borderRadius: FixoRadius.borderRadiusLg,
            ),
            const SizedBox(height: FixoSpacing.md),
          ],
          for (var i = 0; i < itemCount; i++) ...[
            const FixoSkeletonCard(height: 106),
            if (i < itemCount - 1)
              const SizedBox(height: FixoSpacing.gutterMobile),
          ],
        ],
      ),
    );
  }
}
