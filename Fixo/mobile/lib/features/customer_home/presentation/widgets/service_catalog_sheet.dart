import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
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
  int _epoch = 0, _page = 0, _totalPages = 1;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    final epoch = ++_epoch;
    final page = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _items.clear();
    });
    try {
      final response = await ref
          .read(dioClientProvider)
          .get<Map<String, dynamic>>(
            '/services',
            queryParameters: {
              'page': page,
              'limit': 20,
              if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
            },
          );
      final data = response.data;
      if (data == null || data['items'] is! List || data['meta'] is! Map) {
        throw const FormatException('Service catalog is unavailable.');
      }
      final meta = data['meta'] as Map;
      final pages = meta['totalPages'];
      if (pages is! int || pages < 1 || meta['page'] != page) {
        throw const FormatException('Service catalog pagination is invalid.');
      }
      final items = (data['items'] as List).map((value) {
        final json = Map<String, dynamic>.from(value as Map);
        // Never show the older model's example pricing when a response is incomplete.
        for (final field in [
          'baseInspectionEgp',
          'serviceFeeEgp',
          'flatPriceEgp',
        ]) {
          if (json[field] is! num ||
              !(json[field] as num).isFinite ||
              (json[field] as num) < 0 ||
              (json[field] as num) % 1 != 0) {
            throw const FormatException('Service price is unavailable.');
          }
        }
        if (json['id'] is! String || (json['id'] as String).isEmpty) {
          throw const FormatException('Service identity is unavailable.');
        }
        return ServiceOfferModel.fromJson(json);
      }).toList();
      if (!mounted || epoch != _epoch) return;
      setState(() {
        final ids = _items.map((s) => s.id).toSet();
        _items.addAll(items.where((s) => ids.add(s.id)));
        _page = page;
        _totalPages = items.isEmpty ? page : pages;
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
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
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
                        TextButton(
                          key: const Key('catalog-load-more'),
                          onPressed: _load,
                          child: Text(
                            ar ? 'عرض خدمات أكتر' : 'Load more services',
                          ),
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
