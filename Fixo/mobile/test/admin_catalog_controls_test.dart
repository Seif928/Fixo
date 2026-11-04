import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/features/admin/data/admin_repository.dart';
import 'package:fixo_mobile/features/admin/presentation/admin_catalog_panel.dart';
import 'package:fixo_mobile/features/auth/domain/auth_models.dart';
import 'package:fixo_mobile/features/auth/presentation/controllers/auth_controller.dart';

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        session: AuthSession(
          accessToken: 'fixture-token',
          refreshToken: 'fixture-refresh',
          user: AuthUser(
            id: 'admin-owner-id',
            phone: '+201012345678',
            fullName: 'Admin Owner',
            role: 'CUSTOMER',
          ),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Catalog Controls (UI & Interaction)', () {
    late int draftVersion;
    late bool isActive;
    late int? publishedVersion;
    late List<RequestOptions> capturedRequests;
    late List<Map<String, dynamic>> items;

    setUp(() {
      draftVersion = 2;
      isActive = true;
      publishedVersion = 2;
      capturedRequests = [];

      items = [
        {
          'id': 'draft-active-1',
          'slug': 'ac-deep-clean',
          'version': draftVersion,
          'publishedVersion': publishedVersion,
          'categorySlug': 'ac-maintenance',
          'categoryNameEn': 'AC Maintenance',
          'categoryNameAr': 'صيانة التكييف',
          'titleEn': 'AC Deep Clean',
          'titleAr': 'تنظيف عميق للتكييف',
          'descriptionEn': 'Full indoor split wash',
          'descriptionAr': 'غسيل داخلي شامل',
          'baseInspectionEgp': 150,
          'serviceFeeEgp': 250,
          'estimatedDurationMins': 60,
          'isActive': isActive,
        },
      ];
    });

    Dio buildMockDio({bool simulateConflict = false}) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequests.add(options);

            if (options.path == '/admin/catalog' && options.method == 'GET') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'items': items,
                    'categories': [
                      {
                        'categorySlug': 'ac-maintenance',
                        'categoryNameEn': 'AC Maintenance',
                        'categoryNameAr': 'صيانة التكييف',
                      },
                      {
                        'categorySlug': 'plumbing',
                        'categoryNameEn': 'Plumbing',
                        'categoryNameAr': 'سباكة',
                      },
                    ],
                    'meta': {
                      'page': 1,
                      'totalPages': 1,
                      'total': items.length,
                    },
                  },
                ),
              );
              return;
            }

            if (options.path == '/admin/catalog' && options.method == 'POST') {
              final body = options.data as Map<String, dynamic>;
              final newDraft = {
                'id': 'draft-custom-created',
                'slug': body['slug'] ?? 'custom-slug',
                'version': 1,
                'publishedVersion': null,
                'categorySlug': body['categorySlug'],
                'categoryNameEn': 'Plumbing',
                'categoryNameAr': 'سباكة',
                'titleEn': body['titleEn'],
                'titleAr': body['titleAr'],
                'descriptionEn': body['descriptionEn'],
                'descriptionAr': body['descriptionAr'],
                'baseInspectionEgp': body['baseInspectionEgp'],
                'serviceFeeEgp': body['serviceFeeEgp'],
                'estimatedDurationMins': body['estimatedDurationMins'],
                'isActive': true,
              };
              items.add(newDraft);
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: newDraft,
                ),
              );
              return;
            }

            if (options.path.endsWith('/deactivate')) {
              if (simulateConflict) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 409,
                      data: {'code': 'ADMIN_CATALOG_VERSION_CONFLICT'},
                    ),
                  ),
                );
                return;
              }
              isActive = false;
              draftVersion++;
              items[0]['isActive'] = false;
              items[0]['version'] = draftVersion;
              items[0]['publishedVersion'] = draftVersion;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: items[0],
                ),
              );
              return;
            }

            if (options.path.endsWith('/reactivate')) {
              if (simulateConflict) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 409,
                      data: {'code': 'ADMIN_CATALOG_VERSION_CONFLICT'},
                    ),
                  ),
                );
                return;
              }
              isActive = true;
              draftVersion++;
              items[0]['isActive'] = true;
              items[0]['version'] = draftVersion;
              items[0]['publishedVersion'] = draftVersion;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: items[0],
                ),
              );
              return;
            }

            handler.next(options);
          },
        ),
      );
      return dio;
    }

    Widget createTestWidget({
      required Dio dio,
      bool ar = false,
      bool dark = false,
      double width = 800,
    }) {
      return ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuthController()),
          adminRepositoryProvider.overrideWithValue(AdminRepository(dio)),
        ],
        child: MaterialApp(
          locale: Locale(ar ? 'ar' : 'en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: FixoTheme.light(locale: Locale(ar ? 'ar' : 'en')),
          darkTheme: FixoTheme.dark(locale: Locale(ar ? 'ar' : 'en')),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: width,
                child: AdminCatalogPanel(
                  ar: ar,
                  needsConfirmation: false,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('creates custom service draft with explicit bilingual inputs',
        (tester) async {
      final dio = buildMockDio();
      await tester.pumpWidget(createTestWidget(dio: dio, ar: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin-create-draft-btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('admin-create-draft-btn')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byKey(const Key('admin-create-draft-title-en')), findsOneWidget);
      expect(find.byKey(const Key('admin-create-draft-title-ar')), findsOneWidget);

      // Attempt submit without required fields
      await tester.tap(find.byKey(const Key('admin-create-draft-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid English title.'), findsOneWidget);

      // Fill in bilingual details
      await tester.enterText(
        find.byKey(const Key('admin-create-draft-title-en')),
        'Pipe Leak Sealing',
      );
      await tester.enterText(
        find.byKey(const Key('admin-create-draft-title-ar')),
        'عزل ولحام تسريبات المواسير',
      );
      await tester.enterText(
        find.byKey(const Key('admin-create-draft-desc-en')),
        'Thermal sealing and leak isolation',
      );
      await tester.enterText(
        find.byKey(const Key('admin-create-draft-desc-ar')),
        'عزل حراري وإصلاح تسريبات دقيق',
      );
      await tester.enterText(
        find.byKey(const Key('admin-create-draft-slug')),
        'pipe-leak-sealing',
      );

      // Submit
      await tester.tap(find.byKey(const Key('admin-create-draft-submit')));
      await tester.pumpAndSettle();

      // Verify POST request sent
      final postReq = capturedRequests.firstWhere(
        (r) => r.method == 'POST' && r.path == '/admin/catalog',
      );
      expect(postReq.data['titleEn'], 'Pipe Leak Sealing');
      expect(postReq.data['titleAr'], 'عزل ولحام تسريبات المواسير');
      expect(postReq.data['slug'], 'pipe-leak-sealing');
      expect(postReq.data['categorySlug'], 'ac-maintenance');

      // Verify snackbar feedback and catalog reload
      expect(find.text('Service draft created successfully.'), findsOneWidget);
    });

    testWidgets(
        'deactivates published service with confirmation dialog and updates chip',
        (tester) async {
      final dio = buildMockDio();
      await tester.pumpWidget(createTestWidget(dio: dio, ar: false));
      await tester.pumpAndSettle();

      // Active published service shows 'Published' chip and 'Deactivate' button
      expect(find.text('Published'), findsOneWidget);
      final deactBtn = find.byKey(const Key('admin-deactivate-draft-active-1'));
      expect(deactBtn, findsOneWidget);

      await tester.tap(deactBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog appears with safety explanation
      expect(find.text('Deactivate published service'), findsOneWidget);
      expect(find.byKey(const Key('admin-deactivate-confirm')), findsOneWidget);

      // Confirm deactivation
      await tester.tap(find.byKey(const Key('admin-deactivate-confirm')));
      await tester.pumpAndSettle();

      // Verify POST request sent to deactivate endpoint
      final deactReq = capturedRequests.firstWhere(
        (r) =>
            r.method == 'POST' &&
            r.path == '/admin/catalog/draft-active-1/deactivate',
      );
      expect(deactReq.data['version'], 2);

      // Verify success feedback and updated chip
      expect(find.text('Service deactivated successfully.'), findsOneWidget);
      expect(find.text('Deactivated'), findsOneWidget);
      expect(find.byKey(const Key('admin-reactivate-draft-active-1')), findsOneWidget);
    });

    testWidgets(
        'reactivates deactivated service with confirmation dialog and restores published state',
        (tester) async {
      items[0]['isActive'] = false;
      items[0]['version'] = 3;
      items[0]['publishedVersion'] = 3;

      final dio = buildMockDio();
      await tester.pumpWidget(createTestWidget(dio: dio, ar: false));
      await tester.pumpAndSettle();

      // Inactive service shows 'Deactivated' chip and 'Reactivate' button
      expect(find.text('Deactivated'), findsOneWidget);
      final reactBtn = find.byKey(const Key('admin-reactivate-draft-active-1'));
      expect(reactBtn, findsOneWidget);

      await tester.tap(reactBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Reactivate service'), findsOneWidget);
      expect(find.byKey(const Key('admin-reactivate-confirm')), findsOneWidget);

      // Confirm reactivation
      await tester.tap(find.byKey(const Key('admin-reactivate-confirm')));
      await tester.pumpAndSettle();

      // Verify POST request sent to reactivate endpoint
      final reactReq = capturedRequests.firstWhere(
        (r) =>
            r.method == 'POST' &&
            r.path == '/admin/catalog/draft-active-1/reactivate',
      );
      expect(reactReq.data['version'], 3);

      // Verify success feedback and restored published chip
      expect(find.text('Service reactivated successfully.'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
    });

    testWidgets(
        'responsive and bilingual: Arabic RTL, Dark theme at 360, 390, 412dp with 1.35x text scale',
        (tester) async {
      for (final width in [360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final dio = buildMockDio();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
            child: createTestWidget(
              dio: dio,
              ar: true,
              dark: true,
              width: width,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check Arabic texts render correctly without layout overflows
        expect(find.text('الخدمات والأسعار'), findsOneWidget);
        expect(find.text('إضافة خدمة مخصصة'), findsOneWidget);
        expect(find.text('تنظيف عميق للتكييف'), findsOneWidget);
        expect(find.text('منشور'), findsOneWidget);

        // Open create draft dialog on small screen
        await tester.tap(find.byKey(const Key('admin-create-draft-btn')));
        await tester.pumpAndSettle();

        expect(find.text('إضافة خدمة جديدة'), findsOneWidget);
        expect(find.byKey(const Key('admin-create-draft-cancel')), findsOneWidget);

        await tester.tap(find.byKey(const Key('admin-create-draft-cancel')));
        await tester.pumpAndSettle();
      }
    });
  });
}
