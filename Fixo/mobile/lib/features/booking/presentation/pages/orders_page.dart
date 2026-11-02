import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/router/customer_tab_navigation.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../customer_home/presentation/widgets/customer_home_widgets.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';

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
    final horizontal = (MediaQuery.sizeOf(context).width - 680) / 2;
    final inset = horizontal > 16 ? horizontal : 16.0;
    final visible = widget.showChats
        ? _items.where((item) => item.proProfile != null).toList()
        : _items;
    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        title: Text(
          widget.showChats
              ? (ar ? 'المحادثات' : 'Conversations')
              : (ar ? 'طلباتي' : 'My Orders'),
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
                padding: EdgeInsets.symmetric(horizontal: inset, vertical: 16),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
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
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(inset, 4, inset, 24),
                        children: [
                          if (_failed)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      ar
                                          ? 'تعذّر تحميل القائمة.'
                                          : 'Could not load the list.',
                                    ),
                                    TextButton(
                                      onPressed: () => _load(),
                                      child: Text(
                                        ar ? 'إعادة المحاولة' : 'Retry',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!_failed && visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 64),
                              child: Column(
                                children: [
                                  Icon(
                                    widget.showChats
                                        ? Icons.chat_bubble_outline
                                        : Icons.receipt_long_outlined,
                                    size: 48,
                                    color: palette.mutedText,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.showChats
                                        ? (ar
                                              ? 'لا توجد محادثات متاحة بعد.'
                                              : 'No conversations available yet.')
                                        : (ar
                                              ? 'لا توجد طلبات في هذه القائمة.'
                                              : 'No bookings in this list.'),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (widget.showChats)
                                    Text(
                                      ar
                                          ? 'تظهر المحادثة بعد إسناد الطلب لفني.'
                                          : 'Conversations appear after a professional is assigned.',
                                      textAlign: TextAlign.center,
                                    ),
                                ],
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
    return Card(
      key: ValueKey('booking-${booking.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  '#${booking.orderCode}',
                  style: TextStyle(color: palette.mutedText),
                ),
                Text(
                  _status(booking.status, ar),
                  style: TextStyle(
                    color: palette.deepForest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: Theme.of(context).textTheme.titleMedium),
            if (date != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(DateFormat.yMMMd(ar ? 'ar' : 'en').format(date)),
              ),
            const SizedBox(height: 12),
            Text(
              '${booking.pricing.totalEgp} ${ar ? 'ج.م — قيمة الحجز' : 'EGP — booking total'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!widget.showChats)
                  OutlinedButton(
                    onPressed: () async {
                      if (booking.status == 'DRAFT') {
                        await context.push(
                          AppRoutes.checkout.replaceFirst(
                            ':bookingId',
                            Uri.encodeComponent(booking.id),
                          ),
                        );
                        if (mounted) _load();
                      } else {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '#${booking.orderCode}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Text(text),
                                Text(_status(booking.status, ar)),
                                if (date != null)
                                  Text(
                                    DateFormat.yMMMd(
                                      ar ? 'ar' : 'en',
                                    ).format(date),
                                  ),
                                const Divider(height: 28),
                                Text(
                                  '${ar ? 'المعاينة' : 'Inspection'}: ${booking.pricing.baseInspectionEgp} ${ar ? 'ج.م' : 'EGP'}',
                                ),
                                Text(
                                  '${ar ? 'الخدمة' : 'Service'}: ${booking.pricing.serviceFeeEgp} ${ar ? 'ج.م' : 'EGP'}',
                                ),
                                Text(
                                  '${ar ? 'الانتقال' : 'Transport'}: ${booking.pricing.transportFeeEgp} ${ar ? 'ج.م' : 'EGP'}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${ar ? 'قيمة الحجز' : 'Booking total'}: ${booking.pricing.totalEgp} ${ar ? 'ج.م' : 'EGP'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(ar ? 'إغلاق' : 'Close'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      booking.status == 'DRAFT'
                          ? (ar ? 'استكمال الحجز' : 'Continue checkout')
                          : (ar ? 'ملخص الحجز' : 'Booking summary'),
                    ),
                  ),
                if (booking.proProfile != null)
                  FilledButton.icon(
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
      ),
    );
  }
}
