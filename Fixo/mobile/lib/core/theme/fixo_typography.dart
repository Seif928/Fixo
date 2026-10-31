import 'package:flutter/material.dart';
import 'fixo_colors.dart';

/// Typography scale for FIXO: Manrope for English (LTR) and Cairo for Arabic (RTL).
///
/// Enforces tabular figures (`tnum`) on price displays and numerical metrics.
abstract final class FixoTypography {
  static const String englishFontFamily = 'Manrope';
  static const String arabicFontFamily = 'Cairo';
  static const List<String> fallbackFonts = [
    'Segoe UI',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static String fontFamilyForLocale(Locale? locale) {
    if (locale?.languageCode == 'ar') {
      return arabicFontFamily;
    }
    return englishFontFamily;
  }

  /// Display (48px / 56px, w800)
  static TextStyle display({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.44,
    color: color ?? FixoColors.deepestForest,
  );

  /// Display Mobile (36px / 44px, w800)
  static TextStyle displayMobile({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.72,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color ?? FixoColors.deepestForest,
  );

  /// Headline Large (32px / 40px, w700)
  static TextStyle headlineLg({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64,
    color: color ?? FixoColors.deepestForest,
  );

  /// Headline Large Mobile (26px / 34px, w700)
  static TextStyle headlineLgMobile({Color? color, Locale? locale}) =>
      TextStyle(
        fontFamily: fontFamilyForLocale(locale),
        fontFamilyFallback: fallbackFonts,
        fontSize: 26,
        height: 34 / 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.39,
        color: color ?? FixoColors.deepestForest,
      );

  /// Headline Medium (22px / 30px, w600)
  static TextStyle headlineMd({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.22,
    color: color ?? FixoColors.onSurface,
  );

  /// Headline Small (18px / 26px, w600)
  static TextStyle headlineSm({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    color: color ?? FixoColors.onSurface,
  );

  /// Price Display (24px / 28px, w800, tabular figures)
  static TextStyle priceDisplay({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 24,
    height: 28 / 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.48,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color ?? FixoColors.deepestForest,
  );

  /// Body Large (16px / 24px, w400)
  static TextStyle bodyLg({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: color ?? FixoColors.onSurface,
  );

  /// Body Medium (14px / 20px, w400)
  static TextStyle bodyMd({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: color ?? FixoColors.onSurface,
  );

  /// Body Small (12px / 18px, w400)
  static TextStyle bodySm({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: color ?? FixoColors.onSurfaceVariant,
  );

  /// Label Large (14px / 20px, w600)
  static TextStyle labelLg({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color ?? FixoColors.onSurface,
  );

  /// Label Medium (12px / 16px, w600)
  static TextStyle labelMd({Color? color, Locale? locale}) => TextStyle(
    fontFamily: fontFamilyForLocale(locale),
    fontFamilyFallback: fallbackFonts,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color ?? FixoColors.onSurfaceVariant,
  );

  static TextTheme buildTextTheme({
    required Color primaryTextColor,
    required Color secondaryTextColor,
    Locale? locale,
  }) {
    return TextTheme(
      displayLarge: display(color: primaryTextColor, locale: locale),
      displayMedium: displayMobile(color: primaryTextColor, locale: locale),
      headlineLarge: headlineLg(color: primaryTextColor, locale: locale),
      headlineMedium: headlineLgMobile(color: primaryTextColor, locale: locale),
      headlineSmall: headlineMd(color: primaryTextColor, locale: locale),
      titleLarge: headlineSm(color: primaryTextColor, locale: locale),
      titleMedium: labelLg(color: primaryTextColor, locale: locale),
      titleSmall: labelMd(color: secondaryTextColor, locale: locale),
      bodyLarge: bodyLg(color: primaryTextColor, locale: locale),
      bodyMedium: bodyMd(color: primaryTextColor, locale: locale),
      bodySmall: bodySm(color: secondaryTextColor, locale: locale),
      labelLarge: labelLg(color: primaryTextColor, locale: locale),
      labelMedium: labelMd(color: secondaryTextColor, locale: locale),
    );
  }
}

