import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/fixo_colors.dart';
import '../../../../core/theme/fixo_spacing.dart';
import '../../../../core/theme/fixo_typography.dart';
import '../../../../core/widgets/fixo_buttons.dart';
import '../../../../core/widgets/fixo_cards.dart';
import '../../../../core/widgets/fixo_skeleton.dart';
import '../../data/pro_schedule_repository.dart';
import '../../domain/pro_schedule_models.dart';

class ProSchedulePage extends ConsumerStatefulWidget {
  const ProSchedulePage({super.key});

  @override
  ConsumerState<ProSchedulePage> createState() => _ProSchedulePageState();
}

class _ProSchedulePageState extends ConsumerState<ProSchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<ProDaySchedule> _days = [];
  List<ProLeaveItem> _leaves = [];
  bool _isSavingSchedule = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
          await ref.read(proScheduleRepositoryProvider).getSchedule();
      if (!mounted) return;
      setState(() {
        _days = data.weeklySchedule;
        _leaves = data.leaves;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWeeklySchedule() async {
    setState(() => _isSavingSchedule = true);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    try {
      final updated =
          await ref.read(proScheduleRepositoryProvider).updateSchedule(_days);
      if (!mounted) return;
      setState(() {
        _days = updated.weeklySchedule;
        _isSavingSchedule = false;
      });
      final palette = context.fixoPalette;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تم حفظ مواعيد العمل الأسبوعية بنجاح'
                : 'Working schedule saved successfully',
            style: TextStyle(color: palette.onPrimary),
          ),
          backgroundColor: palette.primaryBrand,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingSchedule = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _openCreateLeaveSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateLeaveBottomSheet(
        onLeaveCreated: (newLeave) {
          setState(() {
            _leaves.insert(0, newLeave);
          });
        },
      ),
    );
  }

  Future<void> _cancelLeave(ProLeaveItem leave) async {
    final palette = context.fixoPalette;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'إلغاء الإجازة' : 'Cancel Leave'),
        content: Text(
          isAr
              ? 'هل أنت متأكد من رغبتك في إلغاء هذه الإجازة والعودة للعمل؟'
              : 'Are you sure you want to cancel this leave and return to work?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isAr ? 'تراجع' : 'Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FixoColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isAr ? 'تأكيد الإلغاء' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(proScheduleRepositoryProvider).cancelLeave(leave.id);
      if (!mounted) return;
      setState(() {
        _leaves.removeWhere((l) => l.id == leave.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تم إلغاء الإجازة بنجاح' : 'Leave cancelled successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: TextStyle(color: palette.onErrorContainer),
          ),
          backgroundColor: palette.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'المواعيد والإجازات' : 'Schedule & Leaves',
          style: FixoTypography.headlineSm(color: palette.deepForest),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: palette.primaryBrand,
          unselectedLabelColor: palette.mutedText,
          indicatorColor: palette.primaryBrand,
          tabs: [
            Tab(text: isAr ? 'ساعات العمل' : 'Working Hours'),
            Tab(text: isAr ? 'الإجازات والعطلات' : 'Leaves & Days Off'),
          ],
        ),
      ),
      body: _isLoading
          ? const FixoListSkeleton(itemCount: 4)
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(FixoSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: palette.error),
                        const SizedBox(height: FixoSpacing.md),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: FixoSpacing.md),
                        ElevatedButton(
                          onPressed: _loadSchedule,
                          child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorkingHoursTab(palette, isAr),
                    _buildLeavesTab(palette, isAr),
                  ],
                ),
    );
  }

  Widget _buildWorkingHoursTab(FixoPaletteExtension palette, bool isAr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FixoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr
                ? 'حدد أيام وساعات العمل الأسبوعية لتلقي طلبات الحجز المتاحة'
                : 'Set your weekly working shifts to receive matching service requests',
            style: FixoTypography.bodySm(color: palette.mutedText),
          ),
          const SizedBox(height: FixoSpacing.md),
          ..._days.asMap().entries.map((entry) {
            final idx = entry.key;
            final day = entry.value;
            return _buildDayCard(idx, day, palette, isAr);
          }),
          const SizedBox(height: FixoSpacing.lg),
          FixoPrimaryButton(
            label: isAr ? 'حفظ التعديلات' : 'Save Changes',
            isLoading: _isSavingSchedule,
            onPressed: _saveWeeklySchedule,
          ),
          const SizedBox(height: FixoSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    int index,
    ProDaySchedule day,
    FixoPaletteExtension palette,
    bool isAr,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FixoSpacing.sm),
      child: FixoSurfaceCard(
        padding: const EdgeInsets.all(FixoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day.dayOfWeek.localizedName(isAr),
                style: FixoTypography.bodyLg(color: palette.deepForest)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Switch.adaptive(
                value: day.isActive,
                activeTrackColor: palette.primaryBrand,
                onChanged: (active) {
                  setState(() {
                    _days[index] = day.copyWith(isActive: active);
                  });
                },
              ),
            ],
          ),
          if (day.isActive) ...[
            const SizedBox(height: FixoSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ProDaySchedule.formatMinuteTime(day.startMinute, isAr)} - ${ProDaySchedule.formatMinuteTime(day.endMinute, isAr)}',
                  style: FixoTypography.bodyMd(color: palette.primaryBrand)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: isAr ? 'تقليل ساعة' : 'Minus 1 hour',
                      onPressed: day.startMinute >= 60
                          ? () {
                              setState(() {
                                _days[index] = day.copyWith(
                                  startMinute: day.startMinute - 60,
                                );
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      tooltip: isAr ? 'زيادة ساعة' : 'Plus 1 hour',
                      onPressed: day.startMinute + 60 < day.endMinute
                          ? () {
                              setState(() {
                                _days[index] = day.copyWith(
                                  startMinute: day.startMinute + 60,
                                );
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ] else
            Text(
              isAr ? 'عطلة أسبوعية' : 'Day off',
              style: FixoTypography.labelSm(color: palette.mutedText),
            ),
        ],
      ),
    ));
  }

  Widget _buildLeavesTab(FixoPaletteExtension palette, bool isAr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FixoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isAr ? 'سجل الإجازات' : 'Leaves History',
                  style: FixoTypography.headlineSm(color: palette.deepForest),
                ),
              ),
              InkWell(
                onTap: _openCreateLeaveSheet,
                borderRadius: FixoRadius.borderRadiusMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FixoSpacing.sm,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primaryBrand,
                    borderRadius: FixoRadius.borderRadiusMd,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18, color: palette.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'طلب إجازة' : 'Request Leave',
                        style: FixoTypography.labelSm(color: palette.onPrimary)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.md),
          if (_leaves.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.beach_access_outlined,
                      size: 48,
                      color: palette.mutedText,
                    ),
                    const SizedBox(height: FixoSpacing.sm),
                    Text(
                      isAr
                          ? 'لا توجد إجازات مسجلة حاليًا'
                          : 'No active leaves recorded',
                      style: FixoTypography.bodyMd(color: palette.mutedText),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._leaves.map((leave) => _buildLeaveCard(leave, palette, isAr)),
          const SizedBox(height: FixoSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(
    ProLeaveItem leave,
    FixoPaletteExtension palette,
    bool isAr,
  ) {
    final startStr =
        '${leave.startDate.year}/${leave.startDate.month}/${leave.startDate.day}';
    final endStr =
        '${leave.endDate.year}/${leave.endDate.month}/${leave.endDate.day}';

    return Padding(
      padding: const EdgeInsets.only(bottom: FixoSpacing.sm),
      child: FixoSurfaceCard(
        padding: const EdgeInsets.all(FixoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primaryBrand.withValues(alpha: 0.1),
                  borderRadius: FixoRadius.borderRadiusSm,
                ),
                child: Text(
                  leave.reason.localizedName(isAr),
                  style: FixoTypography.labelSm(color: palette.primaryBrand)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: palette.error, size: 20),
                tooltip: isAr ? 'إلغاء الإجازة' : 'Cancel Leave',
                onPressed: () => _cancelLeave(leave),
              ),
            ],
          ),
          const SizedBox(height: FixoSpacing.xs),
          Text(
            '$startStr - $endStr',
            style: FixoTypography.bodyLg(color: palette.deepForest)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          if (leave.notes != null && leave.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              leave.notes!,
              style: FixoTypography.bodySm(color: palette.mutedText),
            ),
          ],
        ],
      ),
    ));
  }
}

