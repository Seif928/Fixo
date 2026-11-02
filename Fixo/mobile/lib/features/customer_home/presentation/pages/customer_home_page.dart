import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/customer_tab_navigation.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_buttons.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../chat/presentation/notification_sheet.dart';
import '../../domain/marketplace_models.dart';
import '../controllers/customer_home_controller.dart';
import '../widgets/customer_home_widgets.dart';

/// Native Flutter implementation of live Stitch Screen 03 (`03 — Customer Home`,
/// ID `ba52cf458e2a49b191b6912ea76117fa`).
class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCreateBooking({
    ServiceOfferModel? offering,
    ProfessionalCardModel? preferredPro,
  }) {
    context.push(
      AppRoutes.createBooking,
      extra: <String, dynamic>{
        'offering': ?offering,
        'preferredPro': ?preferredPro,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(customerHomeControllerProvider);
    final homeNotifier = ref.read(customerHomeControllerProvider.notifier);
    final locale = ref.watch(appLocaleProvider);
    final isArabic = locale.languageCode == 'ar';
    final palette = context.fixoPalette;

    if (_searchController.text != homeState.searchQuery) {
      _searchController.value = TextEditingValue(
        text: homeState.searchQuery,
        selection: TextSelection.collapsed(
          offset: homeState.searchQuery.length,
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      bottomNavigationBar: FixoCustomerBottomNav(
        currentIndex: 0,
        isArabic: isArabic,
        onTabSelected: (index) {
          homeNotifier.setActiveBottomTab(0);
          navigateCustomerTab(context, index);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top App Bar (Screen 03 h-16 header)
            _buildTopAppBar(
              context,
              homeState: homeState,
              homeNotifier: homeNotifier,
              isArabic: isArabic,
              palette: palette,
            ),

            // Scrollable Marketplace Body
            Expanded(
              child: RefreshIndicator(
                color: palette.primaryBrand,
                onRefresh: homeNotifier.loadFeed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Location Selector Pill & Search Input Bar
                          _buildLocationAndSearchSection(
                            context,
                            homeState: homeState,
                            homeNotifier: homeNotifier,
                            isArabic: isArabic,
                            palette: palette,
                          ),

                          if (homeState.isLoading)
                            _buildLoadingState(palette, isArabic)
                          else if (homeState.errorMessage != null)
                            _buildErrorState(
                              homeState.errorMessage!,
                              homeNotifier,
                              palette,
                              isArabic,
                            )
                          else if (homeState.isEmptySearchResult)
                            _buildEmptyState(homeNotifier, palette, isArabic)
                          else
                            _buildPopulatedMarketplace(
                              context,
                              homeState: homeState,
                              homeNotifier: homeNotifier,
                              isArabic: isArabic,
                              palette: palette,
                            ),
                        ],
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
  }

  Widget _buildTopAppBar(
    BuildContext context, {
    required CustomerHomeState homeState,
    required CustomerHomeController homeNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
      decoration: BoxDecoration(
        color: palette.canvasBackground.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(
            color: palette.subtleBorder.withValues(alpha: 0.65),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: InkWell(
              onTap: homeNotifier.cycleOrSelectZone,
              borderRadius: FixoRadius.borderRadiusSm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FixoBrandMark(showSubtitle: false, iconBoxSize: 32),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: FixoColors.secondary,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                isArabic ? 'القاهرة / الجيزة' : 'Cairo / Giza',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FixoTypography.labelMd(
                                  color: palette.mutedText,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: FixoColors.outline,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                key: const Key('btn-home-toggle-locale'),
                onPressed: () =>
                    ref.read(appLocaleProvider.notifier).toggleLocale(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  isArabic ? 'EN' : 'ع',
                  style: FixoTypography.labelMd(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                key: const Key('btn-home-notifications'),
                tooltip: isArabic ? 'الإشعارات' : 'Notifications',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const NotificationSheet(),
                ),
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: palette.deepForest,
                ),
              ),
              GestureDetector(
                key: const Key('btn-home-profile-avatar'),
                onTap: () async {
                  await context.push(AppRoutes.customerProfile);
                },
                child: FixoArtisanAvatar(
                  identifier:
                      ref.watch(authControllerProvider).session?.user.id ??
                      'FIXO',
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndSearchSection(
    BuildContext context, {
    required CustomerHomeState homeState,
    required CustomerHomeController homeNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    final activeZone = homeState.activeZone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(FixoSpacing.md, 12, FixoSpacing.md, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Material(
                  color: palette.surfaceContainer,
                  borderRadius: FixoRadius.borderRadiusPill,
                  child: InkWell(
                    key: const Key('location-picker-btn'),
                    onTap: homeNotifier.cycleOrSelectZone,
                    borderRadius: FixoRadius.borderRadiusPill,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: palette.deepForest,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              activeZone.localizedName(isArabic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FixoTypography.labelMd(
                                color: palette.deepForest,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 16,
                            color: palette.mutedText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (homeState.selectedCategorySlug != null ||
                  homeState.searchQuery.isNotEmpty)
                TextButton(
                  key: const Key('btn-clear-home-filters'),
                  onPressed: homeNotifier.clearFilters,
                  child: Text(
                    isArabic ? 'مسح الفلتر' : 'Reset',
                    style: FixoTypography.labelMd(
                      color: FixoColors.secondary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar with Filter Icon
          Container(
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: FixoRadius.borderRadiusMd,
              border: Border.all(color: palette.subtleBorder, width: 1),
              boxShadow: FixoShadows.level1CardResting,
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: FixoColors.outline,
                ),
                Expanded(
                  child: TextField(
                    key: const Key('input-customer-home-search'),
                    controller: _searchController,
                    onChanged: homeNotifier.updateSearchQuery,
                    style: FixoTypography.bodyMd(color: palette.inkText),
                    decoration: InputDecoration(
                      fillColor: Colors.transparent,
                      filled: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      hintText: isArabic
                          ? 'ابحث عن كهرباء، سباكة، صيانة تكييف...'
                          : 'Search electrical, plumbing, AC repair...',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Material(
                    color: palette.surfaceContainer,
                    borderRadius: FixoRadius.borderRadiusSm,
                    child: InkWell(
                      key: const Key('btn-search-filters'),
                      onTap: homeNotifier.clearFilters,
                      borderRadius: FixoRadius.borderRadiusSm,
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: palette.primaryBrand,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(FixoPaletteExtension palette, bool isArabic) {
    return Padding(
      key: const Key('customer-home-loading'),
      padding: const EdgeInsets.all(FixoSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircularProgressIndicator(color: palette.primaryBrand),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'جارٍ تحميل خدمات القاهرة والجيزة...'
                : 'Loading Cairo & Giza marketplace services...',
            textAlign: TextAlign.center,
            style: FixoTypography.bodyMd(color: palette.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    String message,
    CustomerHomeController notifier,
    FixoPaletteExtension palette,
    bool isArabic,
  ) {
    return Padding(
      key: const Key('customer-home-error'),
      padding: const EdgeInsets.all(FixoSpacing.md),
      child: FixoSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: FixoColors.error,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'تعذر تحميل بيانات الخدمات'
                        : 'Could not load marketplace services',
                    style: FixoTypography.headlineSm(color: palette.inkText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: FixoTypography.bodyMd(color: palette.mutedText),
            ),
            const SizedBox(height: 16),
            FixoPrimaryButton(
              key: const Key('btn-retry-home'),
              label: isArabic ? 'إعادة المحاولة' : 'Retry Connection',
              trailingIcon: Icons.refresh_rounded,
              onPressed: notifier.loadFeed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    CustomerHomeController notifier,
    FixoPaletteExtension palette,
    bool isArabic,
  ) {
    return Padding(
      key: const Key('customer-home-empty'),
      padding: const EdgeInsets.all(FixoSpacing.md),
      child: FixoSurfaceCard(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: palette.mutedText),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'لا توجد خدمات أو فنيون مطابقون لبحثك'
                  : 'No services or professionals match your search',
              textAlign: TextAlign.center,
              style: FixoTypography.headlineSm(color: palette.inkText),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'جرب البحث عن تكييف، سباكة، أو كهرباء في منطقتك.'
                  : 'Try searching for AC, plumbing, or electrical services in your zone.',
              textAlign: TextAlign.center,
              style: FixoTypography.bodySm(color: palette.mutedText),
            ),
            const SizedBox(height: 14),
            FixoSecondaryButton(
              key: const Key('btn-empty-clear-search'),
              label: isArabic ? 'عرض جميع الخدمات' : 'Show All Services',
              leadingIcon: Icons.clear_all_rounded,
              onPressed: notifier.clearFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedMarketplace(
    BuildContext context, {
    required CustomerHomeState homeState,
    required CustomerHomeController homeNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    final feed = homeState.feed!;
    final selectedCategory = homeState.selectedCategorySlug;
    final seasonalPromo =
        (selectedCategory == null ||
            feed.seasonalPromo?.categorySlug == selectedCategory)
        ? feed.seasonalPromo
        : null;
    final bundleOffer =
        (selectedCategory == null ||
            feed.bundleOffer?.categorySlug == selectedCategory)
        ? feed.bundleOffer
        : null;
    final categories = homeState.filteredCategories;
    final professionals = homeState.filteredProfessionals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Featured Seasonal Promo Card (Flat 350 EGP)
        if (seasonalPromo != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FixoSpacing.md,
              8,
              FixoSpacing.md,
              12,
            ),
            child: SeasonalPromoHeroCard(
              offer: seasonalPromo,
              isArabic: isArabic,
              onBookNow: () =>
                  _navigateToCreateBooking(offering: seasonalPromo),
            ),
          ),

        // 2. Select Service Category (6 Ready + 2-column grid)
        if (categories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FixoSpacing.md,
              8,
              FixoSpacing.md,
              10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        isArabic
                            ? 'اختر فئة الخدمة'
                            : 'Select Service Category',
                        style: FixoTypography.headlineSm(
                          color: palette.inkText,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isArabic
                              ? '${categories.length} متاحة'
                              : '${categories.length} Ready',
                          style: FixoTypography.labelMd(
                            color: palette.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: homeNotifier.clearFilters,
                  child: Text(
                    isArabic ? 'عرض الكل' : 'View All',
                    style: FixoTypography.labelMd(
                      color: FixoColors.secondary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 12.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: categories.map((category) {
                    return SizedBox(
                      width: itemWidth,
                      child: ServiceCategoryGridTile(
                        category: category,
                        isArabic: isArabic,
                        isSelected:
                            homeState.selectedCategorySlug == category.slug,
                        onTap: () => homeNotifier.selectCategory(category.slug),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],

        // 3. Bundle Save Card (Home Safety Inspection — 450 EGP)
        if (bundleOffer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FixoSpacing.md,
              20,
              FixoSpacing.md,
              0,
            ),
            child: BundleSaveInspectionCard(
              offer: bundleOffer,
              isArabic: isArabic,
              onTap: () => _navigateToCreateBooking(offering: bundleOffer),
            ),
          ),

        // 4. Top Rated Cairo Professionals
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FixoSpacing.md,
            24,
            FixoSpacing.md,
            12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الفنيون المتاحون' : 'Available Professionals',
                      style: FixoTypography.headlineSm(
                        color: palette.inkText,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (professionals.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        isArabic
                            ? 'تمت مراجعة الهوية وسجل الخبرة والتقييمات'
                            : 'Identity-reviewed, background checked & vetted',
                        style: FixoTypography.bodySm(color: palette.mutedText),
                      ),
                    ],
                  ],
                ),
              ),
              if (professionals.isNotEmpty)
                TextButton(
                  onPressed: homeNotifier.clearFilters,
                  child: Text(
                    isArabic ? 'استكشاف' : 'Explore',
                    style: FixoTypography.labelMd(
                      color: FixoColors.secondary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
        if (professionals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
            child: Column(
              children: [
                for (int i = 0; i < professionals.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  RecommendedProCard(
                    professional: professionals[i],
                    isArabic: isArabic,
                    onBookSlot: () => _navigateToCreateBooking(
                      preferredPro: professionals[i],
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
            child: FixoSurfaceCard(
              key: const Key('empty-professionals-card'),
              child: Padding(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 28,
                      color: palette.mutedText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'لا يوجد فنيون متاحون حاليًا.'
                            : 'No professionals available yet.',
                        style: FixoTypography.labelMd(
                          color: palette.inkText,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 5. Facility Concierge Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FixoSpacing.md,
            20,
            FixoSpacing.md,
            0,
          ),
          child: ConciergeQuoteBanner(
            isArabic: isArabic,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: FixoColors.primaryForest,
                  content: Text(
                    isArabic
                        ? 'اختار الخدمة، وضيف عنوانك وميعادك، وبعدها أكد الدفع نقداً بعد التنفيذ.'
                        : 'Choose a service, add your address and time, then confirm cash after service.',
                    style: FixoTypography.bodySm(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),

        // 6. Subtle Session / Sign-out Bar when authenticated
        if (ref.watch(authControllerProvider).isAuthenticated)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FixoSpacing.md,
              16,
              FixoSpacing.md,
              0,
            ),
            child: Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                key: const Key('btn-home-sign-out'),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go(AppRoutes.phoneAuth);
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: Text(
                  isArabic ? 'تسجيل الخروج' : 'Sign Out',
                  style: FixoTypography.labelMd(color: palette.mutedText),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
