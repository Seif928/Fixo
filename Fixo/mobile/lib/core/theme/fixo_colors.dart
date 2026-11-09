import 'package:flutter/material.dart';

/// Central color tokens for the FIXO design system.
///
/// Reconciles the Material 3 / Tailwind tokens from the 16 Stitch HTML screens
/// (`01_*` through `16_*`) with the narrative tokens from `DESIGN.md` and
/// `docs/STITCH_AUDIT.md`.
abstract final class FixoColors {
  // Cinematic charcoal / ivory / champagne anchors (legacy API names retained)
  static const Color deepestForest = Color(0xFF17191C); // Tailwind `primary`
  static const Color primaryForest = Color(
    0xFF24262B,
  ); // Tailwind `primary-container` / Narrative Primary Forest
  static const Color secondaryForest = Color(
    0xFF4E4942,
  ); // Narrative Secondary Forest
  static const Color secondary = Color(0xFF645A4A); // Tailwind `secondary`
  static const Color onPrimaryContainer = Color(0xFFC6BBA9);
  static const Color primaryFixed = Color(0xFFECE1D0);
  static const Color primaryFixedDim = Color(0xFFD4C5AF);

  // Secondary Mint Tones
  static const Color secondaryContainer = Color(0xFFE9DDC9);
  static const Color onSecondaryContainer = Color(0xFF574A35);
  static const Color secondaryFixed = Color(0xFFE9DDC9);
  static const Color secondaryFixedDim = Color(0xFFD2C0A3);

  // Lime Accents (Always pair with deepestForest / primaryForest text)
  static const Color limeAccent = Color(
    0xFFC6A779,
  ); // Tailwind `tertiary-fixed`
  static const Color limeHighlight = Color(
    0xFFD8BC90,
  ); // Narrative Lime Highlight
  static const Color limeDim = Color(
    0xFFB3976B,
  ); // Tailwind `tertiary-fixed-dim`
  static const Color tertiary = Color(0xFF302719);
  static const Color tertiaryContainer = Color(0xFF473923);
  static const Color onTertiaryFixed = Color(0xFF241D13);

  // Surfaces & Backgrounds
  static const Color surfaceBotanical = Color(
    0xFFF6F2EB,
  ); // Tailwind `surface` / `background`
  static const Color warmCream = Color(0xFFF6F2EB); // Narrative Warm Cream
  static const Color surfaceContainerLowest = Color(
    0xFFFFFFFF,
  ); // Pure White cards
  static const Color surfaceContainerLow = Color(0xFFF0EBE3);
  static const Color surfaceContainer = Color(0xFFEAE3D8);
  static const Color surfaceContainerHigh = Color(0xFFE4DBCE);
  static const Color surfaceContainerHighest = Color(0xFFDDD2C2);
  static const Color surfaceVariant = Color(0xFFDDD2C2);

  // Typography & Ink
  static const Color onSurface = Color(0xFF24262B); // Tailwind `on-surface`
  static const Color ink = Color(0xFF24262B); // Narrative Ink
  static const Color onSurfaceVariant = Color(
    0xFF5D5750,
  ); // Tailwind `on-surface-variant`
  static const Color mutedText = Color(0xFF71685D); // Narrative Muted Text

  // Borders & Dividers
  static const Color outline = Color(0xFF82786C);
  static const Color outlineVariant = Color(0xFFC8BFB2);
  static const Color softBorder = Color(0xFFE7DED1); // Narrative Border

  // Urgency & Semantic Alerts
  static const Color coral = Color(0xFFFF795F); // Narrative Coral
  static const Color goldAccent = Color(
    0xFFC6A779,
  ); // Luxury Architectural Gold
  static const Color goldBright = Color(0xFFE4D0AE); // Specular Gold Highlight
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Warm charcoal dark-mode surfaces
  static const Color darkBackground = Color(0xFF17191C); // Pure True Black OLED
  static const Color darkSurfaceLowest = Color(
    0xFF1D1F23,
  ); // Deep Obsidian Card Base
  static const Color darkSurfaceLow = Color(0xFF22252A); // Elevated Obsidian
  static const Color darkSurfaceContainer = Color(
    0xFF292C31,
  ); // Interactive Surface
  static const Color darkSurfaceHigh = Color(
    0xFF30333A,
  ); // High Elevation Surface
  static const Color darkOnSurface = Color(0xFFF6F2EB); // Crisp Alabaster White
  static const Color darkOnSurfaceVariant = Color(
    0xFFB8B2A9,
  ); // Silver Botanical Muted
  static const Color darkBorder = Color(0xFF3A3C41); // Specular Obsidian Rim
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
    limeAccent: FixoColors.limeAccent,
    coralUrgent: FixoColors.coral,
    inkText: FixoColors.onSurface,
    mutedText: FixoColors.onSurfaceVariant,
    subtleBorder: FixoColors.softBorder,
  );

  static const FixoPaletteExtension dark = FixoPaletteExtension(
    canvasBackground: FixoColors.darkBackground,
    warmCreamCanvas: FixoColors.darkBackground,
    cardSurface: FixoColors.darkSurfaceLowest,
    surfaceLow: FixoColors.darkSurfaceLow,
    surfaceContainer: FixoColors.darkSurfaceContainer,
    surfaceHigh: FixoColors.darkSurfaceHigh,
    surfaceHighest: FixoColors.darkBorder,
    primaryBrand: FixoColors.primaryForest,
    deepForest: FixoColors.primaryFixed,
    secondaryForest: FixoColors.secondary,
    limeAccent: FixoColors.limeAccent,
    coralUrgent: FixoColors.coral,
    inkText: FixoColors.darkOnSurface,
    mutedText: FixoColors.darkOnSurfaceVariant,
    subtleBorder: FixoColors.darkBorder,
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
    );
  }
}

extension FixoThemeContextExtension on BuildContext {
  FixoPaletteExtension get fixoPalette =>
      Theme.of(this).extension<FixoPaletteExtension>() ??
      FixoPaletteExtension.light;
}
