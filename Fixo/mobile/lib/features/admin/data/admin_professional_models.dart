import 'dart:typed_data';

const professionalStatuses = [
  'DRAFT',
  'PENDING_REVIEW',
  'ACTION_REQUIRED',
  'APPROVED',
  'SUSPENDED',
];
String professionalStatusLabel(String value, bool ar) => switch (value) {
  'DRAFT' => ar ? 'مسودة' : 'Draft',
  'PENDING_REVIEW' => ar ? 'بانتظار المراجعة' : 'Awaiting review',
  'ACTION_REQUIRED' => ar ? 'يحتاج تصحيح' : 'Corrections needed',
  'APPROVED' => ar ? 'مقبول' : 'Approved',
  'SUSPENDED' => ar ? 'موقوف' : 'Suspended',
  _ => throw const FormatException('Unknown professional status.'),
};
String professionalDocumentLabel(String value, bool ar) => switch (value) {
  'NATIONAL_ID_FRONT' => ar ? 'البطاقة — الوجه' : 'National ID — front',
  'NATIONAL_ID_BACK' => ar ? 'البطاقة — الظهر' : 'National ID — back',
  'CRIMINAL_RECORD_CERT' =>
    ar ? 'الفيش الجنائي' : 'Criminal record certificate',
  'SYNDICATE_LICENSE' => ar ? 'مستند مهني إضافي' : 'Additional trade document',
  _ => throw const FormatException('Unknown professional document.'),
};

class AdminLocalizedName {
  const AdminLocalizedName(this.en, this.ar);
  final String en, ar;
  String label(bool arabic) => arabic ? ar : en;
  factory AdminLocalizedName.fromJson(Map json) =>
      AdminLocalizedName(json['nameEn'] as String, json['nameAr'] as String);
}

class AdminProfessionalSummary {
  const AdminProfessionalSummary(
    this.id,
    this.dossierCode,
    this.legalName,
    this.displayName,
    this.status,
    this.documentCount,
  );
  final String id, dossierCode, status;
  final String? legalName, displayName;
  final int documentCount;
  factory AdminProfessionalSummary.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['dossierCode'] is! String ||
        !professionalStatuses.contains(json['verificationStatus']) ||
        json['documentCount'] is! int ||
        (json['documentCount'] as int) < 0) {
      throw const FormatException('Invalid professional summary.');
    }
    return AdminProfessionalSummary(
      json['id'] as String,
      json['dossierCode'] as String,
      json['legalName'] as String?,
      json['displayName'] as String?,
      json['verificationStatus'] as String,
      json['documentCount'] as int,
    );
  }
}

class AdminProfessionalPage {
  const AdminProfessionalPage(
    this.items,
    this.page,
    this.totalPages,
    this.total,
  );
  final List<AdminProfessionalSummary> items;
  final int page, totalPages, total;
  factory AdminProfessionalPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map;
    if (meta['page'] is! int ||
        meta['page'] < 1 ||
        meta['totalPages'] is! int ||
        meta['totalPages'] < 1 ||
        meta['total'] is! int ||
        meta['total'] < 0) {
      throw const FormatException('Invalid professional pagination.');
    }
    return AdminProfessionalPage(
      (json['items'] as List)
          .map(
            (e) => AdminProfessionalSummary.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      meta['page'] as int,
      meta['totalPages'] as int,
      meta['total'] as int,
    );
  }
}

class AdminProfessionalDocument {
  const AdminProfessionalDocument(
    this.id,
    this.type,
    this.status,
    this.mimeType,
  );
  final String id, type, status;
  final String? mimeType;
  factory AdminProfessionalDocument.fromJson(Map json) {
    if (!['PENDING', 'VERIFIED', 'REJECTED'].contains(json['status']) ||
        ![
          'NATIONAL_ID_FRONT',
          'NATIONAL_ID_BACK',
          'CRIMINAL_RECORD_CERT',
          'SYNDICATE_LICENSE',
        ].contains(json['docType'])) {
      throw const FormatException('Invalid document metadata.');
    }
    return AdminProfessionalDocument(
      json['id'] as String,
      json['docType'] as String,
      json['status'] as String,
      json['mimeType'] as String?,
    );
  }
}

class AdminProfessionalDetail {
  const AdminProfessionalDetail(
    this.summary,
    this.nationalId,
    this.phone,
    this.email,
    this.reviewerNote,
    this.category,
    this.zones,
    this.documents,
    this.reviewVersion,
    this.canReview,
  );
  final AdminProfessionalSummary summary;
  final String nationalId, reviewVersion;
  final String? phone, email, reviewerNote;
  final AdminLocalizedName? category;
  final List<AdminLocalizedName> zones;
  final List<AdminProfessionalDocument> documents;
  final bool canReview;
  factory AdminProfessionalDetail.fromJson(Map<String, dynamic> json) {
    if (json['canReview'] is! bool ||
        json['reviewVersion'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(json['reviewVersion'] as String)) {
      throw const FormatException('Invalid dossier authority or version.');
    }
    final docs = (json['documents'] as List)
        .map((e) => AdminProfessionalDocument.fromJson(e as Map))
        .toList();
    return AdminProfessionalDetail(
      AdminProfessionalSummary.fromJson({
        ...json,
        'documentCount': docs.length,
      }),
      json['nationalId'] as String,
      json['phone'] as String?,
      json['email'] as String?,
      json['reviewerNote'] as String?,
      json['category'] == null
          ? null
          : AdminLocalizedName.fromJson(json['category'] as Map),
      (json['coverageZones'] as List)
          .map((e) => AdminLocalizedName.fromJson(e as Map))
          .toList(),
      docs,
      json['reviewVersion'] as String,
      json['canReview'] as bool,
    );
  }
}

class AdminPrivateDocument {
  const AdminPrivateDocument(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}
