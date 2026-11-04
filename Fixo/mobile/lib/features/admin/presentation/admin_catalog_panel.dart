import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_catalog_models.dart';
import '../data/admin_repository.dart';
import 'admin_confirmation_dialog.dart';
import 'admin_create_draft_dialog.dart';
import 'admin_draft_dialog.dart';

class AdminCatalogPanel extends ConsumerStatefulWidget {
  const AdminCatalogPanel({
    super.key,
    required this.ar,
    required this.needsConfirmation,
  });
  final bool ar, needsConfirmation;
  @override
  ConsumerState<AdminCatalogPanel> createState() => _State();
}

class _State extends ConsumerState<AdminCatalogPanel> {
  final _search = TextEditingController();
  Timer? _debounce;
  CancelToken? _cancel;
  late Future<AdminCatalogPageModel> _future;
  int _page = 1;
  String? _category, _error;
  bool _busy = false, _reauth = false;
  List<AdminCatalogCategory> _categories = [];
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancel?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<AdminCatalogPageModel> _load() {
    _cancel?.cancel();
    _cancel = CancelToken();
    return ref
        .read(adminRepositoryProvider)
        .catalog(
          page: _page,
          search: _search.text.trim(),
          category: _category,
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

  Future<void> _confirm() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmationDialog(ar: widget.ar),
    );
  }

