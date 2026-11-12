import 'package:material_ui/material_ui.dart';
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FixoColors.primaryForest,
          textStyle: FixoTypography.labelMd(
            color: FixoColors.primaryForest,
            locale: locale,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FixoColors.surfaceContainerLow,
        selectedColor: FixoColors.primaryForest,
        secondarySelectedColor: FixoColors.primaryForest,
        labelStyle: FixoTypography.labelMd(
          color: FixoColors.onSurface,
          locale: locale,
        ),
        secondaryLabelStyle: FixoTypography.labelMd(
          color: Colors.white,
          locale: locale,
        ),
        side: const BorderSide(color: FixoColors.softBorder),
        shape: const RoundedRectangleBorder(
          borderRadius: FixoRadius.borderRadiusSm,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FixoColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FixoRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FixoColors.deepestForest,
        contentTextStyle: FixoTypography.bodyMd(
          color: Colors.white,
          locale: locale,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: FixoRadius.borderRadiusSm,
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
      appBarTheme: AppBarTheme(
        backgroundColor: FixoColors.darkBackground.withValues(alpha: 0.92),
        foregroundColor: FixoColors.darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: FixoTypography.headlineSm(
          color: FixoColors.darkOnSurface,
          locale: locale,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: FixoColors.darkSurfaceLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FixoRadius.borderRadiusLg,
          side: const BorderSide(color: FixoColors.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FixoColors.darkSurfaceLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FixoSpacing.md,
          vertical: 14,
        ),
        hintStyle: FixoTypography.bodyMd(
          color: FixoColors.darkOnSurfaceVariant,
          locale: locale,
        ),
        labelStyle: FixoTypography.bodyMd(
          color: FixoColors.darkOnSurfaceVariant,
          locale: locale,
        ),
        border: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(
            color: FixoColors.limeAccent,
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
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
          backgroundColor: FixoColors.darkSurfaceLowest,
          foregroundColor: FixoColors.darkOnSurface,
          minimumSize: const Size.fromHeight(FixoSpacing.minTouchTarget),
          side: const BorderSide(color: FixoColors.darkBorder, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: FixoRadius.borderRadiusSm,
          ),
          textStyle: FixoTypography.labelLg(
            color: FixoColors.darkOnSurface,
            locale: locale,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FixoColors.limeAccent,
          textStyle: FixoTypography.labelMd(
            color: FixoColors.limeAccent,
            locale: locale,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FixoColors.darkSurfaceLow,
        selectedColor: FixoColors.primaryForest,
        secondarySelectedColor: FixoColors.primaryForest,
        labelStyle: FixoTypography.labelMd(
          color: FixoColors.darkOnSurface,
          locale: locale,
        ),
        secondaryLabelStyle: FixoTypography.labelMd(
          color: Colors.white,
          locale: locale,
        ),
        side: const BorderSide(color: FixoColors.darkBorder),
        shape: const RoundedRectangleBorder(
          borderRadius: FixoRadius.borderRadiusSm,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FixoColors.darkSurfaceLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FixoRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FixoColors.darkSurfaceHigh,
        contentTextStyle: FixoTypography.bodyMd(
          color: FixoColors.darkOnSurface,
          locale: locale,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: FixoRadius.borderRadiusSm,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FixoColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
