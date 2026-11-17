import 'package:fixo_mobile/app/app.dart';
import 'package:fixo_mobile/app/router/app_router.dart';
import 'package:fixo_mobile/app/router/app_routes.dart';
import 'package:fixo_mobile/core/l10n/app_locale_controller.dart';
import 'package:fixo_mobile/core/theme/fixo_colors.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FIXO Design System Tokens & Themes', () {
    test('FixoColors match approved cinematic DESIGN.md hex values', () {
      expect(FixoColors.deepestForest, const Color(0xFF17191C));
      expect(FixoColors.primaryForest, const Color(0xFF24262B));
      expect(FixoColors.secondaryForest, const Color(0xFF4E4942));
      expect(FixoColors.limeAccent, const Color(0xFFC6A779));
      expect(FixoColors.limeHighlight, const Color(0xFFD8BC90));
      expect(FixoColors.warmCream, const Color(0xFFF6F2EB));
      expect(FixoColors.surfaceBotanical, const Color(0xFFF6F2EB));
      expect(FixoColors.coral, const Color(0xFFFF795F));
    });

    test('Light and Dark themes attach FixoPaletteExtension', () {
      final lightTheme = FixoTheme.light(locale: const Locale('en'));
      final darkTheme = FixoTheme.dark(locale: const Locale('ar'));

      expect(
        lightTheme.extension<FixoPaletteExtension>()?.primaryBrand,
        FixoColors.primaryForest,
      );
      expect(
        darkTheme.extension<FixoPaletteExtension>()?.canvasBackground,
        FixoColors.darkBackground,
      );
    });
  });

  group('Screen 01: OnboardingPage UI & Navigation', () {
    testWidgets('pricing and cash explanations open without authentication', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: FixoApp()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('EGP Price Breakdown'));
      await tester.tap(find.text('EGP Price Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('How booking pricing works'), findsOneWidget);
      expect(
        find.textContaining('Inspection, service and transport'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash After Service'));
      await tester.pumpAndSettle();
      expect(find.text('Cash on service'), findsOneWidget);
      expect(
        find.textContaining('No payment is collected now'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('phone-password-number')), findsNothing);
    });
    testWidgets(
      'renders brand header, hero card, compliant trust chips, and CTAs',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: FixoApp()));
        await tester.pumpAndSettle();

        // Brand header
        expect(find.text('FIXO'), findsOneWidget);
        expect(find.text('Better Homes. Better Everyday.'), findsOneWidget);
        expect(find.text('All Egypt Governorates'), findsOneWidget);

        // Approved slate/amber welcome hero.
        expect(find.text('Home care, thoughtfully done.'), findsOneWidget);

        // Editorial copy & trust chips
        expect(find.text('THE STANDARD IN HOME CARE'), findsOneWidget);
        expect(find.text('Your home, in better hands.'), findsOneWidget);
        expect(find.text('Home Services'), findsOneWidget);
        expect(find.text('EGP Price Breakdown'), findsOneWidget);
        expect(find.text('Cash After Service'), findsOneWidget);
        expect(find.textContaining('142'), findsNothing);
        expect(find.textContaining('Arrival Tracking'), findsNothing);
        expect(find.textContaining('Identity-Reviewed'), findsNothing);

        // Verify unsupported insurance claim was replaced per STITCH_AUDIT.md
        expect(find.textContaining('Insured up to 25,000 EGP'), findsNothing);

        // CTAs
        expect(find.byKey(const Key('btn-get-started')), findsOneWidget);
        expect(find.byKey(const Key('btn-sign-in')), findsOneWidget);
      },
    );

    testWidgets(
      'navigates to /auth/phone (Screen 02 PhoneAuthPage) on Get Started and returns to Onboarding',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: FixoApp()));
        await tester.pumpAndSettle();

        final getStartedFinder = find.byKey(const Key('btn-get-started'));
        await tester.ensureVisible(getStartedFinder);
        await tester.tap(getStartedFinder);
        await tester.pumpAndSettle();

        expect(find.text('Sign in to FIXO'), findsOneWidget);
        expect(find.byKey(const Key('phone-password-number')), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn-back-to-onboarding')));
        await tester.pumpAndSettle();

        expect(find.text('Your home, in better hands.'), findsOneWidget);
      },
    );

    testWidgets(
      'navigates to /auth/phone with signin intent on secondary CTA tap',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: FixoApp()));
        await tester.pumpAndSettle();

        final signInFinder = find.byKey(const Key('btn-sign-in'));
        await tester.ensureVisible(signInFinder);
        await tester.tap(signInFinder);
        await tester.pumpAndSettle();

        expect(find.text('Sign in to FIXO'), findsOneWidget);
        expect(find.byKey(const Key('phone-password-secret')), findsOneWidget);
      },
    );

    testWidgets(
      'trust pillar chips open details dialogs/sheet and navigate to auth on Get Started',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: FixoApp()));
        await tester.pumpAndSettle();

        final pricingChip = find.text('EGP Price Breakdown');
        await tester.ensureVisible(pricingChip);
        await tester.tap(pricingChip);
        await tester.pumpAndSettle();

        expect(find.text('How booking pricing works'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        final servicesChip = find.text('Home Services');
        await tester.ensureVisible(servicesChip);
        await tester.tap(servicesChip);
        await tester.pumpAndSettle();

        expect(find.textContaining('21 trade categories'), findsOneWidget);
        await tester.tap(find.text('Get Started').last);
        await tester.pumpAndSettle();

        expect(find.text('Sign in to FIXO'), findsOneWidget);
      },
    );

    testWidgets(
      'root "/" path redirects cleanly to /onboarding for path URL strategy',
      (WidgetTester tester) async {
        final router = createAppRouter(
          initialLocation: '/',
          isAuthenticated: () => false,
        );
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: router)),
        );
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.onboarding,
        );
      },
    );
  });

  group('Responsive Viewports (360 / 390 / 412dp), Large Text & RTL', () {
    const viewports = <Size>[Size(360, 800), Size(390, 844), Size(412, 915)];

    for (final size in viewports) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}dp and 1.35x text scale',
        (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.35),
                ),
                child: const FixoApp(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Your home, in better hands.'), findsOneWidget);
        },
      );
    }

    testWidgets('supports Arabic RTL and Dark Mode without layout errors', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appLocaleProvider.notifier).setLocale(const Locale('ar'));
      container
          .read(appThemeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const FixoApp()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.text('FIXO'))),
        TextDirection.rtl,
      );
    });
  });
}
