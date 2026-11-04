import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_catalog_models.dart';
import '../data/admin_repository.dart';
import 'admin_draft_dialog.dart';

class AdminCreateDraftDialog extends ConsumerStatefulWidget {
  const AdminCreateDraftDialog({
    super.key,
    required this.ar,
    required this.categories,
  });

  final bool ar;
  final List<AdminCatalogCategory> categories;

  @override
  ConsumerState<AdminCreateDraftDialog> createState() => _State();
}

class _State extends ConsumerState<AdminCreateDraftDialog> {
  final _form = GlobalKey<FormState>();
  late final _owner = ref.read(authControllerProvider).session?.user.id;

  final _titleEn = TextEditingController();
  final _titleAr = TextEditingController();
  final _descEn = TextEditingController();
  final _descAr = TextEditingController();
  final _slug = TextEditingController();
  final _inspection = TextEditingController();
  final _serviceFee = TextEditingController();
  final _duration = TextEditingController();

  String? _selectedCategorySlug;
  final _newCategorySlug = TextEditingController();
  final _newCategoryEn = TextEditingController();
  final _newCategoryAr = TextEditingController();
  bool _isCustomCategory = false;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategorySlug = widget.categories.first.slug;
    } else {
      _isCustomCategory = true;
    }
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleAr.dispose();
    _descEn.dispose();
    _descAr.dispose();
    _slug.dispose();
    _inspection.dispose();
    _serviceFee.dispose();
    _duration.dispose();
    _newCategorySlug.dispose();
    _newCategoryEn.dispose();
    _newCategoryAr.dispose();
    super.dispose();
  }

  int? _number(String value) {
    const eastern = '٠١٢٣٤٥٦٧٨٩', persian = '۰۱۲۳۴۵۶۷۸۹';
    final normal = value
        .trim()
        .split('')
        .map(
          (c) => eastern.contains(c)
              ? eastern.indexOf(c).toString()
              : persian.contains(c)
              ? persian.indexOf(c).toString()
              : c,
        )
        .join();
    return RegExp(r'^\d+$').hasMatch(normal) ? int.tryParse(normal) : null;
  }

  Future<void> _submit() async {
    if (_busy ||
        !_form.currentState!.validate() ||
        _owner == null ||
        ref.read(authControllerProvider).session?.user.id != _owner) {
      return;
    }

    final categorySlug = _isCustomCategory
        ? _newCategorySlug.text.trim()
        : _selectedCategorySlug;

    if (categorySlug == null || categorySlug.isEmpty) {
      setState(() {
        _error = widget.ar
            ? 'يرجى اختيار أو إدخال قسم للخدمة.'
            : 'Please select or enter a service category.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final data = <String, dynamic>{
        'titleEn': _titleEn.text.trim(),
        'titleAr': _titleAr.text.trim(),
        'descriptionEn': _descEn.text.trim(),
        'descriptionAr': _descAr.text.trim(),
        'categorySlug': categorySlug,
      };

      if (_slug.text.trim().isNotEmpty) {
        data['slug'] = _slug.text.trim();
      }

      if (_isCustomCategory) {
        if (_newCategoryEn.text.trim().isNotEmpty) {
          data['categoryNameEn'] = _newCategoryEn.text.trim();
        }
        if (_newCategoryAr.text.trim().isNotEmpty) {
          data['categoryNameAr'] = _newCategoryAr.text.trim();
        }
      }

      final insp = _number(_inspection.text);
      if (insp != null) data['baseInspectionEgp'] = insp;

      final fee = _number(_serviceFee.text);
      if (fee != null) data['serviceFeeEgp'] = fee;

      final dur = _number(_duration.text);
      if (dur != null) data['estimatedDurationMins'] = dur;

      final draft = await ref.read(adminRepositoryProvider).createDraft(data);

      if (mounted &&
          ref.read(authControllerProvider).session?.user.id == _owner) {
        ref.read(adminCatalogRevisionProvider.notifier).state++;
        ref.invalidate(adminAuditProvider);
        Navigator.pop(context, draft);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(error, widget.ar);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ar;

    if (ref.watch(authControllerProvider).session?.user.id != _owner) {
      return AlertDialog(
        title: Text(ar ? 'جلسة الحساب اتغيرت' : 'Account session changed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ar ? 'إغلاق' : 'Close'),
          ),
        ],
      );
    }

    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(ar ? 'إضافة خدمة جديدة' : 'Add custom service'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar
                        ? 'أنشئ مسودة خدمة خاصة جديدة. لن تظهر للعملاء إلا بعد تحديد الأسعار والمراجعة والنشر.'
                        : 'Create a new private service draft. It will not be visible to customers until priced, reviewed, and published.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('admin-create-draft-title-en'),
                    controller: _titleEn,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText:
                          ar ? 'اسم الخدمة (إنجليزي) *' : 'Title (English) *',
                      hintText: 'e.g. Plumbing Leak Detection',
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? (ar
                            ? 'أدخل اسماً إنجليزياً صالحاً.'
                            : 'Enter a valid English title.')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('admin-create-draft-title-ar'),
                    controller: _titleAr,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText:
                          ar ? 'اسم الخدمة (عربي) *' : 'Title (Arabic) *',
                      hintText: 'مثال: كشف تسريبات السباكة',
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? (ar
                            ? 'أدخل اسماً عربياً صالحاً.'
                            : 'Enter a valid Arabic title.')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('admin-create-draft-slug'),
                    controller: _slug,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: ar
                          ? 'المعرّف اللطيف (Slug) - اختياري'
                          : 'Custom slug (optional)',
                      hintText: 'e.g. plumbing-leak-detection',
                      helperText: ar
                          ? 'إذا تُرك فارغاً، سيتم توليده تلقائياً من الاسم الإنجليزي.'
                          : 'If empty, automatically generated from the English title.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.categories.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      key: const Key('admin-create-draft-category'),
                      initialValue: _isCustomCategory
                          ? '__new__'
                          : _selectedCategorySlug,
                      decoration: InputDecoration(
                        labelText: ar ? 'القسم *' : 'Category *',
                      ),
                      items: [
                        for (final cat in widget.categories)
                          DropdownMenuItem(
                            value: cat.slug,
                            child: Text(ar ? cat.ar : cat.en),
                          ),
                        DropdownMenuItem(
                          value: '__new__',
                          child: Text(ar ? '+ قسم جديد...' : '+ New category...'),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (val) {
                              setState(() {
                                if (val == '__new__') {
                                  _isCustomCategory = true;
                                } else {
                                  _isCustomCategory = false;
                                  _selectedCategorySlug = val;
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_isCustomCategory) ...[
                    TextFormField(
                      key: const Key('admin-create-draft-new-cat-slug'),
                      controller: _newCategorySlug,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: ar
                            ? 'معرّف القسم الجديد (slug) *'
                            : 'New category slug *',
                        hintText: 'e.g. smart-home',
                      ),
                      validator: (v) =>
                          _isCustomCategory && (v == null || v.trim().length < 2)
                              ? (ar
                                  ? 'أدخل معرّف قسم صالحاً.'
                                  : 'Enter a valid category slug.')
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('admin-create-draft-new-cat-en'),
                      controller: _newCategoryEn,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: ar
                            ? 'اسم القسم (إنجليزي)'
                            : 'Category name (English)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('admin-create-draft-new-cat-ar'),
                      controller: _newCategoryAr,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText:
                            ar ? 'اسم القسم (عربي)' : 'Category name (Arabic)',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    key: const Key('admin-create-draft-desc-en'),
                    controller: _descEn,
                    enabled: !_busy,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText:
                          ar ? 'الوصف (إنجليزي) *' : 'Description (English) *',
                    ),
                    validator: (v) => v == null || v.trim().length < 3
                        ? (ar
                            ? 'أدخل وصفاً إنجليزياً.'
                            : 'Enter an English description.')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('admin-create-draft-desc-ar'),
                    controller: _descAr,
                    enabled: !_busy,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText:
                          ar ? 'الوصف (عربي) *' : 'Description (Arabic) *',
                    ),
                    validator: (v) => v == null || v.trim().length < 3
                        ? (ar
                            ? 'أدخل وصفاً عربياً.'
                            : 'Enter an Arabic description.')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ar
                        ? 'التسعير المبدئي (اختياري - يمكن تحديده لاحقاً):'
                        : 'Initial pricing (optional - can be set later):',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('admin-create-draft-inspection'),
                          controller: _inspection,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                ar ? 'المعاينة (ج.م)' : 'Inspection (EGP)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('admin-create-draft-service-fee'),
                          controller: _serviceFee,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: ar ? 'الخدمة (ج.م)' : 'Service (EGP)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('admin-create-draft-duration'),
                          controller: _duration,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: ar ? 'المدة (دقيقة)' : 'Duration (mins)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('admin-create-draft-cancel'),
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('admin-create-draft-submit'),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(ar ? 'إنشاء المسودة' : 'Create draft'),
          ),
        ],
      ),
    );
  }
}

