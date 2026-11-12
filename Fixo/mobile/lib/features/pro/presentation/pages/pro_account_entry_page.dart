import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../data/pro_repository.dart';

/// Resume using live server approval and dossier progress, never a chosen role.
class ProAccountEntryPage extends ConsumerStatefulWidget {
  const ProAccountEntryPage({super.key});
  @override
  ConsumerState<ProAccountEntryPage> createState() =>
      _ProAccountEntryPageState();
}

class _ProAccountEntryPageState extends ConsumerState<ProAccountEntryPage> {
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _resume();
  }

  Future<void> _resume() async {
    setState(() => _failed = false);
    try {
      final profile = await ref.read(proRepositoryProvider).getMyProfile();
      if (!mounted) return;
      final route = switch (profile?.verificationStatus) {
        'APPROVED' => AppRoutes.proDashboard,
        'PENDING_REVIEW' ||
        'ACTION_REQUIRED' ||
        'SUSPENDED' => AppRoutes.proVerificationStatus,
        _ =>
          profile?.primaryCategoryId != null
              ? AppRoutes.proVerificationDocs
              : profile?.nationalIdSynthetic?.isNotEmpty == true ||
                    profile?.primaryZoneId != null
              ? AppRoutes.proSkills
              : AppRoutes.proSignUp,
      };
      context.go(route);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: const FixoBrandMark(showSubtitle: false)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_failed) const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _failed
                    ? (ar
                          ? 'تعذر تحميل حساب الفني. حاول مرة تانية.'
                          : 'Could not load your professional account. Please retry.')
                    : (ar
                          ? 'جاري تحميل حساب الفني…'
                          : 'Opening your professional account…'),
                textAlign: TextAlign.center,
              ),
              if (_failed) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _resume,
                  child: Text(ar ? 'حاول مرة تانية' : 'Retry'),
                ),
              ],
              TextButton(
                onPressed: () => context.go(AppRoutes.customerProfile),
                child: Text(ar ? 'حسابي' : 'My profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
