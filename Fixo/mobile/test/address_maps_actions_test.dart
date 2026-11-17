import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
// Directly mocking the launcher boundary keeps all tests offline.
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
import 'package:fixo_mobile/core/location/address_maps_actions.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';

class FakeMapsLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;
  final urls = <Uri>[];
  bool succeeds = true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(Uri.parse(url));
    return succeeds;
  }
}

void main() {
  late FakeMapsLauncher launcher;
  setUp(() {
    final original = UrlLauncherPlatform.instance;
    launcher = FakeMapsLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = original);
  });
  for (final ar in [false, true]) {
    testWidgets(
      'opens only the selected address after a user tap; Arabic=$ar',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: ar ? FixoTheme.dark() : FixoTheme.light(),
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
                child: Directionality(
                  textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                  child: AddressMapsActions(
                    address: '12 شارع النيل, Giza, Egypt',
                    isArabic: ar,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(launcher.urls, isEmpty);
        await tester.tap(find.byKey(const Key('open-address-google-maps')));
        await tester.pumpAndSettle();
        expect(
          launcher.urls.single.queryParameters['query'],
          '12 شارع النيل, Giza, Egypt',
        );
        launcher.succeeds = false;
        await tester.tap(find.byKey(const Key('address-google-directions')));
        await tester.pumpAndSettle();
        expect(
          launcher.urls.last.queryParameters['destination'],
          '12 شارع النيل, Giza, Egypt',
        );
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
