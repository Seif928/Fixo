import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/location/egypt_places.dart';
import 'package:fixo_mobile/core/storage/secure_token_storage.dart';
import 'package:fixo_mobile/features/customer_home/data/marketplace_repository.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/customer_home/presentation/controllers/customer_home_controller.dart';
import 'phase2_auth_and_home_test.dart' show FakeMarketplaceRepository;

class _DelayedSearch extends FakeMarketplaceRepository {
  final pending = Completer<PaginatedServices>();
  @override
  Future<PaginatedServices> getPaginatedServices({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
  }) => pending.future;
}

void main() {
  testWidgets(
    'retired unscoped cache cannot display another area before refresh',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'fixo.home_feed_cache.v1': jsonEncode(
          FakeMarketplaceRepository.sampleFeed().toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = FakeMarketplaceRepository()..shouldFail = true;
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          marketplaceRepositoryProvider.overrideWithValue(repo),
          secureTokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(customerHomeControllerProvider).feed, isNull);
      await tester.pump();
      expect(container.read(customerHomeControllerProvider).feed, isNull);
    },
  );
  testWidgets('empty authoritative search removes old matches', (tester) async {
    final repo = _DelayedSearch();
    final container = ProviderContainer(
      overrides: [
        marketplaceRepositoryProvider.overrideWithValue(repo),
        secureTokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(customerHomeControllerProvider.notifier);
    await tester.pump();
    controller.updateSearchQuery('AC');
    await tester.pump(const Duration(milliseconds: 350));
    repo.pending.complete(
      const PaginatedServices(items: [], page: 1, totalPages: 0, total: 0),
    );
    await tester.pump();
    expect(
      container.read(customerHomeControllerProvider).filteredServices,
      isEmpty,
    );
  });
  testWidgets('old search completion cannot replace a newly selected area', (
    tester,
  ) async {
    final repo = _DelayedSearch();
    final container = ProviderContainer(
      overrides: [
        marketplaceRepositoryProvider.overrideWithValue(repo),
        secureTokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(customerHomeControllerProvider.notifier);
    await tester.pump();
    controller.updateSearchQuery('AC');
    await tester.pump(const Duration(milliseconds: 350));
    await controller.selectArea(
      const SelectedServiceArea(
        zoneSlug: 'giza',
        governorateEn: 'Giza',
        governorateAr: 'الجيزة',
      ),
    );
    repo.pending.complete(
      const PaginatedServices(items: [], page: 1, totalPages: 0, total: 0),
    );
    await tester.pump();
    final state = container.read(customerHomeControllerProvider);
    expect(state.selectedZoneSlug, 'giza');
    expect(state.searchResults, isNull);
    expect(state.searchQuery, isEmpty);
  });
}
