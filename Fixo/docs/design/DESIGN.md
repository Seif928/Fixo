# FIXO interaction design supplement

Derived from live Stitch project 18114732464114306203 (Screen 01 queried and inspected 2026-11-02). The original Stitch project remains the visual source of truth.

## Atmosphere and layout
Calm Egyptian home care, balanced density, editorial left/start aligned headings. Retain the native Flutter illustration, ordered content and clear primary action. Customer and professional entries have distinct copy and destinations, using one consistent brand. No invented availability, verification guarantees or sample financial charts.

## Palette and typography
Deep Forest #173F35 primary actions; Deepest Forest #002920 headings; Fresh Lime #D5EE76 singular accent; Botanical #F1FCF5 and Warm Cream #F7F5EF light surfaces. Dark mode comes from FixoTheme, never ad-hoc screen colors. Manrope EN and Cairo AR are bundled; retain RTL and readable line lengths.

## Controls
Minimum 48 logical pixels for primary touch targets. Native focus, keyboard, hover, ink feedback and gesture cancellation remain. Loading prevents duplicate submits. Disabled actions are visually muted. Inputs keep visible labels and actionable localized errors.

## Motion
Entrance: 280ms ease-out cubic fade and 2.5% vertical translation, once per mount. Pages: 220ms opacity and at most 2% vertical translation; peer tabs fade without sliding navigation. Buttons: 110ms transform to .985 while pressed; reset on cancellation. No layout/size animation, unbounded loops, extra network assets or added animation packages. MediaQuery disableAnimations or accessibleNavigation bypasses movement immediately.

## Responsive rules and anti-patterns
Support 360/390/412dp with 1.35x text plus desktop, EN/LTR and AR/RTL. Keep forms scrollable and actions reachable. No neon glows, oversized headings, invented counters, decorative delays, hidden navigation, external image hotlinks or new paid dependencies.
