import 'dart:convert';
import 'package:dio/dio.dart';
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
import '../controllers/account_entry_controller.dart';
import '../../../../core/uploads/private_media_picker_sheet.dart';
import '../../../profile/data/avatar_repository.dart';

/// Screen 02: Google first registration, phone/password for subsequent sign-in.
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      String message;
      if (error is DioException && error.response?.statusCode == 401) {
        message = error.requestOptions.path == '/auth/phone-password'
            ? (_ar
                  ? 'رقم الموبايل أو كلمة المرور غير صحيحة. راجعهم أو استخدم «نسيت كلمة المرور؟».'
                  : 'Incorrect phone number or password. Check both or use "Forgot password?".')
            : (_ar
                  ? 'تعذّر التحقق من تسجيل الدخول. تابع بحساب جوجل وحاول مرة أخرى.'
                  : 'Your sign-in could not be verified. Continue with Google and try again.');
      } else if (error is DioException && error.response?.statusCode == 409) {
        message = error.requestOptions.path == '/auth/firebase/session'
            ? (_ar
                  ? 'البريد ده مرتبط بطريقة دخول تانية. استخدم حسابك الأصلي للمتابعة.'
                  : 'This Google email already uses another sign-in method. Use the original account to continue.')
            : (_ar
                  ? 'تعذّر استخدام هذا الرقم لهذا الحساب. جرّب رقمك الآخر أو حسابك الأصلي.'
                  : 'This phone cannot be used for this account. Use your other number or original account.');
      } else {
        message = _ar
            ? 'تعذّر إكمال الطلب. تحقق من الاتصال وحاول مرة أخرى.'
            : 'Could not complete the request. Check your connection and retry.';
      }
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        backgroundColor: palette.canvasBackground,
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
                FixoSpacing.xl,
              ),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Stitch Screen 02 Editorial Brand Header
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: FixoColors.primaryForest,
                          borderRadius: FixoRadius.borderRadiusMd,
                          boxShadow: FixoShadows.level1CardResting,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.home_repair_service_rounded,
                          size: 24,
                          color: FixoColors.limeAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      setup
                          ? (ar
                                ? 'أكمل حسابك مرة واحدة'
                                : 'Complete your account once')
                          : professional
                          ? (ar
                                ? 'أهلاً بيك في FIXO للفنيين'
                                : 'Welcome to FIXO Pro')
                          : (ar ? 'مرحباً بك في FIXO' : 'Welcome to FIXO'),
                      style: FixoTypography.headlineLgMobile(
                        color: palette.deepForest,
                        locale: locale,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      setup
                          ? (ar
                                ? 'احفظ اسمك ورقمك واختر كلمة مرور FIXO. الرقم سيكون اسم الدخول، بدون رسائل SMS.'
                                : 'Save your name and phone and choose a FIXO password. Your phone is your sign-in name, without SMS.')
                          : (ar
                                ? 'ادخل برقمك وكلمة مرورك. أول مرة؟ اربط حساب جوجل أدناه.'
                                : 'Sign in with your phone and password. First time? Connect Google below.'),
                      style: FixoTypography.bodyMd(
                        color: palette.mutedText,
                        locale: locale,
                      ).copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 16),

                    // Segmented Step / Mode Indicator Pill (Screen 02 consistency)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        key: const Key('tab-phone-input'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceHigh,
                          borderRadius: FixoRadius.borderRadiusPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              setup
                                  ? Icons.verified_user_outlined
                                  : Icons.phone_android_rounded,
                              size: 15,
                              color: palette.deepForest,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                setup
                                    ? (ar
                                          ? 'تأكيد بيانات الحساب'
                                          : 'Account Profile Setup')
                                    : (ar
                                          ? 'الدخول برقم الموبايل وكلمة المرور'
                                          : 'Phone & Password Access'),
                                style: FixoTypography.labelMd(
                                  color: palette.deepForest,
                                  locale: locale,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error Banner
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: FixoRadius.borderRadiusMd,
                          border: Border.all(
                            color: colors.error.withValues(alpha: 0.35),
                          ),
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

                    // 2. Form Surface Card
                    FixoSurfaceCard(
                      padding: const EdgeInsets.all(FixoSpacing.md),
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
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person_outline,
                                          size: 64,
                                        ),
                                      ),
                                    ),
                                  OutlinedButton.icon(
                                    key: const Key('first-profile-photo'),
                                    onPressed: _busy ? null : _pickPhoto,
                                    icon: const Icon(
                                      Icons.add_a_photo_outlined,
                                    ),
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
                                        ar
                                            ? 'إزالة الاختيار'
                                            : 'Remove selection',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('first-profile-name'),
                              controller: _name,
                              enabled: !_busy,
                              autofillHints: const [AutofillHints.name],
                              maxLength: 100,
                              style: FixoTypography.bodyMd(
                                color: palette.inkText,
                              ),
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
                          TextFormField(
                            key: const Key('phone-password-number'),
                            controller: _phone,
                            onChanged: _clearSignInError,
                            enabled: !_busy,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            style: FixoTypography.bodyMd(
                              color: palette.inkText,
                            ).copyWith(fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: ar
                                  ? 'رقم الموبايل المصري'
                                  : 'Egyptian Mobile Number',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                size: 20,
                                color: palette.mutedText,
                              ),
                            ),
                            validator: (v) => EgyptPhoneValidator.validate(
                              v ?? '',
                              isArabic: ar,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('phone-password-secret'),
                            controller: _password,
                            onChanged: _clearSignInError,
                            enabled: !_busy,
                            obscureText: _obscure,
                            autofillHints: [
                              setup
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            style: FixoTypography.bodyMd(
                              color: palette.inkText,
                            ),
                            decoration: InputDecoration(
                              labelText: ar
                                  ? 'كلمة مرور FIXO'
                                  : 'FIXO password',
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
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return ar
                                    ? 'أدخل كلمة المرور.'
                                    : 'Enter your password.';
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
                              style: FixoTypography.bodyMd(
                                color: palette.inkText,
                              ),
                              decoration: InputDecoration(
                                labelText: ar
                                    ? 'تأكيد كلمة المرور'
                                    : 'Confirm password',
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
                          FilledButton(
                            key: const Key('phone-password-submit'),
                            onPressed: _busy
                                ? null
                                : () {
                                    if (!_form.currentState!.validate()) return;
                                    _run(() async {
                                      final access = ref.read(
                                        emailAccessProvider,
                                      );
                                      final phone =
                                          EgyptPhoneValidator.tryNormalize(
                                            _phone.text,
                                          )!;
                                      if (setup) {
                                        var user = await access
                                            .completePhoneProfile(
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
                                            .read(
                                              authControllerProvider.notifier,
                                            )
                                            .acceptUpdatedProfile(user);
                                        if (context.mounted) {
                                          if (photoFailed) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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
                            child: Text(
                              _busy
                                  ? (ar ? 'جارٍ المتابعة...' : 'Please wait...')
                                  : setup
                                  ? (ar ? 'حفظ ومتابعة' : 'Save and continue')
                                  : (ar ? 'تسجيل الدخول' : 'Sign in'),
                            ),
                          ),
                          if (!setup) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _busy ? null : _recover,
                              child: Text(
                                ar ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                height: 1,
                                color: palette.subtleBorder,
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key('first-use-google'),
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
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                              label: Text(
                                ar
                                    ? 'أول مرة؟ تابع بحساب Google'
                                    : 'First time? Continue with Google',
                              ),
                            ),
                            const SizedBox(height: FixoSpacing.sm),
                            OutlinedButton.icon(
                              key: const Key('first-use-apple'),
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
                                ar
                                    ? 'المتابعة بحساب Apple'
                                    : 'Continue with Apple',
                              ),
                            ),
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
                                ar
                                    ? 'استخدام حساب آخر'
                                    : 'Use a different account',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Trust Strip (Stitch Screen 02)
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
                                  ar
                                      ? 'حساب جوجل بدون رسائل SMS'
                                      : 'Google Account • No SMS Fees',
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
                                Icons.location_on_outlined,
                                size: 16,
                                color: FixoColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  ar
                                      ? 'اختار محافظتك في مصر'
                                      : 'Choose your governorate in Egypt',
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
