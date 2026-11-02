import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../../core/location/egypt_places.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/marketplace_models.dart';

class CustomerHomeState {
  const CustomerHomeState({
    this.isLoading = true,
    this.errorMessage,
    this.feed,
    this.selectedArea,
    this.selectedCategorySlug,
    this.searchQuery = '',
    this.activeBottomTab = 0,
  });

  final bool isLoading;
  final String? errorMessage;
  final CustomerHomeFeed? feed;
  final SelectedServiceArea? selectedArea;
  String? get selectedZoneSlug => selectedArea?.zoneSlug;
  final String? selectedCategorySlug;
  final String searchQuery;
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
    SelectedServiceArea? selectedArea,
    bool clearArea = false,
    String? selectedCategorySlug,
    bool clearCategory = false,
    String? searchQuery,
    int? activeBottomTab,
  }) {
    return CustomerHomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feed: feed ?? this.feed,
      selectedArea: clearArea ? null : (selectedArea ?? this.selectedArea),
      selectedCategorySlug: clearCategory
          ? null
          : (selectedCategorySlug ?? this.selectedCategorySlug),
      searchQuery: searchQuery ?? this.searchQuery,
      activeBottomTab: activeBottomTab ?? this.activeBottomTab,
    );
  }
}

class CustomerHomeController extends Notifier<CustomerHomeState> {
  int _request = 0;
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
    });
    _request++;
    SelectedServiceArea? saved;
    final raw = _userId == null
        ? null
        : ref.read(appPreferencesProvider)?.getString('fixo.area.$_userId');
    try {
      if (raw != null) saved = SelectedServiceArea.fromJson(jsonDecode(raw));
    } catch (_) {
      /* Ignore invalid/old preferences. */
    }
    Future<void>.microtask(loadFeed);
    return CustomerHomeState(isLoading: true, selectedArea: saved);
  }

  Future<void> loadFeed() async {
    if (_disposed) return;
    final request = ++_request;
    state = state.copyWith(isLoading: true, clearError: true);
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

  Future<void> selectArea(SelectedServiceArea area) async {
    final userId = _userId;
    state = state.copyWith(selectedArea: area);
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
