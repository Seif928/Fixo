import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/router/customer_tab_navigation.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../../customer_home/presentation/widgets/customer_home_widgets.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';
import '../widgets/booking_receipt_sheet.dart';

/// Live Stitch Screen 08; the Chat tab lists the user's actual booking threads.
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key, this.showChats = false});
  final bool showChats;
  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final _scroll = ScrollController();
  final List<BookingDetailModel> _items = [];
  String _tab = 'active';
  bool _loading = true, _loadingMore = false, _failed = false, _hasMore = false;
  int _offset = 0, _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || !_hasMore)) return;
    final generation = more ? _generation : ++_generation;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _offset = 0;
      }
      _failed = false;
    });
    try {
      final rows = await ref
          .read(bookingRepositoryProvider)
          .getBookings(
            tab: widget.showChats ? null : _tab,
            limit: 20,
            offset: more ? _offset : 0,
          );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (!more) _items.clear();
        for (final row in rows) {
          if (!_items.any((item) => item.id == row.id)) _items.add(row);
        }
        _offset += rows.length;
        _hasMore = rows.length == 20;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _failed = true;
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  String _status(String value, bool ar) => switch (value) {
    'DRAFT' => ar ? 'مسودة' : 'Draft',
    'PENDING_DISPATCH' => ar ? 'بانتظار إسناد فني' : 'Awaiting assignment',
    'CONFIRMED' => ar ? 'مؤكد' : 'Confirmed',
    'PRO_EN_ROUTE' => ar ? 'الفني في الطريق' : 'Professional en route',
    'ARRIVED' => ar ? 'وصل الفني' : 'Professional arrived',
    'IN_PROGRESS' => ar ? 'جارٍ التنفيذ' : 'In progress',
    'COMPLETED' => ar ? 'مكتمل' : 'Completed',
    'CANCELLED' => ar ? 'ملغي' : 'Cancelled',
    _ => value,
  };

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horizontal = (MediaQuery.sizeOf(context).width - 680) / 2;
    final inset = horizontal > 16 ? horizontal : 16.0;
    final visible = widget.showChats
        ? _items.where((item) => item.proProfile != null).toList()
        : _items;
    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        backgroundColor: palette.cardSurface.withValues(alpha: 0.94),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: FixoSpacing.md,
        title: Row(
          children: [
            const FixoBrandMark(showSubtitle: false, iconBoxSize: 28),
            const SizedBox(width: FixoSpacing.sm),
            Expanded(
              child: Text(
                widget.showChats
                    ? (ar ? 'المحادثات' : 'Conversations')
                    : (ar ? 'طلباتي' : 'My Orders'),
                overflow: TextOverflow.ellipsis,
                style: FixoTypography.headlineSm(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث' : 'Refresh',
            onPressed: _loading ? null : () => _load(),
            icon: Icon(
              Icons.refresh_rounded,
              color: palette.deepForest,
              size: 20,
            ),
          ),
          const SizedBox(width: FixoSpacing.xs),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: palette.subtleBorder, height: 1.0),
        ),
      ),
      bottomNavigationBar: FixoCustomerBottomNav(
        currentIndex: widget.showChats ? 2 : 1,
        isArabic: ar,
        onTabSelected: (index) => navigateCustomerTab(context, index),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.showChats)
              Padding(
                padding: EdgeInsets.fromLTRB(inset, 14, inset, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return palette.primaryBrand;
                        }
                        return palette.surfaceContainer;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return palette.mutedText;
                      }),
                      side: WidgetStatePropertyAll(
                        BorderSide(color: palette.subtleBorder),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: FixoRadius.borderRadiusPill,
                        ),
                      ),
                      textStyle: WidgetStatePropertyAll(
                        FixoTypography.labelMd(
                          color: palette.inkText,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    segments: [
                      ButtonSegment(
                        value: 'active',
                        label: Text(ar ? 'نشطة' : 'Active'),
                      ),
                      ButtonSegment(
                        value: 'completed',
                        label: Text(ar ? 'مكتملة' : 'Completed'),
                      ),
                      ButtonSegment(
                        value: 'cancelled',
                        label: Text(ar ? 'ملغاة' : 'Cancelled'),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (values) {
                      if (_tab == values.first) return;
                      setState(() => _tab = values.first);
                      _load();
                    },
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(inset, 6, inset, 24),
                        children: [
                          if (_failed)
                            FixoSurfaceCard(
                              padding: const EdgeInsets.all(FixoSpacing.md),
                              borderRadius: FixoRadius.borderRadiusLg,
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: FixoColors.error,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ar
                                        ? 'تعذّر تحميل القائمة.'
                                        : 'Could not load the list.',
                                    style: FixoTypography.bodyMd(
                                      color: palette.inkText,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: () => _load(),
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      ar ? 'إعادة المحاولة' : 'Retry',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!_failed && visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: FixoSurfaceCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: FixoSpacing.lg,
                                  vertical: FixoSpacing.xl,
                                ),
                                borderRadius: FixoRadius.borderRadiusLg,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: palette.surfaceLow,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: palette.subtleBorder,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        widget.showChats
                                            ? Icons.chat_bubble_outline_rounded
                                            : Icons.receipt_long_outlined,
                                        size: 28,
                                        color: isDark
                                            ? palette.limeAccent
                                            : palette.deepForest,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      widget.showChats
                                          ? (ar
                                                ? 'لا توجد محادثات متاحة بعد.'
                                                : 'No conversations available yet.')
                                          : (ar
                                                ? 'لا توجد طلبات في هذه القائمة.'
                                                : 'No bookings in this list.'),
                                      textAlign: TextAlign.center,
                                      style: FixoTypography.labelLg(
                                        color: palette.inkText,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if (widget.showChats) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        ar
                                            ? 'تظهر المحادثة بعد إسناد الطلب لفني.'
                                            : 'Conversations appear after a professional is assigned.',
                                        textAlign: TextAlign.center,
                                        style: FixoTypography.bodySm(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          for (final booking in visible)
                            _card(context, booking, ar),
                          if (_hasMore)
                            TextButton(
                              onPressed: _loadingMore
                                  ? null
                                  : () => _load(more: true),
                              child: Text(
                                _loadingMore
                                    ? (ar ? 'جارٍ التحميل...' : 'Loading...')
                                    : (ar ? 'تحميل المزيد' : 'Load more'),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, BookingDetailModel booking, bool ar) {
    final title = booking.offering[ar ? 'titleAr' : 'titleEn'] as String?;
    final date = DateTime.tryParse(booking.scheduledDate);
    final text = title?.trim().isNotEmpty == true
        ? title!
        : (ar ? 'حجز خدمة' : 'Service booking');
    final palette = context.fixoPalette;
    final isDraft = booking.status == 'DRAFT';
    final isCompleted = booking.status == 'COMPLETED';
    final isCancelled = booking.status == 'CANCELLED';

    return Padding(
      key: ValueKey('booking-${booking.id}'),
      padding: const EdgeInsets.only(bottom: 14),
      child: FixoSurfaceCard(
        padding: const EdgeInsets.all(FixoSpacing.md),
        borderRadius: FixoRadius.borderRadiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceLow,
                    borderRadius: FixoRadius.borderRadiusPill,
                    border: Border.all(color: palette.subtleBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 14,
                        color: palette.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#${booking.orderCode}',
                        style: FixoTypography.labelMd(
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? FixoColors.secondaryContainer
                        : isCancelled
                        ? FixoColors.errorContainer
                        : palette.surfaceHigh,
                    borderRadius: FixoRadius.borderRadiusPill,
                  ),
                  child: Text(
                    _status(booking.status, ar),
                    style: FixoTypography.labelMd(
                      color: isCompleted
                          ? FixoColors.onSecondaryContainer
                          : isCancelled
                          ? FixoColors.onErrorContainer
                          : palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.surfaceLow,
                    borderRadius: FixoRadius.borderRadiusMd,
                    border: Border.all(color: palette.subtleBorder),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.home_repair_service_rounded,
                    size: 22,
                    color: palette.deepForest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: FixoTypography.headlineSm(
                          color: palette.inkText,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: palette.mutedText,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                DateFormat.yMMMd(ar ? 'ar' : 'en').format(date),
                                style: FixoTypography.bodySm(
                                  color: palette.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: palette.subtleBorder),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                Text(
                  '${booking.pricing.totalEgp} ${ar ? 'ج.م — قيمة الحجز' : 'EGP — booking total'}',
                  style: FixoTypography.labelLg(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!widget.showChats) ...[
                      if (isDraft)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            backgroundColor: palette.primaryBrand,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: FixoRadius.borderRadiusMd,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () async {
                            await context.push(
                              AppRoutes.checkout.replaceFirst(
                                ':bookingId',
                                Uri.encodeComponent(booking.id),
                              ),
                            );
                            if (mounted) _load();
                          },
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: Text(
                            ar ? 'استكمال الحجز' : 'Continue checkout',
                          ),
                        )
                      else ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            foregroundColor: palette.deepForest,
                            side: BorderSide(color: palette.subtleBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: FixoRadius.borderRadiusMd,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () => context.push(
                            AppRoutes.orderTracking.replaceFirst(
                              ':orderId',
                              Uri.encodeComponent(booking.id),
                            ),
                          ),
                          icon: const Icon(Icons.near_me_outlined, size: 16),
                          label: Text(
                            ar ? 'تتبع الطلب' : 'Live tracking',
                          ),
                        ),
                        if (isCompleted) ...[
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              backgroundColor: FixoColors.primaryForest,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: FixoRadius.borderRadiusMd,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => context.push(
                              AppRoutes.rateReview.replaceFirst(
                                ':orderId',
                                Uri.encodeComponent(booking.id),
                              ),
                            ),
                            icon: const Icon(Icons.star_rate_rounded, size: 16),
                            label: Text(
                              ar ? 'تقييم الخدمة' : 'Rate & Review',
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              foregroundColor: palette.deepForest,
                              side: BorderSide(color: palette.subtleBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: FixoRadius.borderRadiusMd,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => BookingReceiptSheet.show(
                              context,
                              bookingId: booking.id,
                              isArabic: ar,
                            ),
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 16,
                            ),
                            label: Text(ar ? 'الإيصال' : 'Receipt'),
                          ),
                        ],
                      ],
                    ],
                    if (booking.proProfile != null)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          backgroundColor: palette.primaryBrand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: FixoRadius.borderRadiusMd,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => context.push(
                          AppRoutes.customerChat.replaceFirst(
                            ':orderId',
                            Uri.encodeComponent(booking.id),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text(ar ? 'المحادثة' : 'Conversation'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
