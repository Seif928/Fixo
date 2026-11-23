import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fixo_colors.dart';
import '../../../core/theme/fixo_spacing.dart';
import '../../../core/widgets/fixo_cards.dart';
import '../data/communications_repository.dart';

/// Recent-alert cards from official Stitch Screen 10, showing persisted activity only.
class NotificationSheet extends ConsumerStatefulWidget {
  const NotificationSheet({super.key});
  @override
  ConsumerState<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends ConsumerState<NotificationSheet> {
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _items = ref.read(communicationsRepositoryProvider).notifications();
  }

  void _reload() {
    setState(() {
      _items = ref.read(communicationsRepositoryProvider).notifications();
    });
  }

  String _status(String? value, bool ar) {
    if (!ar) return value?.replaceAll('_', ' ') ?? '';
    return const {
          'PENDING_DISPATCH': 'بانتظار التوزيع',
          'OFFERED_TO_PRO': 'تم عرض الطلب على فني',
          'CONFIRMED': 'تم تأكيد الحجز',
          'PRO_EN_ROUTE': 'الفني في الطريق',
          'ARRIVED': 'وصل الفني',
          'IN_PROGRESS': 'الخدمة قيد التنفيذ',
          'COMPLETED': 'اكتملت الخدمة',
          'CANCELLED': 'تم إلغاء الحجز',
        }[value] ??
        'تحديث الحجز';
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final local = DateTime.parse(raw).toLocal();
      final y = local.year.toString().padLeft(4, '0');
      final m = local.month.toString().padLeft(2, '0');
      final d = local.day.toString().padLeft(2, '0');
      final h = local.hour.toString().padLeft(2, '0');
      final min = local.minute.toString().padLeft(2, '0');
      return '$y-$m-$d • $h:$min';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    final palette = context.fixoPalette;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: FixoSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.subtleBorder,
                  borderRadius: FixoRadius.borderRadiusPill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FixoSpacing.md,
                FixoSpacing.sm,
                FixoSpacing.sm,
                FixoSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.primaryBrand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: FixoSpacing.sm),
                  Expanded(
                    child: Text(
                      ar ? 'آخر التنبيهات' : 'Recent Alerts',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: ar ? 'تحديث' : 'Refresh',
                    onPressed: _reload,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: palette.deepForest,
                    ),
                  ),
                  IconButton(
                    tooltip: ar ? 'إغلاق' : 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FixoSpacing.md),
              child: Text(
                ar
                    ? 'تحديثات محفوظة داخل التطبيق. حدّث لعرض الأحدث.'
                    : 'Saved in-app updates. Refresh to see the latest.',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                ),
              ),
            ),
            const SizedBox(height: FixoSpacing.sm),
            Divider(height: 1, color: palette.subtleBorder),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _items,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(FixoSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: palette.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.error_outline_rounded,
                                color: palette.error,
                              ),
                            ),
                            const SizedBox(height: FixoSpacing.sm),
                            TextButton(
                              onPressed: _reload,
                              child: Text(
                                ar
                                    ? 'تعذر تحميل التنبيهات. أعد المحاولة.'
                                    : 'Could not load alerts. Retry.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(FixoSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: palette.surfaceContainer,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: palette.mutedText,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: FixoSpacing.sm),
                            Text(
                              ar ? 'لا توجد تنبيهات حاليًا.' : 'No alerts yet.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: palette.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(FixoSpacing.md),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: FixoSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final message = item['kind'] == 'UNREAD_MESSAGE';
                      final orderCode = item['orderCode']?.toString() ?? '';
                      final createdAt = _formatTimestamp(
                        item['createdAt'] as String?,
                      );

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: FixoRadius.borderRadiusMd,
                          onTap: () {
                            final router = GoRouter.of(context);
                            Navigator.pop(context);
                            router.push(
                              '/customer/orders/${Uri.encodeComponent(item['bookingId'] as String)}/chat',
                            );
                          },
                          child: FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            borderRadius: FixoRadius.borderRadiusMd,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: message
                                        ? palette.primaryBrand
                                        : palette.surfaceHigh,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    message
                                        ? Icons.chat_bubble_outline_rounded
                                        : Icons.notifications_active_outlined,
                                    size: 19,
                                    color: message
                                        ? palette.onPrimary
                                        : palette.deepForest,
                                  ),
                                ),
                                const SizedBox(width: FixoSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              message
                                                  ? (ar
                                                        ? 'رسالة غير مقروءة'
                                                        : 'Unread message')
                                                  : _status(
                                                      item['status'] as String?,
                                                      ar,
                                                    ),
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                          if (orderCode.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: palette.surfaceContainer,
                                                borderRadius: FixoRadius
                                                    .borderRadiusPill,
                                              ),
                                              child: Text(
                                                '#$orderCode',
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: palette.deepForest,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        createdAt,
                                        textDirection: TextDirection.ltr,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: FixoSpacing.xs),
                                Icon(
                                  ar
                                      ? Icons.chevron_left_rounded
                                      : Icons.chevron_right_rounded,
                                  size: 20,
                                  color: palette.mutedText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
