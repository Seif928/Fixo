import 'package:flutter/material.dart';
import 'fixo_colors.dart';
import 'fixo_spacing.dart';
import 'fixo_typography.dart';

/// Central `ThemeData` factory for FIXO (Light and Dark modes, EN and AR locales).
abstract final class FixoTheme {
  static ThemeData light({Locale? locale}) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: FixoColors.deepestForest,
      onPrimary: Colors.white,
      primaryContainer: FixoColors.primaryForest,
      onPrimaryContainer: Colors.white,
      secondary: FixoColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: FixoColors.secondaryContainer,
      onSecondaryContainer: FixoColors.onSecondaryContainer,
      tertiary: FixoColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: FixoColors.limeAccent,
      onTertiaryContainer: FixoColors.onTertiaryFixed,
      error: FixoColors.error,
      onError: Colors.white,
      errorContainer: FixoColors.errorContainer,
      onErrorContainer: FixoColors.onErrorContainer,
      surface: FixoColors.surfaceBotanical,
      onSurface: FixoColors.onSurface,
      surfaceContainerLowest: FixoColors.surfaceContainerLowest,
      surfaceContainerLow: FixoColors.surfaceContainerLow,
      surfaceContainer: FixoColors.surfaceContainer,
      surfaceContainerHigh: FixoColors.surfaceContainerHigh,
      surfaceContainerHighest: FixoColors.surfaceContainerHighest,
      onSurfaceVariant: FixoColors.onSurfaceVariant,
      outline: FixoColors.outline,
      outlineVariant: FixoColors.outlineVariant,
    );

    final textTheme = FixoTypography.buildTextTheme(
      primaryTextColor: FixoColors.onSurface,
      secondaryTextColor: FixoColors.onSurfaceVariant,
      locale: locale,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FixoColors.surfaceBotanical,
      fontFamily: FixoTypography.fontFamilyForLocale(locale),
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[FixoPaletteExtension.light],
      appBarTheme: AppBarTheme(
        backgroundColor: FixoColors.surfaceBotanical.withValues(alpha: 0.9),
        foregroundColor: FixoColors.primaryForest,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: FixoTypography.headlineSm(
          color: FixoColors.primaryForest,
          locale: locale,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: FixoColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FixoRadius.borderRadiusLg,
          side: const BorderSide(color: FixoColors.softBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FixoColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FixoSpacing.md,
          vertical: 14,
        ),
        hintStyle: FixoTypography.bodyMd(
          color: FixoColors.mutedText,
          locale: locale,
        ),
        border: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.softBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.softBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: FixoColors.primaryForest,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.coral, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.coral, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FixoColors.primaryForest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(FixoSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: FixoRadius.borderRadiusSm,
          ),
          textStyle: FixoTypography.labelLg(
            color: Colors.white,
            locale: locale,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: FixoColors.surfaceContainerLowest,
          foregroundColor: FixoColors.deepestForest,
          minimumSize: const Size.fromHeight(FixoSpacing.minTouchTarget),
          side: const BorderSide(color: FixoColors.softBorder, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: FixoRadius.borderRadiusSm,
          ),
          textStyle: FixoTypography.labelLg(
            color: FixoColors.deepestForest,
            locale: locale,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FixoColors.softBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData dark({Locale? locale}) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: FixoColors.limeAccent,
      onPrimary: FixoColors.deepestForest,
      primaryContainer: FixoColors.primaryForest,
      onPrimaryContainer: Colors.white,
      secondary: FixoColors.secondaryFixedDim,
      onSecondary: FixoColors.deepestForest,
      secondaryContainer: FixoColors.secondaryForest,
      onSecondaryContainer: FixoColors.secondaryFixed,
      tertiary: FixoColors.limeAccent,
      onTertiary: FixoColors.onTertiaryFixed,
      tertiaryContainer: FixoColors.tertiaryContainer,
      onTertiaryContainer: FixoColors.limeAccent,
      error: FixoColors.coral,
      onError: FixoColors.deepestForest,
      errorContainer: FixoColors.onErrorContainer,
      onErrorContainer: FixoColors.errorContainer,
      surface: FixoColors.darkBackground,
      onSurface: FixoColors.darkOnSurface,
      surfaceContainerLowest: FixoColors.darkSurfaceLowest,
      surfaceContainerLow: FixoColors.darkSurfaceLow,
      surfaceContainer: FixoColors.darkSurfaceContainer,
      surfaceContainerHigh: FixoColors.darkSurfaceHigh,
      surfaceContainerHighest: FixoColors.darkBorder,
      onSurfaceVariant: FixoColors.darkOnSurfaceVariant,
      outline: FixoColors.outline,
      outlineVariant: FixoColors.darkBorder,
    );

    final textTheme = FixoTypography.buildTextTheme(
      primaryTextColor: FixoColors.darkOnSurface,
      secondaryTextColor: FixoColors.darkOnSurfaceVariant,
      locale: locale,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FixoColors.darkBackground,
      fontFamily: FixoTypography.fontFamilyForLocale(locale),
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[FixoPaletteExtension.dark],
    );
  }
}
