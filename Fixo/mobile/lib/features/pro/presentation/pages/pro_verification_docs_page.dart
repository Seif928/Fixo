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
import '../../data/pro_repository.dart';
import '../../domain/pro_models.dart';

/// Screen 13: Identity & Licenses Upload (`13 — ID & Licenses Upload`)
class ProVerificationDocsPage extends ConsumerStatefulWidget {
  const ProVerificationDocsPage({super.key});

  @override
  ConsumerState<ProVerificationDocsPage> createState() =>
      _ProVerificationDocsPageState();
}

class _ProVerificationDocsPageState
    extends ConsumerState<ProVerificationDocsPage> {
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  String? _uploadingDocType;

  final Map<String, ProDocumentModel> _uploadedDocs = {};

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      final status = await repo.getVerificationStatus();
      if (!mounted) return;
      setState(() {
        for (final doc in status.documents) {
          _uploadedDocs[doc.docType] = doc;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  bool get _hasAllRequired =>
      _uploadedDocs.containsKey('NATIONAL_ID_FRONT') &&
      _uploadedDocs.containsKey('NATIONAL_ID_BACK') &&
      _uploadedDocs.containsKey('CRIMINAL_RECORD_CERT');

  Future<void> _pickAndUpload(
    String docType,
    String titleEn,
    String titleAr,
    bool ar,
  ) async {
    final picked = await PrivateMediaPickerSheet.show(
      context,
      isArabic: ar,
      titleEn: titleEn,
      titleAr: titleAr,
      rationaleEn:
          'Identity and criminal verification documents are securely encrypted and evaluated exclusively by authorized FIXO reviewers.',
      rationaleAr:
          'مستندات التحقق القومي والجنائي مشفرة بالكامل وخاصة، وتراجع حصرياً من قِبل لجان التوثيق المعتمدة في فيكسو.',
      defaultFilePrefix: 'pro_${docType.toLowerCase()}',
      isSyntheticIdentitySpecimen: true,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _uploadingDocType = docType;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(proRepositoryProvider);
      final uploaded = await repo.uploadVerificationDocument(
        docType: docType,
        fileName: picked.fileName,
        mimeType: picked.mimeType,
        contentBase64: picked.contentBase64,
      );

      if (!mounted) return;
      setState(() {
        _uploadedDocs[docType] = uploaded;
        _uploadingDocType = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _uploadingDocType = null;
      });
    }
  }

  Future<void> _submitDossier(bool ar) async {
    if (!_hasAllRequired) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(proRepositoryProvider);
      await repo.submitForVerification();
      if (!mounted) return;
      context.go(AppRoutes.proVerificationStatus);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.canvasBackground,
        appBar: AppBar(
          backgroundColor: palette.cardSurface.withValues(alpha: 0.95),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const FixoBrandMark(iconBoxSize: 26, showSubtitle: false),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  ar ? 'توثيق الهوية والشهادات' : 'ID & Licenses Verification',
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Step Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceLow,
                            borderRadius: FixoRadius.borderRadiusMd,
                            border: Border.all(color: palette.subtleBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: FixoColors.primaryForest,
                                  borderRadius: FixoRadius.borderRadiusPill,
                                ),
                                child: Text(
                                  ar ? 'الخطوة ٣ من ٤' : 'Step 3 of 4',
                                  style: FixoTypography.labelSm(
                                    color: FixoColors.limeAccent,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ar
                                      ? 'رفع المستندات الرسمية وأمان الحساب'
                                      : 'Official Identity & Security Documents',
                                  style: FixoTypography.labelMd(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: FixoSpacing.md),

                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: FixoSpacing.md),
                            padding: const EdgeInsets.all(FixoSpacing.sm),
                            decoration: BoxDecoration(
                              color: FixoColors.errorContainer,
                              borderRadius: FixoRadius.borderRadiusMd,
                            ),
                            child: Text(
                              _errorMessage!,
                              style: FixoTypography.bodySm(
                                color: FixoColors.onErrorContainer,
                              ),
                            ),
                          ),

                        // Security Shield Banner
                        Container(
                          padding: const EdgeInsets.all(FixoSpacing.md),
                          decoration: BoxDecoration(
                            color: FixoColors.secondaryContainer,
                            borderRadius: FixoRadius.borderRadiusLg,
                            border: Border.all(
                              color: FixoColors.primaryForest.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: FixoColors.primaryForest,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ar ? 'حماية مشددة للمستندات' : 'Encrypted Document Privacy',
                                      style: FixoTypography.labelMd(
                                        color: FixoColors.primaryForest,
                                      ).copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ar
                                          ? 'مستنداتك الشخصية مشفرة ولا تظهر لأي عميل أو جهة خارجية وتستخدم للتحقق القانوني فقط.'
                                          : 'Your documents are securely encrypted, never displayed to customers, and used strictly for identity vetting.',
                                      style: FixoTypography.bodySm(
                                        color: FixoColors.deepestForest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: FixoSpacing.md),

                        // 3 Required Document Cards
                        _docCard(
                          docType: 'NATIONAL_ID_FRONT',
                          titleEn: 'National ID (Front Face)',
                          titleAr: 'بطاقة الرقم القومي (الوجه الأمامي)',
                          descEn: 'Clear photo showing full name, photo, and 14 digits',
                          descAr: 'صورة واضحة توضح الاسم والصورة والرقم القومي كاملاً',
                          isRequired: true,
                          ar: ar,
                        ),
                        const SizedBox(height: FixoSpacing.sm),

                        _docCard(
                          docType: 'NATIONAL_ID_BACK',
                          titleEn: 'National ID (Back Face)',
                          titleAr: 'بطاقة الرقم القومي (الوجه الخلفي)',
                          descEn: 'Clear photo showing address, occupation, and serial',
                          descAr: 'صورة واضحة توضح العنوان والمهنة والرقم التسلسلي',
                          isRequired: true,
                          ar: ar,
                        ),
                        const SizedBox(height: FixoSpacing.sm),

                        _docCard(
                          docType: 'CRIMINAL_RECORD_CERT',
                          titleEn: 'Criminal Record Certificate (Fesh)',
                          titleAr: 'صحيفة الحالة الجنائية (فيش وتشبيه)',
                          descEn: 'Recent criminal record check issued within the last 3 months',
                          descAr: 'صحيفة حالة جنائية حديثة موجهة لفيكسو أو بدون سوابق',
                          isRequired: true,
                          ar: ar,
                        ),
                        const SizedBox(height: FixoSpacing.sm),

                        // 1 Optional Document Card
                        _docCard(
                          docType: 'SYNDICATE_LICENSE',
                          titleEn: 'Trade License or Syndicate Card (Optional)',
                          titleAr: 'كارنيه النقابة أو شهادة قياس المهارة (اختياري)',
                          descEn: 'Trade qualification certificate, union card or vocational diploma',
                          descAr: 'شهادة قياس مستوى المهارة أو كارنيه النقابة الحرفية إن وجد',
                          isRequired: false,
                          ar: ar,
                        ),
                        const SizedBox(height: FixoSpacing.lg),

                        // Submit Dossier CTA
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            backgroundColor: _hasAllRequired
                                ? FixoColors.primaryForest
                                : palette.surfaceHigh,
                            foregroundColor: _hasAllRequired
                                ? Colors.white
                                : palette.mutedText,
                            shape: RoundedRectangleBorder(
                              borderRadius: FixoRadius.borderRadiusMd,
                            ),
                          ),
                          onPressed: (_hasAllRequired && !_submitting)
                              ? () => _submitDossier(ar)
                              : null,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            ar
                                ? 'إرسال الملف للمراجعة والاعتماد'
                                : 'Submit Dossier for Verification',
                            style: FixoTypography.labelLg(
                              color: _hasAllRequired ? Colors.white : palette.mutedText,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _docCard({
    required String docType,
    required String titleEn,
    required String titleAr,
    required String descEn,
    required String descAr,
    required bool isRequired,
    required bool ar,
  }) {
    final palette = context.fixoPalette;
    final doc = _uploadedDocs[docType];
    final isUploaded = doc != null;
    final isUploading = _uploadingDocType == docType;

    return FixoSurfaceCard(
      padding: const EdgeInsets.all(FixoSpacing.md),
      borderRadius: FixoRadius.borderRadiusLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUploaded
                  ? FixoColors.secondaryContainer
                  : palette.surfaceLow,
              borderRadius: FixoRadius.borderRadiusMd,
              border: Border.all(
                color: isUploaded ? FixoColors.secondary : palette.subtleBorder,
              ),
            ),
            alignment: Alignment.center,
            child: isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isUploaded
                        ? Icons.check_circle_rounded
                        : Icons.file_upload_outlined,
                    color: isUploaded
                        ? FixoColors.primaryForest
                        : palette.mutedText,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ar ? titleAr : titleEn,
                        style: FixoTypography.labelMd(
                          color: palette.deepForest,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FixoColors.errorContainer,
                          borderRadius: FixoRadius.borderRadiusPill,
                        ),
                        child: Text(
                          ar ? 'إلزامي' : 'Required',
                          style: FixoTypography.labelSm(
                            color: FixoColors.onErrorContainer,
                          ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      Text(
                        ar ? 'اختياري' : 'Optional',
                        style: FixoTypography.labelSm(color: palette.mutedText),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ar ? descAr : descEn,
                  style: FixoTypography.bodySm(color: palette.mutedText),
                ),
                if (isUploaded) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: FixoColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ar
                            ? 'تم رفع المستند (${doc.fileName})'
                            : 'Uploaded (${doc.fileName})',
                        style: FixoTypography.bodySm(
                          color: FixoColors.primaryForest,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: FixoRadius.borderRadiusMd,
                    ),
                  ),
                  onPressed: isUploading
                      ? null
                      : () => _pickAndUpload(docType, titleEn, titleAr, ar),
                  icon: Icon(
                    isUploaded ? Icons.refresh_rounded : Icons.camera_alt_outlined,
                    size: 16,
                  ),
                  label: Text(
                    isUploaded
                        ? (ar ? 'استبدال المستند' : 'Replace document')
                        : (ar ? 'رفع المستند / عينة' : 'Upload document'),
                    style: FixoTypography.labelSm().copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
