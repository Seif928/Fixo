import 'dart:math' as math;

import 'package:fixo_mobile/core/theme/fixo_colors.dart';
import 'package:fixo_mobile/core/theme/fixo_theme.dart';
import 'package:fixo_mobile/core/theme/fixo_workspace_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _channelLuminance(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  return 0.2126 * _channelLuminance(color.r) +
      0.7152 * _channelLuminance(color.g) +
      0.0722 * _channelLuminance(color.b);
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectPaletteContrast(FixoPaletteExtension palette, String label) {
  expect(
    _contrastRatio(palette.inkText, palette.canvasBackground),
    greaterThanOrEqualTo(4.5),
    reason: '$label: inkText on canvasBackground',
  );
  expect(
    _contrastRatio(palette.inkText, palette.cardSurface),
    greaterThanOrEqualTo(4.5),
    reason: '$label: inkText on cardSurface',
  );
  expect(
    _contrastRatio(palette.inkText, palette.surfaceLow),
    greaterThanOrEqualTo(4.5),
    reason: '$label: inkText on surfaceLow',
  );
  expect(
    _contrastRatio(palette.mutedText, palette.canvasBackground),
    greaterThanOrEqualTo(4.5),
    reason: '$label: mutedText on canvasBackground',
  );
  expect(
    _contrastRatio(palette.mutedText, palette.cardSurface),
    greaterThanOrEqualTo(4.5),
    reason: '$label: mutedText on cardSurface',
  );
  expect(
    _contrastRatio(palette.mutedText, palette.surfaceLow),
    greaterThanOrEqualTo(4.5),
    reason: '$label: mutedText on surfaceLow',
  );
  expect(
    _contrastRatio(palette.onPrimary, palette.primaryBrand),
    greaterThanOrEqualTo(4.5),
    reason: '$label: onPrimary on primaryBrand',
  );
  expect(
    _contrastRatio(palette.primaryBrand, palette.cardSurface),
    greaterThanOrEqualTo(4.5),
    reason: '$label: primaryBrand on cardSurface',
  );
  expect(
    _contrastRatio(palette.primaryBrand, palette.canvasBackground),
    greaterThanOrEqualTo(4.5),
    reason: '$label: primaryBrand on canvasBackground',
  );
  expect(
    _contrastRatio(palette.onPrimaryContainer, palette.primaryContainer),
    greaterThanOrEqualTo(4.5),
    reason: '$label: onPrimaryContainer on primaryContainer',
  );
  expect(
    _contrastRatio(palette.success, palette.cardSurface),
    greaterThanOrEqualTo(4.5),
    reason: '$label: success on cardSurface',
  );
  expect(
    _contrastRatio(palette.onSuccessContainer, palette.successContainer),
    greaterThanOrEqualTo(4.5),
    reason: '$label: onSuccessContainer on successContainer',
  );
  expect(
    _contrastRatio(palette.onWarningContainer, palette.warningContainer),
    greaterThanOrEqualTo(4.5),
    reason: '$label: onWarningContainer on warningContainer',
  );
  expect(
    _contrastRatio(palette.error, palette.cardSurface),
    greaterThanOrEqualTo(4.5),
    reason: '$label: error on cardSurface',
  );
  expect(
    _contrastRatio(palette.onErrorContainer, palette.errorContainer),
    greaterThanOrEqualTo(4.5),
    reason: '$label: onErrorContainer on errorContainer',
  );
}

