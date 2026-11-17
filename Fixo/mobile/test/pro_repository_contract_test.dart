import 'package:dio/dio.dart';
import 'package:fixo_mobile/features/pro/data/pro_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/features/pro/domain/pro_models.dart';

void main() {
  test('real catalog enums and nested subskills can be selected', () {
    final catalog = ProCatalogOptionsModel.fromJson({
      'categories': [
        {
          'id': 'cat-test',
          'slug': 'ac',
          'nameEn': 'AC',
          'nameAr': 'تكييف',
          'subSkills': [
            {
              'id': 'skill-test',
              'slug': 'clean',
              'nameEn': 'Cleaning',
              'nameAr': 'تنظيف',
              'categoryId': 'cat-test',
            },
          ],
        },
      ],
      'zones': [],
      'transportModes': ['MOTORCYCLE', 'WORK_VAN', 'METRO_BUS'],
      'experienceTiers': ['SKILLED_3_5Y'],
    });
    expect(catalog.subSkills.single.id, 'skill-test');
    expect(catalog.transportModes.first.key, 'MOTORCYCLE');
    expect(catalog.experienceTiers.single.key, 'SKILLED_3_5Y');
  });
  test(
    'real verification response preserves status, uploaded documents and milestones',
    () {
      final status = ProVerificationStatusModel.fromJson({
        'verificationStatus': 'PENDING_REVIEW',
        'dossierCode': 'TEST-DOSSIER',
        'profile': {
          'documents': [
            {
              'id': 'doc-test',
              'docType': 'NATIONAL_ID_FRONT',
              'fileName': 'document.webp',
              'mimeType': 'image/webp',
              'fileSizeBytes': 500,
              'status': 'PENDING',
              'uploadedAt': '2026-11-02T09:00:00Z',
            },
          ],
        },
        'milestones': [
          {
            'key': 'DOCUMENT_UPLOAD',
            'titleEn': 'Documents',
            'titleAr': 'المستندات',
            'subtitleEn': 'Three photos received',
            'subtitleAr': 'تم الاستلام',
            'state': 'COMPLETED',
          },
        ],
      });
      expect(status.isPendingReview, isTrue);
      expect(status.documents.single.id, 'doc-test');
      expect(status.documents.single.createdAt, '2026-11-02T09:00:00Z');
      expect(status.milestones.single.status, 'DONE');
      expect(status.milestones.single.descEn, 'Three photos received');
    },
  );
  test('real dashboard response exposes actual earnings and assigned jobs', () {
    final dashboard = ProDashboardModel.fromJson({
      'profile': {'isOnline': true},
      'earningsSummary': {
        'todayNetEarningsEgp': 340,
        'weeklyNetEarningsEgp': 680,
        'totalCompletedJobsCount': 2,
        'ratingAvg': 4.5,
        'reviewsCount': 2,
      },
      'weeklyTrajectory': [
        {
          'date': '2026-11-02',
          'dayLabelEn': 'Mon',
          'dayLabelAr': 'الإثنين',
          'netEarningsEgp': 340,
        },
      ],
      'activeOffers': [],
      'activeJobs': [
        {
          'id': 'booking-test',
          'orderCode': 'TEST-1',
          'status': 'ARRIVED',
          'scheduledDate': '2026-11-02',
          'timeWindow': 'MORNING_09_12',
          'offering': {'titleEn': 'AC repair', 'titleAr': 'إصلاح تكييف'},
          'address': {
            'buildingLine': 'Local fixture',
            'districtLine': 'District',
            'zone': {'nameEn': 'Test zone', 'nameAr': 'منطقة اختبار'},
          },
          'customer': {'fullName': 'Local fixture'},
          'pricing': {'totalEgp': 400, 'netArtisanEgp': 340},
        },
      ],
    });
    expect(dashboard.isOnline, isTrue);
    expect(dashboard.todayEarningsEgp, 340);
    expect(dashboard.weekEarningsEgp, 680);
    expect(dashboard.completedJobsCount, 2);
    expect(dashboard.dailyTrajectory.single.netEgp, 340);
    expect(dashboard.todaySchedule.single.serviceTitleEn, 'AC repair');
    expect(dashboard.todaySchedule.single.hasArrivalPin, isTrue);
  });
  test(
    'reads the real /pro/me profile envelope and preserves approval',
    () async {
      Map<String, dynamic> payload = {
        'profile': {
          'id': 'pro-test',
          'userId': 'user-test',
          'fullName': 'Local fixture',
          'verificationStatus': 'APPROVED',
        },
      };
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: payload,
                  statusCode: 200,
                ),
              );
            },
          ),
        );
      final repository = ProRepository(dio);
      final profile = await repository.getMyProfile();
      expect(profile?.id, 'pro-test');
      expect(profile?.verificationStatus, 'APPROVED');
      payload = {'profile': null};
      expect(await repository.getMyProfile(), isNull);
      payload = {};
      await expectLater(repository.getMyProfile(), throwsFormatException);
    },
  );
}
