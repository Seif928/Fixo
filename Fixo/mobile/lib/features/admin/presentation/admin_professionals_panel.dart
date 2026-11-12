import 'dart:async';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_professional_models.dart';
import '../data/admin_repository.dart';
import 'admin_pro_dossier_dialog.dart';

class AdminProfessionalsPanel extends ConsumerStatefulWidget {
  const AdminProfessionalsPanel({super.key, required this.ar});
  final bool ar;
  @override
  ConsumerState<AdminProfessionalsPanel> createState() => _State();
}

class _State extends ConsumerState<AdminProfessionalsPanel> {
  final _search = TextEditingController();
  CancelToken? _cancel;
  Timer? _debounce;
  int _page = 1;
  String _status = 'PENDING_REVIEW';
  late Future<AdminProfessionalPage> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AdminProfessionalPage> _load() {
    _cancel?.cancel();
    _cancel = CancelToken();
    return ref
        .read(adminRepositoryProvider)
        .professionals(
          page: _page,
          status: _status,
          search: _search.text.trim(),
          cancelToken: _cancel,
        );
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminProfessionalsRevisionProvider, (_, _) => _reload());
    final ar = widget.ar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'الفنيون والمراجعة' : 'Professionals and review',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'راجع بيانات الهوية والمستندات، وبعدها اختار قرارًا واضحًا. مفيش قبول تلقائي.'
              : 'Review identity details and documents, then make an explicit decision. Approval is never automatic.',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: _search,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: ar
                    ? 'ابحث بالاسم أو رقم الملف'
                    : 'Search name or dossier',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _page = 1;
                  _reload();
                });
              },
            );
            final filter = DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: InputDecoration(labelText: ar ? 'الحالة' : 'Status'),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(ar ? 'كل الحالات' : 'All statuses'),
                ),
                for (final status in professionalStatuses)
                  DropdownMenuItem(
                    value: status,
                    child: Text(
                      professionalStatusLabel(status, ar),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                _status = value ?? '';
                _page = 1;
                _reload();
              },
            );
            return constraints.maxWidth < 600
                ? Column(children: [search, const SizedBox(height: 12), filter])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: search),
                      const SizedBox(width: 16),
                      Expanded(child: filter),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        FutureBuilder<AdminProfessionalPage>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    ar
                        ? 'تعذر تحميل قائمة الفنيين.'
                        : 'Could not load professionals.',
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.total} ${ar ? 'ملف' : 'dossiers'}'),
                const SizedBox(height: 12),
                if (data.items.isEmpty)
                  Text(
                    ar
                        ? 'لا توجد ملفات مطابقة للحالة أو البحث.'
                        : 'No dossiers match this status or search.',
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 680 ? 2 : 1,
                        width =
                            (constraints.maxWidth - 16 * (columns - 1)) /
                            columns;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final p in data.items)
                          SizedBox(
                            width: width,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.person_outline),
                                    const SizedBox(height: 12),
                                    Text(
                                      p.legalName ??
                                          p.displayName ??
                                          (ar
                                              ? 'اسم غير مسجل'
                                              : 'Name not recorded'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(p.dossierCode),
                                    Text(professionalStatusLabel(p.status, ar)),
                                    Text(
                                      '${p.documentCount} ${ar ? 'مستندات مرفوعة' : 'uploaded documents'}',
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      key: Key('admin-pro-open-${p.id}'),
                                      onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (_) => AdminProDossierDialog(
                                          id: p.id,
                                          ar: ar,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.fact_check_outlined,
                                      ),
                                      label: Text(
                                        ar ? 'فتح الملف' : 'Open dossier',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _page <= 1
                          ? null
                          : () {
                              _page--;
                              _reload();
                            },
                      child: Text(ar ? 'السابق' : 'Previous'),
                    ),
                    Text('$_page / ${data.totalPages}'),
                    OutlinedButton(
                      onPressed: _page >= data.totalPages
                          ? null
                          : () {
                              _page++;
                              _reload();
                            },
                      child: Text(ar ? 'التالي' : 'Next'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
