import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../data/complaints_models.dart';
import '../../data/complaints_repository.dart';

class MyComplaintsPage extends ConsumerStatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  ConsumerState<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends ConsumerState<MyComplaintsPage> {
  bool _loading = true;
  String? _error;
  List<ComplaintItemModel> _complaints = [];

  bool get _isArabic => ref.watch(appLocaleProvider).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(complaintsRepositoryProvider);
      final list = await repo.listMyComplaints();
      if (mounted) {
        setState(() {
          _complaints = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = _isArabic
              ? 'تعذر تحميل الشكاوى. يرجى إعادة المحاولة.'
              : 'Could not load complaints. Please retry.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final textTheme = Theme.of(context).textTheme;
    final ar = _isArabic;

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        title: Text(
          ar ? 'الشكاوى والبلاغات' : 'My Complaints',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.inkText,
          ),
        ),
        backgroundColor: palette.surfaceContainer,
        elevation: 0,
        leading: BackButton(
          color: palette.inkText,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildBody(palette, textTheme, ar),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    FixoPaletteExtension palette,
    TextTheme textTheme,
    bool ar,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(FixoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: palette.coralUrgent),
              const SizedBox(height: FixoSpacing.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: palette.mutedText),
              ),
              const SizedBox(height: FixoSpacing.md),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_complaints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(FixoSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sentiment_satisfied_alt_outlined,
                  size: 36,
                  color: palette.primaryBrand,
                ),
              ),
              const SizedBox(height: FixoSpacing.md),
              Text(
                ar ? 'سجل الشكاوى نظيف' : 'No Complaints',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.inkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ar
                    ? 'لم تقم بتقديم أي شكاوى حتى الآن. نتمنى لك دوماً تجربة مريحة وممتازة!'
                    : 'You have not submitted any complaints yet.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: palette.mutedText),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(FixoSpacing.md),
        itemCount: _complaints.length,
        separatorBuilder: (_, _) => const SizedBox(height: FixoSpacing.md),
        itemBuilder: (context, index) {
          final item = _complaints[index];
          return _buildComplaintCard(item, palette, textTheme, ar);
        },
      ),
    );
  }

  Widget _buildComplaintCard(
    ComplaintItemModel item,
    FixoPaletteExtension palette,
    TextTheme textTheme,
    bool ar,
  ) {
    final statusColor = switch (item.status) {
      ComplaintStatus.open => Colors.orange,
      ComplaintStatus.inReview => Colors.blue,
      ComplaintStatus.resolved => Colors.green,
      ComplaintStatus.rejected => palette.coralUrgent,
    };

    return FixoSurfaceCard(
      key: Key('complaint-card-${item.id}'),
      padding: const EdgeInsets.all(FixoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Category and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(item.category.icon, size: 18, color: palette.primaryBrand),
                  const SizedBox(width: 6),
                  Text(
                    item.category.localizedLabel(ar),
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.inkText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                child: Text(
                  item.status.localizedLabel(ar),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Order code and title
          Text(
            ar
                ? 'طلب #${item.orderCode ?? ""} - ${item.localizedServiceTitle(ar)}'
                : 'Order #${item.orderCode ?? ""} - ${item.localizedServiceTitle(ar)}',
            style: textTheme.bodySmall?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: FixoSpacing.sm),

          // Complaint text
          Text(
            item.description,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.inkText,
            ),
          ),

          // Admin notes if resolved or reviewed
          if (item.adminNotes != null && item.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: FixoSpacing.sm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surfaceContainer,
                borderRadius: FixoRadius.borderRadiusSm,
                border: Border(
                  right: ar
                      ? BorderSide(color: statusColor, width: 3)
                      : BorderSide.none,
                  left: ar
                      ? BorderSide.none
                      : BorderSide(color: statusColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 14, color: palette.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        ar ? 'رد الإدارة' : 'Resolution Note',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.adminNotes!,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.inkText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
