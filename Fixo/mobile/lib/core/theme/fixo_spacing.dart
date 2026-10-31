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