void main() {
  group('FixoTheme & FixoPaletteExtension Light/Dark WCAG contrast', () {
    for (final brightness in Brightness.values) {
      test('base FixoTheme (${brightness.name}) meets WCAG AA contrast', () {
        final theme = brightness == Brightness.dark
            ? FixoTheme.dark()
            : FixoTheme.light();
        final scheme = theme.colorScheme;
        final palette = theme.extension<FixoPaletteExtension>()!;
        final tag = 'FixoTheme(${brightness.name})';

        expect(
          _contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: ColorScheme onPrimary on primary',
        );
        expect(
          _contrastRatio(scheme.onSecondary, scheme.secondary),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: ColorScheme onSecondary on secondary',
        );
        expect(
          _contrastRatio(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: ColorScheme onPrimaryContainer on primaryContainer',
        );
        expect(
          _contrastRatio(scheme.onErrorContainer, scheme.errorContainer),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: ColorScheme onErrorContainer on errorContainer',
        );
        expect(
          _contrastRatio(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: ColorScheme onSurface on surface',
        );
        expect(
          _contrastRatio(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: ColorScheme onSurfaceVariant on surface',
        );

        final elevatedBg =
            (theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}))!;
        final elevatedFg =
            (theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}))!;
        expect(
          _contrastRatio(elevatedFg, elevatedBg),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: ElevatedButton fg/bg contrast',
        );

        final filledBg =
            (theme.filledButtonTheme.style?.backgroundColor?.resolve({}))!;
        final filledFg =
            (theme.filledButtonTheme.style?.foregroundColor?.resolve({}))!;
        expect(
          _contrastRatio(filledFg, filledBg),
          greaterThanOrEqualTo(4.5),
          reason: '$tag: FilledButton fg/bg contrast',
        );

        if (brightness == Brightness.dark) {
          expect(
            _contrastRatio(palette.primaryBrand, palette.canvasBackground),
            greaterThanOrEqualTo(4.5),
            reason: '$tag: dark primaryBrand clearly visible on dark canvas',
          );
          expect(
            _contrastRatio(palette.onPrimary, palette.primaryBrand),
            greaterThanOrEqualTo(4.5),
            reason: '$tag: dark onPrimary readable on dark primaryBrand',
          );
          _expectPaletteContrast(palette, tag);
        } else {
          // Base FixoPaletteExtension.light uses slate navy primaryForest (#1E293B).
          expect(
            _contrastRatio(palette.inkText, palette.canvasBackground),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(palette.mutedText, palette.cardSurface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(palette.onPrimary, palette.primaryBrand),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(
              palette.onSuccessContainer,
              palette.successContainer,
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(palette.onErrorContainer, palette.errorContainer),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    }

    for (final workspace in FixoWorkspace.values) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'FixoWorkspaceTheme(${workspace.name}, ${brightness.name}) meets WCAG AA contrast across all tokens and buttons',
          (tester) async {
            late ThemeData resolvedTheme;
            late FixoPaletteExtension resolvedPalette;

            await tester.pumpWidget(
              MaterialApp(
                theme: FixoTheme.light(),
                darkTheme: FixoTheme.dark(),
                themeMode: brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
                home: FixoWorkspaceTheme(
                  workspace: workspace,
                  child: Builder(
                    builder: (context) {
                      resolvedTheme = Theme.of(context);
                      resolvedPalette = context.fixoPalette;
                      return const Scaffold(body: SizedBox.shrink());
                    },
                  ),
                ),
              ),
            );

            final label = 'Workspace(${workspace.name}, ${brightness.name})';
            _expectPaletteContrast(resolvedPalette, label);

            final scheme = resolvedTheme.colorScheme;
            expect(
              _contrastRatio(scheme.onPrimary, scheme.primary),
              greaterThanOrEqualTo(4.5),
              reason: '$label: ColorScheme onPrimary on primary',
            );
            expect(
              _contrastRatio(
                scheme.onErrorContainer,
                scheme.errorContainer,
              ),
              greaterThanOrEqualTo(4.5),
              reason: '$label: ColorScheme onErrorContainer on errorContainer',
            );

            final elevatedBg = (resolvedTheme
                .elevatedButtonTheme
                .style
                ?.backgroundColor
                ?.resolve({}))!;
            final elevatedFg = (resolvedTheme
                .elevatedButtonTheme
                .style
                ?.foregroundColor
                ?.resolve({}))!;
            expect(
              _contrastRatio(elevatedFg, elevatedBg),
              greaterThanOrEqualTo(4.5),
              reason: '$label: ElevatedButton fg/bg',
            );

            final filledBg = (resolvedTheme
                .filledButtonTheme
                .style
                ?.backgroundColor
                ?.resolve({}))!;
            final filledFg = (resolvedTheme
                .filledButtonTheme
                .style
                ?.foregroundColor
                ?.resolve({}))!;
            expect(
              _contrastRatio(filledFg, filledBg),
              greaterThanOrEqualTo(4.5),
              reason: '$label: FilledButton fg/bg',
            );
          },
        );
      }
    }
  });
}
