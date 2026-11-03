import 'package:flutter/material.dart';
import '../data/admin_professional_models.dart';

class ProReviewDecision {
  const ProReviewDecision(this.note, this.confirmed, this.rejectedDocuments);
  final String note;
  final bool confirmed;
  final List<String> rejectedDocuments;
}

class AdminProDecisionDialog extends StatefulWidget {
  const AdminProDecisionDialog({
    super.key,
    required this.status,
    required this.ar,
    this.documentTypes = const [],
  });
  final String status;
  final bool ar;
  final List<String> documentTypes;
  @override
  State<AdminProDecisionDialog> createState() => _State();
}

class _State extends State<AdminProDecisionDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  bool _confirmed = false;
  final _rejected = <String>{};
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ar, approve = widget.status == 'APPROVED';
    return AlertDialog(
      scrollable: true,
      title: Text(
        approve
            ? (ar ? 'تأكيد قبول الفني' : 'Confirm professional approval')
            : widget.status == 'SUSPENDED'
            ? (ar ? 'إيقاف الفني' : 'Suspend professional')
            : (ar ? 'طلب تصحيح المستندات' : 'Request corrections'),
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approve
                  ? (ar
                        ? 'القبول يسمح للفني باستكمال العمل على FIXO. دي مراجعة داخلية، وليست اعتمادًا حكوميًا.'
                        : 'Approval lets the professional continue working on FIXO. This is an internal review, not government certification.')
                  : (ar
                        ? 'القرار والسبب هيظهروا للفني. الإيقاف أو طلب التصحيح يوقف استقبال عروض جديدة.'
                        : 'The professional can see this decision and reason. Suspension or corrections stop new offers.'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('admin-pro-review-note'),
              controller: _note,
              maxLength: 600,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: approve
                    ? (ar ? 'ملاحظة اختيارية' : 'Optional note')
                    : (ar ? 'السبب المطلوب' : 'Required reason'),
              ),
              validator: (value) => approve || (value?.trim().length ?? 0) >= 3
                  ? null
                  : (ar
                        ? 'اكتب سببًا واضحًا من ٣ أحرف على الأقل.'
                        : 'Enter a clear reason of at least 3 characters.'),
            ),
            if (widget.status == 'ACTION_REQUIRED') ...[
              const SizedBox(height: 12),
              Text(
                ar
                    ? 'اختار المستندات المطلوب استبدالها، لو التصحيح يخص الصور.'
                    : 'Select the documents that need replacing, if the correction concerns photos.',
              ),
              for (final type in widget.documentTypes)
                CheckboxListTile(
                  key: Key('admin-pro-correction-doc-$type'),
                  contentPadding: EdgeInsets.zero,
                  value: _rejected.contains(type),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _rejected.add(type);
                    } else {
                      _rejected.remove(type);
                    }
                  }),
                  title: Text(professionalDocumentLabel(type, ar)),
                ),
            ],
            if (approve)
              CheckboxListTile(
                key: const Key('admin-pro-review-confirmation'),
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                onChanged: (value) =>
                    setState(() => _confirmed = value == true),
                title: Text(
                  ar
                      ? 'راجعت البطاقة وش وضهر والفيش الجنائي، وأوافق على قبول الملف.'
                      : 'I reviewed the ID front/back and criminal record certificate and approve this dossier.',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ar ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          key: const Key('admin-pro-review-submit'),
          onPressed: approve && !_confirmed
              ? null
              : () {
                  if (_form.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      ProReviewDecision(
                        _note.text.trim(),
                        approve && _confirmed,
                        _rejected.toList(),
                      ),
                    );
                  }
                },
          child: Text(ar ? 'تأكيد القرار' : 'Confirm decision'),
        ),
      ],
    );
  }
}
