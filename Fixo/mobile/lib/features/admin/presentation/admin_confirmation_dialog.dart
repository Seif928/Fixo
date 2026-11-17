import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/email_access_service.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Reconfirm only the currently signed-in account, without switching identity.
class AdminConfirmationDialog extends ConsumerStatefulWidget {
  const AdminConfirmationDialog({super.key, required this.ar});
  final bool ar;
  @override
  ConsumerState<AdminConfirmationDialog> createState() => _State();
}

class _State extends ConsumerState<AdminConfirmationDialog> {
  final _password = TextEditingController();
  late final _user = ref.read(authControllerProvider).session?.user;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy || _user == null || _password.text.isEmpty) return;
    if (ref.read(authControllerProvider).session?.user.id != _user.id) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await ref
          .read(emailAccessProvider)
          .signInWithPhone(_user.phone, _password.text);
      if (!mounted ||
          ref.read(authControllerProvider).session?.user.id != _user.id) {
        return;
      }
      if (session.user.id != _user.id) throw StateError('Account mismatch');
      await ref
          .read(authControllerProvider.notifier)
          .acceptVerifiedSession(session);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = widget.ar
              ? 'تعذر تأكيد الحساب. راجع كلمة المرور وحاول تاني.'
              : 'Could not confirm your account. Check your password and retry.',
        );
      }
    } finally {
      _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final same =
        ref.watch(authControllerProvider).session?.user.id == _user?.id &&
        _user != null;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(widget.ar ? 'تأكيد حسابك' : 'Confirm your account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.ar
                    ? 'اكتب كلمة مرور FIXO الحالية لتأكيد تعديل صلاحيات الإدارة.'
                    : 'Enter your current FIXO password to confirm administration changes.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                enabled: !_busy && same,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: widget.ar
                      ? 'كلمة المرور الحالية'
                      : 'Current password',
                ),
                onSubmitted: (_) => _confirm(),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(widget.ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: _busy || !same ? null : _confirm,
            child: Text(
              _busy
                  ? (widget.ar ? 'جاري التأكيد…' : 'Confirming…')
                  : (widget.ar ? 'تأكيد' : 'Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}