  Future<void> _createDraft() async {
    if (_busy || widget.needsConfirmation) return;
    final owner = ref.read(authControllerProvider).session?.user.id;
    setState(() => _busy = true);
    final created = await showDialog<AdminCatalogDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminCreateDraftDialog(
        ar: widget.ar,
        categories: _categories,
      ),
    );
    if (!mounted ||
        ref.read(authControllerProvider).session?.user.id != owner) {
      return;
    }
    setState(() => _busy = false);
    if (created != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.ar
                  ? 'تم إنشاء مسودة الخدمة بنجاح.'
                  : 'Service draft created successfully.',
            ),
          ),
        );
    }
  }

  Future<void> _edit(AdminCatalogDraft draft) async {
    if (_busy || widget.needsConfirmation) return;
    final owner = ref.read(authControllerProvider).session?.user.id;
    setState(() => _busy = true);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminDraftDialog(draft: draft, ar: widget.ar),
    );
    if (!mounted ||
        ref.read(authControllerProvider).session?.user.id != owner) {
      return;
    }
    setState(() => _busy = false);
    // A failed version check may mean another administrator already changed it.
    if (saved != true) _reload();
  }

  Future<void> _publish(AdminCatalogDraft draft) async {
    if (_busy ||
        widget.needsConfirmation ||
        !draft.publishable ||
        !draft.hasChanges) {
      return;
    }
    final owner = ref.read(authControllerProvider).session?.user.id;
    final ar = widget.ar;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(ar ? 'مراجعة نشر الخدمة' : 'Review service publication'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ar ? draft.titleAr : draft.titleEn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '${ar ? 'المعاينة' : 'Inspection'}: ${draft.inspection} ${ar ? 'ج.م' : 'EGP'}',
            ),
            Text(
              '${ar ? 'الخدمة' : 'Service'}: ${draft.serviceFee} ${ar ? 'ج.م' : 'EGP'}',
            ),
            const SizedBox(height: 8),
            Text(
              '${draft.total} ${ar ? 'ج.م' : 'EGP'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              ar
                  ? 'الإجمالي قبل أي رسوم انتقال خاصة بالحجز.'
                  : 'Total before any booking-specific transport charge.',
            ),
            const SizedBox(height: 16),
            Text(
              ar
                  ? 'الخدمة والسعر المحفوظ هيظهروا للعملاء وتتاح للحجز. اتأكد إن الوصف والسعر والتغطية مناسبين قبل النشر.'
                  : 'The saved service and price become visible and bookable. Check the description, price and service coverage before publishing.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('admin-publish-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ar ? 'نشر للعملاء' : 'Publish to customers'),
          ),
        ],
      ),
    );
    if (yes != true ||
        !mounted ||
        owner == null ||
        ref.read(authControllerProvider).session?.user.id != owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _reauth = false;
    });
    try {
      await ref.read(adminRepositoryProvider).publishDraft(draft);
      if (!mounted ||
          ref.read(authControllerProvider).session?.user.id != owner) {
        return;
      }
      ref.invalidate(adminAuditProvider);
      ref.invalidate(adminSummaryProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تم نشر الخدمة والسعر المحفوظ.'
                  : 'Saved service and price published.',
            ),
          ),
        );
      _reload();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(error, ar);
          _reauth = needsAdminConfirmation(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deactivate(AdminCatalogDraft draft) async {
    if (_busy || widget.needsConfirmation || !draft.isPublishedActive) return;
    final owner = ref.read(authControllerProvider).session?.user.id;
    final ar = widget.ar;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(
          ar ? 'تعطيل الخدمة المنشورة' : 'Deactivate published service',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ar ? draft.titleAr : draft.titleEn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              ar
                  ? 'الخدمة ستختفي من قوائم البحث للعملاء ولن يمكن حجزها كطلب جديد. الحجوزات السابقة وسجلات الأسعار تظل محفوظة وقابلة للتشغيل.'
                  : 'This service will disappear from public search and cannot be booked as a new order. Historical bookings and pricing records remain preserved and operable.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('admin-deactivate-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ar ? 'تأكيد التعطيل' : 'Confirm deactivation'),
          ),
        ],
      ),
    );
    if (yes != true ||
        !mounted ||
        owner == null ||
        ref.read(authControllerProvider).session?.user.id != owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _reauth = false;
    });
    try {
      await ref.read(adminRepositoryProvider).deactivateService(draft);
      if (!mounted ||
          ref.read(authControllerProvider).session?.user.id != owner) {
        return;
      }
      ref.invalidate(adminAuditProvider);
      ref.invalidate(adminSummaryProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تم تعطيل الخدمة بنجاح.'
                  : 'Service deactivated successfully.',
            ),
          ),
        );
      _reload();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(error, ar);
          _reauth = needsAdminConfirmation(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reactivate(AdminCatalogDraft draft) async {
    if (_busy || widget.needsConfirmation || !draft.isDeactivated) return;
    final owner = ref.read(authControllerProvider).session?.user.id;
    final ar = widget.ar;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(ar ? 'إعادة تفعيل الخدمة' : 'Reactivate service'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ar ? draft.titleAr : draft.titleEn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              ar
                  ? 'ستعود الخدمة للظهور للعملاء في البحث والتطبيق وتصبح متاحة للحجز بالأسعار المحفوظة.'
                  : 'The service will reappear in customer search and become available for booking with its saved pricing.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('admin-reactivate-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ar ? 'تأكيد التفعيل' : 'Confirm reactivation'),
          ),
        ],
      ),
    );
    if (yes != true ||
        !mounted ||
        owner == null ||
        ref.read(authControllerProvider).session?.user.id != owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _reauth = false;
    });
    try {
      await ref.read(adminRepositoryProvider).reactivateService(draft);
      if (!mounted ||
          ref.read(authControllerProvider).session?.user.id != owner) {
        return;
      }
      ref.invalidate(adminAuditProvider);
      ref.invalidate(adminSummaryProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'تمت إعادة تفعيل الخدمة بنجاح.'
                  : 'Service reactivated successfully.',
            ),
          ),
        );
      _reload();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(error, ar);
          _reauth = needsAdminConfirmation(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _card(AdminCatalogDraft draft) {
    final ar = widget.ar;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ar ? draft.categoryAr : draft.categoryEn,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(
              ar ? draft.titleAr : draft.titleEn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(
                draft.isDeactivated
                    ? Icons.pause_circle_outline
                    : draft.isDraftOnly
                    ? Icons.edit_note
                    : draft.hasChanges
                    ? Icons.pending_outlined
                    : Icons.check_circle_outline,
                size: 18,
              ),
              label: Text(
                draft.isDeactivated
                    ? (ar ? 'معطل' : 'Deactivated')
                    : draft.isDraftOnly
                    ? (ar ? 'مسودة خاصة' : 'Private draft')
                    : draft.hasChanges
                    ? (ar ? 'تعديلات غير منشورة' : 'Unpublished changes')
                    : (ar ? 'منشور' : 'Published'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              draft.total == null
                  ? (ar ? 'السعر لسه مش محدد' : 'Price not set')
                  : '${draft.total} ${ar ? 'ج.م' : 'EGP'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              ar
                  ? 'السعر المحفوظ قبل الانتقال'
                  : 'Saved price before transport',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: Key('admin-edit-${draft.id}'),
                  onPressed: _busy || widget.needsConfirmation
                      ? null
                      : () => _edit(draft),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(ar ? 'تعديل' : 'Edit'),
                ),
                if (draft.hasChanges && !draft.isDeactivated)
                  FilledButton.icon(
                    key: Key('admin-publish-${draft.id}'),
                    onPressed:
                        _busy || widget.needsConfirmation || !draft.publishable
                        ? null
                        : () => _publish(draft),
                    icon: const Icon(Icons.publish_outlined),
                    label: Text(ar ? 'مراجعة النشر' : 'Review publication'),
                  ),
                if (draft.isPublishedActive)
                  OutlinedButton.icon(
                    key: Key('admin-deactivate-${draft.id}'),
                    onPressed: _busy || widget.needsConfirmation
                        ? null
                        : () => _deactivate(draft),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: Text(ar ? 'تعطيل' : 'Deactivate'),
                  ),
                if (draft.isDeactivated)
                  FilledButton.icon(
                    key: Key('admin-reactivate-${draft.id}'),
                    onPressed: _busy || widget.needsConfirmation
                        ? null
                        : () => _reactivate(draft),
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(ar ? 'إعادة التفعيل' : 'Reactivate'),
                  ),
              ],
            ),
            if (!draft.publishable && !draft.isDeactivated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  ar
                      ? 'حدّد المعاينة وسعر الخدمة والمدة قبل النشر.'
                      : 'Set inspection, service price and duration before publishing.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminCatalogRevisionProvider, (_, _) => _reload());
    final ar = widget.ar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'الخدمات والأسعار' : 'Services and pricing',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'المسودات خاصة بالإدارة. احفظ التفاصيل والأسعار، وبعدها راجع النشر لإتاحتها للعملاء.'
              : 'Drafts are private to administration. Save details and prices, then review publication to make them available to customers.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('admin-create-draft-btn'),
          onPressed: _busy || widget.needsConfirmation ? null : _createDraft,
          icon: const Icon(Icons.add),
          label: Text(ar ? 'إضافة خدمة مخصصة' : 'Add custom service'),
        ),
        if (widget.needsConfirmation || _reauth)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _confirm,
              icon: const Icon(Icons.lock_outline),
              label: Text(
                ar ? 'تأكيد حسابك للتعديل' : 'Confirm your account to edit',
              ),
            ),
          ),
        const SizedBox(height: 20),
        FutureBuilder<AdminCatalogPageModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasData) _categories = snapshot.data!.categories;
            final categories = _categories;
            final search = TextField(
              key: const Key('admin-catalog-search'),
              controller: _search,
              decoration: InputDecoration(
                labelText: ar ? 'ابحث عن خدمة' : 'Search services',
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
              key: const Key('admin-catalog-category'),
              initialValue: _category ?? '',
              isExpanded: true,
              decoration: InputDecoration(labelText: ar ? 'القسم' : 'Category'),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(ar ? 'كل الأقسام' : 'All categories'),
                ),
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.slug,
                    child: Text(
                      ar ? category.ar : category.en,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                _category = value?.isEmpty == true ? null : value;
                _page = 1;
                _reload();
              },
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 600
                      ? Column(
                          children: [
                            search,
                            const SizedBox(height: 12),
                            filter,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(flex: 2, child: search),
                            const SizedBox(width: 16),
                            Expanded(child: filter),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  Column(
                    children: [
                      Text(
                        ar
                            ? 'تعذر تحميل الخدمات. أعد المحاولة.'
                            : 'Could not load services. Please retry.',
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  )
                else if (snapshot.hasData) ...[
                  Text('${snapshot.data!.total} ${ar ? 'خدمة' : 'services'}'),
                  const SizedBox(height: 12),
                  if (snapshot.data!.items.isEmpty)
                    Text(
                      ar ? 'لا توجد خدمات مطابقة.' : 'No matching services.',
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 680 ? 2 : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 16) / columns;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: snapshot.data!.items
                            .map((d) => SizedBox(width: width, child: _card(d)))
                            .toList(),
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
                        onPressed: _busy || _page <= 1
                            ? null
                            : () {
                                _page--;
                                _reload();
                              },
                        child: Text(ar ? 'السابق' : 'Previous'),
                      ),
                      Text('$_page / ${snapshot.data!.totalPages}'),
                      OutlinedButton(
                        onPressed: _busy || _page >= snapshot.data!.totalPages
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
              ],
            );
          },
        ),
      ],
    );
  }
}
