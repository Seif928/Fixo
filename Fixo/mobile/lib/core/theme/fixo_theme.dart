import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
      dialogTheme: const DialogThemeData(
        backgroundColor: FixoColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: FixoColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return FixoColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FixoColors.primaryForest;
          }
          return FixoColors.surfaceContainer;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return FixoColors.outlineVariant;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FixoColors.primaryForest;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FixoColors.primaryForest,
      ),
    );
  }

  static ThemeData dark({Locale? locale}) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: FixoColors.amberDark,
      onPrimary: FixoColors.deepestForest,
      primaryContainer: FixoColors.warningSurfaceDark,
      onPrimaryContainer: FixoColors.limeHighlight,
      secondary: FixoColors.darkOnSurfaceVariant,
      onSecondary: FixoColors.deepestForest,
      secondaryContainer: FixoColors.darkSurfaceContainer,
      onSecondaryContainer: FixoColors.darkOnSurface,
      tertiary: FixoColors.limeHighlight,
      onTertiary: FixoColors.deepestForest,
      tertiaryContainer: FixoColors.warningSurfaceDark,
      onTertiaryContainer: FixoColors.limeHighlight,
      error: FixoColors.darkError,
      onError: FixoColors.deepestForest,
      errorContainer: FixoColors.darkErrorContainer,
      onErrorContainer: FixoColors.darkOnErrorContainer,
      surface: FixoColors.darkBackground,
      onSurface: FixoColors.darkOnSurface,
      surfaceContainerLowest: FixoColors.darkSurfaceLowest,
      surfaceContainerLow: FixoColors.darkSurfaceLow,
      surfaceContainer: FixoColors.darkSurfaceContainer,
      surfaceContainerHigh: FixoColors.darkSurfaceHigh,
      surfaceContainerHighest: FixoColors.darkBorder,
      onSurfaceVariant: FixoColors.darkOnSurfaceVariant,
      outline: Color(0xFF94A3B8),
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
        backgroundColor: FixoColors.darkBackground.withValues(alpha: 0.94),
        foregroundColor: FixoColors.darkOnSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
            color: FixoColors.amberDark,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.darkError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: FixoRadius.borderRadiusSm,
          borderSide: const BorderSide(color: FixoColors.darkError, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FixoColors.amberDark,
          foregroundColor: FixoColors.deepestForest,
          disabledBackgroundColor: FixoColors.darkSurfaceHigh,
          disabledForegroundColor: FixoColors.darkOnSurfaceVariant,
          elevation: 0,
          minimumSize: const Size.fromHeight(FixoSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: FixoRadius.borderRadiusSm,
          ),
          textStyle: FixoTypography.labelLg(
            color: FixoColors.deepestForest,
            locale: locale,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FixoColors.amberDark,
          foregroundColor: FixoColors.deepestForest,
          disabledBackgroundColor: FixoColors.darkSurfaceHigh,
          disabledForegroundColor: FixoColors.darkOnSurfaceVariant,
          elevation: 0,
          minimumSize: const Size.fromHeight(FixoSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: FixoRadius.borderRadiusSm,
          ),
          textStyle: FixoTypography.labelLg(
            color: FixoColors.deepestForest,
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
          foregroundColor: FixoColors.amberDark,
          textStyle: FixoTypography.labelMd(
            color: FixoColors.amberDark,
            locale: locale,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FixoColors.darkSurfaceLow,
        selectedColor: FixoColors.amberDark,
        secondarySelectedColor: FixoColors.amberDark,
        labelStyle: FixoTypography.labelMd(
          color: FixoColors.darkOnSurface,
          locale: locale,
        ),
        secondaryLabelStyle: FixoTypography.labelMd(
          color: FixoColors.deepestForest,
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
      dialogTheme: const DialogThemeData(
        backgroundColor: FixoColors.darkSurfaceLowest,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: FixoColors.darkSurfaceLowest,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FixoColors.deepestForest;
          }
          return FixoColors.darkOnSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FixoColors.amberDark;
          }
          return FixoColors.darkSurfaceLow;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return FixoColors.darkBorder;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FixoColors.amberDark;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(FixoColors.deepestForest),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FixoColors.amberDark,
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
