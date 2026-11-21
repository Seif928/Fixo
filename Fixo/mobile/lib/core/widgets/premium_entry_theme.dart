import 'package:material_ui/material_ui.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_workspace_theme.dart';
import 'fixo_brand_mark.dart';

/// The owner's previous Web entry palette, shared by native Flutter forms.
class PremiumEntryTheme extends StatelessWidget {
  const PremiumEntryTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FixoWorkspaceTheme(workspace: FixoWorkspace.customer, child: child);
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
    final size = MediaQuery.sizeOf(context);
    final compactDesktop = size.width >= 600 && size.height <= 860;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 28,
        vertical: compactDesktop ? 16 : 28,
      ),
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
          SizedBox(height: compactDesktop ? 12 : 20),
          Text(
            isArabic ? 'رعاية تليق ببيتك' : 'Home care, thoughtfully done.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compactDesktop ? 24 : 28,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: palette.inkText,
            ),
          ),
          SizedBox(height: compactDesktop ? 6 : 10),
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
          SizedBox(height: compactDesktop ? 14 : 24),
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
