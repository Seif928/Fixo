import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/widgets/fixo_brand_mark.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_repository.dart';
import 'admin_confirmation_dialog.dart';
import 'admin_members_panel.dart';
import 'admin_panels.dart';
import 'admin_catalog_panel.dart';

enum _Section { overview, catalog, members, audit }

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});
  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  _Section _selected = _Section.overview;
  bool get _ar => ref.read(appLocaleProvider).languageCode == 'ar';
  void _back() => context.go(AppRoutes.customerProfile);
  void _refresh() {
    ref.invalidate(adminAccessProvider);
    ref.invalidate(adminSummaryProvider);
    ref.invalidate(adminMembersProvider);
    ref.invalidate(adminAuditProvider);
  }

  Future<void> _confirm() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmationDialog(ar: _ar),
    );
    if (mounted && result == true) _refresh();
  }

  Widget _problem(
    Object error,
    VoidCallback retry, {
    bool gate = false,
  }) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(gate ? Icons.lock_outline : Icons.cloud_off_outlined, size: 36),
        const SizedBox(height: 16),
        Text(
          needsAdminConfirmation(error)
              ? (_ar
                    ? 'أكد حسابك للوصول للإدارة.'
                    : 'Confirm your account to access administration.')
              : gate
              ? (_ar
                    ? 'الإدارة غير متاحة للحساب ده.'
                    : 'Administration access is unavailable for this account.')
              : (_ar
                    ? 'تعذر تحميل البيانات. حاول مرة تانية.'
                    : 'Could not load this information. Please retry.'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: needsAdminConfirmation(error) ? _confirm : retry,
          child: Text(
            needsAdminConfirmation(error)
                ? (_ar ? 'تأكيد حسابك' : 'Confirm your account')
                : (_ar ? 'إعادة المحاولة' : 'Retry'),
          ),
        ),
      ],
    ),
  );
  Widget _async<T>(
    AsyncValue<T> value,
    Widget Function(T) content,
    VoidCallback retry,
  ) => value.when(
    skipLoadingOnRefresh: false,
    skipLoadingOnReload: false,
    data: content,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => _problem(error, retry),
  );
  Widget _navigation(AdminAccess access, bool mobile, bool ar) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: FixoBrandMark(showSubtitle: false),
        ),
        Text(
          access.isOwner
              ? (ar ? 'المالك' : 'Owner')
              : (ar ? 'مسؤول الإدارة' : 'Administrator'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        for (final section in _Section.values.where(
          (s) => s != _Section.members || access.isOwner,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              key: Key('admin-nav-${section.name}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              minLeadingWidth: 24,
              horizontalTitleGap: 12,
              selected: _selected == section,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
              leading: Icon(switch (section) {
                _Section.overview => Icons.grid_view_rounded,
                _Section.catalog => Icons.home_repair_service_outlined,
                _Section.members => Icons.admin_panel_settings_outlined,
                _Section.audit => Icons.history_rounded,
              }),
              title: Text(switch (section) {
                _Section.overview => ar ? 'نظرة عامة' : 'Overview',
                _Section.catalog => ar ? 'الخدمات' : 'Services',
                _Section.members => ar ? 'المسؤولون' : 'Administrators',
                _Section.audit => ar ? 'سجل التغييرات' : 'Activity log',
              }),
              onTap: () {
                if (mobile) Navigator.pop(context);
                setState(() => _selected = section);
              },
            ),
          ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(ar ? 'الرجوع للبروفايل' : 'Back to profile'),
          onTap: _back,
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final account = ref.watch(authControllerProvider).session?.user.id;
    final access = ref.watch(adminAccessProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final current = access.asData?.value;
    // No cached authority/content survives logout, account changes or revalidation.
    if (account == null ||
        access.isLoading ||
        current == null ||
        access.hasError) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(ar ? 'إدارة FIXO' : 'FIXO Administration'),
        ),
        body: Center(
          child: account == null
              ? Text(ar ? 'سجّل الدخول الأول.' : 'Sign in first.')
              : access.isLoading
              ? const CircularProgressIndicator()
              : _problem(
                  access.error ?? StateError('Access unavailable'),
                  _refresh,
                  gate: true,
                ),
        ),
      );
    }
    final selected = _selected == _Section.members && !current.isOwner
        ? _Section.overview
        : _selected;
    final panel = switch (selected) {
      _Section.catalog => AdminCatalogPanel(
        key: ValueKey('catalog-$account'),
        ar: ar,
        needsConfirmation: current.needsConfirmation,
      ),
      _Section.overview => _async(
        ref.watch(adminSummaryProvider),
        (data) => AdminSummaryPanel(summary: data, ar: ar),
        () => ref.invalidate(adminSummaryProvider),
      ),
      _Section.members => _async(
        ref.watch(adminMembersProvider),
        (data) => AdminMembersPanel(
          key: ValueKey(account),
          members: data,
          ar: ar,
          needsConfirmation: current.needsConfirmation,
        ),
        () => ref.invalidate(adminMembersProvider),
      ),
      _Section.audit => _async(
        ref.watch(adminAuditProvider),
        (data) => AdminAuditPanel(items: data, ar: ar),
        () => ref.invalidate(adminAuditProvider),
      ),
    };
    return Scaffold(
      appBar: AppBar(
        leading: wide
            ? null
            : Builder(
                builder: (context) => IconButton(
                  tooltip: ar ? 'فتح القائمة' : 'Open menu',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        automaticallyImplyLeading: false,
        title: Text(ar ? 'إدارة FIXO' : 'FIXO Administration'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث البيانات' : 'Refresh data',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : Drawer(child: _navigation(current, true, ar)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            SizedBox(
              key: const Key('admin-sidebar'),
              width: 288,
              child: _navigation(current, false, ar),
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(wide ? 32 : 16),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: panel,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
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
