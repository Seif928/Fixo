import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/fixo_colors.dart';
import '../storage/secure_token_storage.dart';
import 'device_media_picker.dart';
import 'suggested_avatar.dart';
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
    this.allowSuggestedAvatars = false,
  });
  final bool isArabic, isSyntheticIdentitySpecimen;
  final bool allowSuggestedAvatars;
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
    bool allowSuggestedAvatars = false,
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
      allowSuggestedAvatars: allowSuggestedAvatars,
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
  bool _showAvatars = false;
  bool _recovering = true, _sessionChanged = false, _previewReady = false;
  late final String? _entryOwner;
  PickedPrivateMedia? _recovered;
  ImageProvider? _preview;
  bool get _active =>
      !_sessionChanged && ref.read(activeSessionOwnerProvider) == _entryOwner;
  @override
  void initState() {
    super.initState();
    _entryOwner = ref.read(activeSessionOwnerProvider);
    _recover();
  }

  void _clearPreview() {
    _preview?.evict();
    _preview = null;
    _recovered = null;
    _previewReady = false;
  }

  @override
  void dispose() {
    _clearPreview();
    super.dispose();
  }

  Future<void> _recover() async {
    try {
      final photo = await ref
          .read(deviceMediaPickerProvider)
          .recoveredFor(widget.defaultFilePrefix);
      if (!mounted || !_active) return;
      if (photo != null) {
        setState(() {
          _recovered = photo;
          _preview = ResizeImage.resizeIfNeeded(
            160,
            160,
            MemoryImage(base64Decode(photo.contentBase64)),
          );
        });
      }
    } catch (_) {
      if (mounted && _active) {
        setState(
          () => _error = widget.isArabic
              ? 'تعذر استرجاع الصورة السابقة. اختار صورة من جديد.'
              : 'Could not recover the previous photo. Please choose a photo again.',
        );
      }
    } finally {
      if (mounted && _active) setState(() => _recovering = false);
    }
  }

  Future<void> _useRecovered() async {
    if (!_active || _busy || !_previewReady) return;
    setState(() => _busy = true);
    try {
      final selected = await ref
          .read(deviceMediaPickerProvider)
          .takeRecovered(widget.defaultFilePrefix);
      if (!mounted || !_active) return;
      if (selected != null) {
        Navigator.pop(context, selected);
      } else {
        setState(() {
          _clearPreview();
          _error = widget.isArabic
              ? 'الصورة لم تعد متاحة. اختار صورة جديدة.'
              : 'The photo is no longer available. Please choose another.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discardRecovered() async {
    if (!_active || _busy) return;
    await ref
        .read(deviceMediaPickerProvider)
        .discardRecovered(widget.defaultFilePrefix);
    if (mounted) setState(_clearPreview);
  }

  Future<void> _chooseAvatar(int index) async {
    if (_busy || _recovering || !_active) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final selected = await renderSuggestedAvatar(index);
      if (mounted && _active) Navigator.pop(context, selected);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = widget.isArabic
              ? 'تعذر اختيار الأفاتار. حاول تاني.'
              : 'Could not select this avatar. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy || _recovering || !_active) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final selected = await ref
          .read(deviceMediaPickerProvider)
          .pickFor(source, scope: widget.defaultFilePrefix);
      if (mounted && _active && selected != null) {
        Navigator.pop(context, selected);
      }
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
    ref.listen(activeSessionOwnerProvider, (_, owner) {
      if (owner != _entryOwner && !_sessionChanged) {
        ref
            .read(deviceMediaPickerProvider)
            .discardRecovered(widget.defaultFilePrefix);
        if (mounted) {
          setState(() {
            _sessionChanged = true;
            _clearPreview();
          });
        }
      }
    });
    final ar = widget.isArabic;
    if (!_active) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ar
                    ? 'الجلسة اتغيّرت. اقفل اختيار الصورة وافتحه من جديد.'
                    : 'Session changed. Close and reopen the photo picker.',
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(ar ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        ),
      );
    }
    final disabled = _busy || _recovering;
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
            if (_recovering) const LinearProgressIndicator(),
            if (_recovered != null && _preview != null) ...[
              Text(
                ar
                    ? 'لقينا صورة كنت بتختارها قبل ما التطبيق يتقفل. راجعها واختار تستخدمها أو تتجاهلها.'
                    : 'A previously selected photo was recovered. Review it and choose whether to use or discard it.',
              ),
              const SizedBox(height: 12),
              Center(
                child: Image(
                  key: const Key('recovered-photo-preview'),
                  image: _preview!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, sync) {
                    if ((frame != null || sync) && !_previewReady) {
                      final image = _preview;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted &&
                            _active &&
                            image == _preview &&
                            !_previewReady) {
                          setState(() => _previewReady = true);
                        }
                      });
                    }
                    return child;
                  },
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('use-recovered-photo'),
                onPressed: disabled || !_previewReady ? null : _useRecovered,
                child: Text(
                  ar ? 'استخدام الصورة المسترجعة' : 'Use recovered photo',
                ),
              ),
              TextButton(
                key: const Key('discard-recovered-photo'),
                onPressed: disabled ? null : _discardRecovered,
                child: Text(ar ? 'تجاهل الصورة' : 'Discard photo'),
              ),
              const Divider(height: 24),
            ],
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
                onPressed: disabled ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(ar ? 'التقاط صورة' : 'Take a photo'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              key: const Key('pick-gallery-btn'),
              onPressed: disabled ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(ar ? 'اختيار صورة من الجهاز' : 'Choose a photo'),
            ),
            const SizedBox(height: 12),
            if (widget.allowSuggestedAvatars) ...[
              OutlinedButton.icon(
                key: const Key('choose-suggested-avatar'),
                onPressed: disabled
                    ? null
                    : () => setState(() => _showAvatars = !_showAvatars),
                icon: const Icon(Icons.face_retouching_natural),
                label: Text(
                  ar ? 'اختار من ٢٤ أفاتار جاهز' : 'Choose from 24 avatars',
                ),
              ),
              if (_showAvatars) ...[
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final side = ((constraints.maxWidth - 30) / 4).clamp(
                      40.0,
                      76.0,
                    );
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        suggestedAvatarCount,
                        (index) => Tooltip(
                          message: ar
                              ? 'أفاتار ${index + 1}'
                              : 'Avatar ${index + 1}',
                          child: Semantics(
                            button: true,
                            label: ar
                                ? 'أفاتار ${index + 1}'
                                : 'Avatar ${index + 1}',
                            child: InkWell(
                              key: Key('suggested-avatar-$index'),
                              onTap: disabled
                                  ? null
                                  : () => _chooseAvatar(index),
                              customBorder: const CircleBorder(),
                              child: SuggestedAvatar(index: index, size: side),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
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
