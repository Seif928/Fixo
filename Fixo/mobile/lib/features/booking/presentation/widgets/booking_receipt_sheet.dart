import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_models.dart';

/// Displays an official FIXO Receipt / Invoice modal sheet generated from
/// real Booking, PaymentRecord, and Review records (`GET /bookings/:id/receipt`).
class BookingReceiptSheet extends ConsumerStatefulWidget {
  const BookingReceiptSheet({
    super.key,
    required this.bookingId,
    required this.isArabic,
  });

  final String bookingId;
  final bool isArabic;

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required bool isArabic,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookingReceiptSheet(
        bookingId: bookingId,
        isArabic: isArabic,
      ),
    );
  }

  @override
  ConsumerState<BookingReceiptSheet> createState() =>
      _BookingReceiptSheetState();
}

class _BookingReceiptSheetState extends ConsumerState<BookingReceiptSheet> {
  late Future<BookingReceiptModel> _receiptFuture;

  @override
  void initState() {
    super.initState();
    _receiptFuture = ref
        .read(bookingRepositoryProvider)
        .getBookingReceipt(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    final palette = context.fixoPalette;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(FixoSpacing.lg),
        child: FutureBuilder<BookingReceiptModel>(
          future: _receiptFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: FixoColors.error,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar
                        ? 'تعذّر تحميل إيصال الخدمة.'
                        : 'Could not load service receipt.',
                    style: FixoTypography.bodyMd(color: palette.inkText),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _receiptFuture = ref
                            .read(bookingRepositoryProvider)
                            .getBookingReceipt(widget.bookingId);
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              );
            }

            final receipt = snapshot.data!;
            final issuedDate = DateTime.tryParse(receipt.issuedAt);
            final isPaid = receipt.paymentStatus == 'PAID';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'إيصال الخدمة الرسمي' : 'OFFICIAL SERVICE RECEIPT',
                            style: FixoTypography.labelSm(
                              color: FixoColors.secondary,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: ar ? 0 : 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            receipt.receiptNumber,
                            style: FixoTypography.headlineSm(
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
                        color: isPaid
                            ? FixoColors.secondaryContainer
                            : palette.surfaceHigh,
                        borderRadius: FixoRadius.borderRadiusPill,
                      ),
                      child: Text(
                        isPaid
                            ? (ar ? 'مدفوع نقداً' : 'PAID (CASH)')
                            : (ar ? 'يُحصّل بعد الخدمة' : 'DUE ON COMPLETION'),
                        style: FixoTypography.labelSm(
                          color: isPaid
                              ? FixoColors.onSecondaryContainer
                              : palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FixoSpacing.md),
                FixoSurfaceCard(
                  padding: const EdgeInsets.all(FixoSpacing.md),
                  borderRadius: FixoRadius.borderRadiusMd,
                  backgroundColor: palette.surfaceLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? receipt.serviceTitleAr : receipt.serviceTitleEn,
                        style: FixoTypography.labelLg(
                          color: palette.inkText,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ar ? 'العميل' : 'Customer'}: ${receipt.customerName}',
                        style: FixoTypography.bodySm(color: palette.mutedText),
                      ),
                      if (receipt.proName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${ar ? 'الفني' : 'Professional'}: ${receipt.proName} (${receipt.proDossierCode ?? ''})',
                          style: FixoTypography.bodySm(color: palette.mutedText),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        receipt.addressSummary,
                        style: FixoTypography.bodySm(color: palette.mutedText),
                      ),
                      if (issuedDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${ar ? 'التاريخ' : 'Date'}: ${DateFormat.yMMMd(ar ? 'ar' : 'en').format(issuedDate)}',
                          style: FixoTypography.bodySm(color: palette.mutedText),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: FixoSpacing.md),
                ...receipt.lineItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ar ? item.labelAr : item.labelEn,
                            style: FixoTypography.bodyMd(
                              color: palette.inkText,
                            ),
                          ),
                        ),
                        Text(
                          '${item.amountEgp} ${ar ? 'ج.م' : 'EGP'}',
                          style: FixoTypography.labelLg(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ar ? 'الإجمالي الكلي' : 'Grand Total',
                      style: FixoTypography.headlineSm(
                        color: palette.deepForest,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${receipt.grandTotalEgp} ${ar ? 'ج.م' : 'EGP'}',
                      key: const Key('receipt-grand-total-text'),
                      style: FixoTypography.headlineSm(
                        color: FixoColors.secondary,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: FixoSpacing.lg),
                FilledButton(
                  key: const Key('close-receipt-sheet-btn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: palette.primaryBrand,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(ar ? 'إغلاق الإيصال' : 'Close Receipt'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

