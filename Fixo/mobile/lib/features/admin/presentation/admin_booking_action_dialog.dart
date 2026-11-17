import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_booking_models.dart';
import '../data/admin_repository.dart';

class AdminBookingActionDialog extends ConsumerStatefulWidget {
  const AdminBookingActionDialog({
    super.key,
    required this.id,
    required this.ar,
    required this.offer,
  });
  final String id;
  final bool ar, offer;
  @override
  ConsumerState<AdminBookingActionDialog> createState() => _State();
}

class _State extends ConsumerState<AdminBookingActionDialog> {
  late final _owner = ref.read(authControllerProvider).session?.user.id;
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _cancel = CancelToken();
  bool _sessionChanged = false;
  int _page = 1;
  String? _selected;
  Future<AdminCandidatePage>? _future;
  @override
  void initState() {
    super.initState();
    if (widget.offer) {
      _load();
    }
  }

  void _load() {
    _selected = null;
    _future = ref
        .read(adminRepositoryProvider)
        .bookingCandidates(widget.id, page: _page, cancelToken: _cancel);
  }

  @override
  void dispose() {
    _cancel.cancel();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.session?.user.id), (
      _,
      id,
    ) {
      if (id != _owner && !_sessionChanged) {
        _cancel.cancel();
        if (mounted) {
          setState(() {
            _sessionChanged = true;
            _selected = null;
            _reason.clear();
          });
        }
      }
    });
    final ar = widget.ar,
        active =
            !_sessionChanged &&
            ref.watch(authControllerProvider).session?.user.id == _owner;
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.offer
            ? (ar ? 'إرسال عرض للفني' : 'Send a job offer')
            : (ar ? 'تأكيد إلغاء الحجز' : 'Confirm booking cancellation'),
      ),
      content: SizedBox(
        width: 520,
        child: !active
            ? Text(
                ar
                    ? 'الجلسة اتغيّرت. اقفل النافذة.'
                    : 'Session changed. Close this dialog.',
              )
            : widget.offer
            ? FutureBuilder<AdminCandidatePage>(
                future: _future,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ar
                              ? 'تعذر تحميل الفنيين المتاحين.'
                              : 'Could not load eligible professionals.',
                        ),
                        TextButton(
                          onPressed: () => setState(_load),
                          child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    );
                  }
                  final data = s.data!;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar
                            ? 'الفني لازم يكون مقبول، متاح، ونشاطه ومنطقته مناسبين. العرض مدته ٥ دقائق، والإسناد يتم بقبوله.'
                            : 'Choose an approved, online professional covering this trade and area. Offers last five minutes; assignment requires their acceptance.',
                      ),
                      const SizedBox(height: 12),
                      if (data.items.isEmpty)
                        Text(
                          ar
                              ? 'مفيش فني مؤهل متاح دلوقتي.'
                              : 'No eligible professionals are currently available.',
                        ),
                      for (final p in data.items)
                        ListTile(
                          key: Key('admin-booking-candidate-${p.id}'),
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _selected == p.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          title: Text(p.name ?? p.code),
                          subtitle: Text(p.code),
                          selected: _selected == p.id,
                          onTap: () => setState(() => _selected = p.id),
                        ),
                      Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _page > 1
                                ? () => setState(() {
                                    _page--;
                                    _load();
                                  })
                                : null,
                            child: Text(ar ? 'السابق' : 'Previous'),
                          ),
                          Text('$_page / ${data.meta.totalPages}'),
                          TextButton(
                            onPressed: _page < data.meta.totalPages
                                ? () => setState(() {
                                    _page++;
                                    _load();
                                  })
                                : null,
                            child: Text(ar ? 'التالي' : 'Next'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              )
            : Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ar
                          ? 'الإلغاء متاح قبل بدء التنفيذ وللطلب غير المحصّل فقط. الأسعار والسجل محفوظين، ومش بنسجل أي تحصيل.'
                          : 'Only unpaid bookings before service starts can be cancelled. Pricing and history remain intact; no payment is collected.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('admin-booking-cancel-reason'),
                      controller: _reason,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: ar ? 'سبب الإلغاء' : 'Cancellation reason',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 3
                          ? (ar
                                ? 'اكتب سببًا واضحًا من ٣ حروف على الأقل.'
                                : 'Enter a clear reason of at least three characters.')
                          : null,
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ar ? 'رجوع' : 'Back'),
        ),
        FilledButton(
          key: const Key('admin-booking-action-submit'),
          onPressed: !active || (widget.offer && _selected == null)
              ? null
              : () {
                  if (widget.offer || _form.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      widget.offer ? _selected : _reason.text.trim(),
                    );
                  }
                },
          child: Text(
            widget.offer
                ? (ar ? 'إرسال العرض' : 'Send offer')
                : (ar ? 'تأكيد الإلغاء' : 'Confirm cancellation'),
          ),
        ),
      ],
    );
  }
}
