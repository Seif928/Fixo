import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_spacing.dart';
import '../theme/fixo_typography.dart';
import '../widgets/fixo_cards.dart';

/// Selected private media payload ready for authenticated backend upload.
class PickedPrivateMedia {
  const PickedPrivateMedia({
    required this.fileName,
    required this.mimeType,
    required this.contentBase64,
    required this.sourceLabelEn,
    required this.sourceLabelAr,
  });

  final String fileName;
  final String mimeType;
  final String contentBase64;
  final String sourceLabelEn;
  final String sourceLabelAr;
}

/// Valid 1x1 PNG binary specimen (passes strict PNG 89 50 4E 47 magic-byte verification).
const List<int> _kValidSpecimenPngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
  0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
  0x54, 0x08, 0xD7, 0x63, 0x18, 0x49, 0x38, 0x00,
  0x00, 0x01, 0x42, 0x00, 0x9A, 0x6C, 0x52, 0x47,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
  0xAE, 0x42, 0x60, 0x82,
];

String buildSpecimenPngBase64(String tag) {
  final suffixBytes = utf8.encode(tag);
  final combined = <int>[..._kValidSpecimenPngBytes, ...suffixBytes];
  return base64Encode(combined);
}

/// Contextual permission & private media picker bottom sheet used on
/// Screen 04 (Issue Photos), Screen 09 (Review Photos), and Screen 13 (Pro Docs).
class PrivateMediaPickerSheet extends StatefulWidget {
  const PrivateMediaPickerSheet({
    super.key,
    required this.isArabic,
    required this.titleEn,
    required this.titleAr,
    required this.rationaleEn,
    required this.rationaleAr,
    required this.defaultFilePrefix,
    this.isSyntheticIdentitySpecimen = false,
  });

  final bool isArabic;
  final String titleEn;
  final String titleAr;
  final String rationaleEn;
  final String rationaleAr;
  final String defaultFilePrefix;
  final bool isSyntheticIdentitySpecimen;

  static Future<PickedPrivateMedia?> show(
    BuildContext context, {
    required bool isArabic,
    required String titleEn,
    required String titleAr,
    required String rationaleEn,
    required String rationaleAr,
    required String defaultFilePrefix,
    bool isSyntheticIdentitySpecimen = false,
  }) {
    return showModalBottomSheet<PickedPrivateMedia>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PrivateMediaPickerSheet(
        isArabic: isArabic,
        titleEn: titleEn,
        titleAr: titleAr,
        rationaleEn: rationaleEn,
        rationaleAr: rationaleAr,
        defaultFilePrefix: defaultFilePrefix,
        isSyntheticIdentitySpecimen: isSyntheticIdentitySpecimen,
      ),
    );
  }

  @override
  State<PrivateMediaPickerSheet> createState() =>
      _PrivateMediaPickerSheetState();
}

class _PrivateMediaPickerSheetState extends State<PrivateMediaPickerSheet> {
  bool _permissionGranted = true;
  bool _permissionDeniedState = false;

  void _selectSource({
    required String sourceKey,
    required String sourceLabelEn,
    required String sourceLabelAr,
  }) {
    if (!_permissionGranted) {
      setState(() {
        _permissionDeniedState = true;
      });
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    final fileName = '${widget.defaultFilePrefix}-$sourceKey-$timestamp.png';
    final base64Data = buildSpecimenPngBase64('$fileName:$timestamp');

    Navigator.of(context).pop(
      PickedPrivateMedia(
        fileName: fileName,
        mimeType: 'image/png',
        contentBase64: base64Data,
        sourceLabelEn: sourceLabelEn,
        sourceLabelAr: sourceLabelAr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    final palette = context.fixoPalette;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(FixoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.subtleBorder),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: palette.deepForest,
                    size: 20,
                  ),
                ),
                const SizedBox(width: FixoSpacing.sm),
                Expanded(
                  child: Text(
                    ar ? widget.titleAr : widget.titleEn,
                    style: FixoTypography.headlineSm(
                      color: palette.deepForest,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: palette.mutedText),
                ),
              ],
            ),
            const SizedBox(height: FixoSpacing.sm),
            FixoSurfaceCard(
              padding: const EdgeInsets.all(FixoSpacing.md),
              borderRadius: FixoRadius.borderRadiusMd,
              backgroundColor: palette.surfaceLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: FixoColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ar
                              ? 'إذن وصول سياقي ورفع خاص مشفّر'
                              : 'Contextual Permission & Private Upload',
                          style: FixoTypography.labelMd(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ar ? widget.rationaleAr : widget.rationaleEn,
                    style: FixoTypography.bodySm(color: palette.mutedText),
                  ),
                  if (widget.isSyntheticIdentitySpecimen) ...[
                    const SizedBox(height: 6),
                    Text(
                      ar
                          ? 'تنبيه أمان: استخدم نماذج اختبارية فقط — لا ترفع مستندات هوية شخصية حقيقية.'
                          : 'Safety notice: Use synthetic test specimens only — never upload real personal identity documents.',
                      style: FixoTypography.bodySm(
                        color: FixoColors.secondary,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: FixoSpacing.md),

            if (_permissionDeniedState) ...[
              Container(
                key: const Key('media-permission-denied-banner'),
                padding: const EdgeInsets.all(FixoSpacing.md),
                decoration: BoxDecoration(
                  color: FixoColors.errorContainer,
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ar
                          ? 'تم رفض إذن الكاميرا أو المعرض. يرجى السماح بالوصول للمتابعة.'
                          : 'Camera or gallery permission was denied. Please allow access to continue.',
                      style: FixoTypography.bodySm(
                        color: FixoColors.onErrorContainer,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        key: const Key('retry-media-permission-btn'),
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primaryBrand,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _permissionGranted = true;
                            _permissionDeniedState = false;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          ar
                              ? 'منح الإذن وإعادة المحاولة'
                              : 'Grant Access & Retry',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FixoSpacing.md),
            ],

            FilledButton.icon(
              key: const Key('pick-camera-specimen-btn'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: palette.primaryBrand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
              ),
              onPressed: () => _selectSource(
                sourceKey: 'camera',
                sourceLabelEn: 'Camera Capture',
                sourceLabelAr: 'التقاط بالكاميرا',
              ),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(
                ar
                    ? 'التقاط صورة بالكاميرا (نموذج آمن)'
                    : 'Capture with Camera (Safe Specimen)',
              ),
            ),
            const SizedBox(height: FixoSpacing.sm),
            OutlinedButton.icon(
              key: const Key('pick-gallery-specimen-btn'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: palette.deepForest,
                side: BorderSide(color: palette.subtleBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
              ),
              onPressed: () => _selectSource(
                sourceKey: 'gallery',
                sourceLabelEn: 'Photo Library',
                sourceLabelAr: 'معرض الصور',
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                ar
                    ? 'اختيار من المعرض / الملفات'
                    : 'Choose from Gallery / Files',
              ),
            ),
            const SizedBox(height: FixoSpacing.xs),
            SwitchListTile.adaptive(
              key: const Key('toggle-media-permission-switch'),
              contentPadding: EdgeInsets.zero,
              value: _permissionGranted,
              onChanged: (v) {
                setState(() {
                  _permissionGranted = v;
                  if (v) _permissionDeniedState = false;
                });
              },
              title: Text(
                ar
                    ? 'إذن الوصول للكاميرا والملفات مفعّل'
                    : 'Camera & File Access Permission Granted',
                style: FixoTypography.bodySm(color: palette.mutedText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

