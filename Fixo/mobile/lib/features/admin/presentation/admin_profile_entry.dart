import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../data/admin_repository.dart';

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
        title: Text(ar ? 'لوحة الإدارة' : 'Administration'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.admin),
      ),
    );
  }
}

