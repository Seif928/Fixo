import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/fixo_colors.dart';
import 'device_media_picker.dart';
export 'device_media_picker.dart' show PickedPrivateMedia;

/// OS access is requested only after the user chooses a source.
class PrivateMediaPickerSheet extends ConsumerStatefulWidget {
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
  final bool isArabic, isSyntheticIdentitySpecimen;
  final String titleEn, titleAr, rationaleEn, rationaleAr, defaultFilePrefix;

  static Future<PickedPrivateMedia?> show(
    BuildContext context, {
    required bool isArabic,
    required String titleEn,
    required String titleAr,
    required String rationaleEn,
    required String rationaleAr,
    required String defaultFilePrefix,
    bool isSyntheticIdentitySpecimen = false,
  }) => showModalBottomSheet<PickedPrivateMedia>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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

  @override
  ConsumerState<PrivateMediaPickerSheet> createState() =>
      _PrivateMediaPickerSheetState();
}

class _PrivateMediaPickerSheetState
    extends ConsumerState<PrivateMediaPickerSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final selected = await ref.read(deviceMediaPickerProvider).pick(source);
      if (mounted && selected != null) Navigator.pop(context, selected);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              error is PlatformException && error.code.contains('denied')
              ? (widget.isArabic
                    ? 'السماح بالصور أو الكاميرا مقفول. راجع إعدادات الجهاز أو اختار مصدر تاني.'
                    : 'Photo or camera access is denied. Check device settings or choose another source.')
              : (widget.isArabic
                    ? 'تعذر اختيار الصورة. اختار JPEG أو PNG أو WebP بحجم لا يتجاوز ٢ ميجابايت.'
                    : 'Could not select this photo. Choose JPEG, PNG or WebP up to 2 MB.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    final palette = context.fixoPalette;
    final picker = ref.watch(deviceMediaPickerProvider);
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ar ? widget.titleAr : widget.titleEn,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: ar ? 'إغلاق' : 'Close',
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ar ? widget.rationaleAr : widget.rationaleEn),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  key: const Key('media-picker-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (picker.supportsCamera) ...[
              FilledButton.icon(
                key: const Key('pick-camera-btn'),
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(ar ? 'التقاط صورة' : 'Take a photo'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              key: const Key('pick-gallery-btn'),
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(ar ? 'اختيار صورة من الجهاز' : 'Choose a photo'),
            ),
            const SizedBox(height: 12),
            Text(
              ar
                  ? 'JPEG أو PNG أو WebP · حتى ٢ ميجابايت'
                  : 'JPEG, PNG or WebP · up to 2 MB',
              style: TextStyle(color: palette.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
