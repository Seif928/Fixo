import 'dart:async';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_booking_models.dart';
import '../data/admin_repository.dart';
import 'admin_booking_detail_dialog.dart';

class AdminBookingsPanel extends ConsumerStatefulWidget {
  const AdminBookingsPanel({super.key, required this.ar});
  final bool ar;
  @override
  ConsumerState<AdminBookingsPanel> createState() => _State();
}

class _State extends ConsumerState<AdminBookingsPanel> {
  final _search = TextEditingController();
  Timer? _debounce;
  CancelToken? _cancel;
  int _page = 1;
  String _status = '';
  late Future<AdminBookingPage> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AdminBookingPage> _load() {
    _cancel?.cancel();
    _cancel = CancelToken();
    return ref
        .read(adminRepositoryProvider)
        .bookings(
          page: _page,
          status: _status,
          search: _search.text.trim(),
          cancelToken: _cancel,
        );
  }

  void _reload() {
    if (mounted) {
      final future = _load();
      setState(() {
        _future = future;
      });
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminBookingsRevisionProvider, (_, _) => _reload());
    final ar = widget.ar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'الحجوزات والمتابعة' : 'Bookings and operations',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'راجع الطلب وسجله قبل أي تغيير. إرسال عرض للفني لا يعني قبوله أو تحصيل الدفع.'
              : 'Review the booking and its history before acting. Sending an offer does not confirm acceptance or collect payment.',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final search = TextField(
              controller: _search,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: ar ? 'ابحث برقم الطلب' : 'Search order code',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _page = 1;
                  _reload();
                });
              },
            );
            final status = DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: InputDecoration(labelText: ar ? 'الحالة' : 'Status'),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(ar ? 'كل الحالات' : 'All statuses'),
                ),
                for (final s in adminBookingStatuses)
                  DropdownMenuItem(
                    value: s,
                    child: Text(
                      adminBookingStatusLabel(s, ar),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                _status = v ?? '';
                _page = 1;
                _reload();
              },
            );
            return c.maxWidth < 600
                ? Column(children: [search, const SizedBox(height: 12), status])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: search),
                      const SizedBox(width: 16),
                      Expanded(child: status),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        FutureBuilder<AdminBookingPage>(
          future: _future,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return Column(
                children: [
                  Text(
                    ar ? 'تعذر تحميل الحجوزات.' : 'Could not load bookings.',
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              );
            }
            final data = s.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.meta.total} ${ar ? 'طلب' : 'bookings'}'),
                const SizedBox(height: 12),
                if (data.items.isEmpty)
                  Text(
                    ar
                        ? 'مفيش حجوزات مطابقة للبحث أو الحالة.'
                        : 'No bookings match this search or status.',
                  ),
                for (final b in data.items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.code,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(ar ? b.titleAr : b.titleEn),
                          Text(adminBookingStatusLabel(b.status, ar)),
                          Text(
                            '${MaterialLocalizations.of(context).formatFullDate(b.date)} · ${adminTimeWindowLabel(b.timeWindow, ar)}',
                          ),
                          Text('${b.total} ${ar ? 'ج.م' : 'EGP'}'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: Key('admin-booking-open-${b.id}'),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) =>
                                  AdminBookingDetailDialog(id: b.id, ar: ar),
                            ),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text(
                              ar ? 'تفاصيل الطلب' : 'Booking details',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              _page--;
                              _reload();
                            }
                          : null,
                      child: Text(ar ? 'السابق' : 'Previous'),
                    ),
                    Text('$_page / ${data.meta.totalPages}'),
                    TextButton(
                      onPressed: _page < data.meta.totalPages
                          ? () {
                              _page++;
                              _reload();
                            }
                          : null,
                      child: Text(ar ? 'التالي' : 'Next'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
