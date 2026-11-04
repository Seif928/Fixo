import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/customer_home/domain/marketplace_models.dart';
import 'package:fixo_mobile/features/pro/data/pro_repository.dart';
import 'package:fixo_mobile/features/pro/domain/pro_models.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/incoming_job_page.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_dashboard_page.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_signup_page.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_skills_page.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_verification_docs_page.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_verification_status_page.dart';

class FakeProRepository implements ProRepository {
  bool isOnline = true;
  int reviewsCount = 38;
  String currentStatus = 'APPROVED';
  int acceptCallCount = 0;
  int getOfferCallCount = 0;
  int offerRemainingSeconds = 45;
  Future<JobOfferModel>? nextOfferResponse;
  int declineCallCount = 0;
  String? lastDeclinedReason;
  String? lastAdvancedStatus;
  String? lastArrivalPin;

  @override
  Future<ProCatalogOptionsModel> getCatalogOptions() async {
    return const ProCatalogOptionsModel(
      categories: [
        ServiceCategoryModel(
          id: 'cat-plumbing',
          slug: 'plumbing-sanitary',
          nameEn: 'Plumbing & Sanitary',
          nameAr: 'سباكة وصحي',
          subtitleEn: 'Leaks and repairs',
          subtitleAr: 'تسريبات وإصلاحات',
          iconName: 'plumbing',
          startingPriceEgp: 280,
          sortOrder: 1,
        ),
        ServiceCategoryModel(
          id: 'cat-ac',
          slug: 'air-conditioning',
          nameEn: 'Air Conditioning',
          nameAr: 'تكييف وتبريد',
          subtitleEn: 'Deep cleaning and maintenance',
          subtitleAr: 'تنظيف عميق وصيانة',
          iconName: 'ac_unit',
          startingPriceEgp: 450,
          sortOrder: 2,
        ),
      ],
      subSkills: [
        ProSubSkillModel(
          id: 'sub-leak',
          slug: 'water-pipe-leak',
          nameEn: 'Pipe Leaks',
          nameAr: 'كشف تسريب المواسير',
          categoryId: 'cat-plumbing',
        ),
        ProSubSkillModel(
          id: 'sub-ac-clean',
          slug: 'ac-deep-clean',
          nameEn: 'AC Cleaning',
          nameAr: 'غسيل التكييف',
          categoryId: 'cat-ac',
        ),
      ],
      zones: [
        CoverageZoneModel(
          id: 'zone-new-cairo',
          slug: 'new-cairo',
          nameEn: 'New Cairo, 5th Settlement',
          nameAr: 'القاهرة الجديدة، التجمع الخامس',
          governorate: 'Cairo',
        ),
        CoverageZoneModel(
          id: 'zone-sheikh-zayed',
          slug: 'sheikh-zayed',
          nameEn: 'Sheikh Zayed City',
          nameAr: 'مدينة الشيخ زايد',
          governorate: 'Giza',
        ),
      ],
      transportModes: [
        ProOptionItemModel(
          key: 'MOTORCYCLE',
          labelEn: 'Motorcycle',
          labelAr: 'دراجة نارية',
        ),
        ProOptionItemModel(
          key: 'WORK_VAN',
          labelEn: 'Work Van',
          labelAr: 'سيارة عمل',
        ),
        ProOptionItemModel(
          key: 'METRO_BUS',
          labelEn: 'Metro / Bus',
          labelAr: 'مترو / حافلة',
        ),
      ],
      experienceTiers: [
        ProOptionItemModel(
          key: 'SKILLED_3_5Y',
          labelEn: '3-5 Years',
          labelAr: '٣-٥ سنوات',
        ),
      ],
    );
  }

