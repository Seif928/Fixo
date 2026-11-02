import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/uploads/private_media_picker_sheet.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../../customer_home/presentation/widgets/customer_home_widgets.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';
import '../widgets/booking_receipt_sheet.dart';

/// Screen 09: Rate & Review (`09 — Rate & Review`)
///
/// Allows customers to rate and review their COMPLETED bookings, select
/// compliment tags, attach a private completed-work photo, add an optional
/// 100%-to-artisan tip in EGP, and view the official receipt.
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({
    super.key,
    required this.orderId,
    this.initialBooking,
  });

  final String orderId;
  final BookingDetailModel? initialBooking;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  static const List<(String, String)> _complimentTags = <(String, String)>[
    ('On Time', 'دقة المواعيد'),
    ('Clean Work', 'نظافة العمل'),
    ('Expert Skill', 'مهارة عالية'),
    ('Polite & Respectful', 'تعامل راقٍ'),
    ('Fair Pricing', 'سعر عادل'),
    ('Well Equipped', 'معدات متكاملة'),
  ];

  static const List<int> _presetTips = <int>[0, 20, 50, 100];

  final _commentController = TextEditingController();
  BookingDetailModel? _booking;
  BookingReviewModel? _submittedReview;
  bool _loading = true;
  bool _submitting = false;
  bool _uploadingPhoto = false;
  String? _error;

  int _rating = 5;
  final Set<String> _selectedTags = <String>{'On Time', 'Clean Work'};
  int _selectedTipEgp = 0;
  final List<PrivateUploadResultModel> _uploadedPhotos =
      <PrivateUploadResultModel>[];

  @override
  void initState() {
    super.initState();
    if (widget.initialBooking != null) {
      _booking = widget.initialBooking;
      _submittedReview = widget.initialBooking!.review;
      _loading = false;
    } else {
      _loadBooking();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await ref
          .read(bookingRepositoryProvider)
          .getBookingById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _submittedReview = booking.review;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'LOAD_FAILED';
      });
    }
  }

  Future<void> _attachCompletedWorkPhoto(bool ar) async {
    final picked = await PrivateMediaPickerSheet.show(
      context,
      isArabic: ar,
      titleEn: 'Attach Completed Work Photo',
      titleAr: 'إرفاق صورة للعمل بعد الإتمام',
      rationaleEn:
          'Used only to attach a private photo of the completed service to your review.',
      rationaleAr:
          'يُستخدم فقط لإرفاق صورة خاصة للعمل المكتمل مع تقييمك.',
      defaultFilePrefix: 'review-work',
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final uploaded = await ref
          .read(bookingRepositoryProvider)
          .uploadPrivateMedia(
            purpose: 'REVIEW_PHOTO',
            fileName: picked.fileName,
            mimeType: picked.mimeType,
            contentBase64: picked.contentBase64,
            bookingId: widget.orderId,
          );
      if (!mounted) return;
      setState(() {
        _uploadedPhotos.add(uploaded);
        _uploadingPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'تعذّر رفع الصورة. حاول مرة أخرى.'
                : 'Could not upload photo. Please retry.',
          ),
        ),
      );
    }
  }

  Future<void> _submitReview(bool ar) async {
    if (_submitting || _booking == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final created = await ref
          .read(bookingRepositoryProvider)
          .submitBookingReview(
            widget.orderId,
            rating: _rating,
            tags: _selectedTags.toList(),
            comment: _commentController.text.trim(),
            photoUrls: _uploadedPhotos
                .map((p) => p.privateDataUri)
                .toList(),
            tipAmountEgp: _selectedTipEgp,
          );
      if (!mounted) return;
      setState(() {
        _submittedReview = created;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FixoColors.secondary,
          content: Text(
            ar
                ? 'شكراً لتقييمك! تمت إضافة ٢٥ نقطة مكافآت لحسابك.'
                : 'Thank you for your review! +25 Reward Points added.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = ar
          ? 'تعذّر إرسال التقييم. حاول مرة أخرى.'
          : 'Could not submit review. Please retry.';
      if (e.response?.data is Map) {
        final serverMsg = (e.response?.data as Map)['message'];
        if (serverMsg is String) msg = serverMsg;
      }
      setState(() {
        _submitting = false;
        _error = msg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  String _ratingDescription(int stars, bool ar) => switch (stars) {
        5 => ar ? '٥.٠ — حرفية ممتازة!' : '5.0 — Exceptional Craftsmanship!',
        4 => ar ? '٤.٠ — خدمة جيدة جداً' : '4.0 — Very Good Service',
        3 => ar ? '٣.٠ — خدمة مقبولة' : '3.0 — Satisfactory Service',
        2 => ar ? '٢.٠ — دون المتوقع' : '2.0 — Below Expectations',
        _ => ar ? '١.٠ — تجربة غير مرضية' : '1.0 — Needs Improvement',
      };

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;
    final horizontal = (MediaQuery.sizeOf(context).width - 680) / 2;
    final inset = horizontal > 16 ? horizontal : 16.0;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.canvasBackground,
        appBar: AppBar(
          backgroundColor: palette.cardSurface.withValues(alpha: 0.94),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            key: const Key('review-back-btn'),
            icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.myOrders);
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const FixoBrandMark(showSubtitle: false, iconBoxSize: 26),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  ar ? 'تقييم الخدمة والإيصال' : 'Rate & Review Service',
                  overflow: TextOverflow.ellipsis,
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: palette.subtleBorder, height: 1.0),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _booking == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(FixoSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ar
                                  ? 'تعذّر تحميل بيانات الحجز.'
                                  : 'Could not load booking details.',
                              style: FixoTypography.bodyMd(
                                color: palette.inkText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadBooking,
                              child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildReviewBody(context, _booking!, ar, inset),
        ),
      ),
    );
  }

  Widget _buildReviewBody(
    BuildContext context,
    BookingDetailModel booking,
    bool ar,
    double inset,
  ) {
    final palette = context.fixoPalette;
    final pro = booking.proProfile;
    final userMap = pro?['user'] as Map<String, dynamic>?;
    final proName =
        (userMap?['fullName'] as String?) ??
        (ar ? 'فني فيكسو المعتمد' : 'Verified FIXO Pro');
    final serviceTitle =
        (booking.offering[ar ? 'titleAr' : 'titleEn'] as String?) ??
        (ar ? 'خدمة صيانة منزلية' : 'Home Maintenance Service');

    // Guard 1: Already reviewed (Duplicate review protection view)
    if (_submittedReview != null) {
      final rev = _submittedReview!;
      return ListView(
        padding: EdgeInsets.fromLTRB(inset, FixoSpacing.md, inset, FixoSpacing.xl),
        children: [
          FixoSurfaceCard(
            key: const Key('submitted-review-summary-card'),
            padding: const EdgeInsets.all(FixoSpacing.lg),
            borderRadius: FixoRadius.borderRadiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: FixoColors.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ar
                            ? 'تم تسجيل تقييمك لهذا الطلب بنجاح'
                            : 'Your Review Has Been Recorded',
                        style: FixoTypography.headlineSm(
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$serviceTitle • #${booking.orderCode}',
                  style: FixoTypography.bodyMd(color: palette.mutedText),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= rev.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 26,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${rev.rating}.0 / 5.0',
                      style: FixoTypography.labelLg(
                        color: palette.deepForest,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                if (rev.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rev.tags
                        .map(
                          (t) => Chip(
                            label: Text(t),
                            backgroundColor: palette.surfaceLow,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '"${rev.comment!}"',
                    style: FixoTypography.bodyMd(color: palette.inkText),
                  ),
                ],
                if (rev.tipAmountEgp > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    ar
                        ? 'إكرامية الفني: ${rev.tipAmountEgp} ج.م'
                        : 'Artisan Tip Included: ${rev.tipAmountEgp} EGP',
                    style: FixoTypography.labelMd(
                      color: FixoColors.secondary,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  key: const Key('review-view-receipt-btn'),
                  onPressed: () => BookingReceiptSheet.show(
                    context,
                    bookingId: booking.id,
                    isArabic: ar,
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(ar ? 'عرض الإيصال الرسمي' : 'View Official Receipt'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primaryBrand,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.go(AppRoutes.myOrders),
                  child: Text(ar ? 'العودة إلى طلباتي' : 'Back to My Orders'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Guard 2: Booking is not COMPLETED yet
    if (booking.status != 'COMPLETED') {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: FixoSurfaceCard(
            padding: const EdgeInsets.all(FixoSpacing.lg),
            borderRadius: FixoRadius.borderRadiusLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 36,
                  color: palette.deepForest,
                ),
                const SizedBox(height: 12),
                Text(
                  ar
                      ? 'يتاح التقييم بعد إتمام الخدمة فقط.'
                      : 'Reviews are available only after the service is completed.',
                  textAlign: TextAlign.center,
                  style: FixoTypography.labelLg(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go(
                    AppRoutes.orderTracking.replaceFirst(
                      ':orderId',
                      Uri.encodeComponent(booking.id),
                    ),
                  ),
                  icon: const Icon(Icons.track_changes_rounded),
                  label: Text(ar ? 'متابعة حالة الطلب' : 'Track Order Status'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Active Review Submission Form for COMPLETED Booking (Screen 09)
    return ListView(
      padding: EdgeInsets.fromLTRB(inset, FixoSpacing.md, inset, FixoSpacing.xl),
      children: [
        // 1. Completed Service & Pro Summary Card
        FixoSurfaceCard(
          padding: const EdgeInsets.all(FixoSpacing.md),
          borderRadius: FixoRadius.borderRadiusLg,
          child: Row(
            children: [
              FixoArtisanAvatar(identifier: proName, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proName,
                      style: FixoTypography.headlineSm(
                        color: palette.deepForest,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceTitle,
                      style: FixoTypography.bodySm(color: palette.mutedText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${booking.orderCode} • ${booking.pricing.totalEgp} ${ar ? 'ج.م' : 'EGP'}',
                      style: FixoTypography.labelMd(
                        color: FixoColors.secondary,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: ar ? 'الإيصال' : 'Receipt',
                onPressed: () => BookingReceiptSheet.show(
                  context,
                  bookingId: booking.id,
                  isArabic: ar,
                ),
                icon: Icon(
                  Icons.receipt_long_outlined,
                  color: palette.deepForest,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FixoSpacing.md),

        // 2. Interactive 1-5 Star Rating Card
        FixoSurfaceCard(
          padding: const EdgeInsets.all(FixoSpacing.md),
          borderRadius: FixoRadius.borderRadiusLg,
          child: Column(
            children: [
              Text(
                ar ? 'كيف كانت تجربتك مع الفني؟' : 'How was your service experience?',
                textAlign: TextAlign.center,
                style: FixoTypography.headlineSm(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      key: Key('review-star-$star'),
                      onPressed: () => setState(() => _rating = star),
                      iconSize: 36,
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              Text(
                _ratingDescription(_rating, ar),
                style: FixoTypography.labelLg(
                  color: FixoColors.secondary,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: FixoSpacing.md),

        // 3. Compliment Tags Multi-Select
        FixoSurfaceCard(
          padding: const EdgeInsets.all(FixoSpacing.md),
          borderRadius: FixoRadius.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'ما الذي أعجبك في الخدمة؟' : 'What stood out?',
                style: FixoTypography.labelLg(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _complimentTags.map((tagPair) {
                  final (enLabel, arLabel) = tagPair;
                  final selected = _selectedTags.contains(enLabel);
                  return FilterChip(
                    key: Key('review-tag-$enLabel'),
                    label: Text(ar ? arLabel : enLabel),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTags.add(enLabel);
                        } else {
                          _selectedTags.remove(enLabel);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('review-comment-input'),
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: ar
                      ? 'ملاحظات إضافية عن الخدمة (اختياري)'
                      : 'Written feedback about the work (optional)',
                  hintText: ar
                      ? 'شارك تفاصيل تجربتك لمساعدة العملاء الآخرين...'
                      : 'Share details about punctuality and quality...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    key: const Key('attach-review-photo-btn'),
                    onPressed: _uploadingPhoto
                        ? null
                        : () => _attachCompletedWorkPhoto(ar),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(
                      _uploadingPhoto
                          ? (ar ? 'جارٍ الرفع...' : 'Uploading...')
                          : (ar ? 'إرفاق صورة للعمل' : 'Attach Work Photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_uploadedPhotos.isNotEmpty)
                    Expanded(
                      child: Text(
                        ar
                            ? 'تم إرفاق ${_uploadedPhotos.length} صورة'
                            : '${_uploadedPhotos.length} photo(s) attached',
                        style: FixoTypography.labelMd(
                          color: FixoColors.secondary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: FixoSpacing.md),

        // 4. Optional Artisan Tip Selector (100% goes to Pro)
        FixoSurfaceCard(
          padding: const EdgeInsets.all(FixoSpacing.md),
          borderRadius: FixoRadius.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar
                    ? 'إكرامية اختيارية للفني (١٠٠٪ تذهب للفني)'
                    : 'Optional Artisan Tip (100% goes to your Pro)',
                style: FixoTypography.labelLg(
                  color: palette.deepForest,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetTips.map((tip) {
                  final isSelected = _selectedTipEgp == tip;
                  return ChoiceChip(
                    key: Key('review-tip-$tip'),
                    label: Text(
                      tip == 0
                          ? (ar ? 'بدون إكرامية' : 'No Tip')
                          : '$tip ${ar ? 'ج.م' : 'EGP'}',
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedTipEgp = tip),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: FixoSpacing.sm),
          Container(
            padding: const EdgeInsets.all(FixoSpacing.sm),
            decoration: BoxDecoration(
              color: FixoColors.errorContainer,
              borderRadius: FixoRadius.borderRadiusMd,
            ),
            child: Text(
              _error!,
              style: FixoTypography.bodySm(
                color: FixoColors.onErrorContainer,
              ),
            ),
          ),
        ],

        const SizedBox(height: FixoSpacing.lg),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            key: const Key('submit-review-btn'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.primaryBrand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: FixoRadius.borderRadiusMd,
              ),
            ),
            onPressed: _submitting ? null : () => _submitReview(ar),
            icon: const Icon(Icons.verified_rounded, size: 20),
            label: Text(
              _submitting
                  ? (ar ? 'جارٍ إرسال التقييم...' : 'Submitting Review...')
                  : (ar ? 'إرسال التقييم' : 'Submit Review'),
              style: FixoTypography.labelLg(
                color: Colors.white,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