class _CreateLeaveBottomSheet extends ConsumerStatefulWidget {
  const _CreateLeaveBottomSheet({required this.onLeaveCreated});
  final void Function(ProLeaveItem newLeave) onLeaveCreated;

  @override
  ConsumerState<_CreateLeaveBottomSheet> createState() =>
      _CreateLeaveBottomSheetState();
}

class _CreateLeaveBottomSheetState
    extends ConsumerState<_CreateLeaveBottomSheet> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  ProLeaveReason _reason = ProLeaveReason.vacation;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submitLeave() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _isSubmitting = true);

    try {
      final leave = await ref
          .read(proScheduleRepositoryProvider)
          .createLeave(
            startDate: _startDate,
            endDate: _endDate,
            reason: _reason,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      widget.onLeaveCreated(leave);
      final palette = context.fixoPalette;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تم تسجيل طلب الإجازة بنجاح'
                : 'Leave request recorded successfully',
            style: TextStyle(color: palette.onPrimary),
          ),
          backgroundColor: palette.primaryBrand,
        ),
      );
    } on ProScheduleException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (e.code == 'BOOKING_CONFLICT') {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Text(isAr ? 'تعارض مع حجوزات نشطة' : 'Booking Conflict'),
              ],
            ),
            content: Text(
              isAr
                  ? 'لا يمكن تسجيل إجازة في هذا التاريخ لوجود حجوزات مؤكدة مسندة لك بالفعل. يرجى إتمام الحجوزات أو إعادة تعيينها أولاً.'
                  : 'Cannot schedule leave: you have active confirmed bookings assigned during this period.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(isAr ? 'فهمت' : 'OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final startStr = '${_startDate.year}/${_startDate.month}/${_startDate.day}';
    final endStr = '${_endDate.year}/${_endDate.month}/${_endDate.day}';

    return Material(
      color: palette.cardSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          top: FixoSpacing.lg,
          left: FixoSpacing.lg,
          right: FixoSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + FixoSpacing.lg,
        ),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAr ? 'طلب فترة إجازة جديدة' : 'Request New Leave',
              style: FixoTypography.headlineSm(color: palette.deepForest),
            ),
            const SizedBox(height: FixoSpacing.md),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: FixoRadius.borderRadiusMd,
                side: BorderSide(color: palette.subtleBorder),
              ),
              title: Text(isAr ? 'الفترة الزمنية' : 'Date Range'),
              subtitle: Text('$startStr - $endStr'),
              trailing: const Icon(Icons.date_range),
              onTap: _pickDateRange,
            ),
            const SizedBox(height: FixoSpacing.sm),
            DropdownButtonFormField<ProLeaveReason>(
              initialValue: _reason,
              decoration: InputDecoration(
                labelText: isAr ? 'سبب الإجازة' : 'Leave Reason',
                border: OutlineInputBorder(
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
              ),
              items: ProLeaveReason.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.localizedName(isAr)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _reason = val);
              },
            ),
            const SizedBox(height: FixoSpacing.sm),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: isAr ? 'ملاحظات إضافية (اختياري)' : 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: FixoRadius.borderRadiusMd,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: FixoSpacing.md),
            FixoPrimaryButton(
              label: isAr ? 'تأكيد طلب الإجازة' : 'Confirm Leave',
              isLoading: _isSubmitting,
              onPressed: _submitLeave,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