  @override
  Future<ProProfileModel?> getMyProfile() async {
    return ProProfileModel(
      id: 'pro-101',
      userId: 'usr-101',
      fullName: 'Hassan El-Naggar',
      nationalIdSynthetic: '29304150102938',
      primaryZoneId: 'zone-new-cairo',
      transportMode: 'MOTORCYCLE',
      primaryCategoryId: 'cat-plumbing',
      selectedSubSkillIds: ['sub-leak'],
      experienceTier: 'SKILLED_3_5Y',
      coverageZoneIds: ['zone-new-cairo'],
      acceptsStandardRateCard: true,
      toolkitCommitmentConfirmed: true,
      verificationStatus: 'APPROVED',
      isOnline: true,
      ratingAvg: 4.9,
      reviewsCount: reviewsCount,
      completedJobsCount: 42,
    );
  }

  @override
  Future<ProProfileModel> savePersonalDetails({
    String? fullName,
    required String nationalIdSynthetic,
    String? primaryZoneId,
    String? transportMode,
    String? vehicleDescription,
    String? vehiclePlateAr,
  }) async {
    return ProProfileModel(
      id: 'pro-101',
      userId: 'usr-101',
      fullName: fullName,
      nationalIdSynthetic: nationalIdSynthetic,
      primaryZoneId: primaryZoneId,
      transportMode: transportMode,
      vehicleDescription: vehicleDescription,
      vehiclePlateAr: vehiclePlateAr,
    );
  }

  @override
  Future<ProProfileModel> saveSkillsAndCoverage({
    required String primaryCategoryId,
    List<String> subSkillIds = const [],
    required String experienceTier,
    required List<String> coverageZoneIds,
    required bool acceptsStandardRateCard,
    required bool toolkitCommitmentConfirmed,
    String? specialtyEn,
    String? specialtyAr,
    int? estimatedPriceEgp,
  }) async {
    return ProProfileModel(
      id: 'pro-101',
      userId: 'usr-101',
      primaryCategoryId: primaryCategoryId,
      selectedSubSkillIds: subSkillIds,
      experienceTier: experienceTier,
      coverageZoneIds: coverageZoneIds,
      acceptsStandardRateCard: acceptsStandardRateCard,
      toolkitCommitmentConfirmed: toolkitCommitmentConfirmed,
    );
  }

