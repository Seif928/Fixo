import 'package:material_ui/material_ui.dart';
import '../theme/fixo_colors.dart';
import 'fixo_brand_mark.dart';

/// The owner's previous Web entry palette, shared by native Flutter forms.
class PremiumEntryTheme extends StatelessWidget {
  const PremiumEntryTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final accent = dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final background = dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = dark ? const Color(0xFF172236) : Colors.white;
    final palette = context.fixoPalette.copyWith(
      canvasBackground: background,
      warmCreamCanvas: background,
      cardSurface: surface,
      surfaceLow: background,
      surfaceContainer: dark
          ? const Color(0xFF1E293B)
          : const Color(0xFFF1F5F9),
      surfaceHigh: dark ? const Color(0xFF263449) : const Color(0xFFFFF7ED),
      primaryBrand: accent,
      deepForest: ink,
      inkText: ink,
      limeAccent: accent,
      secondaryForest: accent,
      mutedText: dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
      subtleBorder: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: background,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: dark ? const Color(0xFF0F172A) : Colors.white,
            minimumSize: const Size(48, 48),
          ),
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: surface,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        colorScheme: theme.colorScheme.copyWith(
          primary: accent,
          onPrimary: dark ? const Color(0xFF0F172A) : Colors.white,
          surface: surface,
        ),
        extensions: [
          for (final extension in theme.extensions.values)
            if (extension is! FixoPaletteExtension) extension,
          palette,
        ],
      ),
      child: child,
    );
  }
}

class PremiumEntryMark extends StatelessWidget {
  const PremiumEntryMark({super.key});
  @override
  Widget build(BuildContext context) =>
      const FixoBrandMark(iconOnly: true, iconBoxSize: 56);
}

class PremiumWelcomeHero extends StatelessWidget {
  const PremiumWelcomeHero({super.key, required this.isArabic});
  final bool isArabic;
  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.subtleBorder),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [palette.surfaceHigh, palette.cardSurface],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const PremiumEntryMark(),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'رعاية تليق ببيتك' : 'Home care, thoughtfully done.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: palette.inkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isArabic
                ? 'من أول تسجيل لحد إتمام خدمتك، كل التفاصيل في مكان واحد.'
                : 'From your first sign-in to your next service, all in one place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: palette.mutedText,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final icon in [
                Icons.home_repair_service_outlined,
                Icons.ac_unit_rounded,
                Icons.electrical_services_outlined,
                Icons.cleaning_services_outlined,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(icon, size: 26, color: palette.primaryBrand),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
