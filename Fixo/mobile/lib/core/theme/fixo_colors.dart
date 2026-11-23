import 'package:material_ui/material_ui.dart';

/// Central color tokens for the FIXO design system.
///
/// Reconciles the Material 3 / Tailwind tokens from the 16 Stitch HTML screens
/// (`01_*` through `16_*`) with the narrative tokens from `DESIGN.md` and
/// `docs/STITCH_AUDIT.md`.
abstract final class FixoColors {
  // Shared slate / white / amber foundation (legacy API names retained)
  static const Color deepestForest = Color(0xFF0F172A); // Tailwind `primary`
  static const Color primaryForest = Color(
    0xFF1E293B,
  ); // Tailwind `primary-container` / Narrative Primary Forest
  static const Color secondaryForest = Color(
    0xFF475569,
  ); // Narrative Secondary Forest
  static const Color secondary = Color(0xFF64748B); // Tailwind `secondary`
  static const Color onPrimaryContainer = Color(0xFFE2E8F0);
  static const Color primaryFixed = Color(0xFFF1F5F9);
  static const Color primaryFixedDim = Color(0xFFCBD5E1);

  // Secondary Mint Tones
  static const Color secondaryContainer = Color(0xFFFFF7ED);
  static const Color onSecondaryContainer = Color(0xFF92400E);
  static const Color secondaryFixed = Color(0xFFFFF7ED);
  static const Color secondaryFixedDim = Color(0xFFFDE68A);

  // Lime Accents (Always pair with deepestForest / primaryForest text)
  static const Color limeAccent = Color(
    0xFFC6A779,
  ); // Tailwind `tertiary-fixed`
  static const Color limeHighlight = Color(
    0xFFFDE68A,
  ); // Narrative Lime Highlight
  static const Color limeDim = Color(
    0xFFD97706,
  ); // Tailwind `tertiary-fixed-dim`
  static const Color tertiary = Color(0xFF78350F);
  static const Color tertiaryContainer = Color(0xFF92400E);
  static const Color onTertiaryFixed = Color(0xFF451A03);

  // Surfaces & Backgrounds
  static const Color surfaceBotanical = Color(
    0xFFF8FAFC,
  ); // Tailwind `surface` / `background`
  static const Color warmCream = Color(0xFFF8FAFC); // Narrative Warm Cream
  static const Color surfaceContainerLowest = Color(
    0xFFFFFFFF,
  ); // Pure White cards
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFE2E8F0);
  static const Color surfaceContainerHigh = Color(0xFFDBE4EF);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);
  static const Color surfaceVariant = Color(0xFFCBD5E1);

  // Typography & Ink
  static const Color onSurface = Color(0xFF1E293B); // Tailwind `on-surface`
  static const Color ink = Color(0xFF1E293B); // Narrative Ink
  static const Color onSurfaceVariant = Color(
    0xFF475569,
  ); // Tailwind `on-surface-variant`
  static const Color mutedText = Color(0xFF64748B); // Narrative Muted Text

  // Borders & Dividers
  static const Color outline = Color(0xFF64748B);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color softBorder = Color(0xFFE2E8F0); // Narrative Border

  // Semantics & Alerts
  static const Color coral = Color(0xFFFF795F); // Narrative Coral
  static const Color goldAccent = Color(
    0xFFC6A779,
  ); // Luxury Architectural Gold
  static const Color goldBright = Color(0xFFE4D0AE); // Specular Gold Highlight
  static const Color amberLight = Color(0xFFB45309);
  static const Color amberDark = Color(0xFFFBBF24);
  static const Color successLight = Color(0xFF0F766E);
  static const Color successDark = Color(0xFF34D399);
  static const Color successSurfaceLight = Color(0xFFECFDF5);
  static const Color successSurfaceDark = Color(0xFF0E2E27);
  static const Color onSuccessContainerLight = Color(0xFF065F46);
  static const Color onSuccessContainerDark = Color(0xFFA7F3D0);
  static const Color warningLight = Color(0xFFB45309);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningSurfaceLight = Color(0xFFFFF7ED);
  static const Color warningSurfaceDark = Color(0xFF2B2110);
  static const Color onWarningContainerLight = Color(0xFF92400E);
  static const Color onWarningContainerDark = Color(0xFFFDE68A);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkErrorContainer = Color(0xFF3F161D);
  static const Color darkOnErrorContainer = Color(0xFFFECACA);

  // Obsidian / Slate dark-mode surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurfaceLowest = Color(0xFF172236);
  static const Color darkSurfaceLow = Color(0xFF1E293B);
  static const Color darkSurfaceContainer = Color(0xFF263449);
  static const Color darkSurfaceHigh = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceVariant = Color(0xFFCBD5E1);
  static const Color darkBorder = Color(0xFF334155);
}

