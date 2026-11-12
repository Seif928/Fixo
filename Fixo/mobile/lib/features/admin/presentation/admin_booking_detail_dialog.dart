import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_booking_models.dart';
import '../data/admin_repository.dart';
import 'admin_booking_action_dialog.dart';
import 'admin_confirmation_dialog.dart';

class AdminBookingDetailDialog extends ConsumerStatefulWidget {
  const AdminBookingDetailDialog({
    super.key,
    required this.id,
    required this.ar,
  });
  final String id;
  final bool ar;
  @override
  ConsumerState<AdminBookingDetailDialog> createState() => _State();
}

class _State extends ConsumerState<AdminBookingDetailDialog> {
  late final _owner = ref.read(authControllerProvider).session?.user.id;
  CancelToken? _cancel;
  bool _sessionChanged = false, _busy = false, _reauth = false;
  String? _error;
  late Future<AdminBookingDetail> _future;
  bool get _active =>
      !_sessionChanged &&
      _owner != null &&
      ref.read(authControllerProvider).session?.user.id == _owner;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AdminBookingDetail> _load() {
    _cancel?.cancel();
    _cancel = CancelToken();
    return ref
        .read(adminRepositoryProvider)
        .booking(widget.id, cancelToken: _cancel);
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!_active) {
      return;
    }
    setState(() {
      _error = null;
      _reauth = false;
      _future = _load();
    });
  }

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmationDialog(ar: widget.ar),
    );
    if (mounted && _active && ok == true) {
      _reload();
    }
  }

  Future<void> _act(AdminBookingDetail d, bool offer) async {
    if (!_active || _busy) {
      return;
    }
    final value = await showDialog<String>(
      context: context,
      builder: (_) =>
          AdminBookingActionDialog(id: widget.id, ar: widget.ar, offer: offer),
    );
    if (value == null || !mounted || !_active) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _reauth = false;
    });
    try {
      if (offer) {
        await ref
            .read(adminRepositoryProvider)
            .offerBooking(d, value, cancelToken: _cancel);
      } else {
        await ref
            .read(adminRepositoryProvider)
            .cancelBooking(d, value, cancelToken: _cancel);
      }
      if (!mounted || !_active) {
        return;
      }
      ref.invalidate(adminSummaryProvider);
      ref.invalidate(adminAuditProvider);
      ref.read(adminBookingsRevisionProvider.notifier).state++;
      if (offer) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ar
                  ? 'تم إرسال العرض. الإسناد يتم بعد قبول الفني.'
                  : 'Offer is pending. Assignment requires the professional’s acceptance.',
            ),
          ),
        );
      }
      _reload();
    } catch (error) {
      if (mounted && _active) {
        setState(() {
          _reauth = needsAdminConfirmation(error);
          _error = widget.ar
              ? 'تعذر تأكيد الإجراء. حدّث الطلب وراجع حالته قبل المحاولة.'
              : 'Could not confirm this action. Reload and check the booking before retrying.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.session?.user.id), (
      _,
      id,
    ) {
      if (id != _owner && !_sessionChanged) {
        _cancel?.cancel();
        if (mounted) {
          setState(() => _sessionChanged = true);
        }
      }
    });
    final ar = widget.ar;
    return AlertDialog(
      scrollable: true,
      title: Text(ar ? 'تفاصيل الحجز' : 'Booking details'),
      content: SizedBox(
        width: 700,
        child: !_active
            ? Text(
                ar
                    ? 'الجلسة اتغيّرت. اقفل الطلب وافتحه من جديد.'
                    : 'Session changed. Close and reopen this booking.',
              )
            : FutureBuilder<AdminBookingDetail>(
                future: _future,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s.hasError) {
                    final confirm = needsAdminConfirmation(s.error!);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          confirm
                              ? (ar
                                    ? 'أكد حسابك لعرض بيانات الطلب.'
                                    : 'Confirm your account to view booking details.')
                              : (ar
                                    ? 'تعذر تحميل الطلب.'
                                    : 'Could not load this booking.'),
                        ),
                        TextButton(
                          onPressed: confirm ? _confirm : _reload,
                          child: Text(
                            confirm
                                ? (ar ? 'تأكيد الحساب' : 'Confirm account')
                                : (ar ? 'إعادة المحاولة' : 'Retry'),
                          ),
                        ),
                      ],
                    );
                  }
                  final d = s.data!, b = d.summary;
                  String money(int amount) => '$amount ${ar ? 'ج.م' : 'EGP'}';
                  Widget heading(String value) => Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 8),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                  Widget row(String label, int amount) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Wrap(
                      spacing: 16,
                      children: [Text(label), Text(money(amount))],
                    ),
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.code,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(ar ? b.titleAr : b.titleEn),
                      Text(adminBookingStatusLabel(b.status, ar)),
                      Text(
                        '${MaterialLocalizations.of(context).formatFullDate(b.date)} · ${adminTimeWindowLabel(b.timeWindow, ar)}',
                      ),
                      heading(ar ? 'العميل والعنوان' : 'Customer and address'),
                      if (d.customerName != null) Text(d.customerName!),
                      if (d.customerPhone != null)
                        Text(
                          d.customerPhone!,
                          textDirection: TextDirection.ltr,
                        ),
                      for (final line in d.address) Text(line),
                      if (d.issue?.isNotEmpty == true) ...[
                        heading(ar ? 'وصف المشكلة' : 'Issue description'),
                        Text(d.issue!),
                      ],
                      if (d.proName != null || d.proPhone != null) ...[
                        heading(ar ? 'الفني المسند' : 'Assigned professional'),
                        if (d.proName != null) Text(d.proName!),
                        if (d.proPhone != null)
                          Text(d.proPhone!, textDirection: TextDirection.ltr),
                      ],
                      heading(
                        ar
                            ? 'المبلغ وقت الحجز'
                            : 'Pricing saved with this booking',
                      ),
                      row(
                        ar ? 'المعاينة' : 'Inspection',
                        d.pricing.baseInspectionEgp,
                      ),
                      row(ar ? 'الخدمة' : 'Service', d.pricing.serviceFeeEgp),
                      row(
                        ar ? 'الانتقال' : 'Transport',
                        d.pricing.transportFeeEgp,
                      ),
                      row(ar ? 'الإجمالي' : 'Total', d.pricing.totalEgp),
                      if (d.payment case final p?) ...[
                        Text(
                          '${ar ? 'حالة الدفع' : 'Payment'}: ${p.label(ar)}',
                        ),
                        Text(
                          p.method == 'CASH_ON_SERVICE'
                              ? (ar ? 'نقدًا بعد الخدمة' : 'Cash on service')
                              : (ar
                                    ? 'وسيلة الدفع المسجلة'
                                    : 'Other recorded payment method'),
                        ),
                        if (p.paidAt != null)
                          Text(
                            '${ar ? 'تاريخ التحصيل' : 'Collection date'}: ${MaterialLocalizations.of(context).formatFullDate(p.paidAt!.toLocal())}',
                          ),
                      ],
                      if (d.cancellationReason != null) ...[
                        heading(ar ? 'سبب الإلغاء' : 'Cancellation reason'),
                        Text(d.cancellationReason!),
                      ],
                      heading(ar ? 'سجل الطلب' : 'Booking history'),
                      for (final e in d.history)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(adminBookingStatusLabel(e.status, ar)),
                              Text(
                                '${MaterialLocalizations.of(context).formatFullDate(e.date.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(e.date.toLocal()))}',
                              ),
                              if (e.note != null) Text(e.note!),
                            ],
                          ),
                        ),
                      if (d.hasOlderHistory)
                        Text(
                          ar
                              ? 'معروض آخر ٢٠٠ حدث.'
                              : 'Showing the latest 200 events.',
                        ),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        if (_reauth)
                          TextButton(
                            onPressed: _busy ? null : _confirm,
                            child: Text(
                              ar ? 'تأكيد الحساب' : 'Confirm account',
                            ),
                          ),
                      ],
                      if (_busy) const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (d.canOffer)
                            FilledButton.icon(
                              key: const Key('admin-booking-offer'),
                              onPressed: _busy || _error != null
                                  ? null
                                  : () => _act(d, true),
                              icon: const Icon(Icons.outgoing_mail),
                              label: Text(
                                ar
                                    ? 'إرسال عرض لفني'
                                    : 'Offer to a professional',
                              ),
                            ),
                          if (d.canCancel)
                            OutlinedButton.icon(
                              key: const Key('admin-booking-cancel'),
                              onPressed: _busy || _error != null
                                  ? null
                                  : () => _act(d, false),
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(
                                ar ? 'إلغاء الحجز' : 'Cancel booking',
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy || !_active ? null : _reload,
          child: Text(ar ? 'تحديث الطلب' : 'Reload booking'),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(ar ? 'إغلاق' : 'Close'),
        ),
      ],
    );
  }
}
