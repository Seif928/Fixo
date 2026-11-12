import 'dart:convert';
import '../../../../core/auth/platform_auth_capabilities.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../data/email_access_service.dart';
import '../../domain/auth_models.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_error_formatter.dart';
import '../controllers/account_entry_controller.dart';
import '../../../../core/uploads/private_media_picker_sheet.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../profile/data/avatar_repository.dart';

/// Screen 02: Ultra-Premium Luxury Login & Account Setup.
///
/// Features Apple VisionOS-inspired liquid glassmorphism, responsive split-screen
/// for desktop web, tactile haptics, social single-sign-on (Apple ID & Google),
/// and provider-backed identity verification.
class PhonePasswordPage extends ConsumerStatefulWidget {
  const PhonePasswordPage({super.key, this.professional});
  final bool? professional;

  @override
  ConsumerState<PhonePasswordPage> createState() => _PhonePasswordPageState();
}

class _PhonePasswordPageState extends ConsumerState<PhonePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController();
  final _password = TextEditingController(), _confirm = TextEditingController();
  bool _busy = false, _obscure = true;
  String? _error;
  PickedPrivateMedia? _photo;
  bool get _ar => ref.read(appLocaleProvider).languageCode == 'ar';

  bool get _professional =>
      widget.professional ?? ref.read(professionalEntryProvider);
  String get _destination =>
      _professional ? AppRoutes.proEntry : AppRoutes.customerHome;

  @override
  void initState() {
    super.initState();
    if (widget.professional != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(professionalEntryProvider.notifier)
              .selectProfessional(widget.professional!);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted || isCancelledAuthError(error)) return;
      final message = formatAuthErrorMessage(
        error,
        isArabic: _ar,
        forPhonePassword: true,
      );
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearSignInError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _accept(AuthSession session) async {
    await ref
        .read(authControllerProvider.notifier)
        .acceptVerifiedSession(session);
    if (!mounted) return;
    _password.clear();
    _confirm.clear();
    context.go(
      session.user.requiresProfileSetup
          ? '${AppRoutes.phoneAuth}${_professional ? '?account=pro' : ''}'
          : _destination,
    );
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    final selected = await PrivateMediaPickerSheet.show(
      context,
      isArabic: _ar,
      titleEn: 'Profile photo',
      titleAr: 'صورة الحساب',
      rationaleEn:
          'Choose a photo for your FIXO profile. You can change it later.',
      rationaleAr:
          'اختار صورة لحسابك على FIXO. تقدر تغيرها من البروفايل بعدين.',
      defaultFilePrefix: 'avatar',
      allowSuggestedAvatars: true,
    );
    if (mounted && selected != null) setState(() => _photo = selected);
  }

  Future<void> _recover() async {
    HapticFeedback.selectionClick();
    final email = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_ar ? 'استرجاع كلمة المرور' : 'Reset password'),
        content: TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: _ar ? 'بريد حسابك المرتبط' : 'Your linked email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, email.text.trim()),
            child: Text(_ar ? 'متابعة' : 'Continue'),
          ),
        ],
      ),
    );
    email.dispose();
    if (address == null || !mounted) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      setState(
        () => _error = _ar ? 'أدخل بريداً صحيحاً.' : 'Enter a valid email.',
      );
      return;
    }
    await _run(() async {
      await ref.read(emailAccessProvider).resetPassword(address);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _ar
                  ? 'راجع بريدك للحصول على تعليمات الاسترجاع.'
                  : 'Check your email for recovery instructions.',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.session?.user.id != next.session?.user.id) {
        _photo = null;
        for (final controller in [_name, _phone, _password, _confirm]) {
          controller.clear();
        }
      }
    });
    final session = ref.watch(authControllerProvider).session;
    final setup = session?.user.requiresProfileSetup == true;
    final bool professional =
        widget.professional ?? ref.watch<bool>(professionalEntryProvider);
    final locale = ref.watch(appLocaleProvider);
    final ar = locale.languageCode == 'ar';
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF17191C)
          : const Color(0xFFF6F2EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('btn-back-to-onboarding'),
          icon: Icon(
            ar ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: palette.deepForest,
          ),
          onPressed: _busy
              ? null
              : () async {
                  HapticFeedback.selectionClick();
                  if (setup) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                  if (context.mounted) context.go(AppRoutes.onboarding);
                },
        ),
        title: const FixoBrandMark(showSubtitle: false, iconBoxSize: 28),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: FixoSpacing.sm),
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(appLocaleProvider.notifier).toggleLocale();
              },
              child: Text(
                ar ? 'EN' : 'ع',
                style: FixoTypography.labelMd(
                  color: palette.deepForest,
                  locale: locale,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Luxury Ambient Auroras
          Positioned(
            top: -120,
            right: ar ? null : -100,
            left: ar ? -100 : null,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FixoColors.secondaryForest.withValues(
                      alpha: isDark ? 0.22 : 0.09,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: ar ? null : -80,
            right: ar ? -80 : null,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFC6A779,
                    ).withValues(alpha: isDark ? 0.14 : 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1000;

                if (isDesktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Padding(
                        padding: const EdgeInsets.all(FixoSpacing.xl),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left/Right: Editorial Luxury Showcase
                            Expanded(
                              flex: 5,
                              child: _buildDesktopShowcase(ar, isDark, palette),
                            ),
                            const SizedBox(width: FixoSpacing.xxl),
                            // Right/Left: Suspended Glass Sign-In Card
                            Expanded(
                              flex: 6,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 480,
                                  ),
                                  child: SingleChildScrollView(
                                    child: _buildFormCard(
                                      context: context,
                                      setup: setup,
                                      professional: professional,
                                      ar: ar,
                                      isDark: isDark,
                                      palette: palette,
                                      colors: colors,
                                      locale: locale,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Mobile Layout: Centered Glassmorphic Form Card
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        FixoSpacing.md,
                        FixoSpacing.xs,
                        FixoSpacing.md,
                        FixoSpacing.xl,
                      ),
                      child: _buildFormCard(
                        context: context,
                        setup: setup,
                        professional: professional,
                        ar: ar,
                        isDark: isDark,
                        palette: palette,
                        colors: colors,
                        locale: locale,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopShowcase(
    bool ar,
    bool isDark,
    FixoPaletteExtension palette,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emblem & Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFC6A779).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC6A779).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFC6A779),
              ),
              const SizedBox(width: 6),
              Text(
                ar ? 'خدمات منزلك مع FIXO' : 'Home services with FIXO',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC6A779),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          ar ? 'خدمات منزلك،\nبكل سهولة' : 'Home services,\nmade simple',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.25,
            color: palette.deepForest,
            letterSpacing: ar ? 0 : -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          ar
              ? 'اختار الخدمة والعنوان والموعد المناسب لك، وراجع تفاصيل السعر قبل تأكيد حجزك.'
              : 'Choose your service, address and preferred time, then review the pricing details before confirming your booking.',
          style: TextStyle(fontSize: 16, height: 1.6, color: palette.mutedText),
        ),
        const SizedBox(height: 32),

        // 3 Pillars
        _buildPillarRow(
          icon: Icons.home_repair_service_outlined,
          title: ar ? 'خدمات تناسب منزلك' : 'Services for your home',
          subtitle: ar
              ? 'تصفح الخدمات المتاحة وتفاصيلها'
              : 'Explore available services and their details',
          isDark: isDark,
          palette: palette,
        ),
        const SizedBox(height: 16),
        _buildPillarRow(
          icon: Icons.calendar_month_outlined,
          title: ar ? 'موعد تختاره أنت' : 'A time that works for you',
          subtitle: ar
              ? 'حدد اليوم والساعة عند طلب الخدمة'
              : 'Select your preferred day and time when booking',
          isDark: isDark,
          palette: palette,
        ),
        const SizedBox(height: 16),
        _buildPillarRow(
          icon: Icons.receipt_long_outlined,
          title: ar
              ? 'راجع السعر قبل التأكيد'
              : 'Review pricing before confirmation',
          subtitle: ar
              ? 'تفاصيل الرسوم والإجمالي بالجنيه المصري'
              : 'See the fee breakdown and total in EGP',
          isDark: isDark,
          palette: palette,
        ),
      ],
    );
  }

  Widget _buildPillarRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required FixoPaletteExtension palette,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF292C31) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FixoColors.secondaryForest.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, size: 22, color: FixoColors.secondaryForest),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: palette.inkText,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: palette.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required BuildContext context,
    required bool setup,
    required bool professional,
    required bool ar,
    required bool isDark,
    required FixoPaletteExtension palette,
    required ColorScheme colors,
    required Locale locale,
  }) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Editorial Brand Header
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [FixoColors.primaryForest, Color(0xFF4E4942)],
                ),
                borderRadius: FixoRadius.borderRadiusMd,
                boxShadow: [
                  BoxShadow(
                    color: FixoColors.primaryForest.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.home_repair_service_rounded,
                size: 26,
                color: FixoColors.limeAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            setup
                ? (ar ? 'أكمل حسابك مرة واحدة' : 'Complete your account once')
                : professional
                ? (ar ? 'أهلاً بيك في FIXO للفنيين' : 'Welcome to FIXO Pro')
                : (ar ? 'مرحباً بك في FIXO' : 'Welcome to FIXO'),
            style: FixoTypography.headlineLgMobile(
              color: palette.deepForest,
              locale: locale,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            setup
                ? (ar
                      ? 'أضف اسمك ورقمك واختر كلمة مرور لحسابك.'
                      : 'Add your name, phone number and a password.')
                : (ar
                      ? 'ادخل برقمك وكلمة مرورك. أول مرة؟ اربط حساب جوجل أدناه.'
                      : 'Sign in, or create your account with Google.'),
            style: FixoTypography.bodyMd(
              color: palette.mutedText,
              locale: locale,
            ).copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),

          // Error Banner
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: FixoRadius.borderRadiusMd,
                border: Border.all(color: colors.error.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: colors.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: FixoTypography.bodySm(
                        color: colors.onErrorContainer,
                        locale: locale,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Form Surface Card (VisionOS Liquid Glass Inspired)
          Container(
            padding: const EdgeInsets.all(FixoSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22252A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (setup) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Column(
                      children: [
                        if (_photo != null)
                          ClipOval(
                            child: Image.memory(
                              base64Decode(_photo!.contentBase64),
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.person_outline, size: 64),
                            ),
                          ),
                        OutlinedButton.icon(
                          key: const Key('first-profile-photo'),
                          onPressed: _busy ? null : _pickPhoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            ar
                                ? 'صورة الحساب (اختياري)'
                                : 'Add photo (optional)',
                          ),
                        ),
                        if (_photo != null)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() => _photo = null),
                            child: Text(
                              ar ? 'إزالة الاختيار' : 'Remove selection',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('first-profile-name'),
                    controller: _name,
                    enabled: !_busy,
                    autofillHints: const [AutofillHints.name],
                    maxLength: 100,
                    style: FixoTypography.bodyMd(color: palette.inkText),
                    decoration: InputDecoration(
                      labelText: ar ? 'الاسم' : 'Name',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: palette.mutedText,
                      ),
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? (ar ? 'أدخل اسمك.' : 'Enter your name.')
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],

                // Phone Input
                TextFormField(
                  key: const Key('phone-password-number'),
                  controller: _phone,
                  onChanged: _clearSignInError,
                  enabled: !_busy,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  style: FixoTypography.bodyMd(
                    color: palette.inkText,
                  ).copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: ar
                        ? 'رقم الموبايل المصري'
                        : 'Egyptian Mobile Number',
                    prefixIcon: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        end: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_android_outlined,
                            size: 18,
                            color: palette.mutedText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+20',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: palette.deepForest,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 16,
                            color: palette.subtleBorder,
                          ),
                        ],
                      ),
                    ),
                  ),
                  validator: (v) =>
                      EgyptPhoneValidator.validate(v ?? '', isArabic: ar),
                ),
                const SizedBox(height: 16),

                // Password Input
                TextFormField(
                  key: const Key('phone-password-secret'),
                  controller: _password,
                  onChanged: _clearSignInError,
                  enabled: !_busy,
                  obscureText: _obscure,
                  autofillHints: [
                    setup ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  style: FixoTypography.bodyMd(color: palette.inkText),
                  decoration: InputDecoration(
                    labelText: ar ? 'كلمة مرور FIXO' : 'FIXO password',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: palette.mutedText,
                    ),
                    suffixIcon: IconButton(
                      tooltip: ar
                          ? 'إظهار أو إخفاء كلمة المرور'
                          : 'Show or hide password',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _obscure = !_obscure);
                      },
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return ar ? 'أدخل كلمة المرور.' : 'Enter your password.';
                    }
                    if (setup && v.length < 12) {
                      return ar
                          ? 'كلمة المرور لازم تكون 12 حرفاً على الأقل.'
                          : 'Use at least 12 characters for your password.';
                    }
                    if (v.length > 128) {
                      return ar
                          ? 'كلمة المرور لازم تكون 128 حرفاً أو أقل.'
                          : 'Your password must be 128 characters or fewer.';
                    }
                    return null;
                  },
                ),

                if (setup) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('first-profile-confirm'),
                    controller: _confirm,
                    enabled: !_busy,
                    obscureText: true,
                    style: FixoTypography.bodyMd(color: palette.inkText),
                    decoration: InputDecoration(
                      labelText: ar ? 'تأكيد كلمة المرور' : 'Confirm password',
                      prefixIcon: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: palette.mutedText,
                      ),
                    ),
                    validator: (v) => v != _password.text
                        ? (ar
                              ? 'كلمتا المرور غير متطابقتين.'
                              : 'Passwords do not match.')
                        : null,
                  ),
                ],
                const SizedBox(height: 22),

                // Submit Button
                ElevatedButton(
                  key: const Key('phone-password-submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FixoColors.primaryForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _busy
                      ? null
                      : () {
                          if (!_form.currentState!.validate()) return;
                          _run(() async {
                            final access = ref.read(emailAccessProvider);
                            final phone = EgyptPhoneValidator.tryNormalize(
                              _phone.text,
                            )!;
                            if (setup) {
                              var user = await access.completePhoneProfile(
                                _name.text,
                                phone,
                                _password.text,
                              );
                              bool photoFailed = false;
                              if (_photo != null) {
                                try {
                                  final version = await ref
                                      .read(avatarRepositoryProvider)
                                      .upload(_photo!);
                                  user = user.withAvatar(version);
                                } catch (_) {
                                  photoFailed = true;
                                }
                              }
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .acceptUpdatedProfile(user);
                              if (context.mounted) {
                                if (photoFailed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ar
                                            ? 'حسابك جاهز. تقدر تضيف صورتك بعدين من البروفايل.'
                                            : 'Your account is ready. Add your photo later from Profile.',
                                      ),
                                    ),
                                  );
                                }
                                context.go(_destination);
                              }
                            } else {
                              await _accept(
                                await access.signInWithPhone(
                                  phone,
                                  _password.text,
                                ),
                              );
                            }
                          });
                        },
                  child: _busy
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(ar ? 'جارٍ المتابعة...' : 'Please wait...'),
                          ],
                        )
                      : Text(
                          setup
                              ? (ar ? 'حفظ ومتابعة' : 'Save and continue')
                              : (ar ? 'تسجيل الدخول' : 'Sign in'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),

                if (!setup) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : _recover,
                    child: Text(
                      ar ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                      style: TextStyle(
                        color: FixoColors.secondaryForest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            height: 1,
                            color: palette.subtleBorder,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            ar ? 'أو' : 'OR',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            height: 1,
                            color: palette.subtleBorder,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Google Button (Apple-quality Frosted White)
                  GoogleSignInButton(
                    buttonKey: const Key('first-use-google'),
                    isArabic: ar,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.14),
                      ),
                    ),
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            final value = await ref
                                .read(emailAccessProvider)
                                .signInWithGoogle();
                            if (value == null) {
                              throw StateError(
                                'Verified Google identity required.',
                              );
                            }
                            await _accept(value);
                          }),
                    label: Text(
                      ar
                          ? 'أول مرة؟ تابع بحساب Google'
                          : 'First time? Continue with Google',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: FixoSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('first-use-email'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _busy
                        ? null
                        : () => context.push(
                            '${AppRoutes.phoneAuth}?method=email${_professional ? '&account=pro' : ''}',
                          ),
                    icon: const Icon(Icons.mail_outline_rounded, size: 20),
                    label: Text(
                      ar
                          ? 'الدخول أو التسجيل بالبريد الإلكتروني'
                          : 'Continue with email & password',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (appleSignInAvailable) ...[
                    const SizedBox(height: FixoSpacing.sm),
                    OutlinedButton.icon(
                      key: const Key('first-use-apple'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.black
                            : const Color(0xFF161616),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              final value = await ref
                                  .read(emailAccessProvider)
                                  .promptAndSignInWithApple(
                                    context,
                                    isArabic: ar,
                                  );
                              if (value == null) return;
                              await _accept(value);
                            }),
                      icon: const Icon(Icons.apple_rounded, size: 22),
                      label: Text(
                        ar ? 'المتابعة بحساب Apple' : 'Continue with Apple',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                          ),
                    child: Text(
                      ar ? 'استخدام حساب آخر' : 'Use a different account',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