/// Theme extension providing semantic FIXO surface and accent tokens
/// across Light and Dark themes without hardcoding colors per widget.
@immutable
class FixoPaletteExtension extends ThemeExtension<FixoPaletteExtension> {
  const FixoPaletteExtension({
    required this.canvasBackground,
    required this.warmCreamCanvas,
    required this.cardSurface,
    required this.surfaceLow,
    required this.surfaceContainer,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.primaryBrand,
    required this.deepForest,
    required this.secondaryForest,
    required this.limeAccent,
    required this.coralUrgent,
    required this.inkText,
    required this.mutedText,
    required this.subtleBorder,
    this.onPrimary = Colors.white,
    this.primaryContainer = FixoColors.primaryFixed,
    this.onPrimaryContainer = FixoColors.deepestForest,
    this.success = FixoColors.successLight,
    this.successContainer = FixoColors.successSurfaceLight,
    this.onSuccessContainer = FixoColors.onSuccessContainerLight,
    this.warning = FixoColors.warningLight,
    this.warningContainer = FixoColors.warningSurfaceLight,
    this.onWarningContainer = FixoColors.onWarningContainerLight,
    this.error = FixoColors.error,
    this.errorContainer = FixoColors.errorContainer,
    this.onErrorContainer = FixoColors.onErrorContainer,
  });

  final Color canvasBackground;
  final Color warmCreamCanvas;
  final Color cardSurface;
  final Color surfaceLow;
  final Color surfaceContainer;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color primaryBrand;
  final Color deepForest;
  final Color secondaryForest;
  final Color limeAccent;
  final Color coralUrgent;
  final Color inkText;
  final Color mutedText;
  final Color subtleBorder;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;

