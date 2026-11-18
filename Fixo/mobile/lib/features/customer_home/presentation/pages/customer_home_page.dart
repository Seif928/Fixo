import '../../../../core/theme/fixo_workspace_theme.dart';
import '../../../../core/widgets/workspace_heading.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/customer_tab_navigation.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/location/service_area_picker.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_buttons.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../../../core/widgets/fixo_liquid_glass_layer.dart';
import '../../../../core/widgets/fixo_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/profile_avatar.dart';
import '../../../chat/presentation/notification_sheet.dart';
import '../../domain/marketplace_models.dart';
import '../../data/marketplace_repository.dart';
import '../controllers/customer_home_controller.dart';
import '../widgets/customer_home_widgets.dart';
import '../widgets/cinematic_home_hero.dart';
import '../widgets/service_catalog_sheet.dart';

/// Native Flutter implementation of live Stitch Screen 03 (`03 — Customer Home`,
/// ID `ba52cf458e2a49b191b6912ea76117fa`).
class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  late final TextEditingController _searchController;
  bool _showAllCategories = false;
  bool _showAllServices = false;

  Future<void> _browseServices({ServiceCategoryModel? category}) async {
    final owner = ref.read(authControllerProvider).session?.user.id;
    final selected = await showModalBottomSheet<ServiceOfferModel>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => ServiceCatalogSheet(
        isArabic: ref.read(appLocaleProvider).languageCode == 'ar',
        category: category,
      ),
    );
    if (!mounted ||
        selected == null ||
        owner != ref.read(authControllerProvider).session?.user.id) {
      return;
    }
    _navigateToCreateBooking(offering: selected);
  }

  void _openCategory(ServiceCategoryModel category) {
    final controller = ref.read(customerHomeControllerProvider.notifier);
    if (ref.read(customerHomeControllerProvider).selectedCategorySlug !=
        category.slug) {
      controller.selectCategory(category.slug);
    }
    _browseServices(category: category);
  }

  Future<void> _chooseArea() async {
    final userId = ref.read(authControllerProvider).session?.user.id;
    final area = await showServiceAreaPicker(
      context,
      isArabic: ref.read(appLocaleProvider).languageCode == 'ar',
      initial: ref.read(customerHomeControllerProvider).selectedArea,
      startWithGovernorates: true,
    );
    if (!mounted ||
        area == null ||
        userId != ref.read(authControllerProvider).session?.user.id) {
      return;
    }
    await ref.read(customerHomeControllerProvider.notifier).selectArea(area);
  }

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

  Future<void> _chooseProfessionalService(
    ProfessionalCardModel professional,
  ) async {
    final owner = ref.read(authControllerProvider).session?.user.id;
    final repository = ref.read(marketplaceRepositoryProvider);
    final arabic = ref.read(appLocaleProvider).languageCode == 'ar';
    Future<CustomerHomeFeed> load() => repository.fetchCustomerHomeFeed(
      categoryId: professional.primaryCategoryId,
    );
    var request = load();
    final selected = await showModalBottomSheet<ServiceOfferModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final palette = context.fixoPalette;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Padding(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      arabic ? 'اختار الخدمة' : 'Choose a service',
                      style: FixoTypography.headlineSm(color: palette.inkText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      professional.localizedName(arabic),
                      style: FixoTypography.bodyMd(color: palette.mutedText),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<CustomerHomeFeed>(
                        future: request,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: FixoSecondaryButton(
                                label: arabic
                                    ? 'تعذر تحميل الخدمات، أعد المحاولة'
                                    : 'Could not load services. Retry',
                                onPressed: () => setSheetState(() {
                                  request = load();
                                }),
                              ),
                            );
                          }
                          final services = snapshot.data!.services
                              .where(
                                (service) =>
                                    service.categoryId ==
                                    professional.primaryCategoryId,
                              )
                              .toList();
                          if (services.isEmpty) {
                            return Center(
                              child: Text(
                                arabic
                                    ? 'لا توجد خدمات متاحة للفني حالياً'
                                    : 'No services available for this professional yet.',
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: services.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final service = services[index];
                              return ListTile(
                                key: Key('pro-service-${service.id}'),
                                title: Text(service.localizedTitle(arabic)),
                                subtitle: Text(
                                  '${service.flatPriceEgp} ${arabic ? 'ج.م' : 'EGP'}',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () =>
                                    Navigator.of(sheetContext).pop(service),
                              );
                            },
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
    );
    if (!mounted ||
        selected == null ||
        owner != ref.read(authControllerProvider).session?.user.id) {
      return;
    }
    _navigateToCreateBooking(offering: selected, preferredPro: professional);
  }

  @override
  Widget build(BuildContext context) => FixoWorkspaceTheme(
    workspace: FixoWorkspace.customer,
    child: Consumer(builder: (context, ref, _) => _buildPage(context, ref)),
  );

  Widget _buildPage(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(customerHomeControllerProvider);
    final homeNotifier = ref.read(customerHomeControllerProvider.notifier);
    final isArabic = ref.watch(
      appLocaleProvider.select((locale) => locale.languageCode == 'ar'),
    );
    final palette = context.fixoPalette;

    if (homeState.searchQuery.isEmpty &&
        !homeState.isSearching &&
        _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: palette.canvasBackground,
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 1000
          ? null
          : FixoCustomerBottomNav(
              key: const Key('customer-bottom-nav'),
              currentIndex: 0,
              isArabic: isArabic,
              onTabSelected: (index) {
                homeNotifier.setActiveBottomTab(0);
                navigateCustomerTab(context, index);
              },
            ),
      body: SafeArea(
        bottom: false,
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
                child: _buildScrollableBody(
                  context,
                  homeState: homeState,
                  homeNotifier: homeNotifier,
                  isArabic: isArabic,
                  palette: palette,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FixoBrandMark(
                  key: Key('home-brand'),
                  showSubtitle: false,
                  iconBoxSize: 28,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: InkWell(
                    key: const Key('home-governorate-picker'),
                    onTap: _chooseArea,
                    borderRadius: FixoRadius.borderRadiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 2,
                      ),
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
                                  homeState.selectedArea == null
                                      ? (isArabic
                                            ? 'اختار مكانك'
                                            : 'Choose your area')
                                      : (isArabic
                                            ? homeState
                                                  .selectedArea!
                                                  .governorateAr
                                            : homeState
                                                  .selectedArea!
                                                  .governorateEn),
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
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 1000)
            Row(
              key: const Key('desktop-web-navbar-links'),
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDesktopNavButton(
                  label: isArabic ? 'الرئيسية' : 'Home',
                  icon: Icons.home_rounded,
                  isActive: true,
                  palette: palette,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    homeNotifier.clearFilters();
                  },
                ),
                const SizedBox(width: 6),
                _buildDesktopNavButton(
                  label: isArabic ? 'الخدمات' : 'Services',
                  icon: Icons.grid_view_rounded,
                  isActive: _showAllServices,
                  palette: palette,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _showAllCategories = true;
                      _showAllServices = true;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _buildDesktopNavButton(
                  label: isArabic ? 'طلباتي' : 'Orders',
                  icon: Icons.receipt_long_rounded,
                  isActive: false,
                  palette: palette,
                  onTap: () => navigateCustomerTab(context, 1),
                ),
                const SizedBox(width: 6),
                _buildDesktopNavButton(
                  label: isArabic ? 'المحادثات' : 'Chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  isActive: false,
                  palette: palette,
                  onTap: () => navigateCustomerTab(context, 2),
                ),
              ],
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
              Builder(
                builder: (context) {
                  final avatar = ref.watch(
                    authControllerProvider.select(
                      (s) => (
                        id: s.session?.user.id ?? '',
                        hasAvatar: s.session?.user.hasAvatar ?? false,
                        version: s.session?.user.avatarVersion,
                      ),
                    ),
                  );
                  return GestureDetector(
                    key: const Key('btn-home-profile-avatar'),
                    onTap: () async {
                      await context.push(AppRoutes.customerProfile);
                    },
                    child: ProfileAvatar(
                      userId: avatar.id,
                      hasAvatar: avatar.hasAvatar,
                      version: avatar.version,
                      size: 32,
                    ),
                  );
                },
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
    final hMargin = FixoAdaptive.horizontalMargin(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(hMargin, 12, hMargin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar with Filter Icon
          if (homeState.selectedCategorySlug != null ||
              homeState.searchQuery.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('btn-clear-home-filters'),
                onPressed: homeNotifier.clearFilters,
                child: Text(isArabic ? 'مسح الفلتر' : 'Reset'),
              ),
            ),
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
                if (homeState.isSearching)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.deepForest,
                      ),
                    ),
                  )
                else if (homeState.searchQuery.isNotEmpty ||
                    _searchController.text.isNotEmpty)
                  IconButton(
                    key: const Key('btn-clear-search-input'),
                    visualDensity: VisualDensity.compact,
                    tooltip: isArabic ? 'مسح البحث' : 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      homeNotifier.clearFilters();
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: palette.mutedText,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Material(
                    color: palette.surfaceContainer,
                    borderRadius: FixoRadius.borderRadiusSm,
                    child: InkWell(
                      key: const Key('btn-search-filters'),
                      onTap: _browseServices,
                      borderRadius: FixoRadius.borderRadiusSm,
                      child: Tooltip(
                        message: isArabic ? 'كل الخدمات' : 'All services',
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: palette.deepForest,
                          ),
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
    return KeyedSubtree(
      key: const Key('customer-home-loading'),
      child: FixoMarketplaceSkeleton(isArabic: isArabic),
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

  Widget _buildScrollableBody(
    BuildContext context, {
    required CustomerHomeState homeState,
    required CustomerHomeController homeNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    final maxWidth = MediaQuery.sizeOf(context).width >= 1000 ? 1200.0 : 600.0;
    final locationBar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: WorkspaceHeading(
            workspace: FixoWorkspace.customer,
            isArabic: isArabic,
          ),
        ),
        _buildLocationAndSearchSection(
          context,
          homeState: homeState,
          homeNotifier: homeNotifier,
          isArabic: isArabic,
          palette: palette,
        ),
      ],
    );

    if (homeState.isLoading ||
        homeState.errorMessage != null ||
        homeState.isEmptySearchResult ||
        homeState.feed == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 92),
        child: Center(
          child: ConstrainedBox(
            key: const Key('home-marketplace-layout'),
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                locationBar,
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
                  _buildEmptyState(homeNotifier, palette, isArabic),
              ],
            ),
          ),
        ),
      );
    }

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
    final hasSearchOrCategory =
        homeState.searchQuery.trim().isNotEmpty || selectedCategory != null;
    final catalogServices = homeState.filteredServices
        .where((s) => s.id != seasonalPromo?.id && s.id != bundleOffer?.id)
        .toList();
    final visibleServices = _showAllServices
        ? catalogServices
        : catalogServices.take(hasSearchOrCategory ? 12 : 6).toList();
    final professionals = homeState.filteredProfessionals;
    final shouldVirtualize =
        visibleServices.length > 12 || professionals.length > 6;

    if (!shouldVirtualize) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 92),
        child: Center(
          child: ConstrainedBox(
            key: const Key('home-marketplace-layout'),
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                locationBar,
                ..._buildCompactMarketplaceChildren(
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
      );
    }

    return Center(
      child: ConstrainedBox(
        key: const Key('home-marketplace-layout'),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          scrollCacheExtent: const ScrollCacheExtent.pixels(600),
          slivers: [
            SliverToBoxAdapter(child: locationBar),
            ..._buildPopulatedMarketplaceSlivers(
              context,
              homeState: homeState,
              homeNotifier: homeNotifier,
              isArabic: isArabic,
              palette: palette,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 92)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCompactMarketplaceChildren(
    BuildContext context, {
    required CustomerHomeState homeState,
    required CustomerHomeController homeNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    final slivers = _buildPopulatedMarketplaceSlivers(
      context,
      homeState: homeState,
      homeNotifier: homeNotifier,
      isArabic: isArabic,
      palette: palette,
      forceCompactWidgets: true,
    );
    return [
      for (final sliver in slivers)
        if (sliver is SliverToBoxAdapter && sliver.child != null) sliver.child!,
    ];
  }

  List<Widget> _buildPopulatedMarketplaceSlivers(
    BuildContext context, {
    required CustomerHomeState homeState,
    required CustomerHomeController homeNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
    bool forceCompactWidgets = false,
  }) {
    final feed = homeState.feed!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final hasSearchOrCategory =
        homeState.searchQuery.trim().isNotEmpty || selectedCategory != null;
    final visibleCategories =
        (_showAllCategories || homeState.searchQuery.trim().isNotEmpty)
        ? categories
        : categories.take(8).toList();
    final catalogServices = homeState.filteredServices
        .where((s) => s.id != seasonalPromo?.id && s.id != bundleOffer?.id)
        .toList();
    final visibleServices = _showAllServices
        ? catalogServices
        : catalogServices.take(hasSearchOrCategory ? 12 : 6).toList();
    final categoryIconBySlug = <String, String>{
      for (final c in feed.categories) c.slug: c.iconName,
    };
    final virtualizeServices =
        !forceCompactWidgets && visibleServices.length > 12;
    final virtualizePros = !forceCompactWidgets && professionals.length > 6;

    final leadingLandingChildren = <Widget>[
      CinematicHomeHero(isArabic: isArabic, onBrowse: _browseServices),
      if (seasonalPromo != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: SeasonalPromoHeroCard(
            offer: seasonalPromo,
            isArabic: isArabic,
            onBookNow: () => _navigateToCreateBooking(offering: seasonalPromo),
          ),
        ),
      // 1B. Pinned Liquid Glass Category & Sort Bar
      _buildLiquidGlassFilterAndSortBar(
        context,
        homeState: homeState,
        homeNotifier: homeNotifier,
        categories: categories,
        isArabic: isArabic,
        palette: palette,
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
                      isArabic ? 'اختر فئة الخدمة' : 'Select Service Category',
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
                        style: FixoTypography.labelMd(color: palette.mutedText),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('btn-view-all-categories-and-services'),
                onPressed: () {
                  final hasActiveFilter =
                      homeState.selectedCategorySlug != null ||
                      homeState.searchQuery.trim().isNotEmpty;
                  if (hasActiveFilter) {
                    homeNotifier.clearFilters();
                    setState(() {
                      _showAllCategories = true;
                      _showAllServices = true;
                    });
                  } else {
                    final expandAll = !(_showAllCategories && _showAllServices);
                    setState(() {
                      _showAllCategories = expandAll;
                      _showAllServices = expandAll;
                    });
                  }
                },
                child: Text(
                  (_showAllCategories &&
                          _showAllServices &&
                          homeState.selectedCategorySlug == null &&
                          homeState.searchQuery.trim().isEmpty)
                      ? (isArabic ? 'عرض أقل' : 'Show Less')
                      : (isArabic ? 'عرض الكل' : 'View All'),
                  style: FixoTypography.labelMd(
                    color: isDark
                        ? FixoColors.goldBright
                        : FixoColors.secondary,
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
              final columns = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 760
                  ? 3
                  : 2;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: visibleCategories.map((category) {
                  return SizedBox(
                    width: itemWidth,
                    child: ServiceCategoryGridTile(
                      category: category,
                      isArabic: isArabic,
                      isSelected:
                          homeState.selectedCategorySlug == category.slug,
                      onTap: () => _openCategory(category),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        if (categories.length > 8 && homeState.searchQuery.trim().isEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
            child: Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                key: const Key('btn-toggle-all-categories'),
                onPressed: () => setState(() {
                  _showAllCategories = !_showAllCategories;
                }),
                icon: Icon(
                  _showAllCategories
                      ? Icons.expand_less_rounded
                      : Icons.grid_view_rounded,
                  size: 18,
                  color: FixoColors.secondary,
                ),
                label: Text(
                  _showAllCategories
                      ? (isArabic ? 'عرض أقسام أقل' : 'Show Less Categories')
                      : (isArabic
                            ? 'عرض كل الأقسام (${categories.length})'
                            : 'Show All Categories (${categories.length})'),
                  style: FixoTypography.labelMd(
                    color: FixoColors.secondary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ],
    ];

    Widget buildServiceCard(int index) {
      final service = visibleServices[index];
      return RepaintBoundary(
        child: ServiceOfferCatalogCard(
          offer: service,
          isArabic: isArabic,
          categoryIconName: categoryIconBySlug[service.categorySlug],
          onTap: () => _navigateToCreateBooking(offering: service),
        ),
      );
    }

    Widget buildProCard(int index) {
      final pro = professionals[index];
      return RepaintBoundary(
        child: RecommendedProCard(
          professional: pro,
          isArabic: isArabic,
          onBookSlot: () => _chooseProfessionalService(pro),
        ),
      );
    }

    Widget buildServicesHeader() => Padding(
      padding: const EdgeInsets.fromLTRB(
        FixoSpacing.md,
        20,
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
                  isArabic ? 'الخدمات المتاحة' : 'Available Services',
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
                        ? '${catalogServices.length} خدمة'
                        : '${catalogServices.length} Services',
                    style: FixoTypography.labelMd(color: palette.mutedText),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                key: const Key('btn-view-all-services-inline'),
                onPressed: () => setState(() {
                  _showAllServices = !_showAllServices;
                }),
                child: Text(
                  _showAllServices
                      ? (isArabic ? 'عرض أقل' : 'Show Less')
                      : (isArabic ? 'عرض الكل' : 'View All'),
                  style: FixoTypography.labelMd(
                    color: isDark
                        ? FixoColors.goldBright
                        : FixoColors.secondary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                key: const Key('btn-home-browse-all-services'),
                onPressed: _browseServices,
                child: Text(
                  isArabic ? 'تصفح الكل' : 'Browse All',
                  style: FixoTypography.labelMd(
                    color: isDark ? palette.limeAccent : FixoColors.secondary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    Widget buildShowAllServicesToggle() => Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
          child: Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              key: const Key('btn-toggle-all-services'),
              onPressed: () => setState(() {
                _showAllServices = !_showAllServices;
              }),
              icon: Icon(
                _showAllServices
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
                color: FixoColors.secondary,
              ),
              label: Text(
                _showAllServices
                    ? (isArabic ? 'عرض خدمات أقل' : 'Show Less Services')
                    : (isArabic
                          ? 'عرض كل الخدمات (${catalogServices.length})'
                          : 'Show All Services (${catalogServices.length})'),
                style: FixoTypography.labelMd(
                  color: FixoColors.secondary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );

    Widget buildBundleSection() => Padding(
      padding: const EdgeInsets.fromLTRB(FixoSpacing.md, 20, FixoSpacing.md, 0),
      child: BundleSaveInspectionCard(
        offer: bundleOffer!,
        isArabic: isArabic,
        onTap: () => _navigateToCreateBooking(offering: bundleOffer),
      ),
    );

    Widget buildProsHeader() => Padding(
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
                        ? 'تصفح الفنيين المتاحين حسب الفئة والمنطقة'
                        : 'Browse available professionals by category and zone',
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
    );

    Widget buildEmptyProsCard() => Padding(
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
    );

    Widget buildConciergeBanner() => Padding(
      padding: const EdgeInsets.fromLTRB(FixoSpacing.md, 20, FixoSpacing.md, 0),
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
    );

    if (!virtualizeServices && !virtualizePros) {
      return [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...leadingLandingChildren,
              if (catalogServices.isNotEmpty) ...[
                buildServicesHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FixoSpacing.md,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1000
                          ? 3
                          : constraints.maxWidth >= 700
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - 12 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          for (int i = 0; i < visibleServices.length; i++)
                            SizedBox(width: width, child: buildServiceCard(i)),
                        ],
                      );
                    },
                  ),
                ),
                if (catalogServices.length > visibleServices.length ||
                    _showAllServices)
                  buildShowAllServicesToggle(),
              ],
              if (bundleOffer != null) buildBundleSection(),
              buildProsHeader(),
              if (professionals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FixoSpacing.md,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 850 ? 2 : 1;
                      final width =
                          (constraints.maxWidth - 12 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (int i = 0; i < professionals.length; i++)
                            SizedBox(width: width, child: buildProCard(i)),
                        ],
                      );
                    },
                  ),
                )
              else
                buildEmptyProsCard(),
              buildConciergeBanner(),
            ],
          ),
        ),
      ];
    }

    Widget buildVirtualizedGridSliver({
      required int itemCount,
      required double wideBreakpoint,
      required int wideColumns,
      required double midBreakpoint,
      required int midColumns,
      required double rowSpacing,
      required Widget Function(int index) itemBuilder,
    }) {
      return SliverLayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              (constraints.crossAxisExtent - FixoSpacing.md * 2).clamp(
                1.0,
                double.infinity,
              );
          final columns = availableWidth >= wideBreakpoint
              ? wideColumns
              : availableWidth >= midBreakpoint
              ? midColumns
              : 1;
          final rowCount = (itemCount / columns).ceil();
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
            sliver: SliverList.builder(
              itemCount: rowCount,
              itemBuilder: (context, rowIndex) {
                final startIndex = rowIndex * columns;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex == rowCount - 1 ? 0 : rowSpacing,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: 12),
                        Expanded(
                          child: (startIndex + col) < itemCount
                              ? itemBuilder(startIndex + col)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: leadingLandingChildren,
        ),
      ),

      // 2B. Available Marketplace Services (Virtualized SliverList)
      if (catalogServices.isNotEmpty) ...[
        SliverToBoxAdapter(child: buildServicesHeader()),
        buildVirtualizedGridSliver(
          itemCount: visibleServices.length,
          wideBreakpoint: 1000,
          wideColumns: 3,
          midBreakpoint: 700,
          midColumns: 2,
          rowSpacing: 10,
          itemBuilder: buildServiceCard,
        ),
        if (catalogServices.length > visibleServices.length || _showAllServices)
          SliverToBoxAdapter(child: buildShowAllServicesToggle()),
      ],

      // 3. Bundle Save Card (Home Safety Inspection — 450 EGP)
      if (bundleOffer != null) SliverToBoxAdapter(child: buildBundleSection()),

      // 4. Top Rated Cairo Professionals (Virtualized SliverList)
      SliverToBoxAdapter(child: buildProsHeader()),
      if (professionals.isNotEmpty)
        buildVirtualizedGridSliver(
          itemCount: professionals.length,
          wideBreakpoint: 850,
          wideColumns: 2,
          midBreakpoint: 850,
          midColumns: 2,
          rowSpacing: 12,
          itemBuilder: buildProCard,
        )
      else
        SliverToBoxAdapter(child: buildEmptyProsCard()),

      // 5. Facility Concierge Banner
      SliverToBoxAdapter(child: buildConciergeBanner()),
    ];
  }

  Widget _buildDesktopNavButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required FixoPaletteExtension palette,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isActive
          ? (isDark ? FixoColors.primaryForest : palette.surfaceHigh)
          : Colors.transparent,
      borderRadius: FixoRadius.borderRadiusPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: FixoRadius.borderRadiusPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? (isDark ? FixoColors.limeAccent : palette.deepForest)
                    : palette.mutedText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style:
                    FixoTypography.labelMd(
                      color: isActive
                          ? (isDark ? Colors.white : palette.deepForest)
                          : palette.mutedText,
                    ).copyWith(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassFilterAndSortBar(
    BuildContext context, {
    required CustomerHomeState homeState,
    required CustomerHomeController homeNotifier,
    required List<ServiceCategoryModel> categories,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortOptions =
        <({String id, String labelAr, String labelEn, IconData icon})>[
          (
            id: 'default',
            labelAr: 'الكل',
            labelEn: 'All',
            icon: Icons.auto_awesome_rounded,
          ),
          (
            id: 'lowest_price',
            labelAr: 'الأقل سعرًا',
            labelEn: 'Lowest price',
            icon: Icons.sell_outlined,
          ),
          (
            id: 'fastest',
            labelAr: 'الأقصر مدة',
            labelEn: 'Shortest duration',
            icon: Icons.bolt_rounded,
          ),
        ];

    return Padding(
      key: const Key('pinned-liquid-glass-filter-bar'),
      padding: const EdgeInsets.fromLTRB(FixoSpacing.md, 4, FixoSpacing.md, 8),
      child: LiquidGlassLayer(
        borderRadius: FixoRadius.borderRadiusMd,
        blurSigma: 20.0,
        tintOpacity: isDark ? 0.45 : 0.68,
        specularIntensity: 0.55,
        borderWidth: 1.0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final opt in sortOptions) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: InkWell(
                    key: Key('sort-pill-${opt.id}'),
                    borderRadius: FixoRadius.borderRadiusPill,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      homeNotifier.selectSortMode(opt.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: homeState.sortMode == opt.id
                            ? FixoColors.primaryForest
                            : palette.surfaceContainer,
                        borderRadius: FixoRadius.borderRadiusPill,
                        border: Border.all(
                          color: homeState.sortMode == opt.id
                              ? FixoColors.limeAccent.withValues(alpha: 0.7)
                              : palette.subtleBorder,
                        ),
                      ),
                      child: Text(
                        isArabic ? opt.labelAr : opt.labelEn,
                        style: FixoTypography.labelSm(
                          color: homeState.sortMode == opt.id
                              ? FixoColors.limeAccent
                              : palette.inkText,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: palette.subtleBorder,
              ),
              for (final cat in categories.take(10))
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: InkWell(
                    key: Key('quick-cat-pill-${cat.slug}'),
                    borderRadius: FixoRadius.borderRadiusPill,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _openCategory(cat);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: homeState.selectedCategorySlug == cat.slug
                            ? FixoColors.secondaryForest
                            : Colors.transparent,
                        borderRadius: FixoRadius.borderRadiusPill,
                        border: Border.all(
                          color: homeState.selectedCategorySlug == cat.slug
                              ? FixoColors.goldBright
                              : palette.subtleBorder,
                        ),
                      ),
                      child: Text(
                        isArabic
                            ? 'قسم: ${cat.localizedName(true)}'
                            : 'Trade: ${cat.localizedName(false)}',
                        style: FixoTypography.labelSm(
                          color: homeState.selectedCategorySlug == cat.slug
                              ? Colors.white
                              : palette.mutedText,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
