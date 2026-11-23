import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixo_mobile/features/admin/data/admin_repository.dart';
import 'package:fixo_mobile/features/admin/presentation/admin_profile_entry.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/theme/fixo_workspace_theme.dart';
import 'package:fixo_mobile/core/widgets/workspace_heading.dart';

void main() {
  test('routes select presentation only, with exact workspace boundaries', () {
    expect(FixoWorkspace.forPath('/customer/home'), FixoWorkspace.customer);
    expect(FixoWorkspace.forPath('/pro/schedule'), FixoWorkspace.professional);
    expect(
      FixoWorkspace.forPath('/admin/support'),
      FixoWorkspace.administrator,
    );
    expect(
      FixoWorkspace.forPath('/profile?role=OWNER'),
      FixoWorkspace.customer,
    );
    expect(FixoWorkspace.forPath('/professional-fake'), FixoWorkspace.customer);
  });
  for (final role in ['CUSTOMER', 'PRO', 'ADMIN', 'OWNER']) {
    testWidgets('account badge uses verified membership for $role', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminAccessProvider.overrideWith((ref) async {
              if (role == 'ADMIN' || role == 'OWNER') {
                return AdminAccess(role, false);
              }
              throw StateError('No administration access');
            }),
          ],
          child: MaterialApp(
            home: Scaffold(body: AccountRoleBadge(professional: role == 'PRO')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(switch (role) {
          'OWNER' => 'App Owner',
          'ADMIN' => 'Administrator · Admin',
          'PRO' => 'FIXO Professional',
          _ => 'FIXO Customer',
        }),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final role in FixoWorkspace.values) {
    for (final dark in [false, true]) {
      testWidgets('${role.name} is distinct, readable and responsive ($dark)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late Color accent;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? FixoTheme.dark() : FixoTheme.light(),
            home: FixoWorkspaceTheme(
              workspace: role,
              child: Builder(
                builder: (context) {
                  accent = Theme.of(context).colorScheme.primary;
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.35)),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Scaffold(
                        body: WorkspaceHeading(workspace: role, isArabic: true),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(role.label(true)), findsOneWidget);
        expect(find.byKey(ValueKey('workspace-${role.name}')), findsOneWidget);
        expect(tester.takeException(), isNull);
        final onAccent = dark ? const Color(0xFF0F172A) : Colors.white;
        final hi =
            accent.computeLuminance().compareTo(onAccent.computeLuminance()) > 0
            ? accent
            : onAccent;
        final lo = hi == accent ? onAccent : accent;
        expect(
          (hi.computeLuminance() + .05) / (lo.computeLuminance() + .05),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  }
}
