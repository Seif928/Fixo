import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_catalog_models.dart';
import '../data/admin_repository.dart';
import 'admin_confirmation_dialog.dart';

String catalogError(Object error, bool ar) {
  if (needsAdminConfirmation(error)) {
    return ar
        ? 'أكد حسابك قبل حفظ التغيير.'
        : 'Confirm your account before saving.';
  }
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['code'] == 'ADMIN_CATALOG_SLUG_EXISTS') {
        return ar
            ? 'الرمز التعريفي مستخدم لخدمة تانية. اختر اسماً أو رمزاً مختلفاً.'
            : 'A service or draft with this slug already exists.';
      }
      if (data['code'] == 'ADMIN_CATALOG_PRICING_REQUIRED') {
        return ar
            ? 'حدّد المعاينة وسعر الخدمة والمدة بإجمالي أكبر من الصفر قبل النشر.'
            : 'Set inspection, service price and duration with a positive total before publishing.';
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    if (error.response?.statusCode == 409) {
      return ar
          ? 'الخدمة اتعدّلت. اقفل النافذة وحدّث القائمة قبل المحاولة تاني.'
          : 'This service changed. Close this window and reload the list before retrying.';
    }
  }
  return ar
      ? 'تعذر تأكيد حفظ التغيير. حدّث القائمة وحاول تاني.'
      : 'Could not confirm this change. Reload the list and retry.';
}

class AdminDraftDialog extends ConsumerStatefulWidget {
  const AdminDraftDialog({super.key, required this.draft, required this.ar});
  final AdminCatalogDraft draft;
  final bool ar;
  @override
  ConsumerState<AdminDraftDialog> createState() => _State();
}

class _State extends ConsumerState<AdminDraftDialog> {
  final _form = GlobalKey<FormState>();
  late final _owner = ref.read(authControllerProvider).session?.user.id;
  late final Map<String, TextEditingController> _fields = {
    'titleEn': TextEditingController(text: widget.draft.titleEn),
    'titleAr': TextEditingController(text: widget.draft.titleAr),
    'descriptionEn': TextEditingController(text: widget.draft.descriptionEn),
    'descriptionAr': TextEditingController(text: widget.draft.descriptionAr),
    'baseInspectionEgp': TextEditingController(
      text: widget.draft.inspection?.toString() ?? '',
    ),
    'serviceFeeEgp': TextEditingController(
      text: widget.draft.serviceFee?.toString() ?? '',
    ),
    'estimatedDurationMins': TextEditingController(
      text: widget.draft.duration?.toString() ?? '',
    ),
  };
  bool _busy = false, _reauth = false;
  String? _error;
  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
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

  Future<void> _save() async {
    if (_busy ||
        !_form.currentState!.validate() ||
        _owner == null ||
        ref.read(authControllerProvider).session?.user.id != _owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(adminRepositoryProvider).saveDraft(widget.draft, {
        for (final entry in _fields.entries)
          entry.key:
              [
                'baseInspectionEgp',
                'serviceFeeEgp',
                'estimatedDurationMins',
              ].contains(entry.key)
              ? _number(entry.value.text)
              : entry.value.text.trim(),
      });
      if (mounted &&
          ref.read(authControllerProvider).session?.user.id == _owner) {
        ref.read(adminCatalogRevisionProvider.notifier).state++;
        ref.invalidate(adminAuditProvider);
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(error, widget.ar);
          _reauth = needsAdminConfirmation(error);
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
    final inspection = _number(_fields['baseInspectionEgp']!.text),
        service = _number(_fields['serviceFeeEgp']!.text);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(ar ? 'تعديل مسودة الخدمة' : 'Edit service draft'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ar
                        ? 'الحفظ وحده لا ينشر الخدمة أو يغيّر السعر الحالي للعملاء.'
                        : 'Saving alone does not publish this service or change its current customer price.',
                  ),
                  const SizedBox(height: 16),
                  for (final text in [
                    ('titleEn', ar ? 'الاسم بالإنجليزي' : 'English name'),
                    ('titleAr', ar ? 'الاسم بالعربي' : 'Arabic name'),
                    (
                      'descriptionEn',
                      ar ? 'الوصف بالإنجليزي' : 'English description',
                    ),
                    (
                      'descriptionAr',
                      ar ? 'الوصف بالعربي' : 'Arabic description',
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _fields[text.$1],
                        enabled: !_busy,
                        textDirection: text.$1.endsWith('Ar')
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        maxLength: text.$1.startsWith('title') ? 160 : 1600,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: text.$2),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : (ar ? 'الحقل مطلوب.' : 'Required.'),
                      ),
                    ),
                  for (final money in [
                    (
                      'baseInspectionEgp',
                      'inspection',
                      ar ? 'المعاينة بالجنيه' : 'Inspection in EGP',
                    ),
                    (
                      'serviceFeeEgp',
                      'service-fee',
                      ar ? 'الخدمة بالجنيه' : 'Service in EGP',
                    ),
                    (
                      'estimatedDurationMins',
                      'duration',
                      ar ? 'المدة بالدقائق' : 'Duration in minutes',
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        key: Key('admin-draft-${money.$2}'),
                        controller: _fields[money.$1],
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        maxLength: 7,
                        decoration: InputDecoration(
                          labelText: money.$3,
                          helperText: ar
                              ? 'اتركه فارغًا لو لسه مش محدد.'
                              : 'Leave blank until decided.',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final n = _number(value),
                              durationField = money.$2 == 'duration';
                          return n != null &&
                                  n >= (durationField ? 5 : 0) &&
                                  n <= (durationField ? 1440 : 1000000)
                              ? null
                              : (ar
                                    ? 'اكتب رقم صحيح في النطاق المسموح.'
                                    : 'Enter a whole number within the allowed range.');
                        },
                      ),
                    ),
                  if (inspection != null && service != null)
                    Text(
                      '${ar ? 'الإجمالي قبل رسوم الانتقال' : 'Total before transport'}: ${inspection + service} ${ar ? 'ج.م' : 'EGP'}',
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_reauth)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => AdminConfirmationDialog(ar: ar),
                              );
                            },
                      child: Text(ar ? 'تأكيد حسابك' : 'Confirm your account'),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('admin-draft-save'),
            onPressed: _busy ? null : _save,
            child: Text(
              _busy
                  ? (ar ? 'جاري الحفظ…' : 'Saving…')
                  : (ar ? 'حفظ مسودة' : 'Save draft'),
            ),
          ),
        ],
      ),
    );
  }
}
