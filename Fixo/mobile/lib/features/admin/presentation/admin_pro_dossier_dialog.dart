import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/admin_professional_models.dart';
import '../data/admin_repository.dart';
import 'admin_confirmation_dialog.dart';
import 'admin_document_dialog.dart';
import 'admin_pro_decision_dialog.dart';

class AdminProDossierDialog extends ConsumerStatefulWidget {
  const AdminProDossierDialog({super.key, required this.id, required this.ar});
  final String id;
  final bool ar;
  @override
  ConsumerState<AdminProDossierDialog> createState() => _State();
}

class _State extends ConsumerState<AdminProDossierDialog> {
  static const requiredTypes = [
    'NATIONAL_ID_FRONT',
    'NATIONAL_ID_BACK',
    'CRIMINAL_RECORD_CERT',
  ];
  final _viewed = <String>{};
  late final _owner = ref.read(authControllerProvider).session?.user.id;
  CancelToken? _cancel;
  late Future<AdminProfessionalDetail> _future;
  bool _busy = false, _reauth = false, _sessionChanged = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AdminProfessionalDetail> _load() {
    _cancel?.cancel();
    _cancel = CancelToken();
    return ref
        .read(adminRepositoryProvider)
        .professional(widget.id, cancelToken: _cancel);
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _viewed.clear();
      _error = null;
      _reauth = false;
      _future = _load();
    });
  }

  Future<void> _confirm() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmationDialog(ar: widget.ar),
    );
    if (mounted && result == true) _reload();
  }

  Future<void> _view(AdminProfessionalDocument doc) async {
    if (_sessionChanged ||
        ref.read(authControllerProvider).session?.user.id != _owner) {
      return;
    }
    final reviewed = await showDialog<bool>(
      context: context,
      builder: (_) => AdminDocumentDialog(
        profileId: widget.id,
        document: doc,
        ar: widget.ar,
      ),
    );
    if (mounted &&
        reviewed == true &&
        ref.read(authControllerProvider).session?.user.id == _owner) {
      setState(() => _viewed.add(doc.id));
    }
  }

  Future<void> _review(AdminProfessionalDetail detail, String status) async {
    if (_busy ||
        _sessionChanged ||
        !detail.canReview ||
        ref.read(authControllerProvider).session?.user.id != _owner) {
      return;
    }
    final decision = await showDialog<ProReviewDecision>(
      context: context,
      builder: (_) => AdminProDecisionDialog(
        status: status,
        ar: widget.ar,
        documentTypes: detail.documents
            .where((d) => requiredTypes.contains(d.type))
            .map((d) => d.type)
            .toList(),
      ),
    );
    if (decision == null ||
        !mounted ||
        _owner == null ||
        ref.read(authControllerProvider).session?.user.id != _owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _reauth = false;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .reviewProfessional(
            detail,
            status,
            decision.note,
            confirmed: decision.confirmed,
            rejectedTypes: decision.rejectedDocuments,
          );
      if (!mounted ||
          ref.read(authControllerProvider).session?.user.id != _owner) {
        return;
      }
      ref.invalidate(adminAuditProvider);
      ref.invalidate(adminSummaryProvider);
      ref.read(adminProfessionalsRevisionProvider.notifier).state++;
      _reload();
    } catch (error) {
      if (mounted) {
        setState(() {
          _reauth = needsAdminConfirmation(error);
          _error = _reauth
              ? (widget.ar
                    ? 'أكد حسابك قبل القرار.'
                    : 'Confirm your account before the decision.')
              : error is DioException && error.response?.statusCode == 409
              ? (widget.ar
                    ? 'الملف اتغيّر. حدّثه وراجع الصور الحالية قبل أي قرار.'
                    : 'This dossier changed. Reload and review the current images before deciding.')
              : (widget.ar
                    ? 'تعذر تأكيد القرار. حدّث الملف وتأكد من اكتمال البيانات والمستندات.'
                    : 'Could not confirm the decision. Reload and check that identity, skills and documents are complete.');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _detail(AdminProfessionalDetail detail) {
    final ar = widget.ar;
    final ready = requiredTypes.every(
      (type) => detail.documents.any(
        (d) =>
            d.type == type && d.status != 'REJECTED' && _viewed.contains(d.id),
      ),
    );
    final status = detail.summary.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          detail.summary.legalName ??
              detail.summary.displayName ??
              (ar ? 'الاسم غير مسجل' : 'Name not recorded'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(professionalStatusLabel(status, ar)),
        const SizedBox(height: 16),
        SelectableText(
          '${ar ? 'الرقم القومي' : 'National ID'}: ${detail.nationalId}',
        ),
        if (detail.phone != null)
          SelectableText(detail.phone!, textDirection: TextDirection.ltr),
        if (detail.email != null)
          SelectableText(detail.email!, textDirection: TextDirection.ltr),
        const SizedBox(height: 12),
        Text(
          detail.category?.label(ar) ??
              (ar ? 'القسم غير محدد' : 'Trade not selected'),
        ),
        Text(detail.zones.map((z) => z.label(ar)).join(' · ')),
        if (detail.reviewerNote?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(detail.reviewerNote!),
          ),
        const Divider(height: 32),
        Text(
          ar ? 'المستندات الخاصة' : 'Private documents',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'افتح صور المستندات الثلاثة وراجعها قبل الموافقة. تقدر تكبّر كل صورة.'
              : 'Open and review all three document photos before approving. Each photo supports zoom.',
        ),
        for (final type in requiredTypes) ...[
          const SizedBox(height: 12),
          if (!detail.documents.any((d) => d.type == type))
            Text(
              '${professionalDocumentLabel(type, ar)} — ${ar ? 'غير مرفوع' : 'Not uploaded'}',
            )
          else
            for (final doc in detail.documents.where((d) => d.type == type))
              OutlinedButton.icon(
                key: Key('admin-pro-document-${doc.id}'),
                onPressed: _busy ? null : () => _view(doc),
                icon: Icon(
                  _viewed.contains(doc.id)
                      ? Icons.check_circle_outline
                      : Icons.visibility_outlined,
                ),
                label: Text(
                  '${professionalDocumentLabel(type, ar)}${doc.status == 'REJECTED' ? (ar ? ' — يحتاج استبدال' : ' — replacement needed') : ''}',
                ),
              ),
        ],
        const SizedBox(height: 20),
        if (!detail.canReview)
          Text(
            ar
                ? 'مش مسموح تراجع أو تعتمد ملفك الشخصي بنفسك.'
                : 'You cannot review your own professional dossier.',
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (status == 'PENDING_REVIEW')
                FilledButton(
                  key: const Key('admin-pro-approve'),
                  onPressed: _busy || !ready
                      ? null
                      : () => _review(detail, 'APPROVED'),
                  child: Text(ar ? 'قبول الفني' : 'Approve professional'),
                ),
              if (status != 'DRAFT')
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _review(detail, 'ACTION_REQUIRED'),
                  child: Text(ar ? 'طلب تصحيح' : 'Request corrections'),
                ),
              if (status == 'APPROVED')
                OutlinedButton(
                  onPressed: _busy ? null : () => _review(detail, 'SUSPENDED'),
                  child: Text(ar ? 'إيقاف الفني' : 'Suspend professional'),
                ),
            ],
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_reauth)
          TextButton(
            onPressed: _busy ? null : _confirm,
            child: Text(ar ? 'تأكيد حسابك' : 'Confirm your account'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authControllerProvider.select((state) => state.session?.user.id),
      (_, owner) {
        if (owner != _owner && !_sessionChanged) {
          _cancel?.cancel();
          if (mounted) {
            setState(() {
              _sessionChanged = true;
              _viewed.clear();
            });
          }
        }
      },
    );
    final ar = widget.ar,
        same =
            !_sessionChanged &&
            ref.watch(authControllerProvider).session?.user.id == _owner &&
            _owner != null;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(ar ? 'مراجعة ملف الفني' : 'Professional dossier'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: !same
                ? Text(ar ? 'جلسة الحساب اتغيرت.' : 'Account session changed.')
                : FutureBuilder<AdminProfessionalDetail>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        final reauth = needsAdminConfirmation(snapshot.error!);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reauth
                                  ? (ar
                                        ? 'أكد حسابك علشان تفتح بيانات الهوية.'
                                        : 'Confirm your account to open identity details.')
                                  : (ar
                                        ? 'تعذر تحميل الملف الخاص.'
                                        : 'Could not load the private dossier.'),
                            ),
                            TextButton(
                              onPressed: reauth ? _confirm : _reload,
                              child: Text(
                                reauth
                                    ? (ar
                                          ? 'تأكيد حسابك'
                                          : 'Confirm your account')
                                    : (ar ? 'إعادة المحاولة' : 'Retry'),
                              ),
                            ),
                          ],
                        );
                      }
                      return _detail(snapshot.data!);
                    },
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy || !same ? null : _reload,
            child: Text(ar ? 'تحديث الملف' : 'Reload dossier'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(ar ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }
}
