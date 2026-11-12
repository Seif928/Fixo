import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_repository.dart';
import 'admin_confirmation_dialog.dart';

class AdminMembersPanel extends ConsumerStatefulWidget {
  const AdminMembersPanel({
    super.key,
    required this.members,
    required this.ar,
    required this.needsConfirmation,
  });
  final List<AdminMember> members;
  final bool ar;
  final bool needsConfirmation;
  @override
  ConsumerState<AdminMembersPanel> createState() => _State();
}

class _State extends ConsumerState<AdminMembersPanel> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false, _confirmNeeded = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _change({required bool revoke}) async {
    if (_busy ||
        widget.needsConfirmation ||
        (!revoke && !_form.currentState!.validate())) {
      return;
    }
    final owner = ref.read(authControllerProvider).session?.user.id;
    final email = _email.text.trim().toLowerCase();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(
          widget.ar
              ? (revoke ? 'إلغاء صلاحيات المسؤول؟' : 'السماح للمسؤول الثاني؟')
              : (revoke
                    ? 'Revoke administrator access?'
                    : 'Authorize the second administrator?'),
        ),
        content: Text(
          revoke
              ? (widget.ar
                    ? 'هيفقد المسؤول الثاني صلاحيات الإدارة فورًا. حسابه العادي هيفضل موجود.'
                    : 'The second administrator immediately loses administration access. Their regular account remains.')
              : (widget.ar
                    ? 'السماح لـ $email. أي مسؤول ثانٍ سابق هيفقد صلاحياته فورًا. الدعوة صالحة ٧ أيام ومش هنبعت إيميل تلقائي.'
                    : 'Authorize $email. Any previous second administrator loses access immediately. The invitation expires in 7 days; no email is sent automatically.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('admin-confirm-action'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.ar ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        owner == null ||
        ref.read(authControllerProvider).session?.user.id != owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _confirmNeeded = false;
    });
    try {
      final repository = ref.read(adminRepositoryProvider);
      if (revoke) {
        await repository.revoke();
      } else {
        await repository.invite(email);
      }
      if (!mounted ||
          ref.read(authControllerProvider).session?.user.id != owner) {
        return;
      }
      _email.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.ar
                  ? 'تم حفظ صلاحيات الإدارة.'
                  : 'Administration access saved.',
            ),
          ),
        );
      ref.invalidate(adminMembersProvider);
      ref.invalidate(adminAuditProvider);
    } catch (error) {
      if (mounted &&
          ref.read(authControllerProvider).session?.user.id == owner) {
        setState(() {
          _confirmNeeded = needsAdminConfirmation(error);
          _error = _confirmNeeded
              ? (widget.ar
                    ? 'أكد حسابك، وبعدها أعد المحاولة.'
                    : 'Confirm your account, then retry the change.')
              : (widget.ar
                    ? 'تعذر تأكيد حفظ الصلاحيات. أعد تحميل القائمة قبل المحاولة تاني.'
                    : 'Could not confirm this change. Reload the list before retrying.');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'مسؤولو الإدارة' : 'Administrators',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'مالك واحد ومسؤول إضافي واحد. إدارة العضوية متاحة للمالك فقط.'
              : 'One owner and one additional administrator. Only the owner manages membership.',
        ),
        const SizedBox(height: 20),
        for (final member in widget.members)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.role == 'OWNER'
                        ? (ar ? 'المالك' : 'Owner')
                        : (ar ? 'المسؤول' : 'Admin'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(member.email, textDirection: TextDirection.ltr),
                  const SizedBox(height: 4),
                  Text(
                    !member.active
                        ? (ar ? 'الصلاحيات ملغاة' : 'Access revoked')
                        : member.expiresAt != null &&
                              member.expiresAt!.isBefore(DateTime.now())
                        ? (ar ? 'الدعوة انتهت' : 'Invitation expired')
                        : member.bound
                        ? (ar ? 'نشط' : 'Active')
                        : (ar
                              ? 'في انتظار تسجيل الدخول بالبريد المدعو — خلال ٧ أيام'
                              : 'Awaiting sign-in with the invited email — within 7 days'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        Form(
          key: _form,
          child: TextFormField(
            key: const Key('admin-invite-email'),
            controller: _email,
            enabled: !_busy && !widget.needsConfirmation,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            maxLength: 254,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: ar
                  ? 'بريد المسؤول الثاني'
                  : 'Second administrator email',
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            validator: (value) =>
                value != null &&
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
                ? null
                : (ar
                      ? 'اكتب بريد إلكتروني صحيح.'
                      : 'Enter a valid email address.'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const Key('admin-invite-submit'),
              onPressed: _busy || widget.needsConfirmation
                  ? null
                  : () => _change(revoke: false),
              icon: const Icon(Icons.person_add_alt),
              label: Text(ar ? 'السماح للمسؤول' : 'Authorize administrator'),
            ),
            OutlinedButton.icon(
              key: const Key('admin-revoke'),
              onPressed:
                  _busy ||
                      widget.needsConfirmation ||
                      !widget.members.any((m) => m.role == 'ADMIN' && m.active)
                  ? null
                  : () => _change(revoke: true),
              icon: const Icon(Icons.person_remove_outlined),
              label: Text(
                ar ? 'إلغاء صلاحيات المسؤول' : 'Revoke administrator',
              ),
            ),
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_confirmNeeded || widget.needsConfirmation)
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    final valid = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => AdminConfirmationDialog(ar: ar),
                    );
                    if (mounted && valid == true) {
                      ref.invalidate(adminAccessProvider);
                    }
                  },
            child: Text(ar ? 'تأكيد حسابك' : 'Confirm your account'),
          ),
      ],
    );
  }
}
