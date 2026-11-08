import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/widgets/fixo_skeleton.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/marketplace_models.dart';

/// Browses the live catalog independently of the Home search/category filter.
class ServiceCatalogSheet extends ConsumerStatefulWidget {
  const ServiceCatalogSheet({super.key, required this.isArabic});
  final bool isArabic;
  @override
  ConsumerState<ServiceCatalogSheet> createState() =>
      _ServiceCatalogSheetState();
}

class _ServiceCatalogSheetState extends ConsumerState<ServiceCatalogSheet> {
  final _search = TextEditingController();
  final _items = <ServiceOfferModel>[];
  Timer? _debounce;
  CancelToken? _cancelToken;
  int _epoch = 0, _page = 0, _totalPages = 1;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    _cancelToken?.cancel();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    final epoch = ++_epoch;
    final page = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _items.clear();
    });
    try {
      final repository = ref.read(marketplaceRepositoryProvider);
      final searchVal =
          _search.text.trim().isNotEmpty ? _search.text.trim() : null;
      final result = repository is DioMarketplaceRepository
          ? await repository.getPaginatedServices(
              page: page,
              limit: 20,
              search: searchVal,
              cancelToken: cancelToken,
            )
          : await repository.getPaginatedServices(
              page: page,
              limit: 20,
              search: searchVal,
            );
      if (!mounted || epoch != _epoch) return;
      setState(() {
        final ids = _items.map((s) => s.id).toSet();
        _items.addAll(result.items.where((s) => ids.add(s.id)));
        _page = page;
        _totalPages = result.items.isEmpty ? page : result.totalPages;
        _loading = false;
      });
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() {
          _loading = false;
          _error = widget.isArabic
              ? 'تعذر تحميل الخدمات. حاول تاني.'
              : 'Could not load services. Please retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    _epoch++;
    _debounce?.cancel();
    _cancelToken?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ar ? 'كل الخدمات' : 'All services',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: ar ? 'إغلاق' : 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                TextField(
                  key: const Key('catalog-search'),
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: ar ? 'ابحث في كل الخدمات' : 'Search all services',
                  ),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _cancelToken?.cancel();
                    _epoch++;
                    setState(() {
                      _loading = true;
                      _items.clear();
                      _error = null;
                    });
                    _debounce = Timer(
                      const Duration(milliseconds: 300),
                      () => _load(reset: true),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      for (final service in _items)
                        ListTile(
                          key: ValueKey('catalog-service-${service.id}'),
                          title: Text(service.localizedTitle(ar)),
                          subtitle: Text(
                            '${service.flatPriceEgp} ${ar ? 'ج.م' : 'EGP'} · ${service.estimatedDurationMins} ${ar ? 'دقيقة' : 'min'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _loading
                              ? null
                              : () => Navigator.pop(context, service),
                        ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: FixoSpacing.sm),
                          child: FixoListSkeleton(
                            itemCount: 3,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      if (_error != null)
                        Column(
                          children: [
                            Text(_error!),
                            TextButton(
                              onPressed: () =>
                                  _load(reset: _page == 0 || _items.isEmpty),
                              child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                            ),
                          ],
                        ),
                      if (!_loading && _error == null && _items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            ar
                                ? 'مفيش خدمات مطابقة حاليًا.'
                                : 'No matching services available yet.',
                          ),
                        ),
                      if (!_loading && _error == null && _page < _totalPages)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            TextButton(
                              key: const Key('catalog-load-more'),
                              onPressed: _load,
                              child: Text(
                                ar ? 'عرض خدمات أكتر' : 'Load more services',
                              ),
                            ),
                            TextButton(
                              key: const Key('catalog-load-all'),
                              onPressed: () async {
                                while (mounted &&
                                    !_loading &&
                                    _error == null &&
                                    _page < _totalPages) {
                                  await _load();
                                }
                              },
                              child: Text(
                                ar ? 'عرض الكل' : 'Show all',
                              ),
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
      ),
    );
  }
}
