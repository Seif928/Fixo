import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../data/admin_repository.dart';
import '../../../core/theme/fixo_workspace_theme.dart';

/// Discoverable only after a real successful membership lookup; backend still
/// protects every administrative read and write independently.
class AdminProfileEntry extends ConsumerWidget {
  const AdminProfileEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(adminAccessProvider);
    if (access.isLoading || access.hasError || access.asData == null) {
      return const SizedBox.shrink();
    }
    final ar = ref.watch(
      appLocaleProvider.select((locale) => locale.languageCode == 'ar'),
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings_outlined),
        title: Text(
          access.asData!.value.isOwner
              ? (ar ? 'لوحة المالك' : 'Owner console')
              : (ar ? 'لوحة الإدارة' : 'Administration'),
        ),
        subtitle: Text(
          access.asData!.value.isOwner
              ? (ar
                    ? 'إدارة المشروع والمشرفين'
                    : 'Manage your business and administrators')
              : (ar
                    ? 'متابعة الحجوزات والخدمات'
                    : 'Manage bookings and services'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.admin),
      ),
    );
  }
}

/// Identity labels follow verified server membership; cached user.role is not
/// sufficient to advertise administration authority.
class AccountRoleBadge extends ConsumerWidget {
  const AccountRoleBadge({super.key, required this.professional});
  final bool professional;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final access = ref.watch(adminAccessProvider);
    final member = !access.isLoading && !access.hasError
        ? access.asData?.value
        : null;
    final role = member != null
        ? (member.isOwner ? FixoWorkspace.owner : FixoWorkspace.administrator)
        : professional
        ? FixoWorkspace.professional
        : FixoWorkspace.customer;
    return Semantics(
      label: role.accountLabel(ar),
      child: Text(
        role.accountLabel(ar),
        key: const Key('account-role-badge'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