  @override
  Future<ProDocumentModel> uploadVerificationDocument({
    required String docType,
    required String fileName,
    required String mimeType,
    required String contentBase64,
  }) async {
    return ProDocumentModel(
      id: 'doc-001',
      docType: docType,
      fileName: fileName,
      fileSizeBytes: 1024,
      mimeType: mimeType,
      status: 'PENDING',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<ProVerificationStatusModel> submitForVerification() async {
    currentStatus = 'PENDING_REVIEW';
    return getVerificationStatus();
  }

  @override
  Future<ProVerificationStatusModel> getVerificationStatus() async {
    return ProVerificationStatusModel(
      status: currentStatus,
      dossierCode: 'FIXO-PRO-8492',
      isComplete: currentStatus == 'APPROVED',
      milestones: const [
        ProVerificationMilestoneModel(
          key: 'SUBMITTED',
          stepNumber: 1,
          titleEn: 'Profile Submitted',
          titleAr: 'تم تقديم الملف',
          descEn: 'Personal and trade details received',
          descAr: 'تم استلام البيانات الشخصية والحرفية',
          status: 'DONE',
        ),
        ProVerificationMilestoneModel(
          key: 'BACKGROUND_CHECK',
          stepNumber: 2,
          titleEn: 'Security Vetting',
          titleAr: 'التدقيق الأمني والجنائي',
          descEn: 'Criminal record and ID verification',
          descAr: 'فحص صحيفة الحالة الجنائية والبطاقة القومية',
          status: 'DONE',
        ),
        ProVerificationMilestoneModel(
          key: 'TECHNICAL_EVALUATION',
          stepNumber: 3,
          titleEn: 'Technical Assessment',
          titleAr: 'التقييم الفني والمعدات',
          descEn: 'Trade experience and toolkit check',
          descAr: 'معاينة شنطة العدة والخبرة العملية',
          status: 'DONE',
        ),
        ProVerificationMilestoneModel(
          key: 'ACTIVATION_DECISION',
          stepNumber: 4,
          titleEn: 'Account Activation',
          titleAr: 'تفعيل الحساب والاعتماد',
          descEn: 'Ready for live dispatch offers',
          descAr: 'جاهز لاستقبال طلبات الزبائن المباشرة',
          status: 'DONE',
        ),
      ],
      documents: const [
        ProDocumentModel(
          id: 'doc-1',
          docType: 'NATIONAL_ID_FRONT',
          fileName: 'id-front.png',
          fileSizeBytes: 2048,
          mimeType: 'image/png',
          status: 'VERIFIED',
          createdAt: '2026-11-01T10:00:00Z',
        ),
        ProDocumentModel(
          id: 'doc-2',
          docType: 'NATIONAL_ID_BACK',
          fileName: 'id-back.png',
          fileSizeBytes: 2048,
          mimeType: 'image/png',
          status: 'VERIFIED',
          createdAt: '2026-11-01T10:00:00Z',
        ),
        ProDocumentModel(
          id: 'doc-3',
          docType: 'CRIMINAL_RECORD_CERT',
          fileName: 'fesh.png',
          fileSizeBytes: 3072,
          mimeType: 'image/png',
          status: 'VERIFIED',
          createdAt: '2026-11-01T10:00:00Z',
        ),
      ],
    );
  }

  @override
  Future<bool> updateAvailability(bool online) async {
    isOnline = online;
    return isOnline;
  }

  @override
  Future<ProDashboardModel> getDashboard() async {
    return ProDashboardModel(
      isOnline: isOnline,
      todayEarningsEgp: 780,
      weekEarningsEgp: 4250,
      completedJobsCount: 14,
      ratingAvg: 4.9,
      reviewsCount: reviewsCount,
      dailyTrajectory: const [
        ProDashboardDailyEarningsModel(
          dayKey: 'SAT',
          dayLabelEn: 'Sat',
          dayLabelAr: 'سبت',
          netEgp: 650,
        ),
        ProDashboardDailyEarningsModel(
          dayKey: 'SUN',
          dayLabelEn: 'Sun',
          dayLabelAr: 'أحد',
          netEgp: 720,
        ),
        ProDashboardDailyEarningsModel(
          dayKey: 'MON',
          dayLabelEn: 'Mon',
          dayLabelAr: 'إثنين',
          netEgp: 780,
        ),
        ProDashboardDailyEarningsModel(
          dayKey: 'TUE',
          dayLabelEn: 'Tue',
          dayLabelAr: 'ثلاثاء',
          netEgp: 0,
        ),
        ProDashboardDailyEarningsModel(
          dayKey: 'WED',
          dayLabelEn: 'Wed',
          dayLabelAr: 'أربعاء',
          netEgp: 0,
        ),
        ProDashboardDailyEarningsModel(
          dayKey: 'THU',
          dayLabelEn: 'Thu',
          dayLabelAr: 'خميس',
          netEgp: 0,
        ),
        ProDashboardDailyEarningsModel(
          dayKey: 'FRI',
          dayLabelEn: 'Fri',
          dayLabelAr: 'جمعة',
          netEgp: 0,
        ),
      ],
      activeOffers: const [
        JobOfferModel(
          id: 'offer-8899',
          bookingId: 'bk-8899',
          orderCode: 'FX-8899',
          status: 'OFFERED',
          expiresAt: '2026-11-02T12:00:00Z',
          remainingSeconds: 45,
          serviceTitleEn: 'AC Deep Wash',
          serviceTitleAr: 'تنظيف عميق للتكييف',
          categoryNameEn: 'Air Conditioning',
          categoryNameAr: 'تكييف وتبريد',
          customerName: 'Kareem Tarek',
          customerPhoneMasked: '010****8821',
          districtLine: 'New Cairo, Dist. 1',
          zoneNameEn: 'New Cairo',
          zoneNameAr: 'القاهرة الجديدة',
          scheduledDate: '2026-11-05',
          timeWindow: 'AFTERNOON_13_16',
          grossEgp: 400,
          platformFeeEgp: 60,
          netArtisanEgp: 340,
        ),
      ],
      todaySchedule: const [
        ProScheduledJobModel(
          bookingId: 'bk-7744',
          orderCode: 'FX-7744',
          status: 'ARRIVED',
          serviceTitleEn: 'Bathroom Plumbing Leak',
          serviceTitleAr: 'إصلاح تسريب سباكة الحمام',
          customerName: 'Nouran Mostafa',
          customerPhoneMasked: '012****9932',
          addressLine: 'Villa 22, Road 9',
          districtLine: 'Maadi Degla',
          zoneNameEn: 'Maadi',
          zoneNameAr: 'المعادي',
          timeWindow: 'MORNING_09_12',
          scheduledDate: '2026-11-02',
          totalEgp: 350,
          netArtisanEgp: 295,
          hasArrivalPin: true,
        ),
      ],
    );
  }

  @override
  Future<JobOfferModel> getJobOfferById(String offerId) async {
    getOfferCallCount++;
    final pending = nextOfferResponse;
    nextOfferResponse = null;
    if (pending != null) return pending;
    return JobOfferModel(
      id: 'offer-8899',
      bookingId: 'bk-8899',
      orderCode: 'FX-8899',
      status: 'OFFERED',
      expiresAt: '2026-11-02T12:00:00Z',
      remainingSeconds: offerRemainingSeconds,
      serviceTitleEn: 'AC Deep Wash',
      serviceTitleAr: 'تنظيف عميق للتكييف',
      categoryNameEn: 'Air Conditioning',
      categoryNameAr: 'تكييف وتبريد',
      customerName: 'Kareem Tarek',
      customerPhoneMasked: '010****8821',
      districtLine: 'New Cairo, Dist. 1',
      zoneNameEn: 'New Cairo',
      zoneNameAr: 'القاهرة الجديدة',
      scheduledDate: '2026-11-05',
      timeWindow: 'AFTERNOON_13_16',
      grossEgp: 400,
      platformFeeEgp: 60,
      netArtisanEgp: 340,
    );
  }

  @override
  Future<JobOfferModel> acceptJobOffer(String offerId) async {
    acceptCallCount++;
    return getJobOfferById(offerId);
  }

  @override
  Future<JobOfferModel> declineJobOffer(
    String offerId, {
    String? reason,
  }) async {
    declineCallCount++;
    lastDeclinedReason = reason;
    return getJobOfferById(offerId);
  }

  @override
  Future<BookingDetailModel> advanceBookingStatus(
    String bookingId, {
    required String toStatus,
    String? arrivalPinCode,
    String? note,
  }) async {
    lastAdvancedStatus = toStatus;
    lastArrivalPin = arrivalPinCode;
    return BookingDetailModel(
      id: bookingId,
      orderCode: 'FX-7744',
      customerId: 'cust-202',
      offeringId: 'off-ac',
      addressId: 'addr-202',
      status: toStatus,
      scheduledDate: '2026-11-02',
      timeWindow: 'MORNING_09_12',
      pricing: const BookingPricingModel(
        baseInspectionEgp: 150,
        serviceFeeEgp: 200,
        transportFeeEgp: 0,
        totalEgp: 350,
      ),
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

class _FakeLocaleNotifier extends AppLocaleNotifier {
  _FakeLocaleNotifier(this._initialLocale);
  final Locale _initialLocale;
  @override
  Locale build() => _initialLocale;
}

Widget buildTestableScreen({
  required Widget screen,
  required FakeProRepository fakeRepo,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1.0,
  Duration Function()? offerClock,
}) {
  return ProviderScope(
    overrides: [
      proRepositoryProvider.overrideWithValue(fakeRepo),
      if (offerClock != null)
        jobOfferClockProvider.overrideWithValue(offerClock),
      appLocaleProvider.overrideWith(() => _FakeLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: FixoTheme.light(locale: locale),
      darkTheme: FixoTheme.dark(locale: locale),
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: screen,
      ),
    ),
  );
}

void main() {
  late FakeProRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeProRepository();
  });

  group('Professional Flow Screens (11–16) Verification', () {
    testWidgets(
      'Screen 11: ProSignUpPage renders form inputs and validates 14-digit National ID',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const ProSignUpPage(),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('FIXO Pro Onboarding'), findsOneWidget);
        expect(find.text('Step 1 of 4'), findsOneWidget);
        expect(find.text('National ID (14 digits)'), findsOneWidget);
        expect(find.text('Primary Coverage Zone'), findsNothing);
        expect(find.text('Motorcycle'), findsNothing);
        expect(find.byType(TextFormField), findsNWidgets(2));

        // Tap submit and verify 14-digit validation
        final submitBtn = find.text('Continue to Skills & Coverage');
        expect(submitBtn, findsOneWidget);
      },
    );

    testWidgets(
      'Screen 12: ProSkillsPage renders trade category chips and rate card switch',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const ProSkillsPage(),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Trade Skills & Coverage'), findsOneWidget);
        expect(find.text('Step 2 of 4'), findsOneWidget);
        expect(find.text('Primary Trade Specialty'), findsOneWidget);
        expect(find.text('Plumbing & Sanitary'), findsOneWidget);
        expect(find.text('Accept FIXO Standard Rate Card'), findsOneWidget);
        expect(find.text('Continue to Document Upload'), findsOneWidget);
      },
    );

    testWidgets(
      'Screen 13: ProVerificationDocsPage lists 3 required document cards and upload buttons',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const ProVerificationDocsPage(),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ID & Licenses Verification'), findsOneWidget);
        expect(find.text('Step 3 of 4'), findsOneWidget);
        expect(find.text('National ID (Front Face)'), findsOneWidget);
        expect(find.text('National ID (Back Face)'), findsOneWidget);
        expect(find.text('Criminal Record Certificate (Fesh)'), findsOneWidget);
        expect(
          find.text('Trade License or Syndicate Card (Optional)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Screen 14: ProVerificationStatusPage displays APPROVED badge and 4 milestones in Arabic RTL',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const ProVerificationStatusPage(),
            fakeRepo: fakeRepo,
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('حالة اعتماد الفني'), findsOneWidget);
        expect(find.text('معتمد ومفعل'), findsOneWidget);
        expect(find.text('مراحل التحقق والاعتماد'), findsOneWidget);
        expect(find.text('الانتقال إلى لوحة الفني'), findsOneWidget);
      },
    );

    testWidgets(
      'Screen 15: ProDashboardPage displays net earnings, weekly trajectory, and arrival PIN verification',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const ProDashboardPage(),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('FIXO Pro Dashboard'), findsOneWidget);
        expect(find.text("Today's Net Earnings"), findsOneWidget);
        expect(find.text('780'), findsAtLeast(1));
        expect(find.text('Weekly Total'), findsOneWidget);
        expect(find.text('4250 EGP'), findsOneWidget);
        expect(find.text('7-Day Net Trajectory'), findsOneWidget);
        expect(find.text("Today's Schedule"), findsOneWidget);

        // Verify arrival PIN action
        expect(find.text('Enter Arrival PIN'), findsOneWidget);
      },
    );