  static const FixoPaletteExtension light = FixoPaletteExtension(
    canvasBackground: FixoColors.surfaceBotanical,
    warmCreamCanvas: FixoColors.warmCream,
    cardSurface: FixoColors.surfaceContainerLowest,
    surfaceLow: FixoColors.surfaceContainerLow,
    surfaceContainer: FixoColors.surfaceContainer,
    surfaceHigh: FixoColors.surfaceContainerHigh,
    surfaceHighest: FixoColors.surfaceContainerHighest,
    primaryBrand: FixoColors.primaryForest,
    deepForest: FixoColors.deepestForest,
    secondaryForest: FixoColors.secondaryForest,
    limeAccent: FixoColors.goldBright,
    coralUrgent: FixoColors.coral,
    inkText: FixoColors.deepestForest,
    mutedText: FixoColors.onSurfaceVariant,
    subtleBorder: FixoColors.softBorder,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEFF4FA),
    onPrimaryContainer: FixoColors.deepestForest,
    success: FixoColors.successLight,
    successContainer: FixoColors.successSurfaceLight,
    onSuccessContainer: FixoColors.onSuccessContainerLight,
    warning: FixoColors.warningLight,
    warningContainer: FixoColors.warningSurfaceLight,
    onWarningContainer: FixoColors.onWarningContainerLight,
    error: FixoColors.error,
    errorContainer: FixoColors.errorContainer,
    onErrorContainer: FixoColors.onErrorContainer,
  );

  static const FixoPaletteExtension dark = FixoPaletteExtension(
    canvasBackground: FixoColors.darkBackground,
    warmCreamCanvas: FixoColors.darkBackground,
    cardSurface: FixoColors.darkSurfaceLowest,
    surfaceLow: FixoColors.darkSurfaceLow,
    surfaceContainer: FixoColors.darkSurfaceContainer,
    surfaceHigh: FixoColors.darkSurfaceHigh,
    surfaceHighest: FixoColors.darkBorder,
    primaryBrand: FixoColors.amberDark,
    deepForest: FixoColors.darkOnSurface,
    secondaryForest: Color(0xFF94A3B8),
    limeAccent: FixoColors.limeHighlight,
    coralUrgent: FixoColors.darkError,
    inkText: FixoColors.darkOnSurface,
    mutedText: FixoColors.darkOnSurfaceVariant,
    subtleBorder: FixoColors.darkBorder,
    onPrimary: FixoColors.deepestForest,
    primaryContainer: FixoColors.warningSurfaceDark,
    onPrimaryContainer: FixoColors.limeHighlight,
    success: FixoColors.successDark,
    successContainer: FixoColors.successSurfaceDark,
    onSuccessContainer: FixoColors.onSuccessContainerDark,
    warning: FixoColors.warningDark,
    warningContainer: FixoColors.warningSurfaceDark,
    onWarningContainer: FixoColors.onWarningContainerDark,
    error: FixoColors.darkError,
    errorContainer: FixoColors.darkErrorContainer,
    onErrorContainer: FixoColors.darkOnErrorContainer,
  );

  @override
  FixoPaletteExtension copyWith({
    Color? canvasBackground,
    Color? warmCreamCanvas,
    Color? cardSurface,
    Color? surfaceLow,
    Color? surfaceContainer,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? primaryBrand,
    Color? deepForest,
    Color? secondaryForest,
    Color? limeAccent,
    Color? coralUrgent,
    Color? inkText,
    Color? mutedText,
    Color? subtleBorder,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? error,
    Color? errorContainer,
    Color? onErrorContainer,
  }) {
    return FixoPaletteExtension(
      canvasBackground: canvasBackground ?? this.canvasBackground,
      warmCreamCanvas: warmCreamCanvas ?? this.warmCreamCanvas,
      cardSurface: cardSurface ?? this.cardSurface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      primaryBrand: primaryBrand ?? this.primaryBrand,
      deepForest: deepForest ?? this.deepForest,
      secondaryForest: secondaryForest ?? this.secondaryForest,
      limeAccent: limeAccent ?? this.limeAccent,
      coralUrgent: coralUrgent ?? this.coralUrgent,
      inkText: inkText ?? this.inkText,
      mutedText: mutedText ?? this.mutedText,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    );
  }

  @override
  FixoPaletteExtension lerp(
    covariant ThemeExtension<FixoPaletteExtension>? other,
    double t,
  ) {
    if (other is! FixoPaletteExtension) return this;
    return FixoPaletteExtension(
      canvasBackground: Color.lerp(
        canvasBackground,
        other.canvasBackground,
        t,
      )!,
      warmCreamCanvas: Color.lerp(warmCreamCanvas, other.warmCreamCanvas, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      primaryBrand: Color.lerp(primaryBrand, other.primaryBrand, t)!,
      deepForest: Color.lerp(deepForest, other.deepForest, t)!,
      secondaryForest: Color.lerp(secondaryForest, other.secondaryForest, t)!,
      limeAccent: Color.lerp(limeAccent, other.limeAccent, t)!,
      coralUrgent: Color.lerp(coralUrgent, other.coralUrgent, t)!,
      inkText: Color.lerp(inkText, other.inkText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
    );
  }
}

extension FixoThemeContextExtension on BuildContext {
  FixoPaletteExtension get fixoPalette =>
      Theme.of(this).extension<FixoPaletteExtension>() ??
      FixoPaletteExtension.light;
}
