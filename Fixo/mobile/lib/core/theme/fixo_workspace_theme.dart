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
    final ink = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final muted = dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final canvas = dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = dark ? const Color(0xFF172236) : Colors.white;
    final surfaceLow = dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final border = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final tint = Color.alphaBlend(
      accent.withValues(alpha: dark ? .14 : .08),
      surface,
    );
    final onAccent = dark ? const Color(0xFF0F172A) : Colors.white;
    final err = dark ? FixoColors.darkError : FixoColors.error;
    final errBg = dark
        ? FixoColors.darkErrorContainer
        : FixoColors.errorContainer;
    final onErrBg = dark
        ? FixoColors.darkOnErrorContainer
        : FixoColors.onErrorContainer;
    final ok = dark ? FixoColors.successDark : FixoColors.successLight;
    final okBg = dark
        ? FixoColors.successSurfaceDark
        : FixoColors.successSurfaceLight;
    final onOkBg = dark
        ? FixoColors.onSuccessContainerDark
        : FixoColors.onSuccessContainerLight;
    final warnBg = dark
        ? FixoColors.warningSurfaceDark
        : FixoColors.warningSurfaceLight;
    final onWarnBg = dark
        ? FixoColors.onWarningContainerDark
        : FixoColors.onWarningContainerLight;
    final highlightPill = dark
        ? FixoColors.amberDark
        : FixoColors.goldBright;

    final colors = theme.colorScheme.copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: tint,
      onPrimaryContainer: ink,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: tint,
      onSecondaryContainer: ink,
      error: err,
      onError: onAccent,
      errorContainer: errBg,
      onErrorContainer: onErrBg,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: border,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: tint,
      surfaceContainerHigh: tint,
      surfaceContainerHighest: border,
    );
    final palette = context.fixoPalette.copyWith(
      canvasBackground: canvas,
      warmCreamCanvas: canvas,
      cardSurface: surface,
      surfaceLow: surfaceLow,
      surfaceContainer: tint,
      surfaceHigh: tint,
      surfaceHighest: border,
      primaryBrand: accent,
      onPrimary: onAccent,
      primaryContainer: tint,
      onPrimaryContainer: ink,
      deepForest: ink,
      secondaryForest: dark ? const Color(0xFF94A3B8) : muted,
      limeAccent: highlightPill,
      coralUrgent: err,
      inkText: ink,
      mutedText: muted,
      subtleBorder: border,
      success: ok,
      successContainer: okBg,
      onSuccessContainer: onOkBg,
      warning: accent,
      warningContainer: warnBg,
      onWarningContainer: onWarnBg,
      error: err,
      errorContainer: errBg,
      onErrorContainer: onErrBg,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final solid = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? (dark ? const Color(0xFF263449) : border)
            : accent,
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
            backgroundColor: surface,
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
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return onAccent;
            return muted;
          }),
          trackColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return accent;
            return surfaceLow;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return Colors.transparent;
            return border;
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return accent;
            return Colors.transparent;
          }),
          checkColor: WidgetStatePropertyAll(onAccent),
        ),
        chipTheme: theme.chipTheme.copyWith(
          backgroundColor: surfaceLow,
          selectedColor: accent,
          secondarySelectedColor: accent,
          labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
          secondaryLabelStyle: TextStyle(
            color: onAccent,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(color: border),
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
        dialogTheme: theme.dialogTheme.copyWith(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: theme.popupMenuTheme.copyWith(
          color: surface,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: theme.bottomSheetTheme.copyWith(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
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
