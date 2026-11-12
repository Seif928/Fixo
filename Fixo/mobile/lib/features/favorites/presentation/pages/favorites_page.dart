import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../data/favorites_models.dart';
import '../../data/favorites_repository.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  int _tabIndex = 0; // 0 = Services, 1 = Professionals
  bool _loading = true;
  String? _error;
  List<FavoriteServiceItem> _services = [];
  List<FavoriteProfessionalItem> _professionals = [];
  final Set<String> _mutatingIds = {};

  bool get _isArabic => ref.watch(appLocaleProvider).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      final sPage = await repo.listFavoriteServices();
      final pPage = await repo.listFavoriteProfessionals();

      if (mounted) {
        setState(() {
          _services = sPage.items;
          _professionals = pPage.items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = _isArabic
              ? 'تعذر تحميل المفضلة. يرجى إعادة المحاولة.'
              : 'Could not load favorites. Please retry.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeService(FavoriteServiceItem item) async {
    if (_mutatingIds.contains(item.id)) return;
    setState(() => _mutatingIds.add(item.id));

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      await repo.removeFavoriteService(item.offeringId);
      if (mounted) {
        setState(() {
          _services.removeWhere((s) => s.id == item.id);
          _mutatingIds.remove(item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'تمت إزالة الخدمة من المفضلة'
                  : 'Removed from favorites',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _mutatingIds.remove(item.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'تعذر إزالة الخدمة. حاول مرة أخرى.'
                  : 'Could not remove service. Please retry.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeProfessional(FavoriteProfessionalItem item) async {
    if (_mutatingIds.contains(item.id)) return;
    setState(() => _mutatingIds.add(item.id));

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      await repo.removeFavoriteProfessional(item.proProfileId);
      if (mounted) {
        setState(() {
          _professionals.removeWhere((p) => p.id == item.id);
          _mutatingIds.remove(item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'تمت إزالة الفني من المفضلة'
                  : 'Removed technician from favorites',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _mutatingIds.remove(item.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'تعذر إزالة الفني. حاول مرة أخرى.'
                  : 'Could not remove technician. Please retry.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final textTheme = Theme.of(context).textTheme;
    final ar = _isArabic;

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        title: Text(
          ar ? 'المفضلة' : 'Favorites',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.inkText,
          ),
        ),
        centerTitle: false,
        backgroundColor: palette.surfaceContainer,
        elevation: 0,
        leading: BackButton(
          color: palette.inkText,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(FixoSpacing.md),
                  child: SegmentedButton<int>(
                    key: const Key('favorites-segmented-tabs'),
                    segments: [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text(
                          ar
                              ? 'الخدمات (${_services.length})'
                              : 'Services (${_services.length})',
                          key: const Key('favorites-tab-services'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        icon: const Icon(Icons.home_repair_service_outlined),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text(
                          ar
                              ? 'الفنيون (${_professionals.length})'
                              : 'Pros (${_professionals.length})',
                          key: const Key('favorites-tab-pros'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        icon: const Icon(Icons.person_pin_outlined),
                      ),
                    ],
                    selected: {_tabIndex},
                    onSelectionChanged: (set) {
                      setState(() => _tabIndex = set.first);
                    },
                  ),
                ),
                Expanded(
                  child: _buildBody(context, palette, textTheme, ar),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FixoPaletteExtension palette,
    TextTheme textTheme,
    bool ar,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(FixoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: FixoColors.coral,
                size: 48,
              ),
              const SizedBox(height: FixoSpacing.sm),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: palette.mutedText),
              ),
              const SizedBox(height: FixoSpacing.md),
              FilledButton.icon(
                key: const Key('favorites-error-retry'),
                onPressed: _loadFavorites,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tabIndex == 0) {
      if (_services.isEmpty) {
        return _buildEmptyState(
          key: const Key('favorites-empty-services'),
          icon: Icons.favorite_border_rounded,
          title: ar ? 'لا توجد خدمات مفضلة بعد' : 'No favorite services yet',
          subtitle: ar
              ? 'تصفح الخدمات واحفظ ما يناسبك للوصول السريع إليها لاحقاً.'
              : 'Browse services and save the ones you need for quick access.',
          palette: palette,
          textTheme: textTheme,
        );
      }
      return RefreshIndicator(
        onRefresh: _loadFavorites,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: FixoSpacing.md,
            vertical: FixoSpacing.sm,
          ),
          itemCount: _services.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: FixoSpacing.sm),
          itemBuilder: (context, index) {
            final item = _services[index];
            return _buildServiceCard(context, item, palette, textTheme, ar);
          },
        ),
      );
    } else {
      if (_professionals.isEmpty) {
        return _buildEmptyState(
          key: const Key('favorites-empty-pros'),
          icon: Icons.person_search_outlined,
          title: ar ? 'لا يوجد فنيون مفضلون بعد' : 'No favorite technicians yet',
          subtitle: ar
              ? 'احفظ الفنيين المتميزين للوصول السريع عند تكرار طلب الخدمات.'
              : 'Save top-rated technicians for quick selection when booking services.',
          palette: palette,
          textTheme: textTheme,
        );
      }
      return RefreshIndicator(
        onRefresh: _loadFavorites,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: FixoSpacing.md,
            vertical: FixoSpacing.sm,
          ),
          itemCount: _professionals.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: FixoSpacing.sm),
          itemBuilder: (context, index) {
            final item = _professionals[index];
            return _buildProCard(context, item, palette, textTheme, ar);
          },
        ),
      );
    }
  }

  Widget _buildEmptyState({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required FixoPaletteExtension palette,
    required TextTheme textTheme,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(FixoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.surfaceContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 36, color: palette.mutedText),
            ),
            const SizedBox(height: FixoSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.inkText,
              ),
            ),
            const SizedBox(height: FixoSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: palette.mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    FavoriteServiceItem item,
    FixoPaletteExtension palette,
    TextTheme textTheme,
    bool ar,
  ) {
    final isMutating = _mutatingIds.contains(item.id);

    return FixoSurfaceCard(
      key: Key('favorite-service-card-${item.id}'),
      padding: const EdgeInsets.all(FixoSpacing.md),
      borderRadius: FixoRadius.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!item.isAvailable)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FixoColors.coral.withValues(alpha: 0.12),
                          borderRadius: FixoRadius.borderRadiusPill,
                        ),
                        child: Text(
                          ar ? 'غير متوفرة حالياً' : 'Currently unavailable',
                          style: textTheme.labelSmall?.copyWith(
                            color: FixoColors.coral,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      item.localizedTitle(ar),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.inkText,
                      ),
                    ),
                    if (item.localizedDescription(ar).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.localizedDescription(ar),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                key: Key('remove-favorite-service-${item.id}'),
                tooltip: ar ? 'إزالة من المفضلة' : 'Remove favorite',
                icon: isMutating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.favorite_rounded,
                        color: FixoColors.coral,
                        size: 22,
                      ),
                onPressed: isMutating ? null : () => _removeService(item),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.sm),
          Divider(height: 1, color: palette.subtleBorder),
          const SizedBox(height: FixoSpacing.sm),
          Row(
            children: [
              Text(
                '${item.flatPriceEgp} ${ar ? 'ج.م' : 'EGP'}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.primaryBrand,
                ),
              ),
              const Spacer(),
              if (item.isAvailable)
                FilledButton.icon(
                  key: Key('book-favorite-service-${item.id}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    backgroundColor: palette.primaryBrand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: FixoRadius.borderRadiusMd,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () {
                    context.push(
                      AppRoutes.createBooking,
                      extra: {'offering': item.toServiceOfferModel()},
                    );
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 14),
                  label: Text(ar ? 'احجز الآن' : 'Book now'),
                )
              else
                OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: FixoRadius.borderRadiusMd,
                    ),
                  ),
                  child: Text(ar ? 'غير متاحة للحجز' : 'Not bookable'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProCard(
    BuildContext context,
    FavoriteProfessionalItem item,
    FixoPaletteExtension palette,
    TextTheme textTheme,
    bool ar,
  ) {
    final isMutating = _mutatingIds.contains(item.id);

    return FixoSurfaceCard(
      key: Key('favorite-pro-card-${item.id}'),
      padding: const EdgeInsets.all(FixoSpacing.md),
      borderRadius: FixoRadius.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.primaryBrand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_rounded,
                  color: palette.primaryBrand,
                  size: 24,
                ),
              ),
              const SizedBox(width: FixoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!item.isAvailable)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FixoColors.coral.withValues(alpha: 0.12),
                          borderRadius: FixoRadius.borderRadiusPill,
                        ),
                        child: Text(
                          ar ? 'غير متوفر حالياً' : 'Currently unavailable',
                          style: textTheme.labelSmall?.copyWith(
                            color: FixoColors.coral,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      item.localizedFullName(ar),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.inkText,
                      ),
                    ),
                    if (item.localizedSpecialty(ar).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.localizedSpecialty(ar),
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rate_rounded,
                          size: 16,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.ratingAvg > 0
                              ? item.ratingAvg.toStringAsFixed(1)
                              : (ar ? 'جديد' : 'New'),
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.inkText,
                          ),
                        ),
                        if (item.completedJobsCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${item.completedJobsCount} ${ar ? 'خدمة منجزة' : 'jobs'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.mutedText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('remove-favorite-pro-${item.id}'),
                tooltip: ar ? 'إزالة من المفضلة' : 'Remove technician',
                icon: isMutating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.favorite_rounded,
                        color: FixoColors.coral,
                        size: 22,
                      ),
                onPressed: isMutating ? null : () => _removeProfessional(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
