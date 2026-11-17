import 'package:material_ui/material_ui.dart';
import 'fixo_colors.dart';

/// Workspace appearance is never an authorization decision.
/// Administration authority still comes from the server's AdminAccess response.
enum FixoWorkspace {
  customer,
  professional,
  administrator,
  owner;

  static FixoWorkspace forPath(String path) {
    final route = Uri.tryParse(path)?.path ?? '';
    if (route == '/admin' || route.startsWith('/admin/')) return administrator;
    if (route == '/pro' || route.startsWith('/pro/')) return professional;
    return customer;
  }

  String label(bool ar) => switch (this) {
    customer => ar ? 'مساحة العميل' : 'Customer space',
    professional => ar ? 'مساحة الفني' : 'Professional workspace',
    administrator => ar ? 'لوحة الإدارة' : 'Administration',
    owner => ar ? 'لوحة المالك' : 'Owner console',
  };

  String accountLabel(bool ar) => switch (this) {
    customer => ar ? 'حساب عميل FIXO' : 'FIXO Customer',
    professional => ar ? 'حساب فني FIXO' : 'FIXO Professional',
    administrator => ar ? 'مسؤول الإدارة · Admin' : 'Administrator · Admin',
    owner => ar ? 'مالك التطبيق · Owner' : 'App Owner',
  };

  String description(bool ar) => switch (this) {
    customer =>
      ar
          ? 'خدمات بيتك وحجوزاتك، في مكان واحد.'
          : 'Home services and bookings, all in one place.',
    professional =>
      ar
          ? 'طلباتك ومواعيدك وأرباحك، تحت إيدك.'
          : 'Your jobs, schedule and earnings at a glance.',
    administrator =>
      ar
          ? 'متابعة الحجوزات والخدمات ومراجعة الفنيين.'
          : 'Manage bookings, services and professional reviews.',
    owner =>
      ar
          ? 'إدارة المشروع والمشرفين والصلاحيات.'
          : 'Manage your business, administrators and access.',
  };

  IconData get icon => switch (this) {
    customer => Icons.home_outlined,
    professional => Icons.handyman_outlined,
    administrator => Icons.admin_panel_settings_outlined,
    owner => Icons.verified_user_outlined,
  };
}

class FixoWorkspaceTheme extends StatelessWidget {
  const FixoWorkspaceTheme({
    super.key,
    required this.workspace,
    required this.child,
  });
  final FixoWorkspace workspace;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = switch (workspace) {
      FixoWorkspace.customer || FixoWorkspace.owner =>
        dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      FixoWorkspace.professional =>
        dark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
      FixoWorkspace.administrator =>
        dark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
    };
    final ink = dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final muted = dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
    final canvas = dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = dark ? const Color(0xFF172236) : Colors.white;
    final border = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final tint = Color.alphaBlend(
      accent.withValues(alpha: dark ? .12 : .06),
      surface,
    );
    final onAccent = dark ? const Color(0xFF0F172A) : Colors.white;
    final colors = theme.colorScheme.copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: tint,
      onPrimaryContainer: ink,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: tint,
      onSecondaryContainer: ink,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: border,
      surfaceContainerLowest: surface,
      surfaceContainerLow: canvas,
      surfaceContainer: tint,
      surfaceContainerHigh: tint,
    );
    final palette = context.fixoPalette.copyWith(
      canvasBackground: canvas,
      warmCreamCanvas: canvas,
      cardSurface: surface,
      surfaceLow: canvas,
      surfaceContainer: tint,
      surfaceHigh: tint,
      surfaceHighest: border,
      primaryBrand: accent,
      deepForest: ink,
      secondaryForest: accent,
      limeAccent: dark
          ? accent
          : Color.alphaBlend(accent.withValues(alpha: .2), surface),
      inkText: ink,
      mutedText: muted,
      subtleBorder: border,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final solid = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? border : accent,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? muted : onAccent,
      ),
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      shape: WidgetStatePropertyAll(shape),
      elevation: const WidgetStatePropertyAll(0),
    );
    return Theme(
      data: theme.copyWith(
        colorScheme: colors,
        scaffoldBackgroundColor: canvas,
        textTheme: theme.textTheme.apply(bodyColor: ink, displayColor: ink),
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: theme.cardTheme.copyWith(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: border),
          ),
        ),
        dividerTheme: theme.dividerTheme.copyWith(color: border, thickness: 1),
        filledButtonTheme: FilledButtonThemeData(style: solid),
        elevatedButtonTheme: ElevatedButtonThemeData(style: solid),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: BorderSide(color: border),
            shape: shape,
            minimumSize: const Size(48, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accent,
            minimumSize: const Size(48, 48),
          ),
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: surface,
          filled: true,
          labelStyle: TextStyle(color: muted),
          hintStyle: TextStyle(color: muted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        navigationBarTheme: theme.navigationBarTheme.copyWith(
          backgroundColor: surface,
          indicatorColor: tint,
        ),
        drawerTheme: theme.drawerTheme.copyWith(backgroundColor: surface),
        dialogTheme: theme.dialogTheme.copyWith(backgroundColor: surface),
        bottomSheetTheme: theme.bottomSheetTheme.copyWith(
          backgroundColor: surface,
        ),
        extensions: [
          for (final e in theme.extensions.values)
            if (e is! FixoPaletteExtension) e,
          palette,
        ],
      ),
      child: child,
    );
  }
}
