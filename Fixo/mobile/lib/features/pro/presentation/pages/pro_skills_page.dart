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
import '../../../customer_home/domain/marketplace_models.dart';
import '../../data/pro_repository.dart';
import '../../domain/pro_models.dart';

/// Screen 12: Services & Skills (`12 — Services & Skills`)
class ProSkillsPage extends ConsumerStatefulWidget {
  const ProSkillsPage({super.key});

  @override
  ConsumerState<ProSkillsPage> createState() => _ProSkillsPageState();
}

class _ProSkillsPageState extends ConsumerState<ProSkillsPage> {
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  List<ServiceCategoryModel> _categories = [];
  List<ProSubSkillModel> _subSkills = [];
  List<CoverageZoneModel> _zones = [];
  List<ProOptionItemModel> _experienceTiers = [];

  String? _selectedCategoryId;
  final Set<String> _selectedSubSkillIds = {};
  String _selectedTier = 'SKILLED_3_5Y';
  final Set<String> _selectedZoneIds = {};
  bool _acceptsStandardRateCard = true;
  bool _toolkitCommitted = false;

  late final TextEditingController _specialtyController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _specialtyController = TextEditingController();
    _priceController = TextEditingController(text: '280');
    _loadCatalog();
  }

  @override
  void dispose() {
    _specialtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(proRepositoryProvider);
      final catalog = await repo.getCatalogOptions();
      final profile = await repo.getMyProfile();

      if (!mounted) return;
      setState(() {
        _categories = catalog.categories;
        _subSkills = catalog.subSkills;
        _zones = catalog.zones;
        _experienceTiers = catalog.experienceTiers;

        if (catalog.categories.isNotEmpty) {
          _selectedCategoryId =
              profile?.primaryCategoryId ?? catalog.categories.first.id;
        }

        if (profile != null) {
          _selectedSubSkillIds.addAll(profile.selectedSubSkillIds);
          if (profile.experienceTier != null) {
            _selectedTier = profile.experienceTier!;
          }
          _selectedZoneIds.addAll(profile.coverageZoneIds);
          _acceptsStandardRateCard = profile.acceptsStandardRateCard;
          _toolkitCommitted = profile.toolkitCommitmentConfirmed;
          if (profile.specialtyAr != null) {
            _specialtyController.text = profile.specialtyAr!;
          }
          if (profile.estimatedPriceEgp != null) {
            _priceController.text = profile.estimatedPriceEgp.toString();
          }
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit(bool ar) async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'يرجى اختيار التخصص الأساسي'
                : 'Please select a primary trade category',
          ),
        ),
      );
      return;
    }
    if (_selectedZoneIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'يرجى اختيار منطقة تغطية واحدة على الأقل'
                : 'Please select at least one coverage zone',
          ),
        ),
      );
      return;
    }
    if (!_toolkitCommitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'يرجى تأكيد امتلاك شنطة العدة ومعدات الأمان'
                : 'Please confirm ownership of professional toolkit and safety gear',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(proRepositoryProvider);
      final price = int.tryParse(_priceController.text.trim()) ?? 280;

      await repo.saveSkillsAndCoverage(
        primaryCategoryId: _selectedCategoryId!,
        subSkillIds: _selectedSubSkillIds.toList(),
        experienceTier: _selectedTier,
        coverageZoneIds: _selectedZoneIds.toList(),
        acceptsStandardRateCard: _acceptsStandardRateCard,
        toolkitCommitmentConfirmed: _toolkitCommitted,
        specialtyAr: _specialtyController.text.trim(),
        specialtyEn: _specialtyController.text.trim(),
        estimatedPriceEgp: price,
      );

      if (!mounted) return;
      context.push(AppRoutes.proVerificationDocs);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appLocaleProvider).languageCode == 'ar';
    final palette = context.fixoPalette;

    final filteredSubSkills = _subSkills
        .where((s) => s.categoryId == _selectedCategoryId)
        .toList();

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
                  ar ? 'المهارات ومناطق الخدمة' : 'Trade Skills & Coverage',
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
                    constraints: const BoxConstraints(maxWidth: 640),
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
                                  ar ? 'الخطوة ٢ من ٤' : 'Step 2 of 4',
                                  style: FixoTypography.labelSm(
                                    color: FixoColors.limeAccent,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ar
                                      ? 'تحديد الحرفة والمناطق وبطاقة الأسعار'
                                      : 'Trade Specialty, Coverage & Rates',
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

                        // Primary Trade Category
                        FixoSurfaceCard(
                          padding: const EdgeInsets.all(FixoSpacing.md),
                          borderRadius: FixoRadius.borderRadiusLg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar
                                    ? 'مجال الحرفة الأساسي'
                                    : 'Primary Trade Specialty',
                                style: FixoTypography.headlineSm(
                                  color: palette.deepForest,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ar
                                    ? 'اختر مجالك الرئيسي لاستقبال طلبات الزبائن المناسبة لخبرتك'
                                    : 'Select your primary trade to receive relevant job offers',
                                style: FixoTypography.bodySm(
                                  color: palette.mutedText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories.map((cat) {
                                  final isSelected =
                                      _selectedCategoryId == cat.id;
                                  return ChoiceChip(
                                    label: Text(cat.localizedName(ar)),
                                    selected: isSelected,
                                    selectedColor:
                                        FixoColors.secondaryContainer,
                                    labelStyle: FixoTypography.labelMd(
                                      color: isSelected
                                          ? FixoColors.primaryForest
                                          : palette.inkText,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _selectedCategoryId = cat.id;
                                          _selectedSubSkillIds.clear();
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),

                              if (filteredSubSkills.isNotEmpty) ...[
                                const SizedBox(height: FixoSpacing.md),
                                Divider(height: 1, color: palette.subtleBorder),
                                const SizedBox(height: 12),
                                Text(
                                  ar
                                      ? 'المهارات التفصيلية'
                                      : 'Detailed Skills & Services',
                                  style: FixoTypography.labelMd(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: filteredSubSkills.map((sub) {
                                    final isSelected = _selectedSubSkillIds
                                        .contains(sub.id);
                                    return FilterChip(
                                      label: Text(ar ? sub.nameAr : sub.nameEn),
                                      selected: isSelected,
                                      selectedColor:
                                          FixoColors.secondaryContainer,
                                      labelStyle: FixoTypography.bodySm(
                                        color: isSelected
                                            ? FixoColors.primaryForest
                                            : palette.inkText,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                      onSelected: (val) {
                                        setState(() {
                                          if (val) {
                                            _selectedSubSkillIds.add(sub.id);
                                          } else {
                                            _selectedSubSkillIds.remove(sub.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: FixoSpacing.md),

                        // Experience Tier & Coverage Zones
                        FixoSurfaceCard(
                          padding: const EdgeInsets.all(FixoSpacing.md),
                          borderRadius: FixoRadius.borderRadiusLg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar ? 'سنوات الخبرة' : 'Experience Tier',
                                style: FixoTypography.headlineSm(
                                  color: palette.deepForest,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              ..._experienceTiers.map((tier) {
                                final isSel = _selectedTier == tier.key;
                                return InkWell(
                                  onTap: () =>
                                      setState(() => _selectedTier = tier.key),
                                  borderRadius: FixoRadius.borderRadiusMd,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          isSel
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: isSel
                                              ? FixoColors.primaryForest
                                              : palette.mutedText,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tier.localizedLabel(ar),
                                                style:
                                                    FixoTypography.labelMd(
                                                      color: palette.deepForest,
                                                    ).copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              if (tier.descAr != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  ar
                                                      ? tier.descAr!
                                                      : (tier.descEn ?? ''),
                                                  style: FixoTypography.bodySm(
                                                    color: palette.mutedText,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const Divider(height: 24),
                              Text(
                                ar
                                    ? 'اختار مناطق شغلك في مصر'
                                    : 'Choose your service areas in Egypt',
                                style: FixoTypography.labelMd(
                                  color: palette.deepForest,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _zones.map((zone) {
                                  final isSelected = _selectedZoneIds.contains(
                                    zone.id,
                                  );
                                  return FilterChip(
                                    label: Text(zone.localizedName(ar)),
                                    selected: isSelected,
                                    selectedColor:
                                        FixoColors.secondaryContainer,
                                    onSelected: (val) {
                                      setState(() {
                                        if (val) {
                                          _selectedZoneIds.add(zone.id);
                                        } else {
                                          if (_selectedZoneIds.length > 1) {
                                            _selectedZoneIds.remove(zone.id);
                                          }
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: FixoSpacing.md),

                        // Standards, Rates & Commitments
                        FixoSurfaceCard(
                          padding: const EdgeInsets.all(FixoSpacing.md),
                          borderRadius: FixoRadius.borderRadiusLg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar
                                    ? 'بطاقة الأسعار والالتزام المهني'
                                    : 'Rate Card & Quality Commitments',
                                style: FixoTypography.headlineSm(
                                  color: palette.deepForest,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: Text(
                                  ar
                                      ? 'الموافقة على تسعيرة فيكسو الموحدة'
                                      : 'Accept FIXO Standard Rate Card',
                                  style: FixoTypography.labelMd(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  ar
                                      ? '١٥٠ ج.م حد أدنى للمعاينة وكشف العطل + تكلفة الإصلاح المعتمدة.'
                                      : '150 EGP standard inspection fee + itemized service pricing.',
                                  style: FixoTypography.bodySm(
                                    color: palette.mutedText,
                                  ),
                                ),
                                value: _acceptsStandardRateCard,
                                onChanged: (val) => setState(
                                  () => _acceptsStandardRateCard = val,
                                ),
                              ),
                              const Divider(height: 16),
                              CheckboxListTile(
                                title: Text(
                                  ar
                                      ? 'أؤكد امتلاكي لشنطة العدة ومعدات الأمان'
                                      : 'I confirm ownership of professional toolkit & safety gear',
                                  style: FixoTypography.labelMd(
                                    color: palette.deepForest,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  ar
                                      ? 'الالتزام بشنطة العدة الكاملة ومعدات السلامة المهنية شرط أساسي لاعتماد الحساب.'
                                      : 'Complete toolkit and safety gear are mandatory for account activation.',
                                  style: FixoTypography.bodySm(
                                    color: palette.mutedText,
                                  ),
                                ),
                                value: _toolkitCommitted,
                                onChanged: (val) => setState(
                                  () => _toolkitCommitted = val ?? false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: FixoSpacing.lg),

                        // Next CTA
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
                                ? 'المتابعة لرفع مستندات التحقق'
                                : 'Continue to Document Upload',
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
    );
  }
}
