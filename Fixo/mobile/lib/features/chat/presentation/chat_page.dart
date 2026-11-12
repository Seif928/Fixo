import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/fixo_colors.dart';
import '../../../core/theme/fixo_spacing.dart';
import '../../../core/theme/fixo_typography.dart';
import '../../../core/widgets/fixo_brand_mark.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/booking_models.dart';
import '../../customer_home/presentation/widgets/customer_home_widgets.dart';
import '../data/communications_repository.dart';

/// Native Screen 07, inspected against live Stitch 104e7c1e31454fb786e493cea82afc86.
/// Text messages are persisted by NestJS; no synthetic replies or online/ETA claims.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.bookingId});
  final String bookingId;
  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _reading = <String>{};
  List<ChatMessageModel> _messages = [];
  BookingDetailModel? _booking;
  String? _cursor;
  bool _loading = true, _refreshing = false, _sending = false, _paging = false;
  String? _error;
  Timer? _poll;
  bool _foreground = true;
  bool get _ar => Directionality.of(context) == TextDirection.rtl;
  bool get _writable =>
      _booking?.proProfileId != null &&
      const [
        'CONFIRMED',
        'PRO_EN_ROUTE',
        'ARRIVED',
        'IN_PROGRESS',
      ].contains(_booking?.status);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_foreground && (ModalRoute.of(context)?.isCurrent ?? true)) {
        unawaited(_refresh(silent: true));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_refresh(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing || _paging || !mounted) return;
    _refreshing = true;
    try {
      final booking = await ref
          .read(bookingRepositoryProvider)
          .getBookingById(widget.bookingId);
      if (!mounted) return;
      final page = await ref
          .read(communicationsRepositoryProvider)
          .messages(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        // Keep already-loaded older pages, updating read receipts for recent messages.
        final merged = {
          for (final message in _messages) message.id: message,
          for (final message in page.items) message.id: message,
        };
        _messages = merged.values.toList()
          ..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt) != 0
                ? b.createdAt.compareTo(a.createdAt)
                : b.id.compareTo(a.id),
          );
        if (_cursor == null && _messages.length <= 30) {
          _cursor = page.nextCursor;
        }
        _loading = false;
        if (!silent) _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (!silent || _booking == null) {
            _error = _ar
                ? 'تعذر تحميل المحادثة. حاول مرة أخرى.'
                : 'Could not load this conversation. Please retry.';
          }
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _older() async {
    if (_paging || _refreshing || _cursor == null) return;
    setState(() => _paging = true);
    try {
      final page = await ref
          .read(communicationsRepositoryProvider)
          .messages(widget.bookingId, before: _cursor);
      if (!mounted) return;
      setState(() {
        final ids = _messages.map((m) => m.id).toSet();
        _messages.addAll(page.items.where((m) => !ids.contains(m.id)));
        _cursor = page.nextCursor;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _ar
              ? 'تعذر تحميل الرسائل الأقدم.'
              : 'Could not load older messages.',
        );
      }
    } finally {
      if (mounted) setState(() => _paging = false);
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (!_writable || _sending || body.isEmpty || body.length > 2000) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final message = await ref
          .read(communicationsRepositoryProvider)
          .send(widget.bookingId, body);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
        _messages.insert(0, message);
        _text.clear();
      });
    } catch (_) {
      // Do not automatically resend: a timeout can happen after server persistence.
      if (mounted) {
        setState(
          () => _error = _ar
              ? 'تعذر تأكيد الإرسال. حدّث المحادثة وتحقق قبل إعادة الإرسال.'
              : 'Send could not be confirmed. Refresh and check before sending again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _seen(ChatMessageModel message, String actor) {
    if (!_foreground ||
        !(ModalRoute.of(context)?.isCurrent ?? true) ||
        actor.isEmpty ||
        message.senderUserId == actor ||
        message.readAt != null ||
        !_reading.add(message.id)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_foreground) {
        _reading.remove(message.id);
        return;
      }
      try {
        await ref
            .read(communicationsRepositoryProvider)
            .markRead(widget.bookingId, message.id);
      } catch (_) {
        _reading.remove(message.id);
      }
    });
  }

  void _showBookingSummarySheet(BuildContext context, BookingDetailModel booking) {
    final palette = context.fixoPalette;
    final title = booking.offering[_ar ? 'titleAr' : 'titleEn'] as String? ??
        booking.offering['titleEn'] as String? ??
        (_ar ? 'خدمة منزلية' : 'Home Service');
    final addressLabel = booking.address['label'] as String? ?? '';
    final districtLine = booking.address['districtLine'] as String? ?? '';

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(FixoSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _ar ? 'ملخص الحجز' : 'Booking Summary',
                      style: FixoTypography.headlineSm(
                        color: palette.deepForest,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close_rounded, color: palette.mutedText),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: FixoTypography.labelLg(
                    color: palette.inkText,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${booking.orderCode} • ${booking.status.replaceAll('_', ' ')}',
                  style: FixoTypography.bodySm(color: palette.mutedText),
                ),
                if (addressLabel.isNotEmpty || districtLine.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [addressLabel, districtLine]
                        .where((s) => s.isNotEmpty)
                        .join(' — '),
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surfaceLow,
                    borderRadius: FixoRadius.borderRadiusMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _ar ? 'الإجمالي المقدر' : 'Total Quote',
                        style: FixoTypography.labelMd(color: palette.mutedText),
                      ),
                      Text(
                        '${booking.pricing.totalEgp} EGP',
                        style: FixoTypography.labelLg(
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final colors = Theme.of(context).colorScheme;
    final actor = ref.watch(authControllerProvider).session?.user.id ?? '';
    final proUser = _booking?.proProfile?['user'];
    final name = proUser is Map ? proUser['fullName'] as String? : null;
    final hasAssignedPro = _booking?.proProfileId != null;
    final title =
        _booking?.offering[_ar ? 'titleAr' : 'titleEn'] as String? ??
        _booking?.offering['titleEn'] as String? ??
        '';
    final district = _booking?.address['districtLine'] as String? ??
        _booking?.address['label'] as String? ??
        '';

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        backgroundColor: palette.canvasBackground,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const Flexible(
              child: FixoBrandMark(showSubtitle: false, iconBoxSize: 28),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _ar ? 'المحادثة' : 'Chat',
                style: FixoTypography.headlineSm(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _ar ? 'تحديث' : 'Refresh',
            onPressed: () => _refresh(),
            icon: Icon(Icons.refresh_rounded, color: palette.deepForest),
          ),
          if (_booking != null)
            IconButton(
              tooltip: _ar ? 'تفاصيل الطلب' : 'Order Info',
              onPressed: () => _showBookingSummarySheet(context, _booking!),
              icon: Icon(Icons.info_outline_rounded, color: palette.mutedText),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: palette.subtleBorder),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_booking != null) ...[
              // Stitch Screen 07 Provider & Order Context Header
              Container(
                color: palette.surfaceLow,
                padding: const EdgeInsets.fromLTRB(
                  FixoSpacing.md,
                  12,
                  FixoSpacing.md,
                  12,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (hasAssignedPro)
                          FixoArtisanAvatar(
                            identifier: name ?? 'pro',
                            size: 46,
                          )
                        else
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: palette.surfaceContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.subtleBorder),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: palette.mutedText,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name ??
                                          (_ar
                                              ? 'لم يتم تعيين فني بعد'
                                              : 'No professional assigned yet'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FixoTypography.labelLg(
                                        color: palette.inkText,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (hasAssignedPro) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: FixoColors.secondary,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _ar
                                    ? 'تُحدّث الرسائل أثناء فتح هذه الشاشة'
                                    : 'Messages refresh while this screen is open',
                                style: FixoTypography.bodySm(
                                  color: palette.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Honest disabled call action from Stitch Screen 07
                        Tooltip(
                          message: _ar
                              ? 'المكالمات الصوتية غير مفعلة حاليًا'
                              : 'Voice calls are not enabled in this release',
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: palette.cardSurface.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.subtleBorder),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.call_outlined,
                              size: 18,
                              color: palette.mutedText.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Live Order Context Strip (Stitch Screen 07)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.cardSurface,
                        borderRadius: FixoRadius.borderRadiusMd,
                        border: Border.all(color: palette.subtleBorder),
                        boxShadow: FixoShadows.level1CardResting,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: palette.surfaceContainer,
                              borderRadius: FixoRadius.borderRadiusSm,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.home_repair_service_outlined,
                              size: 20,
                              color: palette.deepForest,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '#${_booking!.orderCode}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FixoTypography.labelMd(
                                          color: FixoColors.secondary,
                                        ).copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    if (district.isNotEmpty) ...[
                                      Text(
                                        ' • ',
                                        style: FixoTypography.bodySm(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          district,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: FixoTypography.bodySm(
                                            color: palette.mutedText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (title.isNotEmpty)
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FixoTypography.labelMd(
                                      color: palette.inkText,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.limeAccent,
                              borderRadius: FixoRadius.borderRadiusPill,
                            ),
                            child: Text(
                              '${_booking!.pricing.totalEgp} EGP',
                              style: FixoTypography.labelMd(
                                color: FixoColors.onTertiaryFixed,
                                tabularFigures: true,
                              ).copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: FixoRadius.borderRadiusMd,
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: colors.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: FixoTypography.bodySm(
                          color: colors.onErrorContainer,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _refresh(),
                      child: Text(_ar ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: palette.deepForest,
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: palette.surfaceLow,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.forum_outlined,
                                size: 26,
                                color: palette.mutedText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _ar ? 'لا توجد رسائل بعد.' : 'No messages yet.',
                              style: FixoTypography.labelLg(
                                color: palette.inkText,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_cursor != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return Center(
                            child: TextButton(
                              onPressed: _paging ? null : _older,
                              child: Text(
                                _ar ? 'رسائل أقدم' : 'Older messages',
                              ),
                            ),
                          );
                        }
                        final message = _messages[index];
                        final mine = message.senderUserId == actor;
                        _seen(message, actor);
                        return Align(
                          alignment: mine
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.sizeOf(
                                    context,
                                  ).width.clamp(0, 800).toDouble() *
                                  .82,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? FixoColors.primaryForest
                                  : palette.cardSurface,
                              borderRadius: BorderRadiusDirectional.only(
                                topStart: const Radius.circular(18),
                                topEnd: const Radius.circular(18),
                                bottomStart: Radius.circular(mine ? 18 : 4),
                                bottomEnd: Radius.circular(mine ? 4 : 18),
                              ),
                              border: mine
                                  ? null
                                  : Border.all(color: palette.subtleBorder),
                              boxShadow: FixoShadows.level1CardResting,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.body,
                                  style: FixoTypography.bodyMd(
                                    color: mine
                                        ? Colors.white
                                        : palette.inkText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      TimeOfDay.fromDateTime(
                                        message.createdAt.toLocal(),
                                      ).format(context),
                                      style: FixoTypography.bodySm(
                                        color: mine
                                            ? Colors.white70
                                            : palette.mutedText,
                                      ).copyWith(fontSize: 11),
                                    ),
                                    if (mine) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        message.readAt == null
                                            ? Icons.done
                                            : Icons.done_all,
                                        size: 16,
                                        color: message.readAt == null
                                            ? Colors.white70
                                            : palette.limeAccent,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (!_loading && !_writable)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceLow,
                  borderRadius: FixoRadius.borderRadiusMd,
                  border: Border.all(color: palette.subtleBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 18,
                      color: palette.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ar
                            ? 'الإرسال متاح بعد تعيين فني وتأكيد الحجز، وأثناء تنفيذ الخدمة.'
                            : 'Sending is available after a professional is assigned and the booking is confirmed, while service is active.',
                        style: FixoTypography.bodySm(color: palette.mutedText),
                      ),
                    ),
                  ],
                ),
              ),
            if (_writable)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final reply in [
                      _ar ? 'من فضلك اضغط الجرس' : 'Please ring the bell',
                      _ar ? 'أنا في المنزل' : 'I am at home',
                    ])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ActionChip(
                          backgroundColor: palette.cardSurface,
                          side: BorderSide(color: palette.subtleBorder),
                          shape: const StadiumBorder(),
                          label: Text(
                            reply,
                            style: FixoTypography.labelMd(
                              color: palette.deepForest,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          onPressed: _sending
                              ? null
                              : () {
                                  _text.text = reply;
                                  setState(() {});
                                },
                        ),
                      ),
                  ],
                ),
              ),
            // Stitch Screen 07 Pill Composer Bar
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: palette.surfaceLow,
                  border: Border(top: BorderSide(color: palette.subtleBorder)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: palette.subtleBorder),
                    boxShadow: FixoShadows.level1CardResting,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: _ar
                            ? 'إرفاق الصور سيتوفر قريبًا'
                            : 'Photo attachments coming soon',
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: palette.surfaceContainer,
                            child: Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: palette.mutedText.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          enabled: _writable && !_sending,
                          maxLength: 2000,
                          maxLines: 4,
                          minLines: 1,
                          onChanged: (_) => setState(() {}),
                          style: FixoTypography.bodyMd(color: palette.inkText),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: false,
                            hintText: _ar ? 'اكتب رسالة…' : 'Type a message…',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        key: const Key('send-chat-message'),
                        tooltip: _ar ? 'إرسال' : 'Send',
                        style: IconButton.styleFrom(
                          backgroundColor: FixoColors.primaryForest,
                          foregroundColor: palette.limeAccent,
                          disabledBackgroundColor: palette.surfaceContainer,
                        ),
                        onPressed:
                            !_writable || _sending || _text.text.trim().isEmpty
                            ? null
                            : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_upward),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
