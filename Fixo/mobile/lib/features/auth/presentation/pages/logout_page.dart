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
import '../controllers/auth_controller.dart';
import '../../../profile/presentation/profile_avatar.dart';

/// Premium Luxury Logout & Session Security Page.
///
/// Provides a secure, high-end experience for signing out, reviewing
/// active session safety, or switching accounts with VisionOS styling.
class LogoutPage extends ConsumerStatefulWidget {
  const LogoutPage({super.key});

  @override
  ConsumerState<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends ConsumerState<LogoutPage>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  bool _signedOutSuccess = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _busy = false;
        _signedOutSuccess = true;
      });
      _animController.reset();
      _animController.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _handleSwitchAccount() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go(AppRoutes.phoneAuth);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final ar = locale.languageCode == 'ar';
    final palette = context.fixoPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.session?.user;
    final isPro = user?.role == 'PRO';

    final effectiveUser = user;
    final isActuallyAuthed = authState.isAuthenticated && !_signedOutSuccess;

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('btn-logout-back'),
          icon: Icon(
            ar ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: palette.deepForest,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.customerHome);
            }
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
          // Background Luxury Ambient Glows
          Positioned(
            top: -100,
            right: ar ? null : -80,
            left: ar ? -80 : null,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.primaryBrand.withValues(
                      alpha: isDark ? 0.14 : 0.08,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: ar ? null : -60,
            right: ar ? -60 : null,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFC6A779,
                    ).withValues(alpha: isDark ? 0.12 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FixoSpacing.md,
                    vertical: FixoSpacing.lg,
                  ),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _signedOutSuccess
                        ? _buildSignedOutSuccessView(
                            context,
                            ar,
                            isDark,
                            palette,
                          )
                        : _buildConfirmSignOutView(
                            context,
                            ar,
                            isDark,
                            palette,
                            effectiveUser,
                            isActuallyAuthed,
                            isPro,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmSignOutView(
    BuildContext context,
    bool ar,
    bool isDark,
    FixoPaletteExtension palette,
    dynamic user,
    bool isAuthed,
    bool isPro,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Security Emblem
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.cardSurface,
              border: Border.all(
                color: palette.primaryBrand.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: FixoShadows.level1CardResting,
            ),
            child: Icon(
              Icons.lock_person_outlined,
              size: 36,
              color: palette.primaryBrand,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Title & Description
        Text(
          ar ? 'تأكيد تسجيل الخروج' : 'Secure Sign Out',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.deepForest,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ar
              ? 'هل ترغب في تسجيل الخروج من جلستك الحالية؟ ستبقى جميع طلباتك وعناوينك وتفضيلاتك محفوظة بأمان.'
              : 'Sign out? Your bookings and saved addresses will stay in your account.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: palette.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Active Session Card
        if (isAuthed && user != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.subtleBorder),
              boxShadow: FixoShadows.level1CardResting,
            ),
            child: Row(
              children: [
                // Avatar
                ProfileAvatar(
                  userId: user.id ?? 'user-id',
                  version: user.avatarVersion,
                  hasAvatar: user.avatarVersion != null,
                  size: 56,
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              (user.fullName != null &&
                                      user.fullName!.isNotEmpty)
                                  ? user.fullName!
                                  : (ar
                                        ? 'عميل فيكسو المميز'
                                        : 'Valued Customer'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.inkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPro
                                  ? (ar ? 'فني معتمد' : 'Pro')
                                  : (ar ? 'عميل' : 'Customer'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: palette.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (user.phone != null && user.phone!.isNotEmpty)
                            ? user.phone!
                            : (ar ? 'رقم الهاتف محمي' : 'Protected phone'),
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Trust Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.subtleBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: palette.success,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ar
                      ? 'يمكنك الدخول مجدداً لمتابعة طلباتك'
                      : 'Sign in again to continue your bookings',
                  style: textTheme.labelSmall?.copyWith(
                    color: palette.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action 1: Confirm Sign Out (Primary Red/Gold)
        ElevatedButton.icon(
          key: const Key('confirm-sign-out-btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
          ),
          onPressed: _busy ? null : _handleSignOut,
          icon: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.logout_rounded, size: 20),
          label: Text(
            _busy
                ? (ar ? 'جارٍ تسجيل الخروج...' : 'Signing out...')
                : (ar ? 'تسجيل الخروج الآمن' : 'Confirm Secure Sign Out'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),

        // Action 2: Switch Account
        OutlinedButton.icon(
          key: const Key('switch-account-btn'),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.deepForest,
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _busy ? null : _handleSwitchAccount,
          icon: const Icon(Icons.switch_account_rounded, size: 20),
          label: Text(
            ar ? 'تبديل الحساب' : 'Switch Account',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        const SizedBox(height: 12),

        // Action 3: Cancel & Stay Signed In
        TextButton(
          key: const Key('cancel-logout-btn'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            foregroundColor: palette.mutedText,
          ),
          onPressed: _busy
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.customerHome);
                  }
                },
          child: Text(
            ar ? 'إلغاء والعودة للرئيسية' : 'Cancel & Return Home',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSignedOutSuccessView(
    BuildContext context,
    bool ar,
    bool isDark,
    FixoPaletteExtension palette,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.successContainer,
              border: Border.all(color: palette.success, width: 2),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 46,
              color: palette.success,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          ar ? 'تم تسجيل الخروج بنجاح' : 'Successfully Signed Out',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.deepForest,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'شكراً لاستخدامك فيكسو مصر. تم تأمين جلستك وحفظ سجلاتك بنجاح. نتطلع لخدمتك مجدداً في أقرب وقت!'
              : 'Thank you for choosing FIXO Egypt. Your session is closed and your data is safe. We look forward to serving you again soon!',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: palette.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Sign In Button
        ElevatedButton.icon(
          key: const Key('post-logout-signin-btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primaryBrand,
            foregroundColor: palette.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go(AppRoutes.phoneAuth);
          },
          icon: const Icon(Icons.login_rounded, size: 20),
          label: Text(
            ar ? 'تسجيل الدخول مجدداً' : 'Sign In Again',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),

        // Explore Home Button
        OutlinedButton.icon(
          key: const Key('post-logout-explore-btn'),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.deepForest,
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.go(AppRoutes.customerHome);
          },
          icon: const Icon(Icons.home_outlined, size: 20),
          label: Text(
            ar ? 'تصفح الخدمات كزائر' : 'Explore Services as Guest',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