    testWidgets(
      'Screen 16: IncomingJobPage displays countdown, customer summary, gross/net breakdown, and accept button',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const IncomingJobPage(jobOfferId: 'offer-8899'),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Incoming Job Request'), findsOneWidget);
        expect(find.text('#FX-8899'), findsOneWidget);
        expect(find.text('AC Deep Wash'), findsOneWidget);
        expect(find.text('Artisan Earnings Breakdown'), findsOneWidget);
        expect(find.text('400 EGP'), findsOneWidget); // Gross
        expect(find.text('- 60 EGP'), findsOneWidget); // 15% platform fee
        expect(find.text('340 EGP'), findsOneWidget); // Net guaranteed
        expect(find.textContaining('15%'), findsNothing);
        expect(find.textContaining('AFTERNOON_13_16'), findsNothing);

        // Tap Accept
        final acceptBtn = find.text('Accept Job Offer');
        expect(acceptBtn, findsOneWidget);
        await tester.tap(acceptBtn);
        await tester.pump();
        expect(fakeRepo.acceptCallCount, equals(1));

        // Clean teardown so timer doesn't linger
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'incoming offer revalidates after resume before allowing acceptance',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const IncomingJobPage(jobOfferId: 'offer-8899'),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(fakeRepo.getOfferCallCount, 1);
        final pending = Completer<JobOfferModel>();
        fakeRepo.nextOfferResponse = pending.future;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(fakeRepo.getOfferCallCount, 2);
        expect(find.text('Accept Job Offer'), findsNothing);
        final expiredRepo = FakeProRepository()..offerRemainingSeconds = 0;
        pending.complete(await expiredRepo.getJobOfferById('offer-8899'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final accept = find.byKey(const Key('pro-offer-accept'));
        expect(accept, findsOneWidget);
        expect(tester.widget<FilledButton>(accept).onPressed, isNull);
        expect(fakeRepo.acceptCallCount, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets('a delayed timer cannot let an expired offer accept on tap', (
      tester,
    ) async {
      var elapsed = Duration.zero;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        buildTestableScreen(
          screen: const IncomingJobPage(jobOfferId: 'offer-8899'),
          fakeRepo: fakeRepo,
          offerClock: () => elapsed,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final accept = find.text('Accept Job Offer');
      await tester.ensureVisible(accept);
      await tester.pump();
      elapsed = const Duration(seconds: 46);
      await tester.tap(accept);
      await tester.pump();
      expect(fakeRepo.acceptCallCount, 0);
      expect(find.text('Offer has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets(
      'a failed resume refresh hides old offer actions and provides retry',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const IncomingJobPage(jobOfferId: 'offer-8899'),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final pending = Completer<JobOfferModel>();
        fakeRepo.nextOfferResponse = pending.future;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        pending.completeError(StateError('Fixture connection failure'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Accept Job Offer'), findsNothing);
        expect(find.text('Retry'), findsOneWidget);
        fakeRepo.offerRemainingSeconds = 0;
        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(fakeRepo.getOfferCallCount, 3);
        expect(find.text('Offer has expired'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      'an older offer read cannot replace the latest resume response',
      (tester) async {
        final old = Completer<JobOfferModel>();
        fakeRepo.nextOfferResponse = old.future;
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          buildTestableScreen(
            screen: const IncomingJobPage(jobOfferId: 'offer-8899'),
            fakeRepo: fakeRepo,
          ),
        );
        await tester.pump();
        final fresh = Completer<JobOfferModel>();
        fakeRepo.nextOfferResponse = fresh.future;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        fresh.complete(
          await (FakeProRepository()..offerRemainingSeconds = 0)
              .getJobOfferById('offer-8899'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        old.complete(await FakeProRepository().getJobOfferById('offer-8899'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Offer has expired'), findsOneWidget);
        expect(fakeRepo.getOfferCallCount, 2);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('pro-offer-accept')))
              .onPressed,
          isNull,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
    for (final width in [360.0, 390.0, 412.0]) {
      for (final locale in [const Locale('en'), const Locale('ar')]) {
        for (final dark in [false, true]) {
          testWidgets(
            'incoming offer fits $width ${locale.languageCode} dark=$dark at 1.35x',
            (tester) async {
              await tester.binding.setSurfaceSize(Size(width, 844));
              await tester.pumpWidget(
                buildTestableScreen(
                  screen: const IncomingJobPage(jobOfferId: 'offer-8899'),
                  fakeRepo: fakeRepo,
                  locale: locale,
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  textScale: 1.35,
                ),
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 100));
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
            },
          );
        }
      }
    }
    testWidgets(
      'Responsive Matrix: Screen 15 ProDashboard renders across 360dp, 390dp, 412dp viewports with 1.35x text scale in Arabic and Dark Theme',
      (tester) async {
        fakeRepo.reviewsCount = 0;
        final viewports = [
          const Size(360, 640),
          const Size(390, 844),
          const Size(412, 915),
        ];

        for (final size in viewports) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            buildTestableScreen(
              screen: const ProDashboardPage(),
              fakeRepo: fakeRepo,
              locale: const Locale('ar'),
              themeMode: ThemeMode.dark,
              textScale: 1.35,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('لوحة الفني'), findsOneWidget);
          expect(find.text('صافي أرباح اليوم'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
