import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_locale_controller.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_brand_mark.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../data/email_access_service.dart';
import '../../domain/auth_models.dart';
import '../controllers/auth_controller.dart';

/// Email variant of approved Screen 02, retaining the native FIXO auth layout.
class EmailAuthPage extends ConsumerStatefulWidget {
  const EmailAuthPage({super.key});
  @override
  ConsumerState<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends ConsumerState<EmailAuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _create = false, _busy = false, _verify = false, _hidden = true;
  String? _error, _notice;
  bool get _ar => ref.read(appLocaleProvider).languageCode == 'ar';
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _message(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return _ar
              ? 'البريد مستخدم بالفعل. سجّل الدخول أو استعد كلمة المرور.'
              : 'Email already registered. Sign in or reset your password.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return _ar ? 'بيانات الدخول غير صحيحة.' : 'Invalid sign-in details.';
        case 'too-many-requests':
          return _ar
              ? 'محاولات كثيرة. انتظر ثم حاول مجددًا.'
              : 'Too many attempts. Wait before retrying.';
        case 'weak-password':
          return _ar ? 'اختر كلمة مرور أقوى.' : 'Choose a stronger password.';
        case 'operation-not-allowed':
          return _ar
              ? 'طريقة الدخول غير مفعلة حاليًا.'
              : 'This sign-in method is not enabled.';
      }
    }
    if (error is DioException && error.response?.statusCode == 409) {
      return _ar
          ? 'البريد مرتبط بحساب سابق؛ يلزم تسجيل الدخول بالطريقة الأصلية لربطه.'
          : 'This email belongs to an existing account. Sign in using the original method to link it.';
    }
    return _ar
        ? 'تعذر إكمال الطلب. تحقق من الاتصال وحاول مرة أخرى.'
        : 'Could not complete the request. Check your connection and retry.';
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(AuthSession? session) async {
    if (!mounted) return;
    if (session == null) {
      setState(() => _verify = true);
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .acceptVerifiedSession(session);
    if (mounted) context.go('/customer/home');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final ar = locale.languageCode == 'ar';
    final palette = context.fixoPalette;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        backgroundColor: palette.canvasBackground,
        elevation: 0,
        leading: IconButton(
          tooltip: ar ? 'العودة لتسجيل الموبايل' : 'Back to Phone Sign-In',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.phoneAuth);
            }
          },
          icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
        ),
        title: const FixoBrandMark(showSubtitle: false, iconBoxSize: 30),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(appLocaleProvider.notifier).toggleLocale(),
            child: Text(
              ar ? 'EN' : 'ع',
              style: FixoTypography.labelMd(
                color: palette.deepForest,
                locale: locale,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                FixoSpacing.md,
                FixoSpacing.sm,
                FixoSpacing.md,
                FixoSpacing.lg,
              ),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Editorial Brand Header (Stitch Screen 02)
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
                            Icons.home_repair_service_outlined,
                            size: 26,
                            color: palette.limeAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ar ? 'أهلًا بك في FIXO' : 'Welcome to FIXO',
                          textAlign: TextAlign.center,
                          style: FixoTypography.headlineLgMobile(
                            color: palette.inkText,
                            locale: locale,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            ar
                                ? 'ادخل ببريد مؤكد. لا تتم مشاركة كلمة مرورك مع FIXO.'
                                : 'Sign in with a verified email. FIXO does not receive your password.',
                            textAlign: TextAlign.center,
                            style: FixoTypography.bodyMd(
                              color: palette.mutedText,
                              locale: locale,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: FixoRadius.borderRadiusMd,
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: FixoTypography.bodySm(
                                  color: colorScheme.onErrorContainer,
                                  locale: locale,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_notice != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceHigh,
                          borderRadius: FixoRadius.borderRadiusMd,
                          border: Border.all(color: palette.subtleBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: palette.deepForest,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _notice!,
                                style: FixoTypography.bodySm(
                                  color: palette.inkText,
                                  locale: locale,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                    FixoSurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_verify) ...[
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: palette.surfaceHigh,
                                    borderRadius: FixoRadius.borderRadiusSm,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 20,
                                    color: palette.deepForest,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ar
                                        ? 'افتح رسالة التأكيد في بريدك، ثم ارجع واضغط تم التأكيد.'
                                        : 'Open the verification email, then return and select “I verified my email”.',
                                    style: FixoTypography.bodyMd(
                                      color: palette.inkText,
                                      locale: locale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        final session = await ref
                                            .read(emailAccessProvider)
                                            .checkVerification();
                                        if (session == null && mounted) {
                                          setState(
                                            () => _error = ar
                                                ? 'البريد لم يتأكد بعد.'
                                                : 'Email is not verified yet.',
                                          );
                                          return;
                                        }
                                        await _accept(session);
                                      }),
                              child: Text(
                                ar ? 'تم تأكيد بريدي' : 'I verified my email',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        await ref
                                            .read(emailAccessProvider)
                                            .resendVerification();
                                        if (mounted) {
                                          setState(
                                            () => _notice = ar
                                                ? 'تم إرسال طلب التأكيد.'
                                                : 'Verification email requested.',
                                          );
                                        }
                                      }),
                              child: Text(
                                ar
                                    ? 'إعادة إرسال التأكيد'
                                    : 'Resend verification',
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() => _verify = false),
                              child: Text(
                                ar
                                    ? 'استخدام حساب آخر'
                                    : 'Use a different account',
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              key: const Key('email-use-google'),
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        await _accept(
                                          await ref
                                              .read(emailAccessProvider)
                                              .signInWithGoogle(),
                                        );
                                      }),
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                              label: Text(
                                ar
                                    ? 'المتابعة بحساب Google'
                                    : 'Continue with Google',
                              ),
                            ),
                            const SizedBox(height: FixoSpacing.sm),
                            OutlinedButton.icon(
                              key: const Key('email-use-apple'),
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        final session = await ref
                                            .read(emailAccessProvider)
                                            .promptAndSignInWithApple(
                                              context,
                                              isArabic: ar,
                                            );
                                        if (session == null) return;
                                        await _accept(session);
                                      }),
                              icon: const Icon(Icons.apple_rounded, size: 22),
                              label: Text(
                                ar
                                    ? 'المتابعة بحساب Apple'
                                    : 'Continue with Apple',
                              ),
                            ),
                            const SizedBox(height: FixoSpacing.md),
                            TextFormField(
                              key: const Key('email-sign-in-address'),
                              controller: _email,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText:
                                    ar ? 'البريد الإلكتروني' : 'Email',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                  color: palette.mutedText,
                                ),
                              ),
                              validator: (value) =>
                                  value == null ||
                                          !RegExp(
                                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                          ).hasMatch(value.trim())
                                      ? (ar
                                          ? 'أدخل بريدًا صحيحًا.'
                                          : 'Enter a valid email.')
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('email-sign-in-password'),
                              controller: _password,
                              enabled: !_busy,
                              obscureText: _hidden,
                              autofillHints: [
                                _create
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: ar ? 'كلمة المرور' : 'Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: palette.mutedText,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: ar
                                      ? 'إظهار أو إخفاء كلمة المرور'
                                      : 'Show or hide password',
                                  onPressed: () =>
                                      setState(() => _hidden = !_hidden),
                                  icon: Icon(
                                    _hidden
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null ||
                                          value.isEmpty ||
                                          (_create && value.length < 12)
                                      ? (ar
                                          ? 'أدخل كلمة المرور؛ للحساب الجديد 12 حرفًا على الأقل.'
                                          : 'Enter your password; new accounts require at least 12 characters.')
                                      : null,
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              key: const Key('email-sign-in-submit'),
                              onPressed: _busy
                                  ? null
                                  : () {
                                      if (_form.currentState!.validate()) {
                                        _run(() async {
                                          await _accept(
                                            await ref
                                                .read(emailAccessProvider)
                                                .signIn(
                                                  _email.text,
                                                  _password.text,
                                                  create: _create,
                                                ),
                                          );
                                        });
                                      }
                                    },
                              child: Text(
                                _busy
                                    ? (ar ? 'جارٍ التنفيذ…' : 'Please wait…')
                                    : _create
                                        ? (ar
                                            ? 'إنشاء الحساب'
                                            : 'Create account')
                                        : (ar ? 'تسجيل الدخول' : 'Sign in'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _create = !_create;
                                        _error = null;
                                      }),
                              child: Text(
                                _create
                                    ? (ar
                                        ? 'لدي حساب بالفعل'
                                        : 'I already have an account')
                                    : (ar
                                        ? 'إنشاء حساب جديد'
                                        : 'Create an account'),
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        if (_email.text.trim().isEmpty) {
                                          setState(
                                            () => _error = ar
                                                ? 'أدخل البريد أولًا.'
                                                : 'Enter your email first.',
                                          );
                                          return;
                                        }
                                        await ref
                                            .read(emailAccessProvider)
                                            .resetPassword(_email.text);
                                        if (mounted) {
                                          setState(
                                            () => _notice = ar
                                                ? 'راجع بريدك لاستعادة كلمة المرور.'
                                                : 'Check your email for password recovery.',
                                          );
                                        }
                                      }),
                              child: Text(
                                ar ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stitch Screen 02 Trust Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceLow,
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
                                Icons.verified_user_outlined,
                                size: 16,
                                color: FixoColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  ar ? 'بريد إلكتروني مؤكد' : 'Verified Email Auth',
                                  style: FixoTypography.bodySm(
                                    color: palette.mutedText,
                                    locale: locale,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '•',
                            style: FixoTypography.bodySm(
                              color: FixoColors.outline,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.support_agent_rounded,
                                size: 16,
                                color: FixoColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  ar ? 'دعم القاهرة والجيزة' : 'Cairo & Giza Support',
                                  style: FixoTypography.bodySm(
                                    color: palette.mutedText,
                                    locale: locale,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        ar
                            ? 'بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بـ FIXO.'
                            : "By continuing, you agree to FIXO's Terms of Service and Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: FixoTypography.bodySm(
                          color: palette.mutedText,
                          locale: locale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
