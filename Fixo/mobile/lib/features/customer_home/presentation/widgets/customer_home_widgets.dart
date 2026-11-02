import 'package:flutter/material.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../domain/marketplace_models.dart';

/// Maps Stitch Material Symbol names to native Flutter `IconData`.
IconData mapCategoryIconName(String iconName) {
  switch (iconName) {
    case 'mode_fan':
      return Icons.ac_unit_rounded;
    case 'plumbing':
      return Icons.plumbing_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'cleaning_services':
      return Icons.cleaning_services_rounded;
    case 'handyman':
      return Icons.handyman_rounded;
    case 'format_paint':
      return Icons.format_paint_rounded;
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
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;

    return Container(
      key: const Key('card-seasonal-promo'),
      decoration: BoxDecoration(
        color: palette.primaryBrand,
        borderRadius: FixoRadius.borderRadiusLg,
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
  Widget build(BuildContext context) {
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
                          color: FixoColors.secondary,
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
  Widget build(BuildContext context) {
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
                          '${professional.ratingAvg}',
                          style: FixoTypography.labelMd(
                            color: palette.inkText,
                            tabularFigures: true,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
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
              Container(
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

/// Customer 4-Tab Bottom Navigation Bar (`Home`, `Orders`, `Chat`, `Profile`) from Screen 03.
class FixoCustomerBottomNav extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final items = <_NavTabItem>[
      _NavTabItem(
        keyName: 'nav-tab-home',
        icon: Icons.home_rounded,
        label: isArabic ? 'الرئيسية' : 'Home',
      ),
      _NavTabItem(
        keyName: 'nav-tab-orders',
        icon: Icons.receipt_long_rounded,
        label: isArabic ? 'طلباتي' : 'Orders',
      ),
      _NavTabItem(
        keyName: 'nav-tab-chat',
        icon: Icons.chat_bubble_outline_rounded,
        label: isArabic ? 'المحادثات' : 'Chat',
      ),
      _NavTabItem(
        keyName: 'nav-tab-profile',
        icon: Icons.account_circle_outlined,
        label: isArabic ? 'حسابي' : 'Profile',
      ),
    ];

    return Container(
      key: const Key('customer-bottom-nav'),
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: palette.subtleBorder, width: 1)),
        boxShadow: FixoShadows.level2Interactive,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              final fgColor = isSelected
                  ? palette.deepForest
                  : palette.mutedText;

              return Expanded(
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  child: InkWell(
                    key: Key(item.keyName),
                    onTap: () => onTabSelected(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: isSelected ? 22 : 0,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? palette.limeAccent
                                : Colors.transparent,
                            borderRadius: FixoRadius.borderRadiusPill,
                          ),
                        ),
                        Icon(item.icon, size: 22, color: fgColor),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FixoTypography.labelMd(color: fgColor)
                              .copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
    required this.label,
  });

  final String keyName;
  final IconData icon;
  final String label;
}
