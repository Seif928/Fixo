import 'package:flutter/foundation.dart';
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
import '../../../../core/widgets/fixo_buttons.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../../../core/widgets/fixo_inputs.dart';
import '../../data/email_access_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/phone_auth_widgets.dart';

/// Native Flutter implementation of live Stitch Screen 02 (`02 — Phone Auth & OTP`,
/// ID `2f0c722b3ccc4030ac95264aaf5df667`).
class PhoneAuthPage extends ConsumerStatefulWidget {
  const PhoneAuthPage({super.key, this.entryIntent = 'signup'});

  final String entryIntent;

  @override
  ConsumerState<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends ConsumerState<PhoneAuthPage> {
  late final TextEditingController _phoneTextController;
  late final TextEditingController _otpHiddenController;
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialAuth = ref.read(authControllerProvider);
    _phoneTextController = TextEditingController(text: initialAuth.phoneInput);
    _otpHiddenController = TextEditingController(text: initialAuth.otpCode);
  }

  @override
  void dispose() {
    _phoneTextController.dispose();
    _otpHiddenController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final locale = ref.watch(appLocaleProvider);
    final isArabic = locale.languageCode == 'ar';
    final palette = context.fixoPalette;

    // Keep text controllers synced when state changes externally (e.g. clear button or keypad)
    if (_phoneTextController.text != authState.phoneInput) {
      _phoneTextController.value = TextEditingValue(
        text: authState.phoneInput,
        selection: TextSelection.collapsed(offset: authState.phoneInput.length),
      );
    }
    if (_otpHiddenController.text != authState.otpCode) {
      _otpHiddenController.value = TextEditingValue(
        text: authState.otpCode,
        selection: TextSelection.collapsed(offset: authState.otpCode.length),
      );
    }

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                FixoSpacing.md,
                FixoSpacing.md,
                FixoSpacing.md,
                FixoSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back & Locale/Theme Utility Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        key: const Key('btn-back-to-onboarding'),
                        tooltip: isArabic
                            ? 'العودة إلى البداية'
                            : 'Back to Onboarding',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.onboarding);
                          }
                        },
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: palette.deepForest,
                        ),
                      ),
                      Flexible(
                        child: PhoneAuthStepSwitcher(
                          activeStep: authState.step,
                          onStepSelected: authNotifier.switchStep,
                          isArabic: isArabic,
                        ),
                      ),
                      TextButton(
                        key: const Key('btn-auth-toggle-locale'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () =>
                            ref.read(appLocaleProvider.notifier).toggleLocale(),
                        child: Text(
                          isArabic ? 'EN' : 'ع',
                          style: FixoTypography.labelMd(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const Key('auth-use-email-google'),
                    onPressed: () =>
                        context.go('${AppRoutes.phoneAuth}?method=email'),
                    icon: Image.asset(
                      'assets/brand/google-g.png',
                      width: 18,
                      height: 18,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                    label: Text(
                      isArabic
                          ? 'الدخول بالبريد أو Google'
                          : 'Continue with email or Google',
                    ),
                  ),
                  if (appleSignInAvailable) ...[
                    const SizedBox(height: FixoSpacing.sm),
                    OutlinedButton.icon(
                      key: const Key('auth-use-apple'),
                      onPressed: () async {
                        final session = await ref
                            .read(emailAccessProvider)
                            .promptAndSignInWithApple(
                              context,
                              isArabic: isArabic,
                            );
                        if (session != null && context.mounted) {
                          await authNotifier.acceptVerifiedSession(session);
                          if (context.mounted) {
                            context.go(AppRoutes.customerHome);
                          }
                        }
                      },
                      icon: const Icon(Icons.apple_rounded, size: 22),
                      label: Text(
                        isArabic
                            ? 'المتابعة بحساب Apple'
                            : 'Continue with Apple',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Editorial Brand Header
                  Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: palette.primaryBrand,
                          borderRadius: FixoRadius.borderRadiusMd,
                          boxShadow: FixoShadows.level1CardResting,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.home_repair_service_rounded,
                          size: 26,
                          color: palette.limeAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? 'مرحباً بك في فيكسو' : 'Welcome to FIXO',
                        textAlign: TextAlign.center,
                        style: FixoTypography.headlineLgMobile(
                          color: palette.inkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: Text(
                          isArabic
                              ? 'أدخل رقم الموبايل المصري لتسجيل الدخول أو إنشاء حساب.'
                              : 'Enter your Egyptian mobile number to sign in or register.',
                          textAlign: TextAlign.center,
                          style: FixoTypography.bodyMd(
                            color: palette.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  if (authState.errorMessage != null) ...[
                    Container(
                      key: const Key('auth-error-banner'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: FixoColors.errorContainer,
                        borderRadius: FixoRadius.borderRadiusMd,
                        border: Border.all(
                          color: FixoColors.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: FixoColors.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: FixoTypography.bodySm(
                                color: FixoColors.onErrorContainer,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FixoSpacing.md),
                  ],

                  if (authState.step == PhoneAuthStep.phoneInput)
                    _buildPhoneInputState(
                      context,
                      authState: authState,
                      authNotifier: authNotifier,
                      isArabic: isArabic,
                      palette: palette,
                    )
                  else
                    _buildOtpVerificationState(
                      context,
                      authState: authState,
                      authNotifier: authNotifier,
                      isArabic: isArabic,
                      palette: palette,
                    ),

                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      isArabic
                          ? 'بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بـ FIXO.'
                          : "By continuing, you agree to FIXO's Terms of Service and Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: FixoTypography.bodySm(color: FixoColors.outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputState(
    BuildContext context, {
    required AuthState authState,
    required AuthController authNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    return Column(
      key: const Key('section-phone-input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FixoSurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FixoEgyptPhoneField(
                key: const Key('field-egypt-phone'),
                controller: _phoneTextController,
                label: isArabic
                    ? 'رقم الموبايل المصري'
                    : 'Egyptian Mobile Number',
                hintText: '010 2345 6789',
                onChanged: authNotifier.updatePhoneInput,
                onClear: authState.phoneInput.isNotEmpty
                    ? authNotifier.clearPhoneInput
                    : null,
              ),
              const SizedBox(height: FixoSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceLow,
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: FixoColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isArabic ? 'رمز SMS فوري' : 'Instant SMS code',
                            style: FixoTypography.bodySm(
                              color: FixoColors.secondary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '•',
                      style: FixoTypography.bodySm(color: FixoColors.outline),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_reset_rounded,
                          size: 16,
                          color: FixoColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isArabic
                                ? 'بدون كلمة مرور'
                                : 'No password required',
                            style: FixoTypography.bodySm(
                              color: FixoColors.secondary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FixoPrimaryButton(
          key: const Key('btn-continue-phone'),
          label: isArabic ? 'متابعة' : 'Continue',
          trailingIcon: Icons.arrow_forward_rounded,
          isLoading: authState.isLoading,
          onPressed: () async {
            await authNotifier.requestOtp(isArabic: isArabic);
          },
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceLow,
            borderRadius: FixoRadius.borderRadiusMd,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.surfaceHighest,
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: palette.deepForest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'تغطية القاهرة والجيزة'
                          : 'Cairo & Giza Coverage',
                      style: FixoTypography.labelMd(
                        color: palette.inkText,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'المعادي • الزمالك • القاهرة الجديدة • الشيخ زايد'
                          : 'Maadi • Zamalek • New Cairo • Sheikh Zayed',
                      style: FixoTypography.bodySm(color: palette.mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        CairoLifestyleMoodAnchorCard(isArabic: isArabic),
      ],
    );
  }

  Widget _buildOtpVerificationState(
    BuildContext context, {
    required AuthState authState,
    required AuthController authNotifier,
    required bool isArabic,
    required FixoPaletteExtension palette,
  }) {
    final canResend = authState.resendCountdownSec == 0 && !authState.isLoading;

    return Column(
      key: const Key('section-otp-code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FixoSurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic ? 'رمز التحقق' : 'Verification Code',
                style: FixoTypography.labelMd(
                  color: palette.mutedText,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  RichText(
                    text: TextSpan(
                      style: FixoTypography.bodyMd(color: palette.inkText),
                      children: [
                        TextSpan(
                          text: isArabic
                              ? 'تم إرسال الرمز المكون من 6 أرقام إلى '
                              : 'Sent 6-digit code to ',
                        ),
                        TextSpan(
                          text: authState.formattedPhoneForDisplay,
                          style: FixoTypography.bodyMd(
                            color: palette.deepForest,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: palette.surfaceLow,
                    borderRadius: FixoRadius.borderRadiusSm,
                    child: InkWell(
                      key: const Key('btn-edit-phone'),
                      onTap: () =>
                          authNotifier.switchStep(PhoneAuthStep.phoneInput),
                      borderRadius: FixoRadius.borderRadiusSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: palette.primaryBrand,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isArabic ? 'تعديل' : 'Edit',
                              style: FixoTypography.labelMd(
                                color: palette.primaryBrand,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (kDebugMode) ...[
                Container(
                  key: const Key('banner-demo-otp-hint'),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceLow,
                    borderRadius: FixoRadius.borderRadiusSm,
                    border: Border.all(
                      color: palette.limeAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        size: 16,
                        color: palette.primaryBrand,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'رمز الدخول التجريبي: 482910'
                              : 'Demo OTP Code: 482910',
                          style: FixoTypography.labelMd(
                            color: palette.primaryBrand,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Accessible hidden text field for direct keyboard / test input
              SizedBox(
                height: 1,
                child: Opacity(
                  opacity: 0.0,
                  child: TextField(
                    key: const Key('otp-hidden-input'),
                    controller: _otpHiddenController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: authNotifier.setOtpCode,
                  ),
                ),
              ),

              FixoOtpDigitRow(
                otpCode: authState.otpCode,
                onTap: () => _otpFocusNode.requestFocus(),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: FixoColors.outline,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: RichText(
                            key: const Key('otp-resend-countdown-label'),
                            text: TextSpan(
                              style: FixoTypography.labelMd(
                                color: palette.mutedText,
                              ),
                              children: [
                                TextSpan(
                                  text: isArabic
                                      ? 'إعادة الإرسال خلال '
                                      : 'Resend code in ',
                                ),
                                TextSpan(
                                  text: _formatCountdown(
                                    authState.resendCountdownSec,
                                  ),
                                  style: FixoTypography.labelMd(
                                    color: palette.inkText,
                                    tabularFigures: true,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('btn-resend-otp'),
                    onPressed: canResend
                        ? () => authNotifier.resendOtp(isArabic: isArabic)
                        : null,
                    child: Text(
                      isArabic ? 'إعادة إرسال SMS' : 'Resend SMS',
                      style: FixoTypography.labelMd(
                        color: canResend
                            ? palette.primaryBrand
                            : FixoColors.outline.withValues(alpha: 0.6),
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Trust Badge Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surfaceHigh,
            borderRadius: FixoRadius.borderRadiusMd,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: FixoColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isArabic
                          ? 'تحقق رمز الدخول التجريبي'
                          : 'Development OTP verification',
                      style: FixoTypography.bodySm(
                        color: palette.mutedText,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Text(
                '•',
                style: FixoTypography.bodySm(color: FixoColors.outline),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home_repair_service_outlined,
                    size: 16,
                    color: FixoColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isArabic
                          ? 'خدمات منزلية في القاهرة والجيزة'
                          : 'Cairo & Giza Home Services',
                      style: FixoTypography.bodySm(
                        color: palette.mutedText,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // High-Energy Lime Verification CTA
        FixoAccentButton(
          key: const Key('btn-verify-otp'),
          label: authState.isLoading
              ? (isArabic ? 'جارٍ التحقق...' : 'Verifying...')
              : (isArabic
                    ? 'تأكيد الرمز والدخول للحساب'
                    : 'Verify & Access Account'),
          leadingIcon: Icons.check_circle_outline_rounded,
          onPressed: authState.isLoading
              ? null
              : () async {
                  final verified = await authNotifier.verifyOtp(
                    isArabic: isArabic,
                  );
                  if (verified && context.mounted) {
                    context.go(AppRoutes.customerHome);
                  }
                },
        ),
        const SizedBox(height: 14),

        // Tactile 3x4 Numeric Keypad
        FixoNumericKeypad(
          onDigitPressed: authNotifier.appendOtpDigit,
          onBackspacePressed: authNotifier.backspaceOtpDigit,
        ),
      ],
    );
  }
}
