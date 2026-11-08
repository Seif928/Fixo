import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/profile_repository.dart';
import 'controllers/profile_controller.dart';

class ProfileDetailsDialog extends ConsumerStatefulWidget {
  const ProfileDetailsDialog({
    super.key,
    required this.initialValue,
    required this.isPhone,
    required this.isArabic,
  });
  final String initialValue;
  final bool isPhone, isArabic;
  @override
  ConsumerState<ProfileDetailsDialog> createState() =>
      _ProfileDetailsDialogState();
}

class _ProfileDetailsDialogState extends ConsumerState<ProfileDetailsDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _value;
  final _password = TextEditingController();
  late final String? _owner;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _value = TextEditingController(text: widget.initialValue);
    _owner = ref.read(authControllerProvider).session?.user.id;
  }

  @override
  void dispose() {
    _value.dispose();
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_owner == null ||
        ref.read(authControllerProvider).session?.user.id != _owner) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(profileControllerProvider.notifier);
      if (widget.isPhone) {
        final phone = EgyptPhoneValidator.tryNormalize(_value.text)!;
        await controller.updatePhone(
          phone: phone,
          password: _password.text,
        );
      } else {
        await controller.updateDisplayName(_value.text.trim());
      }
      if (!mounted ||
          ref.read(authControllerProvider).session?.user.id != _owner) {
        return;
      }
      Navigator.pop(context, true);
    } on ProfileApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.isUnauthorized
              ? (widget.isArabic
                  ? 'تعذر تأكيد كلمة المرور. راجع كلمة مرورك الحالية.'
                  : 'Password confirmation failed. Check your current password.')
              : error.isConflict
              ? (widget.isArabic
                  ? 'لا يمكن استخدام الرقم ده للحساب. راجع الرقم أو حاول تاني.'
                  : 'This phone cannot be used for this account. Check it or retry.')
              : (widget.isArabic
                  ? 'تعذر تأكيد حفظ التغيير. حاول تاني.'
                  : 'Could not confirm this change. Please retry.');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = widget.isArabic
              ? 'تعذر تأكيد حفظ التغيير. حاول تاني.'
              : 'Could not confirm this change. Please retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    if (ref.watch(authControllerProvider).session?.user.id != _owner) {
      return AlertDialog(
        title: Text(ar ? 'جلسة الحساب اتغيرت' : 'Account session changed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إغلاق' : 'Close'),
          ),
        ],
      );
    }
    return PopScope(
      canPop: !_saving,
      child: Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(
            widget.isPhone
                ? (ar ? 'تغيير رقم الدخول' : 'Change sign-in phone')
                : (ar ? 'تعديل الاسم' : 'Edit name'),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('edit-profile-value'),
                    controller: _value,
                    enabled: !_saving,
                    keyboardType: widget.isPhone
                        ? TextInputType.phone
                        : TextInputType.name,
                    textDirection: widget.isPhone ? TextDirection.ltr : null,
                    maxLength: widget.isPhone ? 24 : 100,
                    decoration: InputDecoration(
                      labelText: widget.isPhone
                          ? (ar ? 'رقم الموبايل الجديد' : 'New mobile number')
                          : (ar ? 'الاسم' : 'Name'),
                    ),
                    validator: (value) {
                      if (widget.isPhone) {
                        return EgyptPhoneValidator.validate(
                          value ?? '',
                          isArabic: ar,
                        );
                      }
                      final name = value?.trim() ?? '';
                      return name.length < 2 ||
                              name.length > 100 ||
                              RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)
                          ? (ar
                                ? 'اكتب اسمًا صحيحًا من حرفين على الأقل.'
                                : 'Enter a valid name with at least 2 characters.')
                          : null;
                    },
                  ),
                  if (widget.isPhone) ...[
                    Text(
                      ar
                          ? 'أكد بكلمة مرور FIXO الحالية. هيتسجّل خروج من الجلسات القديمة بعد التغيير، من غير SMS.'
                          : 'Confirm with your current FIXO password. Previous sessions will be signed out after this change. No SMS.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('confirm-profile-password'),
                      controller: _password,
                      enabled: !_saving,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: ar
                            ? 'كلمة المرور الحالية'
                            : 'Current password',
                      ),
                      validator: (v) => v == null || v.isEmpty || v.length > 128
                          ? (ar
                                ? 'اكتب كلمة مرورك الحالية.'
                                : 'Enter your current password.')
                          : null,
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              key: const Key('save-profile-details'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(ar ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
