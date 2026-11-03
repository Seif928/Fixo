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
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/pro_repository.dart';

/// Screen 11: Pro Sign-Up & Personal Details (`11 — Pro Sign-Up & Details`)
class ProSignUpPage extends ConsumerStatefulWidget {
  const ProSignUpPage({super.key});

  @override
  ConsumerState<ProSignUpPage> createState() => _ProSignUpPageState();
}

class _ProSignUpPageState extends ConsumerState<ProSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nationalIdController;

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nationalIdController = TextEditingController();
    _loadInitial();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      final profile = await repo.getMyProfile();

      if (!mounted) return;
      setState(() {
        if (profile != null) {
          if (profile.fullName != null) {
            _nameController.text = profile.fullName!;
          }
          if (profile.nationalIdSynthetic != null) {
            _nationalIdController.text = profile.nationalIdSynthetic!;
          }
        }
        if (_nameController.text.isEmpty) {
          _nameController.text =
              ref.read(authControllerProvider).session?.user.fullName ?? '';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ref.read(appLocaleProvider).languageCode == 'ar'
            ? 'تعذر تحميل البيانات. حاول تاني.'
            : 'Could not load your details. Please retry.';
        _loading = false;
      });
    }
  }

  Future<void> _submit(bool ar) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(proRepositoryProvider);
      await repo.savePersonalDetails(
        fullName: _nameController.text.trim(),
        nationalIdSynthetic: _nationalIdController.text.trim(),
      );

      if (!mounted) return;
      context.push(AppRoutes.proSkills);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ar
            ? 'تعذر حفظ البيانات. حاول تاني.'
            : 'Could not save your details. Please retry.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.canvasBackground,
        appBar: AppBar(
          backgroundColor: palette.cardSurface.withValues(alpha: 0.95),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.deepForest),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const FixoBrandMark(iconBoxSize: 26, showSubtitle: false),
              const SizedBox(width: FixoSpacing.xs),
              Expanded(
                child: Text(
                  ar ? 'تسجيل فني فيكسو' : 'FIXO Pro Onboarding',
                  style: FixoTypography.headlineSm(
                    color: palette.deepForest,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(FixoSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Step Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceLow,
                              borderRadius: FixoRadius.borderRadiusMd,
                              border: Border.all(color: palette.subtleBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FixoColors.primaryForest,
                                    borderRadius: FixoRadius.borderRadiusPill,
                                  ),
                                  child: Text(
                                    ar ? 'الخطوة ١ من ٤' : 'Step 1 of 4',
                                    style: FixoTypography.labelSm(
                                      color: FixoColors.limeAccent,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ar
                                        ? 'الاسم والرقم القومي'
                                        : 'Name & National ID',
                                    style: FixoTypography.labelMd(
                                      color: palette.deepForest,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.md),

                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(
                                bottom: FixoSpacing.md,
                              ),
                              padding: const EdgeInsets.all(FixoSpacing.sm),
                              decoration: BoxDecoration(
                                color: FixoColors.errorContainer,
                                borderRadius: FixoRadius.borderRadiusMd,
                              ),
                              child: Text(
                                _errorMessage!,
                                style: FixoTypography.bodySm(
                                  color: FixoColors.onErrorContainer,
                                ),
                              ),
                            ),

                          // Form Card
                          FixoSurfaceCard(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            borderRadius: FixoRadius.borderRadiusLg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ar
                                      ? 'الاسم القانوني بالكامل'
                                      : 'Full Legal Name',
                                  style: FixoTypography.labelMd(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  enabled: !_saving,
                                  maxLength: 120,
                                  decoration: InputDecoration(
                                    hintText: ar
                                        ? 'الاسم كما هو مدون بالبطاقة القومية'
                                        : 'Name as shown on National ID',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().length < 3)
                                      ? (ar
                                            ? 'يرجى كتابة الاسم الثلاثي على الأقل'
                                            : 'Please enter full legal name')
                                      : null,
                                ),
                                const SizedBox(height: FixoSpacing.md),

                                Text(
                                  ar
                                      ? 'الرقم القومي (١٤ رقم)'
                                      : 'National ID (14 digits)',
                                  style: FixoTypography.labelMd(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nationalIdController,
                                  enabled: !_saving,
                                  keyboardType: TextInputType.number,
                                  maxLength: 14,
                                  decoration: InputDecoration(
                                    hintText: '29801010102938',
                                    prefixIcon: const Icon(
                                      Icons.badge_outlined,
                                    ),
                                    counterText: '',
                                    helperText: ar
                                        ? '١٤ رقمًا كما هو مدون على البطاقة'
                                        : '14-digit National ID matching your uploaded photos',
                                  ),
                                  validator: (v) {
                                    if (v == null ||
                                        !RegExp(
                                          r'^\d{14}$',
                                        ).hasMatch(v.trim())) {
                                      return ar
                                          ? 'الرقم القومي يجب أن يتكون من ١٤ رقم بالضبط'
                                          : 'National ID must be an exact 14-digit number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FixoSpacing.lg),

                          // Submit CTA
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              backgroundColor: FixoColors.primaryForest,
                              shape: RoundedRectangleBorder(
                                borderRadius: FixoRadius.borderRadiusMd,
                              ),
                            ),
                            onPressed: _saving ? null : () => _submit(ar),
                            icon: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    ar
                                        ? Icons.arrow_back_rounded
                                        : Icons.arrow_forward_rounded,
                                  ),
                            label: Text(
                              ar
                                  ? 'المتابعة لتحديد المهارات والتغطية'
                                  : 'Continue to Skills & Coverage',
                              style: FixoTypography.labelLg(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.bold),
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
