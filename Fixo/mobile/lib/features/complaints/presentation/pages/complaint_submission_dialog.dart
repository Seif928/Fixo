import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../data/complaints_models.dart';
import '../../data/complaints_repository.dart';
import '../extensions/complaint_ui_extensions.dart';

class ComplaintSubmissionDialog extends ConsumerStatefulWidget {
  const ComplaintSubmissionDialog({
    super.key,
    required this.bookingId,
    required this.orderCode,
    this.serviceTitle,
  });

  final String bookingId;
  final String orderCode;
  final String? serviceTitle;

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required String orderCode,
    String? serviceTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComplaintSubmissionDialog(
        bookingId: bookingId,
        orderCode: orderCode,
        serviceTitle: serviceTitle,
      ),
    );
  }

  @override
  ConsumerState<ComplaintSubmissionDialog> createState() =>
      _ComplaintSubmissionDialogState();
}

class _ComplaintSubmissionDialogState
    extends ConsumerState<ComplaintSubmissionDialog> {
  ComplaintCategory _selectedCategory = ComplaintCategory.serviceQuality;
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isArabic => ref.watch(appLocaleProvider).languageCode == 'ar';

  Future<void> _submit() async {
    final text = _descriptionController.text.trim();
    if (text.length < 10) {
      setState(() {
        _error = _isArabic
            ? 'يرجى كتابة تفاصيل المشكلة (١٠ أحرف على الأقل).'
            : 'Please write issue details (at least 10 characters).';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(complaintsRepositoryProvider);
      await repo.createComplaint(
        bookingId: widget.bookingId,
        category: _selectedCategory,
        description: text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'تم استلام شكواك بنجاح وجارٍ مراجعتها من فريق الجودة.'
                  : 'Complaint submitted successfully and is under review.',
            ),
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final serverMessage = e.response?.data?['message'];
        setState(() {
          _submitting = false;
          _error = serverMessage is String
              ? serverMessage
              : (_isArabic
                  ? 'تعذر تقديم الشكوى. يرجى المحاولة لاحقاً.'
                  : 'Could not submit complaint. Please try again.');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = _isArabic
              ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
              : 'Unexpected error. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final textTheme = Theme.of(context).textTheme;
    final ar = _isArabic;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: FixoSpacing.lg,
        right: FixoSpacing.lg,
        top: FixoSpacing.lg,
        bottom: bottomInset + FixoSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.subtleBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: FixoSpacing.md),

            // Header
            Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  color: palette.coralUrgent,
                  size: 24,
                ),
                const SizedBox(width: FixoSpacing.sm),
                Expanded(
                  child: Text(
                    ar ? 'تقديم شكوى أو بلاغ' : 'File a Complaint',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.inkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ar
                  ? 'طلب #${widget.orderCode} - ${widget.serviceTitle ?? "خدمة منزلية"}'
                  : 'Order #${widget.orderCode} - ${widget.serviceTitle ?? "Home Service"}',
              style: textTheme.bodySmall?.copyWith(
                color: palette.mutedText,
              ),
            ),
            const SizedBox(height: FixoSpacing.md),

            // Categories
            Text(
              ar ? 'نوع المشكلة' : 'Issue Category',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.inkText,
              ),
            ),
            const SizedBox(height: FixoSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ComplaintCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  key: Key('complaint-category-${cat.wireValue}'),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : palette.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(cat.localizedLabel(ar)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: palette.primaryBrand,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : palette.inkText,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: FixoSpacing.md),

            // Description input
            Text(
              ar ? 'تفاصيل الشكوى' : 'Complaint Details',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.inkText,
              ),
            ),
            const SizedBox(height: FixoSpacing.xs),
            TextField(
              key: const Key('complaint-description-field'),
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 1000,
              style: TextStyle(color: palette.inkText),
              decoration: InputDecoration(
                hintText: ar
                    ? 'اشرح بالتفصيل ما حدث ليتسنى لفريق الجودة حل المشكلة...'
                    : 'Explain what happened in detail for quality review...',
                hintStyle: TextStyle(color: palette.mutedText),
                filled: true,
                fillColor: palette.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: FixoRadius.borderRadiusMd,
                  borderSide: BorderSide(color: palette.subtleBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: FixoRadius.borderRadiusMd,
                  borderSide: BorderSide(color: palette.subtleBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: FixoRadius.borderRadiusMd,
                  borderSide: BorderSide(color: palette.primaryBrand, width: 2),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: FixoSpacing.xs),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.coralUrgent.withValues(alpha: 0.1),
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: palette.coralUrgent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: FixoSpacing.md),

            // Submit Button
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const Key('complaint-submit-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: FixoRadius.borderRadiusMd,
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        ar ? 'إرسال الشكوى' : 'Submit Complaint',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
