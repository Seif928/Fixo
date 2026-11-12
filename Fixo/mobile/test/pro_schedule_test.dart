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
import 'package:fixo_mobile/features/pro/data/pro_schedule_repository.dart';
import 'package:fixo_mobile/features/pro/domain/pro_schedule_models.dart';
import 'package:fixo_mobile/features/pro/presentation/pages/pro_schedule_page.dart';

class _FakeLocaleNotifier extends AppLocaleNotifier {
  _FakeLocaleNotifier(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

class _FakeProScheduleRepository implements ProScheduleRepository {
  _FakeProScheduleRepository({
    ProScheduleData? initialData,
    this.createLeaveConflict = false,
  }) : currentData = initialData ??
            ProScheduleData(
              weeklySchedule: [
                const ProDaySchedule(
                  dayOfWeek: ProDayOfWeek.sunday,
                  startMinute: 540,
                  endMinute: 1080,
                  isActive: true,
                ),
                const ProDaySchedule(
                  dayOfWeek: ProDayOfWeek.monday,
                  startMinute: 540,
                  endMinute: 1080,
                  isActive: true,
                ),
                const ProDaySchedule(
                  dayOfWeek: ProDayOfWeek.tuesday,
                  startMinute: 540,
                  endMinute: 1080,
                  isActive: true,
                ),
                const ProDaySchedule(
                  dayOfWeek: ProDayOfWeek.wednesday,
                  startMinute: 540,
                  endMinute: 1080,
                  isActive: true,
                ),
                const ProDaySchedule(
                  dayOfWeek: ProDayOfWeek.thursday,
                  startMinute: 540,
                  endMinute: 1080,
                  isActive: true,
                ),
                const ProDaySchedule(
                  dayOfWeek: ProDayOfWeek.friday,
                  startMinute: 540,
                  endMinute: 1080,
                  isActive: false,
                ),
                const ProDaySchedule(
                  dayOfWeek: ProDayOfWeek.saturday,
                  startMinute: 540,
                  endMinute: 1080,
                  isActive: true,
                ),
              ],
              leaves: [],
            );

  ProScheduleData currentData;
  final bool createLeaveConflict;
  bool updateScheduleCalled = false;
  bool createLeaveCalled = false;
  bool cancelLeaveCalled = false;

  @override
  Future<ProScheduleData> getSchedule() async {
    return currentData;
  }

  @override
  Future<ProScheduleData> updateSchedule(List<ProDaySchedule> days) async {
    updateScheduleCalled = true;
    currentData = ProScheduleData(weeklySchedule: days, leaves: currentData.leaves);
    return currentData;
  }

  @override
  Future<ProLeaveItem> createLeave({
    required DateTime startDate,
    required DateTime endDate,
    required ProLeaveReason reason,
    String? notes,
  }) async {
    createLeaveCalled = true;
    if (createLeaveConflict) {
      throw const ProScheduleException(
        'Cannot schedule leave: active bookings are assigned during this time.',
        code: 'BOOKING_CONFLICT',
        conflictingBookingsCount: 2,
      );
    }
    final item = ProLeaveItem(
      id: 'leave-123',
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: ProLeaveStatus.approved,
      notes: notes,
    );
    currentData = ProScheduleData(
      weeklySchedule: currentData.weeklySchedule,
      leaves: [item, ...currentData.leaves],
    );
    return item;
  }

  @override
  Future<void> cancelLeave(String leaveId) async {
    cancelLeaveCalled = true;
    currentData = ProScheduleData(
      weeklySchedule: currentData.weeklySchedule,
      leaves: currentData.leaves.where((l) => l.id != leaveId).toList(),
    );
  }
}

void main() {
  Widget createTestWidget({
    required ProScheduleRepository repo,
    Locale locale = const Locale('ar'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.proSchedule,
      routes: [
        GoRoute(
          path: AppRoutes.proSchedule,
          builder: (context, state) => const ProSchedulePage(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        proScheduleRepositoryProvider.overrideWithValue(repo),
        appLocaleProvider.overrideWith(() => _FakeLocaleNotifier(locale)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
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
      ),
    );
  }

  group('Milestone 2: Professional Schedule & Leaves Tests', () {
    testWidgets('loads and renders 7 days working hours with toggles', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeProScheduleRepository();
      await tester.pumpWidget(createTestWidget(repo: fakeRepo, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('المواعيد والإجازات'), findsOneWidget);
      expect(find.text('ساعات العمل'), findsOneWidget);
      expect(find.text('الإجازات والعطلات'), findsOneWidget);

      // Verify Friday is marked as Day Off ('عطلة أسبوعية')
      expect(find.text('الجمعة'), findsOneWidget);
      expect(find.text('عطلة أسبوعية'), findsOneWidget);

      // Verify Sunday is active and displays time range
      expect(find.text('الأحد'), findsOneWidget);
      expect(find.textContaining('09:00 ص'), findsWidgets);
    });

    testWidgets('toggles day off to active and saves schedule', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeProScheduleRepository();
      await tester.pumpWidget(createTestWidget(repo: fakeRepo, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Day off'), findsOneWidget);

      // Scroll to Friday switch
      final switches = find.byType(Switch);
      await tester.ensureVisible(switches.at(5));
      await tester.pumpAndSettle();

      await tester.tap(switches.at(5));
      await tester.pumpAndSettle();

      // Now Friday should show working hours
      expect(find.text('Day off'), findsNothing);

      // Ensure Save Changes is visible and tap it
      final saveButton = find.text('Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.updateScheduleCalled, isTrue);
      expect(find.text('Working schedule saved successfully'), findsOneWidget);
    });

    testWidgets('displays empty leaves state and switches between tabs', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeProScheduleRepository();
      await tester.pumpWidget(createTestWidget(repo: fakeRepo, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Tap Leaves Tab via Tab index 1
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      expect(find.text('سجل الإجازات'), findsOneWidget);
      expect(find.text('لا توجد إجازات مسجلة حاليًا'), findsOneWidget);
      expect(find.text('طلب إجازة'), findsOneWidget);
    });

    testWidgets('submits new leave successfully and displays it in list', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeProScheduleRepository();
      await tester.pumpWidget(createTestWidget(repo: fakeRepo, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      // Tap Request Leave
      await tester.tap(find.text('طلب إجازة'));
      await tester.pumpAndSettle();

      expect(find.text('طلب فترة إجازة جديدة'), findsOneWidget);

      final confirmBtn = find.text('تأكيد طلب الإجازة');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.createLeaveCalled, isTrue);
      expect(find.text('تم تسجيل طلب الإجازة بنجاح'), findsOneWidget);
      expect(find.text('إجازة سنوية'), findsOneWidget);
    });

    testWidgets('shows conflict dialog when booking conflict exists', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeProScheduleRepository(createLeaveConflict: true);
      await tester.pumpWidget(createTestWidget(repo: fakeRepo, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('طلب إجازة'));
      await tester.pumpAndSettle();

      final confirmBtn = find.text('تأكيد طلب الإجازة');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('تعارض مع حجوزات نشطة'), findsOneWidget);
      expect(
        find.textContaining('لا يمكن تسجيل إجازة في هذا التاريخ لوجود حجوزات مؤكدة'),
        findsOneWidget,
      );

      // Dismiss dialog
      await tester.tap(find.text('فهمت'));
      await tester.pumpAndSettle();
      expect(find.text('تعارض مع حجوزات نشطة'), findsNothing);
    });

    testWidgets('cancels leave with confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final existingLeave = ProLeaveItem(
        id: 'leave-existing',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
        reason: ProLeaveReason.sick,
        status: ProLeaveStatus.approved,
        notes: 'Rest after medical checkup',
      );
      final fakeRepo = _FakeProScheduleRepository(
        initialData: ProScheduleData(
          weeklySchedule: [
            const ProDaySchedule(
              dayOfWeek: ProDayOfWeek.sunday,
              startMinute: 540,
              endMinute: 1080,
              isActive: true,
            ),
          ],
          leaves: [existingLeave],
        ),
      );

      await tester.pumpWidget(createTestWidget(repo: fakeRepo, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      expect(find.text('إجازة مرضية'), findsOneWidget);
      expect(find.text('Rest after medical checkup'), findsOneWidget);

      // Tap cancel icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('إلغاء الإجازة'), findsOneWidget);
      expect(find.text('تأكيد الإلغاء'), findsOneWidget);

      await tester.tap(find.text('تأكيد الإلغاء'));
      await tester.pumpAndSettle();

      expect(fakeRepo.cancelLeaveCalled, isTrue);
      expect(find.text('تم إلغاء الإجازة بنجاح'), findsOneWidget);
      expect(find.text('إجازة مرضية'), findsNothing);
    });

    testWidgets('responsive layout on 360/390/412dp with 1.35x font scale and dark theme', (tester) async {
      final fakeRepo = _FakeProScheduleRepository();

      for (final width in [360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: const TextScaler.linear(1.35),
            ),
            child: createTestWidget(
              repo: fakeRepo,
              locale: const Locale('ar'),
              themeMode: ThemeMode.dark,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('المواعيد والإجازات'), findsOneWidget);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
