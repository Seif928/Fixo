import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_tilt_3d.dart';
import '../../../../core/widgets/fixo_holographic_pro_badge.dart';
import '../../../../core/widgets/fixo_liquid_glass_layer.dart';
import '../../domain/marketplace_models.dart';

/// Maps Stitch Material Symbol names to native Flutter `IconData`.
IconData mapCategoryIconName(String iconName) {
  switch (iconName) {
    case 'mode_fan':
    case 'ac_unit':
      return Icons.ac_unit_rounded;
    case 'plumbing':
      return Icons.plumbing_rounded;
    case 'bolt':
    case 'electrical_services':
      return Icons.bolt_rounded;
    case 'cleaning_services':
      return Icons.cleaning_services_rounded;
    case 'handyman':
    case 'carpenter':
      return Icons.handyman_rounded;
    case 'format_paint':
      return Icons.format_paint_rounded;
    case 'local_laundry_service':
      return Icons.local_laundry_service_rounded;
    case 'kitchen':
      return Icons.kitchen_rounded;
    case 'microwave':
      return Icons.microwave_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'local_shipping':
      return Icons.local_shipping_rounded;
    case 'pest_control':
      return Icons.pest_control_rounded;
    case 'yard':
      return Icons.yard_rounded;
    case 'window':
      return Icons.window_rounded;
    case 'hardware':
      return Icons.hardware_rounded;
    case 'grid_view':
      return Icons.grid_view_rounded;
    case 'roofing':
      return Icons.roofing_rounded;
    case 'lock':
      return Icons.lock_rounded;
    case 'router':
      return Icons.router_rounded;
    case 'chair':
      return Icons.chair_rounded;
    case 'blender':
      return Icons.blender_rounded;
    default:
      return Icons.home_repair_service_rounded;
  }
}

/// Local vector portrait avatar for customers and Cairo professionals.
///
/// Replaces temporary `lh3.googleusercontent.com` URLs with deterministic
/// illustrated portraits matching Screen 03 (`Eng. Tarek Mansour`, `Hassan El-Sayed`, `Salma`).
class FixoArtisanAvatar extends StatelessWidget {
  const FixoArtisanAvatar({
    super.key,
    required this.identifier,
    this.size = 52,
  });

  final String identifier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isHassan = identifier.toLowerCase().contains('hassan');
    final isCustomer =
        identifier.toLowerCase().contains('salma') ||
        identifier.toLowerCase().contains('customer');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: FixoShadows.level1CardResting,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCustomer
              ? const [Color(0xFFDCEBE3), Color(0xFFB5D4C6)]
              : isHassan
              ? const [Color(0xFFE7DEC8), Color(0xFFC4B699)]
              : const [Color(0xFFE5DFCE), Color(0xFFB9C7BC)],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _PortraitAvatarPainter(
            shirtColor: isCustomer
                ? const Color(0xFF245B4B)
                : isHassan
                ? const Color(0xFF1A3047) // Navy HVAC uniform
                : const Color(0xFF173F35), // Dark green FIXO polo
            hasHvacGaugeBadge: isHassan,
          ),
        ),
      ),
    );
  }
}

class _PortraitAvatarPainter extends CustomPainter {
  const _PortraitAvatarPainter({
    required this.shirtColor,
    required this.hasHvacGaugeBadge,
  });

  final Color shirtColor;
  final bool hasHvacGaugeBadge;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Shoulders / polo collar
    final shoulderPath = Path()
      ..moveTo(size.width * 0.14, size.height)
      ..quadraticBezierTo(
        centerX,
        size.height * 0.62,
        size.width * 0.86,
        size.height,
      )
      ..close();
    canvas.drawPath(shoulderPath, Paint()..color = shirtColor);

    // Subtle lime FIXO chest emblem
    canvas.drawCircle(
      Offset(size.width * 0.63, size.height * 0.84),
      size.width * 0.045,
      Paint()
        ..color = hasHvacGaugeBadge
            ? const Color(0xFF6BB5FF)
            : FixoColors.limeAccent,
    );

