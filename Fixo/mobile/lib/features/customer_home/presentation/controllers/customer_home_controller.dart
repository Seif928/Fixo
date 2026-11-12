import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/egypt_places.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/marketplace_models.dart';

String _normalizeSearchText(String input) {
  return input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
}

class CustomerHomeState {
  const CustomerHomeState({
    this.isLoading = true,
    this.isSearching = false,
    this.errorMessage,
    this.feed,
    this.selectedArea,
    this.selectedCategorySlug,
    this.searchQuery = '',
    this.sortMode = 'default',
    this.searchResults,
    this.activeBottomTab = 0,
  });

  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final CustomerHomeFeed? feed;
  final SelectedServiceArea? selectedArea;
  String? get selectedZoneSlug => selectedArea?.zoneSlug;
  final String? selectedCategorySlug;
  final String searchQuery;
  final String sortMode;
  final List<ServiceOfferModel>? searchResults;
  final int activeBottomTab;

  CoverageZoneModel? get activeZone {
    final zones = feed?.zones ?? const <CoverageZoneModel>[];
    for (final zone in zones) {
      if (zone.slug == selectedZoneSlug) {
        return zone;
      }
    }
    return null;
  }

  List<ServiceCategoryModel> get filteredCategories {
    final all = feed?.categories ?? const <ServiceCategoryModel>[];
    final q = _normalizeSearchText(searchQuery);
    if (q.isEmpty) {
      return all;
    }
    return all.where((cat) {
      final text = _normalizeSearchText(
        '${cat.nameEn} ${cat.nameAr} ${cat.subtitleEn} ${cat.subtitleAr} ${cat.slug}',
      );
      return text.contains(q);
    }).toList();
  }

  List<ProfessionalCardModel> get filteredProfessionals {
    var pros = (feed?.professionals ?? const <ProfessionalCardModel>[])
        .toList();
    if (selectedCategorySlug != null && selectedCategorySlug!.isNotEmpty) {
      pros = pros
          .where((p) => p.primaryCategorySlug == selectedCategorySlug)
          .toList();
    }
    final q = _normalizeSearchText(searchQuery);
    if (q.isNotEmpty) {
      pros = pros.where((p) {
        final text = _normalizeSearchText(
          '${p.fullNameEn} ${p.fullNameAr} ${p.specialtyEn} ${p.specialtyAr} ${p.zonesLabelEn} ${p.zonesLabelAr} ${p.primaryCategorySlug}',
        );
        return text.contains(q);
      }).toList();
    }
    if (sortMode == 'top_rated') {
      pros.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    } else if (sortMode == 'lowest_price') {
      pros.sort((a, b) => a.estimatedPriceEgp.compareTo(b.estimatedPriceEgp));
    } else if (sortMode == 'fastest') {
      pros.sort((a, b) {
        final aScore = (a.isOnline ? 2 : 0) + (a.isFastResponder ? 1 : 0);
        final bScore = (b.isOnline ? 2 : 0) + (b.isFastResponder ? 1 : 0);
        return bScore.compareTo(aScore);
      });
    }
    return pros;
  }

  List<ServiceOfferModel> get filteredServices {
    var services =
        (searchResults ?? feed?.services ?? const <ServiceOfferModel>[])
            .toList();
    if (selectedCategorySlug != null && selectedCategorySlug!.isNotEmpty) {
      services = services
          .where((s) => s.categorySlug == selectedCategorySlug)
          .toList();
    }
    final q = _normalizeSearchText(searchQuery);
    if (q.isNotEmpty) {
      services = services.where((s) {
        final text = _normalizeSearchText(
          '${s.titleEn} ${s.titleAr} ${s.descriptionEn} ${s.descriptionAr} ${s.categorySlug} ${s.slug}',
        );
        return text.contains(q);
      }).toList();
    }
    if (sortMode == 'lowest_price') {
      services.sort((a, b) => a.flatPriceEgp.compareTo(b.flatPriceEgp));
    } else if (sortMode == 'fastest') {
      services.sort(
        (a, b) => a.estimatedDurationMins.compareTo(b.estimatedDurationMins),
      );
    }
    return services;
  }

  bool get isEmptySearchResult {
    if (isLoading || errorMessage != null || feed == null) {
      return false;
    }
    final hasActiveFilter =
        searchQuery.trim().isNotEmpty || selectedCategorySlug != null;
    if (!hasActiveFilter) {
      return feed!.categories.isEmpty &&
          feed!.services.isEmpty &&
          feed!.professionals.isEmpty;
    }
    return filteredCategories.isEmpty &&
        filteredServices.isEmpty &&
        filteredProfessionals.isEmpty;
  }

  CustomerHomeState copyWith({
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    bool clearError = false,
    CustomerHomeFeed? feed,
    SelectedServiceArea? selectedArea,
    bool clearArea = false,
    String? selectedCategorySlug,
    bool clearCategory = false,
    String? searchQuery,
    String? sortMode,
    List<ServiceOfferModel>? searchResults,
    bool clearSearchResults = false,
    int? activeBottomTab,
  }) {
    return CustomerHomeState(
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feed: feed ?? this.feed,
      selectedArea: clearArea ? null : (selectedArea ?? this.selectedArea),
      selectedCategorySlug: clearCategory
          ? null
          : (selectedCategorySlug ?? this.selectedCategorySlug),
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
      searchResults: clearSearchResults
          ? null
          : (searchResults ?? this.searchResults),
      activeBottomTab: activeBottomTab ?? this.activeBottomTab,
    );
  }
}

