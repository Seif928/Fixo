import 'package:flutter/material.dart';
import 'fixo_colors.dart';

/// 8pt baseline spacing, border-radius, and ambient botanical shadow tokens.
abstract final class FixoSpacing {
  // Spacing Scale
  static const double xs = 4.0; // 0.25rem (space-xs)
  static const double sm = 8.0; // 0.5rem (space-sm)
  static const double gutterMobile = 12.0; // 0.75rem (gutter-mobile)
  static const double md = 16.0; // 1.0rem (space-md / gutter / margin)
  static const double lg = 24.0; // 1.5rem (space-lg)
  static const double xl = 40.0; // 2.5rem (space-xl)

  // Standard Touch Targets
  static const double minTouchTarget = 48.0;

  // Responsive Breakpoints
  static const double compactMobileWidth = 360.0;
  static const double standardMobileWidth = 390.0;
  static const double largeMobileWidth = 412.0;
  static const double tabletBreakpoint = 600.0;
}

/// Shape and border-radius tokens matching `DESIGN.md` and Stitch Tailwind configs.
abstract final class FixoRadius {
  static const double xs = 4.0;
  static const double sm = 8.0; // Inputs, Buttons, Badges (0.5rem)
  static const double md = 12.0; // Inner cards & panels (0.75rem)
  static const double lg = 16.0; // Primary cards & hero containers (1.0rem)
  static const double xl = 24.0; // Modals & bottom sheets (1.5rem)
  static const double pill = 9999.0; // Full pill radius

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(sm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(md),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(lg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(xl),
  );
  static const BorderRadius borderRadiusPill = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Diffused botanical elevation shadows defined in `DESIGN.md`.
abstract final class FixoShadows {
  /// Level 1 (Card Resting): subtle ambient green-tinted shadow.
  static const List<BoxShadow> level1CardResting = [
    BoxShadow(
      color: Color(0x0A173F35), // rgba(23, 63, 53, 0.04)
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x05173F35), // rgba(23, 63, 53, 0.02)
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Level 2 (Interactive Hover & Modal Bottom Sheets).
  static const List<BoxShadow> level2Interactive = [
    BoxShadow(
      color: Color(0x14173F35), // rgba(23, 63, 53, 0.08)
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x0A173F35), // rgba(23, 63, 53, 0.04)
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  /// Level 3 (Toasts & Overlays).
  static List<BoxShadow> get level3Overlay => [
    BoxShadow(
      color: FixoColors.ink.withValues(alpha: 0.14),
      offset: const Offset(0, 20),
      blurRadius: 32,
      spreadRadius: -8,
    ),
  ];
}

/// Adaptive layout ergonomics providing calibrated margins and insets
/// tailored across iPhone, Android, and Desktop/Web viewports.
abstract final class FixoAdaptive {
  static const double desktopBreakpoint = 1000.0;
  static const double tabletBreakpoint = 600.0;
  static const double standardPhoneWidth = 390.0;
  static const double compactPhoneWidth = 360.0;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  /// Optimal horizontal margin calibrated for the active device:
  /// - Desktop / Web: 32.0 (spacious breathing room)
  /// - Tablet: 24.0
  /// - Standard iPhone / Android (>=375dp): 16.0 (Apple HIG standard)
  /// - Compact Android (<375dp): 12.0 (prevents edge crampedness)
  static double horizontalMargin(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return 32.0;
    if (width >= tabletBreakpoint) return 24.0;
    if (width >= 375.0) return FixoSpacing.md;
    return FixoSpacing.gutterMobile;
  }

  /// Page padding taking into account device horizontal margins.
  static EdgeInsets pagePadding(BuildContext context, {double vertical = 12.0}) {
    return EdgeInsets.symmetric(
      horizontal: horizontalMargin(context),
      vertical: vertical,
    );
  }

  /// Maximum readable container width for desktop/web:
  /// Returns 1200 on desktop, 600 on tablet/foldables, and infinity on mobile.
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return 1200.0;
    if (width >= tabletBreakpoint) return 680.0;
    return double.infinity;
  }

  /// Safe bottom inset protecting against iPhone Home Indicator bar (~34dp)
  /// and Android gesture navigation bar (~16-24dp).
  static double bottomSafeInset(BuildContext context, {double extra = 12.0}) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return bottomPadding > 0 ? bottomPadding + extra : extra;
  }

  /// Safe top inset protecting against iPhone Dynamic Island (~59dp),
  /// iOS notch (~47dp), and Android punch-hole cameras.
  static double topSafeInset(BuildContext context, {double extra = 8.0}) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return topPadding > 0 ? topPadding + extra : extra;
  }
}

