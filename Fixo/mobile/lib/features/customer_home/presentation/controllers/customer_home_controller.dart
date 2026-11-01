import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/marketplace_models.dart';

class CustomerHomeState {
  const CustomerHomeState({
    this.isLoading = true,
    this.errorMessage,
    this.feed,
    this.selectedZoneSlug = 'sheikh-zayed',
    this.selectedCategorySlug,
    this.searchQuery = '',
    this.activeBottomTab = 0,
  });

  final bool isLoading;
  final String? errorMessage;
  final CustomerHomeFeed? feed;
  final String selectedZoneSlug;
  final String? selectedCategorySlug;
  final String searchQuery;
  final int activeBottomTab;

  CoverageZoneModel get activeZone {
    final zones = feed?.zones ?? const <CoverageZoneModel>[];
    for (final zone in zones) {
      if (zone.slug == selectedZoneSlug) {
        return zone;
      }
    }
    if (zones.isNotEmpty) {
      return zones.first;
    }
    return const CoverageZoneModel(
      id: 'zone-sheikh-zayed',
      slug: 'sheikh-zayed',
      nameEn: 'Sheikh Zayed, Dist. 9',
      nameAr: 'الشيخ زايد، الحي التاسع',
      governorate: 'Giza',
    );
  }

  List<ServiceCategoryModel> get filteredCategories {
    final all = feed?.categories ?? const <ServiceCategoryModel>[];
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return all;
    }
    return all.where((cat) {
      final text =
          '${cat.nameEn} ${cat.nameAr} ${cat.subtitleEn} ${cat.subtitleAr}'
              .toLowerCase();
      return text.contains(q);
    }).toList();
  }

  List<ProfessionalCardModel> get filteredProfessionals {
    var pros = feed?.professionals ?? const <ProfessionalCardModel>[];
    if (selectedCategorySlug != null && selectedCategorySlug!.isNotEmpty) {
      pros = pros
          .where((p) => p.primaryCategorySlug == selectedCategorySlug)
          .toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      pros = pros.where((p) {
        final text =
            '${p.fullNameEn} ${p.fullNameAr} ${p.specialtyEn} ${p.specialtyAr} ${p.zonesLabelEn} ${p.zonesLabelAr}'
                .toLowerCase();
        return text.contains(q);
      }).toList();
    }
    return pros;
  }

  List<ServiceOfferModel> get filteredServices {
    var services = feed?.services ?? const <ServiceOfferModel>[];
    if (selectedCategorySlug != null && selectedCategorySlug!.isNotEmpty) {
      services = services
          .where((s) => s.categorySlug == selectedCategorySlug)
          .toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      services = services.where((s) {
        final text =
            '${s.titleEn} ${s.titleAr} ${s.descriptionEn} ${s.descriptionAr}'
                .toLowerCase();
        return text.contains(q);
      }).toList();
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
    String? errorMessage,
    bool clearError = false,
    CustomerHomeFeed? feed,
    String? selectedZoneSlug,
    String? selectedCategorySlug,
    bool clearCategory = false,
    String? searchQuery,
    int? activeBottomTab,
  }) {
    return CustomerHomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feed: feed ?? this.feed,
      selectedZoneSlug: selectedZoneSlug ?? this.selectedZoneSlug,
      selectedCategorySlug: clearCategory
          ? null
          : (selectedCategorySlug ?? this.selectedCategorySlug),
      searchQuery: searchQuery ?? this.searchQuery,
      activeBottomTab: activeBottomTab ?? this.activeBottomTab,
    );
  }
}

class CustomerHomeController extends Notifier<CustomerHomeState> {
  @override
  CustomerHomeState build() {
    Future<void>.microtask(loadFeed);
    return const CustomerHomeState(isLoading: true);
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(marketplaceRepositoryProvider);
      final feed = await repository.fetchCustomerHomeFeed();
      state = state.copyWith(isLoading: false, feed: feed, clearError: true);
    } on MarketplaceApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Unable to connect to FIXO marketplace service. Please try again.',
      );
    }
  }

  void updateSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void selectCategory(String? categorySlug) {
    if (state.selectedCategorySlug == categorySlug) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategorySlug: categorySlug);
    }
  }

  void cycleOrSelectZone([String? zoneSlug]) {
    if (zoneSlug != null) {
      state = state.copyWith(selectedZoneSlug: zoneSlug);
      return;
    }
    final zones = state.feed?.zones ?? const <CoverageZoneModel>[];
    if (zones.isEmpty) {
      return;
    }
    final currentIndex = zones.indexWhere(
      (z) => z.slug == state.selectedZoneSlug,
    );
    final nextIndex = (currentIndex + 1) % zones.length;
    state = state.copyWith(selectedZoneSlug: zones[nextIndex].slug);
  }

  void clearFilters() {
    state = state.copyWith(searchQuery: '', clearCategory: true);
  }

  void setActiveBottomTab(int index) {
    state = state.copyWith(activeBottomTab: index);
  }
}

final customerHomeControllerProvider =
    NotifierProvider<CustomerHomeController, CustomerHomeState>(
      CustomerHomeController.new,
    );
