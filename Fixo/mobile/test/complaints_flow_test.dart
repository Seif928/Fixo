import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/booking/data/booking_repository.dart';
import 'package:fixo_mobile/features/booking/domain/booking_models.dart';
import 'package:fixo_mobile/features/booking/presentation/pages/orders_page.dart';
import 'package:fixo_mobile/features/complaints/data/complaints_models.dart';
import 'package:fixo_mobile/features/complaints/data/complaints_repository.dart';
import 'package:fixo_mobile/features/complaints/presentation/pages/complaint_submission_dialog.dart';
import 'package:fixo_mobile/features/complaints/presentation/pages/my_complaints_page.dart';

class _FakeLocaleNotifier extends AppLocaleNotifier {
  _FakeLocaleNotifier(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

class _FakeComplaintsRepository implements ComplaintsRepository {
  _FakeComplaintsRepository({
    this.complaints = const [],
  });

  final List<ComplaintItemModel> complaints;
  final List<Map<String, dynamic>> createdCalls = [];

  @override
  Future<ComplaintItemModel> createComplaint({
    required String bookingId,
    required ComplaintCategory category,
    required String description,
    List<String>? photoUrls,
  }) async {
    createdCalls.add({
      'bookingId': bookingId,
      'category': category,
      'description': description,
      'photoUrls': photoUrls,
    });
    return ComplaintItemModel(
      id: 'cmp-new-1',
      bookingId: bookingId,
      customerId: 'user-1',
      category: category,
      description: description,
      photoUrls: photoUrls ?? const [],
      status: ComplaintStatus.open,
      createdAt: DateTime.now(),
      orderCode: 'FX-CMP-1',
    );
  }

  @override
  Future<List<ComplaintItemModel>> listMyComplaints({
    int page = 1,
    int limit = 20,
    ComplaintStatus? status,
  }) async {
    return complaints;
  }

  @override
  Future<ComplaintItemModel> getComplaintDetails(String id) async {
    return complaints.firstWhere((c) => c.id == id);
  }
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository(this.bookings);
  final List<BookingDetailModel> bookings;

  @override
  Future<List<BookingDetailModel>> getBookings({
    String? tab,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    return bookings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithApp({
  required Widget child,
  required List<Override> overrides,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  Size surfaceSize = const Size(390, 844),
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith(() => _FakeLocaleNotifier(locale)),
      ...overrides,
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
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  group('Milestone 1: Complaints Submission Dialog', () {
    testWidgets('shows categories, validates minimum length, and submits successfully', (tester) async {
      final fakeRepo = _FakeComplaintsRepository();

      await tester.pumpWidget(
        _wrapWithApp(
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ComplaintSubmissionDialog.show(
                  ctx,
                  bookingId: 'book-123',
                  orderCode: 'FX-ORD1',
                  serviceTitle: 'Plumbing Repair',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          overrides: [
            complaintsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('File a Complaint'), findsOneWidget);
      expect(find.textContaining('FX-ORD1'), findsOneWidget);

      // Tap submit with empty description -> shows error
      await tester.tap(find.byKey(const Key('complaint-submit-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('at least 10 characters'), findsOneWidget);

      // Select Overcharging category chip
      await tester.tap(find.byKey(const Key('complaint-category-OVERCHARGING')));
      await tester.pumpAndSettle();

      // Enter valid description
      await tester.enterText(
        find.byKey(const Key('complaint-description-field')),
        'Technician asked for extra cash beyond invoice amount.',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('complaint-submit-button')));
      await tester.pumpAndSettle();

      expect(fakeRepo.createdCalls.length, 1);
      expect(fakeRepo.createdCalls.first['bookingId'], 'book-123');
      expect(fakeRepo.createdCalls.first['category'], ComplaintCategory.overcharging);
      expect(
        fakeRepo.createdCalls.first['description'],
        'Technician asked for extra cash beyond invoice amount.',
      );
    });
  });

  group('Milestone 1: My Complaints Page', () {
    testWidgets('displays empty state when no complaints exist', (tester) async {
      final fakeRepo = _FakeComplaintsRepository(complaints: []);

      await tester.pumpWidget(
        _wrapWithApp(
          child: const MyComplaintsPage(),
          overrides: [
            complaintsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Complaints'), findsOneWidget);
    });

    testWidgets('displays complaints list with status badges and resolution notes', (tester) async {
      final complaints = [
        ComplaintItemModel(
          id: 'cmp-1',
          bookingId: 'book-1',
          customerId: 'user-1',
          category: ComplaintCategory.serviceQuality,
          description: 'The pipe leak returned after technician departed.',
          status: ComplaintStatus.resolved,
          adminNotes: 'Warranty dispatched second technician free of charge.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          orderCode: 'FX-101',
          serviceTitleEn: 'Pipe Leak Repair',
          serviceTitleAr: 'إصلاح تسريب المواسير',
        ),
      ];

      final fakeRepo = _FakeComplaintsRepository(complaints: complaints);

      await tester.pumpWidget(
        _wrapWithApp(
          child: const MyComplaintsPage(),
          overrides: [
            complaintsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service Quality'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.textContaining('FX-101'), findsOneWidget);
      expect(find.text('The pipe leak returned after technician departed.'), findsOneWidget);
      expect(find.text('Warranty dispatched second technician free of charge.'), findsOneWidget);
      expect(find.text('Resolution Note'), findsOneWidget);
    });

    testWidgets('responsive layout at 360/390/412dp with 1.35x text, RTL, and dark theme', (tester) async {
      final complaints = [
        ComplaintItemModel(
          id: 'cmp-1',
          bookingId: 'book-1',
          customerId: 'user-1',
          category: ComplaintCategory.propertyDamage,
          description: 'خدش في حائط الصالون أثناء نقل المعدات.',
          status: ComplaintStatus.inReview,
          adminNotes: 'فريق الجودة يتواصل مع العميل لتحديد التعويض.',
          createdAt: DateTime.now(),
          orderCode: 'FX-999',
          serviceTitleEn: 'Furniture Move',
          serviceTitleAr: 'نقل أثاث',
        ),
      ];
      final fakeRepo = _FakeComplaintsRepository(complaints: complaints);

      for (final width in [360.0, 390.0, 412.0]) {
        await tester.pumpWidget(
          _wrapWithApp(
            surfaceSize: Size(width, 844),
            textScale: 1.35,
            locale: const Locale('ar'),
            themeMode: ThemeMode.dark,
            child: const MyComplaintsPage(),
            overrides: [
              complaintsRepositoryProvider.overrideWithValue(fakeRepo),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الشكاوى والبلاغات'), findsOneWidget);
        expect(find.text('تلفيات أو أضرار'), findsOneWidget);
        expect(find.text('قيد المراجعة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Milestone 1: Orders Page Report Issue Entry Point', () {
    testWidgets('orders page shows "Report issue" button on completed order', (tester) async {
      final completedBooking = BookingDetailModel(
        id: 'book-completed-1',
        orderCode: 'FX-COMP1',
        status: 'COMPLETED',
        customerId: 'user-1',
        offeringId: 'offering-1',
        addressId: 'addr-1',
        createdAt: '2026-04-01T10:00:00Z',
        offering: {
          'id': 'offering-1',
          'slug': 'ac-split-clean',
          'titleEn': 'AC Split Cleaning',
          'titleAr': 'تنظيف تكييف سبليت',
        },
        scheduledDate: '2026-04-10T10:00:00Z',
        timeWindow: 'MORNING_09_12',
        pricing: const BookingPricingModel(
          baseInspectionEgp: 150,
          serviceFeeEgp: 150,
          transportFeeEgp: 0,
          totalEgp: 300,
        ),
      );

      final fakeBookingRepo = _FakeBookingRepository([completedBooking]);
      final fakeComplaintsRepo = _FakeComplaintsRepository();

      final router = GoRouter(
        initialLocation: AppRoutes.myOrders,
        routes: [
          GoRoute(
            path: AppRoutes.myOrders,
            builder: (_, _) => const OrdersPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(fakeBookingRepo),
            complaintsRepositoryProvider.overrideWithValue(fakeComplaintsRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: FixoTheme.light(locale: const Locale('en')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap completed tab to reveal completed booking
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<String>),
          matching: find.text('Completed'),
        ),
      );
      await tester.pumpAndSettle();

      final complaintButton = find.byKey(const Key('booking-complaint-book-completed-1'));
      expect(complaintButton, findsOneWidget);

      // Tap "Report issue" -> opens submission sheet
      await tester.tap(complaintButton);
      await tester.pumpAndSettle();

      expect(find.text('File a Complaint'), findsOneWidget);
      expect(find.textContaining('FX-COMP1'), findsNWidgets(2));
    });
  });
}
