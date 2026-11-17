import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_professional_models.dart';
import '../data/admin_repository.dart';

class AdminDocumentDialog extends ConsumerStatefulWidget {
  const AdminDocumentDialog({
    super.key,
    required this.profileId,
    required this.document,
    required this.ar,
  });
  final String profileId;
  final AdminProfessionalDocument document;
  final bool ar;
  @override
  ConsumerState<AdminDocumentDialog> createState() => _State();
}

class _State extends ConsumerState<AdminDocumentDialog> {
  final _cancel = CancelToken();
  late final _owner = ref.read(authControllerProvider).session?.user.id;
  late final Future<AdminPrivateDocument> _future = ref
      .read(adminRepositoryProvider)
      .professionalDocument(
        widget.profileId,
        widget.document.id,
        cancelToken: _cancel,
      )
      .then((doc) {
        if (!mounted ||
            ref.read(authControllerProvider).session?.user.id != _owner) {
          throw StateError('Account changed');
        }
        if (doc.mimeType.startsWith('image/')) _image = MemoryImage(doc.bytes);
        return doc;
      });
  MemoryImage? _image;
  bool _decoded = false, _sessionChanged = false;
  @override
  void dispose() {
    _cancel.cancel();
    _image?.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authControllerProvider.select((state) => state.session?.user.id),
      (_, owner) {
        if (owner != _owner && !_sessionChanged) {
          _cancel.cancel();
          _image?.evict();
          if (mounted) {
            setState(() {
              _sessionChanged = true;
              _decoded = false;
              _image = null;
            });
          }
        }
      },
    );
    final ar = widget.ar;
    final same =
        !_sessionChanged &&
        ref.watch(authControllerProvider).session?.user.id == _owner &&
        _owner != null;
    if (!same) {
      _cancel.cancel();
      _image?.evict();
    }
    return AlertDialog(
      title: Text(professionalDocumentLabel(widget.document.type, ar)),
      content: SizedBox(
        width: 700,
        height: MediaQuery.sizeOf(context).height * .5,
        child: !same
            ? Text(ar ? 'جلسة الحساب اتغيرت.' : 'Account session changed.')
            : FutureBuilder<AdminPrivateDocument>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(
                      ar
                          ? 'تعذر تحميل المستند الخاص. اقفل النافذة وحاول تاني.'
                          : 'Could not load the private document. Close this window and retry.',
                    );
                  }
                  if (_image == null) {
                    return Text(
                      ar
                          ? 'معاينة صور المستندات متاحة فقط. اطلب صورة واضحة بدل الملف ده قبل الموافقة.'
                          : 'This viewer supports document photos. Request a clear photo in place of this file before approving.',
                    );
                  }
                  return InteractiveViewer(
                    minScale: .5,
                    maxScale: 4,
                    child: Image(
                      image: _image!,
                      fit: BoxFit.contain,
                      semanticLabel: professionalDocumentLabel(
                        widget.document.type,
                        ar,
                      ),
                      frameBuilder: (context, child, frame, synchronous) {
                        if (frame != null && !_decoded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _decoded = true);
                          });
                        }
                        return child;
                      },
                      errorBuilder: (_, _, _) => Text(
                        ar
                            ? 'تعذر عرض صورة المستند.'
                            : 'Could not display the document photo.',
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(ar ? 'إغلاق' : 'Close'),
        ),
        FilledButton(
          key: const Key('admin-document-reviewed'),
          onPressed: !same || !_decoded
              ? null
              : () => Navigator.pop(context, true),
          child: Text(ar ? 'راجعت الصورة' : 'Photo reviewed'),
        ),
      ],
    );
  }
}