class CustomerHomeController extends Notifier<CustomerHomeState> {
  int _request = 0;
  int _searchEpoch = 0;
  Timer? _searchDebounce;
  CancelToken? _searchCancelToken;
  String? _userId;
  bool _disposed = false;

  @override
  CustomerHomeState build() {
    _disposed = false;
    _userId = ref.watch(
      authControllerProvider.select((s) => s.session?.user.id),
    );
    ref.onDispose(() {
      _disposed = true;
      _request++;
      _searchEpoch++;
      _searchDebounce?.cancel();
      _searchCancelToken?.cancel('Disposed');
    });
    _request++;
    final prefs = ref.read(appPreferencesProvider);
    SelectedServiceArea? saved;
    final raw = _userId == null ? null : prefs?.getString('fixo.area.$_userId');
    try {
      if (raw != null) saved = SelectedServiceArea.fromJson(jsonDecode(raw));
    } catch (_) {
      /* Ignore invalid/old preferences. */
    }
    // Retire the unscoped cache: it mixed area-dependent professional results.
    if (prefs != null) unawaited(prefs.remove('fixo.home_feed_cache.v1'));
    Future<void>.microtask(loadFeed);
    return CustomerHomeState(isLoading: true, selectedArea: saved);
  }

  void selectSortMode(String mode) {
    state = state.copyWith(sortMode: mode);
  }

  Future<void> loadFeed() async {
    if (_disposed) return;
    final request = ++_request;
    state = state.copyWith(isLoading: state.feed == null, clearError: true);
    try {
      final repository = ref.read(marketplaceRepositoryProvider);
      final feed = await repository.fetchCustomerHomeFeed(
        zone: state.selectedZoneSlug,
      );
      if (_disposed || request != _request) return;
      state = state.copyWith(isLoading: false, feed: feed, clearError: true);
    } on MarketplaceApiException catch (error) {
      if (_disposed || request != _request) return;
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      if (_disposed || request != _request) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Unable to connect to FIXO marketplace service. Please try again.',
      );
    }
  }

  void _scheduleDebounceFrames() {
    if (_disposed || !(_searchDebounce?.isActive ?? false)) return;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!_disposed && (_searchDebounce?.isActive ?? false)) {
        _scheduleDebounceFrames();
      }
    });
  }

  /// Waits 300ms after the user finishes typing, cancels any previous in-flight
  /// search token (`CancelToken`), and updates/fetches matching services.
  void updateSearchQuery(String value) {
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Superseded by new search input');
    final epoch = ++_searchEpoch;

    if (value.trim().isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        isSearching: false,
        clearSearchResults: true,
      );
      return;
    }

    state = state.copyWith(isSearching: true, clearSearchResults: true);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_disposed || epoch != _searchEpoch) return;
      state = state.copyWith(searchQuery: value, isSearching: true);
      final cancelToken = CancelToken();
      _searchCancelToken = cancelToken;
      unawaited(_executeDebouncedSearch(value.trim(), epoch, cancelToken));
    });
    _scheduleDebounceFrames();
  }

  Future<void> _executeDebouncedSearch(
    String query,
    int epoch,
    CancelToken cancelToken,
  ) async {
    try {
      final repository = ref.read(marketplaceRepositoryProvider);
      final paginated = repository is DioMarketplaceRepository
          ? await repository.getPaginatedServices(
              page: 1,
              limit: 50,
              search: query,
              categoryId: state.selectedCategorySlug,
              cancelToken: cancelToken,
            )
          : await repository.getPaginatedServices(
              page: 1,
              limit: 50,
              search: query,
              categoryId: state.selectedCategorySlug,
            );
      if (_disposed || epoch != _searchEpoch || cancelToken.isCancelled) return;
      state = state.copyWith(
        isSearching: false,
        searchResults: paginated.items,
      );
    } catch (_) {
      if (!_disposed && epoch == _searchEpoch) {
        state = state.copyWith(isSearching: false);
      }
    }
  }

  void selectCategory(String? categorySlug) {
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Category changed');
    _searchEpoch++;
    state = state.copyWith(isSearching: false, clearSearchResults: true);
    if (state.selectedCategorySlug == categorySlug) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategorySlug: categorySlug);
    }
  }

  Future<void> selectArea(SelectedServiceArea area) async {
    final userId = _userId;
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Area changed');
    _searchEpoch++;
    state = CustomerHomeState(
      selectedArea: area,
      selectedCategorySlug: state.selectedCategorySlug,
    );
    final preferences = ref.read(appPreferencesProvider);
    final fetch = loadFeed();
    if (userId != null && preferences != null) {
      await preferences.setString(
        'fixo.area.$userId',
        jsonEncode(area.toJson()),
      );
    }
    await fetch;
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Filters cleared');
    _searchEpoch++;
    state = state.copyWith(
      searchQuery: '',
      clearSearchResults: true,
      clearCategory: true,
      isSearching: false,
    );
  }

  void setActiveBottomTab(int index) {
    state = state.copyWith(activeBottomTab: index);
  }
}

final customerHomeControllerProvider =
    NotifierProvider<CustomerHomeController, CustomerHomeState>(
      CustomerHomeController.new,
    );