    // Head silhouette
    canvas.drawCircle(
      Offset(centerX, size.height * 0.40),
      size.width * 0.21,
      Paint()..color = const Color(0xFFC89B7B),
    );

    // Hair / beard arc
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(centerX, size.height * 0.37),
        radius: size.width * 0.215,
      ),
      3.14,
      3.14,
      true,
      Paint()..color = const Color(0xFF23201E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hero Seasonal Promo Card (`Summer AC Deep Clean & Gas Refill — Flat 350 EGP`) from Screen 03.
class SeasonalPromoHeroCard extends StatelessWidget {
  const SeasonalPromoHeroCard({
    super.key,
    required this.offer,
    required this.isArabic,
    required this.onBookNow,
  });

  final ServiceOfferModel offer;
  final bool isArabic;
  final VoidCallback onBookNow;

  @override
  Widget build(BuildContext context) => FixoTilt3D(
    maxTilt: 0.07,
    glareOpacity: 0.16,
    borderRadius: FixoRadius.borderRadiusLg,
    child: _card(context),
  );

  Widget _card(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      key: const Key('card-seasonal-promo'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F5446),
            Color(0xFF11332A),
            Color(0xFF071914),
          ],
        ),
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(
          color: FixoColors.goldAccent.withValues(alpha: 0.42),
          width: 1.1,
        ),
        boxShadow: FixoShadows.level2Interactive,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -36,
            child: IgnorePointer(
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.limeAccent.withValues(alpha: 0.11),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.limeAccent,
                        borderRadius: FixoRadius.borderRadiusPill,
                      ),
                      child: Text(
                        (offer.localizedBadge(isArabic) ?? 'SEASONAL PEAK')
                            .toUpperCase(),
                        style:
                            FixoTypography.labelMd(
                              color: FixoColors.onTertiaryFixed,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  offer.localizedTitle(isArabic),
                  style: FixoTypography.headlineMd(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  offer.localizedDescription(isArabic),
                  style: FixoTypography.bodyMd(
                    color: FixoColors.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isArabic ? 'سعر ثابت' : 'Flat',
                          style: FixoTypography.labelMd(
                            color: FixoColors.surfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${offer.flatPriceEgp}',
                          style: FixoTypography.priceDisplay(
                            color: palette.limeAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'EGP',
                          style: FixoTypography.labelMd(
                            color: palette.limeAccent,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Material(
                      color: palette.limeAccent,
                      borderRadius: FixoRadius.borderRadiusMd,
                      child: InkWell(
                        key: const Key('btn-book-seasonal-promo'),
                        onTap: onBookNow,
                        borderRadius: FixoRadius.borderRadiusMd,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isArabic ? 'احجز الآن' : 'Book Now',
                                style: FixoTypography.labelLg(
                                  color: FixoColors.onTertiaryFixed,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: FixoColors.onTertiaryFixed,
                              ),
                            ],
                          ),
                        ),
                      ),
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

/// Service category tile in the 2-column grid on Screen 03 (`h-36 rounded-2xl`).
class ServiceCategoryGridTile extends StatelessWidget {
  const ServiceCategoryGridTile({
    super.key,
    required this.category,
    required this.isArabic,
    required this.isSelected,
    required this.onTap,
  });

  final ServiceCategoryModel category;
  final bool isArabic;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FixoTilt3D(
    maxTilt: 0.14,
    borderRadius: FixoRadius.borderRadiusLg,
    child: _card(context),
  );

  Widget _card(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: palette.cardSurface,
      borderRadius: FixoRadius.borderRadiusLg,
      child: InkWell(
        key: Key('category-tile-${category.slug}'),
        onTap: onTap,
        borderRadius: FixoRadius.borderRadiusLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: 138),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: FixoRadius.borderRadiusLg,
            border: Border.all(
              color: isSelected
                  ? (isDark ? palette.limeAccent : palette.primaryBrand)
                  : palette.subtleBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: FixoShadows.level1CardResting,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primaryBrand
                          : palette.surfaceHigh,
                      borderRadius: FixoRadius.borderRadiusMd,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      mapCategoryIconName(category.iconName),
                      size: 22,
                      color: isSelected
                          ? palette.limeAccent
                          : palette.deepForest,
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 6),
                      child: Text(
                        '~${category.startingPriceEgp} EGP',
                        textAlign: TextAlign.end,
                        style: FixoTypography.labelMd(
                          color: isDark
                              ? FixoColors.goldBright
                              : FixoColors.secondary,
                          tabularFigures: true,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.localizedName(isArabic),
                    style: FixoTypography.labelLg(
                      color: palette.inkText,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.localizedSubtitle(isArabic),
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bundle Save Card (`Home Safety Inspection — 450 EGP`) from Screen 03.
class BundleSaveInspectionCard extends StatelessWidget {
  const BundleSaveInspectionCard({
    super.key,
    required this.offer,
    required this.isArabic,
    required this.onTap,
  });

  final ServiceOfferModel offer;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Material(
      color: palette.surfaceHigh,
      borderRadius: FixoRadius.borderRadiusLg,
      child: InkWell(
        key: const Key('card-bundle-save'),
        onTap: onTap,
        borderRadius: FixoRadius.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.primaryBrand,
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.health_and_safety_outlined,
                  size: 26,
                  color: palette.limeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.limeAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            offer.localizedBadge(isArabic) ?? 'BUNDLE SAVE',
                            style:
                                FixoTypography.labelMd(
                                  color: FixoColors.onTertiaryFixed,
                                ).copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Text(
                          offer.localizedTitle(isArabic),
                          style: FixoTypography.labelLg(
                            color: palette.inkText,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.localizedDescription(isArabic),
                      style: FixoTypography.bodySm(color: palette.mutedText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${offer.flatPriceEgp}',
                    style: FixoTypography.priceDisplay(
                      color: palette.deepForest,
                    ),
                  ),
                  Text(
                    'EGP',
                    style: FixoTypography.labelMd(
                      color: palette.mutedText,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive Service Offering Card for CustomerHomePage catalog & search results.
class ServiceOfferCatalogCard extends StatelessWidget {
  const ServiceOfferCatalogCard({
    super.key,
    required this.offer,
    required this.isArabic,
    required this.onTap,
    this.categoryIconName,
  });

  final ServiceOfferModel offer;
  final bool isArabic;
  final VoidCallback onTap;
  final String? categoryIconName;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = mapCategoryIconName(categoryIconName ?? '');

    return Material(
      color: palette.cardSurface,
      borderRadius: FixoRadius.borderRadiusMd,
      child: InkWell(
        key: Key('home-service-card-${offer.id}'),
        onTap: onTap,
        borderRadius: FixoRadius.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(FixoSpacing.md),
          decoration: BoxDecoration(
            borderRadius: FixoRadius.borderRadiusMd,
            border: Border.all(
              color: palette.subtleBorder.withValues(alpha: isDark ? 0.85 : 0.7),
              width: 1,
            ),
            boxShadow: FixoShadows.level1CardResting,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? palette.surfaceHigh : palette.surfaceContainer,
                  borderRadius: FixoRadius.borderRadiusSm,
                  border: Border.all(
                    color: palette.subtleBorder.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  size: 22,
                  color: isDark ? palette.limeAccent : palette.deepForest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.localizedTitle(isArabic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FixoTypography.labelLg(
                        color: palette.inkText,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      offer.localizedDescription(isArabic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FixoTypography.bodySm(color: palette.mutedText),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceHigh,
                            borderRadius: FixoRadius.borderRadiusPill,
                          ),
                          child: Text(
                            '${offer.flatPriceEgp} ${isArabic ? 'ج.م' : 'EGP'}',
                            style: FixoTypography.labelMd(
                              color: isDark
                                  ? palette.limeAccent
                                  : palette.deepForest,
                              tabularFigures: true,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '• ${offer.estimatedDurationMins} ${isArabic ? 'دقيقة' : 'min'}',
                          style: FixoTypography.bodySm(
                            color: palette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? palette.limeAccent : palette.primaryBrand,
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                child: Text(
                  isArabic ? 'احجز' : 'Book',
                  style: FixoTypography.labelMd(
                    color: isDark ? FixoColors.onTertiaryFixed : Colors.white,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recommended Professional card (`Eng. Tarek Mansour — 250 EGP`, `Hassan El-Sayed — 350 EGP`) from Screen 03.
class RecommendedProCard extends StatelessWidget {
  const RecommendedProCard({
    super.key,
    required this.professional,
    required this.isArabic,
    required this.onBookSlot,
  });

  final ProfessionalCardModel professional;
  final bool isArabic;
  final VoidCallback onBookSlot;

  @override
  Widget build(BuildContext context) => FixoTilt3D(
    maxTilt: 0.06,
    glareOpacity: 0.14,
    borderRadius: FixoRadius.borderRadiusLg,
    child: _card(context),
  );

  Widget _card(BuildContext context) {
    final palette = context.fixoPalette;
    final isFastResponder = professional.isFastResponder;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: Key('pro-card-${professional.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: FixoRadius.borderRadiusLg,
        border: Border.all(color: palette.subtleBorder, width: 1),
        boxShadow: FixoShadows.level1CardResting,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FixoArtisanAvatar(identifier: professional.fullNameEn),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.localizedName(isArabic),
                      style: FixoTypography.labelLg(
                        color: palette.inkText,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${professional.localizedSpecialty(isArabic)} • ${professional.localizedZones(isArabic)}',
                      style: FixoTypography.bodySm(color: palette.mutedText),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: isDark
                              ? palette.limeAccent
                              : const Color(0xFF313D00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          professional.reviewsCount == 0
                              ? (isArabic
                                    ? 'لا توجد تقييمات بعد'
                                    : 'No reviews yet')
                              : '${professional.ratingAvg}',
                          style: FixoTypography.labelMd(
                            color: palette.inkText,
                            tabularFigures: true,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        if (professional.reviewsCount > 0)
                          Flexible(
                            child: Text(
                              isArabic
                                  ? '(${professional.reviewsCount} تقييم)'
                                  : '(${professional.reviewsCount} reviews)',
                              style: FixoTypography.bodySm(
                                color: palette.mutedText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isArabic ? 'تقديري' : 'Est.',
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${professional.estimatedPriceEgp}',
                        style: FixoTypography.headlineSm(
                          color: palette.deepForest,
                          tabularFigures: true,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'EGP',
                        style: FixoTypography.labelMd(
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (professional.localizedBadge(isArabic).trim().isNotEmpty)
                !isFastResponder
                    ? FixoHolographicProBadge(
                        isArabic: isArabic,
                        badgeText: professional.localizedBadge(isArabic),
                        isCompact: true,
                      )
                    : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isFastResponder
                        ? FixoColors.secondaryContainer
                        : palette.surfaceHigh,
                    borderRadius: FixoRadius.borderRadiusPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFastResponder
                            ? Icons.bolt_rounded
                            : Icons.verified_user_rounded,
                        size: 14,
                        color: isFastResponder
                            ? FixoColors.onSecondaryContainer
                            : palette.deepForest,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          professional.localizedBadge(isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FixoTypography.labelMd(
                            color: isFastResponder
                                ? FixoColors.onSecondaryContainer
                                : palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              Material(
                color: palette.primaryBrand,
                borderRadius: FixoRadius.borderRadiusMd,
                child: InkWell(
                  key: Key('btn-book-pro-${professional.id}'),
                  onTap: onBookSlot,
                  borderRadius: FixoRadius.borderRadiusMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      isArabic ? 'احجز موعداً' : 'Book Slot',
                      style: FixoTypography.labelMd(
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Residential Facility Concierge Card (`Need a custom enterprise quote?`) from Screen 03.
class ConciergeQuoteBanner extends StatelessWidget {
  const ConciergeQuoteBanner({
    super.key,
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: FixoRadius.borderRadiusLg,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 24,
            color: FixoColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'إزاي تحجز خدمتك؟' : 'How does booking work?',
                  style: FixoTypography.labelMd(
                    color: palette.inkText,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'اختار الخدمة والميعاد، والدفع بعد التنفيذ'
                      : 'Choose a service and time. Pay after service.',
                  style: FixoTypography.bodySm(color: palette.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: palette.cardSurface,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  isArabic
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.deepForest,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Customer 4-Tab Bottom Navigation Bar (`Home`, `Orders`, `Chat`, `Profile`)
/// styled as a compact, draggable Apple VisionOS / iOS 27 Liquid Glass Dock.
class FixoCustomerBottomNav extends StatefulWidget {
  const FixoCustomerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.isArabic,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isArabic;

  @override
  State<FixoCustomerBottomNav> createState() => _FixoCustomerBottomNavState();
}

class _FixoCustomerBottomNavState extends State<FixoCustomerBottomNav> {
  double? _dragTabPosition;
  double _barTranslateX = 0.0;
  bool _isDragging = false;

  void _updateDragFromLocalDx(
    double localDx,
    double trackWidth,
    bool isRtl,
  ) {
    if (trackWidth <= 0) return;
    final normalized = (localDx / trackWidth).clamp(0.0, 1.0);
    final effectiveFraction = isRtl ? (1.0 - normalized) : normalized;
    final tabPos = (effectiveFraction * 3.0).clamp(0.0, 3.0);
    final centerDelta = ((localDx / trackWidth) - 0.5) * 14.0;
    setState(() {
      _isDragging = true;
      _dragTabPosition = tabPos;
      _barTranslateX = centerDelta.clamp(-10.0, 10.0);
    });
  }

  void _finishDrag() {
    final targetPos = _dragTabPosition;
    setState(() {
      _isDragging = false;
      _dragTabPosition = null;
      _barTranslateX = 0.0;
    });
    if (targetPos != null) {
      final targetIndex = targetPos.round().clamp(0, 3);
      if (targetIndex != widget.currentIndex) {
        widget.onTabSelected(targetIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final items = <_NavTabItem>[
      _NavTabItem(
        keyName: 'nav-tab-home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: widget.isArabic ? 'الرئيسية' : 'Home',
      ),
      _NavTabItem(
        keyName: 'nav-tab-orders',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: widget.isArabic ? 'طلباتي' : 'Orders',
      ),
      _NavTabItem(
        keyName: 'nav-tab-chat',
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: widget.isArabic ? 'المحادثات' : 'Chat',
      ),
      _NavTabItem(
        keyName: 'nav-tab-profile',
        icon: Icons.account_circle_outlined,
        activeIcon: Icons.account_circle_rounded,
        label: widget.isArabic ? 'حسابي' : 'Profile',
      ),
    ];

    final activePosition =
        (_dragTabPosition ?? widget.currentIndex.toDouble()).clamp(0.0, 3.0);
    final activeIndex = activePosition.round().clamp(0, 3);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        FixoSpacing.md,
        0,
        FixoSpacing.md,
        FixoSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 316),
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isDragging ? 30 : 260),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(
              _barTranslateX,
              _isDragging ? -2.0 : 0.0,
              0.0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pillWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 316.0;
                final innerTrackWidth = (pillWidth - 8.0).clamp(160.0, 308.0);
                final tabWidth = innerTrackWidth / items.length;
                final lensLeft = isRtl
                    ? ((3.0 - activePosition) * tabWidth)
                    : (activePosition * tabWidth);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) => _updateDragFromLocalDx(
                    details.localPosition.dx - 4.0,
                    innerTrackWidth,
                    isRtl,
                  ),
                  onHorizontalDragUpdate: (details) => _updateDragFromLocalDx(
                    details.localPosition.dx - 4.0,
                    innerTrackWidth,
                    isRtl,
                  ),
                  onHorizontalDragEnd: (_) => _finishDrag(),
                  onHorizontalDragCancel: _finishDrag,
                  child: LiquidGlassLayer(
                    key: const Key('customer-bottom-nav'),
                    borderRadius: FixoRadius.borderRadiusPill,
                    blurSigma: 28.0,
                    tintOpacity: isDark ? 0.54 : 0.72,
                    specularIntensity: 0.76,
                    borderWidth: 1.15,
                    enableInteractiveCaustics: true,
                    padding: const EdgeInsets.all(FixoSpacing.xs),
                    child: SizedBox(
                      height: 50,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Top Prismatic Specular Rim Reflection
                          Positioned(
                            top: 0,
                            left: 24,
                            right: 24,
                            child: IgnorePointer(
                              child: Container(
                                height: 1.0,
                                decoration: BoxDecoration(
                                  borderRadius: FixoRadius.borderRadiusPill,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(
                                        alpha: isDark ? 0.48 : 0.88,
                                      ),
                                      FixoColors.goldBright.withValues(
                                        alpha: isDark ? 0.42 : 0.35,
                                      ),
                                      Colors.white.withValues(
                                        alpha: isDark ? 0.48 : 0.88,
                                      ),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Sliding Apple VisionOS Liquid Glass Lens Pill
                          AnimatedPositioned(
                            duration: Duration(
                              milliseconds: _isDragging ? 16 : 240,
                            ),
                            curve: _isDragging
                                ? Curves.linear
                                : Curves.easeOutCubic,
                            left: lensLeft,
                            top: 1,
                            bottom: 1,
                            width: tabWidth,
                            child: IgnorePointer(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 180),
                                scale: _isDragging ? 1.06 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: FixoRadius.borderRadiusPill,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isDark
                                          ? [
                                              Colors.white.withValues(
                                                alpha: _isDragging ? 0.28 : 0.20,
                                              ),
                                              palette.primaryBrand.withValues(
                                                alpha: 0.52,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ]
                                          : [
                                              Colors.white.withValues(
                                                alpha: 0.96,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.74,
                                              ),
                                              palette.primaryBrand.withValues(
                                                alpha: 0.10,
                                              ),
                                            ],
                                      stops: const [0.0, 0.52, 1.0],
                                    ),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(
                                              alpha: _isDragging ? 0.52 : 0.32,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark
                                                ? palette.limeAccent
                                                : palette.primaryBrand)
                                            .withValues(
                                              alpha: _isDragging
                                                  ? 0.28
                                                  : (isDark ? 0.16 : 0.10),
                                            ),
                                        blurRadius: _isDragging ? 16 : 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 4 Interactive Tab Items
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List<Widget>.generate(
                              items.length,
                              (index) {
                                final item = items[index];
                                final isSelected = index == activeIndex;
                                final fgColor = isSelected
                                    ? (isDark
                                          ? palette.limeAccent
                                          : palette.deepForest)
                                    : palette.mutedText;

                                return Expanded(
                                  child: Semantics(
                                    selected: isSelected,
                                    button: true,
                                    child: InkWell(
                                      key: Key(item.keyName),
                                      borderRadius: FixoRadius.borderRadiusPill,
                                      onTap: () => widget.onTabSelected(index),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: FixoSpacing.xxs,
                                          vertical: 3,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isSelected
                                                  ? item.activeIcon
                                                  : item.icon,
                                              size: 19,
                                              color: fgColor,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              item.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  FixoTypography.labelSm(
                                                    color: fgColor,
                                                  ).copyWith(
                                                    fontSize: 10.5,
                                                    height: 1.1,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem {
  const _NavTabItem({
    required this.keyName,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String keyName;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
