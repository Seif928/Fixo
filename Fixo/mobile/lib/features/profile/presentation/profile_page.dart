import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/router/customer_tab_navigation.dart';

import '../../../core/l10n/app_locale_controller.dart';
import '../domain/profile_models.dart';
import 'package:fixo_mobile/app/providers/profile_providers.dart';
import 'controllers/profile_controller.dart';
import '../../../core/notifications/device_push_service.dart';
import '../../../core/theme/fixo_colors.dart';
import '../../../core/theme/fixo_spacing.dart';
import '../../../core/widgets/fixo_brand_mark.dart';
import '../../../core/widgets/fixo_cards.dart';
import '../../../core/widgets/fixo_skeleton.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../chat/presentation/notification_sheet.dart';
import '../../customer_home/presentation/widgets/customer_home_widgets.dart';
import '../../../core/uploads/private_media_picker_sheet.dart';
import '../data/avatar_repository.dart';
import '../data/account_deletion_repository.dart';
import 'profile_avatar.dart';
import 'profile_details_dialog.dart';
import '../../admin/presentation/admin_profile_entry.dart';

/// Screen 10: live Stitch profile/alerts cards, with persisted real preferences.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late Future<UserProfile> _profile;
  bool _saving = false;
  bool? _optimisticArrivalAlerts;
  bool get _ar => ref.read(appLocaleProvider).languageCode == 'ar';

  Future<void> _confirmDeleteAccount() async {
    final ar = _ar;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: FixoColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ar ? 'حذف الحساب نهائيًا' : 'Delete Account Permanently',
              ),
            ),
          ],
        ),
        content: Text(
          ar
              ? 'هل أنت متأكد من رغبتك في حذف حسابك؟ سيتم إلغاء تفعيل حسابك وحذف جميع عناوينك المسجلة وأجهزتك فورًا، مع الاحتفاظ الآمن بسجلات الفواتير السابقة لأغراض الضرائب والمحاسبة.'
              : 'Are you sure you want to permanently delete your account? Your personal data, delivery addresses, and push notifications will be wiped immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm-delete-account-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FixoColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ar ? 'تأكيد الحذف' : 'Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _saving = true);
      await ref.read(accountDeletionRepositoryProvider).deleteAccount();
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      context.go('/auth/phone');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'تم حذف الحساب والبيانات الشخصية بنجاح'
                : 'Account and personal data deleted successfully',
          ),
        ),
      );
    } on AccountDeletionException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ar ? 'تعذر حذف الحساب' : 'Cannot Delete Account'),
          content: Text(
            ar
                ? 'لا يمكن حذف الحساب لوجود حجوزات جارية أو معلقة. يرجى إتمام الحجوزات أو إلغاؤها أولاً.'
                : e.message,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ar ? 'حسنًا' : 'OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: FixoColors.error,
        ),
      );
    }
  }

  Future<void> _editDetails(String initialValue, {bool isPhone = false}) async {
    final owner = ref.read(authControllerProvider).session?.user.id;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileDetailsDialog(
        initialValue: initialValue,
        isPhone: isPhone,
        isArabic: _ar,
      ),
    );
    if (saved == true &&
        mounted &&
        owner == ref.read(authControllerProvider).session?.user.id) {
      setState(() {
        _profile = _load();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<UserProfile> _load() async {
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> _save(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _ar
                    ? 'تعذر حفظ الإعداد. حاول مرة أخرى.'
                    : 'Could not save this setting. Please retry.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openRecentAlerts() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const NotificationSheet(),
    );
  }

  Future<void> _editPhoto() async {
    final userId = ref.read(authControllerProvider).session?.user.id;
    if (userId == null) return;
    final selected = await PrivateMediaPickerSheet.show(
      context,
      isArabic: _ar,
      titleEn: 'Change profile photo',
      titleAr: 'تغيير صورة الحساب',
      rationaleEn:
          'Choose a new profile photo. Your current photo stays until the upload succeeds.',
      rationaleAr: 'اختار صورة جديدة. الصورة الحالية هتفضل لحد ما الرفع ينجح.',
      defaultFilePrefix: 'avatar',
      allowSuggestedAvatars: true,
    );
    if (selected == null ||
        !mounted ||
        ref.read(authControllerProvider).session?.user.id != userId) {
      return;
    }
    await _save(() async {
      final version = await ref.read(avatarRepositoryProvider).upload(selected);
      if (!mounted) return;
      final currentUser = ref.read(authControllerProvider).session?.user;
      if (currentUser?.id == userId) {
        await ref
            .read(authControllerProvider.notifier)
            .acceptUpdatedProfile(currentUser!.withAvatar(version));
      }
      if (mounted && currentUser?.id == userId) {
        setState(() {
          _profile = _load();
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _ar ? 'تم تحديث صورة الحساب.' : 'Profile photo updated.',
              ),
            ),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final mode = ref.watch(appThemeModeProvider);
    final ar = locale.languageCode == 'ar';
    final palette = context.fixoPalette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: palette.canvasBackground,
      appBar: AppBar(
        backgroundColor: palette.canvasBackground,
        titleSpacing: FixoSpacing.md,
        title: Row(
          children: [
            const FixoBrandMark(showSubtitle: false, iconBoxSize: 28),
            const SizedBox(width: FixoSpacing.sm),
            Expanded(
              child: Text(
                ar ? 'الملف الشخصي والإعدادات' : 'Profile & Settings',
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: ar ? 'آخر التنبيهات' : 'Recent Alerts',
            onPressed: _openRecentAlerts,
            icon: Icon(
              Icons.notifications_none_rounded,
              color: palette.deepForest,
            ),
          ),
          const SizedBox(width: FixoSpacing.xs),
        ],
      ),
      bottomNavigationBar: FixoCustomerBottomNav(
        currentIndex: 3,
        isArabic: ar,
        onTabSelected: (index) => navigateCustomerTab(context, index),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width > 712
                ? (MediaQuery.sizeOf(context).width - 680) / 2
                : FixoSpacing.md,
            FixoSpacing.sm,
            MediaQuery.sizeOf(context).width > 712
                ? (MediaQuery.sizeOf(context).width - 680) / 2
                : FixoSpacing.md,
            FixoSpacing.xl,
          ),
          children: [
            FutureBuilder<UserProfile>(
              future: _profile,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return FixoSurfaceCard(
                    padding: const EdgeInsets.all(FixoSpacing.md),
                    borderRadius: FixoRadius.borderRadiusLg,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: FixoColors.error,
                          size: 28,
                        ),
                        const SizedBox(height: FixoSpacing.xs),
                        TextButton(
                          onPressed: () => setState(() {
                            _profile = _load();
                          }),
                          child: Text(
                            ar
                                ? 'تعذر تحميل الملف. أعد المحاولة.'
                                : 'Could not load profile. Retry.',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const FixoListSkeleton(
                    itemCount: 3,
                    showHeaderBanner: true,
                  );
                }
                final user = snapshot.data!;
                final isPro = user['role'] == 'PRO';
                final fullName =
                    user['fullName'] as String? ??
                    (ar ? 'حساب FIXO' : 'FIXO account');
                final email = user['email'] as String?;
                final phone = user['phone'] as String?;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Stitch Screen 10 Profile Hero Card
                    FixoSurfaceCard(
                      padding: const EdgeInsets.all(FixoSpacing.lg),
                      borderRadius: FixoRadius.borderRadiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 88,
                                height: 88,
                                child: Stack(
                                  children: [
                                    PositionedDirectional(
                                      start: 0,
                                      top: 0,
                                      child: Tooltip(
                                        message: ar
                                            ? 'تغيير الصورة'
                                            : 'Change photo',
                                        child: InkWell(
                                          key: const Key(
                                            'profile-photo-button',
                                          ),
                                          onTap: _saving ? null : _editPhoto,
                                          customBorder: const CircleBorder(),
                                          child: ProfileAvatar(
                                            userId: user['id'] as String? ?? '',
                                            hasAvatar:
                                                user['hasAvatar'] == true,
                                            version:
                                                user['avatarVersion']
                                                    as String?,
                                            size: 80,
                                          ),
                                        ),
                                      ),
                                    ),
                                    PositionedDirectional(
                                      end: 0,
                                      bottom: 0,
                                      child: IconButton.filled(
                                        key: const Key('profile-change-photo'),
                                        onPressed: _saving ? null : _editPhoto,
                                        tooltip: ar
                                            ? 'تغيير الصورة'
                                            : 'Change photo',
                                        style: IconButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                          backgroundColor: palette.primaryBrand,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                        ),
                                        icon: const Icon(
                                          Icons.photo_camera_outlined,
                                          size: 21,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: FixoSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.primaryBrand,
                                        borderRadius:
                                            FixoRadius.borderRadiusPill,
                                      ),
                                      child: AccountRoleBadge(
                                        professional: isPro,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            fullName,
                                            style: textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        IconButton(
                                          key: const Key('profile-edit-name'),
                                          tooltip: ar
                                              ? 'تعديل الاسم'
                                              : 'Edit name',
                                          onPressed: _saving
                                              ? null
                                              : () => _editDetails(fullName),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (email != null ||
                              (phone != null && phone.isNotEmpty)) ...[
                            const SizedBox(height: FixoSpacing.md),
                            Divider(height: 1, color: palette.subtleBorder),
                            const SizedBox(height: FixoSpacing.sm),
                          ],
                          if (email != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.mail_outline_rounded,
                                    size: 16,
                                    color: palette.mutedText,
                                  ),
                                  const SizedBox(width: FixoSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: palette.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (phone != null && phone.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: palette.mutedText,
                                ),
                                const SizedBox(width: FixoSpacing.xs),
                                Expanded(
                                  child: Text(
                                    phone,
                                    textDirection: TextDirection.ltr,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: palette.inkText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: const Key('profile-edit-phone'),
                                  tooltip: ar
                                      ? 'تغيير رقم الدخول'
                                      : 'Change sign-in phone',
                                  onPressed: _saving
                                      ? null
                                      : () =>
                                            _editDetails(phone, isPhone: true),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FixoSpacing.md),

                    const AdminProfileEntry(),
                    // 2. Stitch Screen 10 "Earn With FIXO Pro" Partner Banner
                    InkWell(
                      onTap: () {
                        if (isPro) {
                          context.push(AppRoutes.proDashboard);
                        } else {
                          context.push(AppRoutes.proSignUp);
                        }
                      },
                      borderRadius: FixoRadius.borderRadiusLg,
                      child: Container(
                        padding: const EdgeInsets.all(FixoSpacing.md),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0F172A),
                              Color(0xFF172236),
                              Color(0xFF1E293B),
                            ],
                          ),
                          borderRadius: FixoRadius.borderRadiusLg,
                          border: Border.all(
                            color: const Color(0xFF93C5FD).withValues(alpha: 0.35),
                          ),
                          boxShadow: FixoShadows.level2Interactive,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF93C5FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.engineering_rounded,
                                color: FixoColors.deepestForest,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: FixoSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ar
                                        ? 'انضم لشبكة فنيي فيكسو'
                                        : 'EARN WITH FIXO PRO',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF93C5FD),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: ar ? 0 : 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isPro
                                        ? (ar
                                              ? 'لوحة تحكم الفني والحجوزات المسندة'
                                              : 'Pro partner dashboard & assigned jobs')
                                        : (ar
                                              ? 'هل أنت فني أو حرفي خدمات منزلية؟'
                                              : 'Are you a home services technician or artisan?'),
                                    style: textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: FixoRadius.borderRadiusPill,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isPro
                                              ? (ar
                                                    ? 'فتح لوحة الفني'
                                                    : 'Open Pro Dashboard')
                                              : (ar
                                                    ? 'تسجيل كشريك فني'
                                                    : 'Apply as Pro Partner'),
                                          style: textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          ar
                                              ? Icons.arrow_back_rounded
                                              : Icons.arrow_forward_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: FixoSpacing.md),

                    // 3. Manage & Details Card (In-app booking updates + Device Push)
                    FixoSurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: FixoSpacing.sm,
                      ),
                      borderRadius: FixoRadius.borderRadiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              FixoSpacing.md,
                              FixoSpacing.xs,
                              FixoSpacing.md,
                              FixoSpacing.xs,
                            ),
                            child: Text(
                              ar ? 'الإدارة والتنبيهات' : 'Manage & Details',
                              style: textTheme.labelSmall?.copyWith(
                                color: palette.mutedText,
                                fontWeight: FontWeight.w800,
                                letterSpacing: ar ? 0 : 0.8,
                              ),
                            ),
                          ),
                          ListTile(
                            key: const Key('profile-favorites-tile'),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: palette.primaryBrand.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.favorite_rounded,
                                color: palette.primaryBrand,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              ar ? 'المفضلة' : 'Saved Favorites',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              ar
                                  ? 'الخدمات والفنيون المفضلون لديك'
                                  : 'Your favorite services and technicians',
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.mutedText,
                              ),
                            ),
                            trailing: Icon(
                              ar
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              color: palette.mutedText,
                            ),
                            onTap: () => context.push(AppRoutes.favorites),
                          ),
                          Divider(height: 1, color: palette.subtleBorder),
                          SwitchListTile(
                            title: Text(
                              ar
                                  ? 'تحديثات الحجوزات داخل التطبيق'
                                  : 'In-app booking updates',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              ar
                                  ? 'لا يشمل هذا تفعيل SMS أو إشعارات الجهاز.'
                                  : 'This setting does not activate SMS or device push.',
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.mutedText,
                              ),
                            ),
                            value:
                                _optimisticArrivalAlerts ??
                                (user['arrivalAlertsEnabled'] == true),
                            onChanged: _saving
                                ? null
                                : (enabled) {
                                    setState(
                                      () => _optimisticArrivalAlerts = enabled,
                                    );
                                    _save(() async {
                                      try {
                                        await ref
                                            .read(
                                              profileControllerProvider
                                                  .notifier,
                                            )
                                            .updateNotificationPreferences(
                                              arrivalAlertsEnabled: enabled,
                                            );
                                        if (!mounted) return;
                                        final refreshed = _load();
                                        refreshed.whenComplete(() {
                                          if (mounted) {
                                            setState(() {
                                              _optimisticArrivalAlerts = null;
                                            });
                                          }
                                        });
                                        setState(() {
                                          _profile = refreshed;
                                        });
                                      } catch (_) {
                                        if (mounted) {
                                          setState(() {
                                            _optimisticArrivalAlerts = null;
                                          });
                                        }
                                        rethrow;
                                      }
                                    });
                                  },
                          ),
                          Divider(height: 1, color: palette.subtleBorder),
                          Padding(
                            padding: const EdgeInsets.all(FixoSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton.icon(
                                  key: const Key('enable-device-notifications'),
                                  onPressed: _saving
                                      ? null
                                      : () => _save(() async {
                                          final result = await ref
                                              .read(devicePushProvider)
                                              .enable();
                                          if (!context.mounted) return;
                                          final text = switch (result) {
                                            PushOptInResult.enabled =>
                                              ar
                                                  ? 'تم تسجيل هذا الجهاز للإشعارات.'
                                                  : 'This device is registered for notifications.',
                                            PushOptInResult.denied =>
                                              ar
                                                  ? 'الإذن مرفوض. يمكنك تفعيله من إعدادات الجهاز، وتنبيهات التطبيق ما زالت متاحة.'
                                                  : 'Permission denied. You can enable it in device settings. In-app alerts remain available.',
                                            PushOptInResult.unavailable =>
                                              ar
                                                  ? 'إشعارات الجهاز غير متاحة حالياً على هذه المنصة. تنبيهات التطبيق متاحة.'
                                                  : 'Device notifications are unavailable on this platform right now. In-app alerts remain available.',
                                          };
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(text)),
                                          );
                                        }),
                                  icon: const Icon(
                                    Icons.notifications_active_outlined,
                                  ),
                                  label: Text(
                                    ar
                                        ? 'تفعيل إشعارات هذا الجهاز'
                                        : 'Enable device notifications',
                                  ),
                                ),
                                const SizedBox(height: FixoSpacing.xs),
                                TextButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _save(
                                          () => ref
                                              .read(devicePushProvider)
                                              .disable(),
                                        ),
                                  child: Text(
                                    ar
                                        ? 'إيقاف إشعارات هذا الجهاز'
                                        : 'Disable device notifications',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: FixoSpacing.md),

            // 4. Recent Alerts Card (Stitch Screen 10)
            FixoSurfaceCard(
              padding: const EdgeInsets.all(FixoSpacing.md),
              borderRadius: FixoRadius.borderRadiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: palette.primaryBrand,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: FixoSpacing.xs),
                      Expanded(
                        child: Text(
                          ar
                              ? 'تحديثات الطلبات والرسائل'
                              : 'Order & Message Activity',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ar
                        ? 'راجع آخر تحديثات الحجوزات والرسائل غير المقروءة المحفوظة في حسابك.'
                        : 'Review your persisted booking status changes and unread order messages.',
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(height: FixoSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _openRecentAlerts,
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(ar ? 'آخر التنبيهات' : 'Recent Alerts'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FixoSpacing.md),

            // 5. Language & Appearance Card (Stitch Screen 10)
            FixoSurfaceCard(
              padding: const EdgeInsets.all(FixoSpacing.md),
              borderRadius: FixoRadius.borderRadiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ar ? 'اللغة والمظهر' : 'Language & Appearance',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: FixoSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('العربية'),
                        selected: ar,
                        onSelected: _saving
                            ? null
                            : (_) => _save(
                                () => ref
                                    .read(appLocaleProvider.notifier)
                                    .setLocale(const Locale('ar')),
                              ),
                      ),
                      ChoiceChip(
                        label: const Text('English'),
                        selected: !ar,
                        onSelected: _saving
                            ? null
                            : (_) => _save(
                                () => ref
                                    .read(appLocaleProvider.notifier)
                                    .setLocale(const Locale('en')),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FixoSpacing.md),
                  DropdownButtonFormField<ThemeMode>(
                    initialValue: mode,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: ar ? 'المظهر' : 'Appearance',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(ar ? 'حسب إعداد الجهاز' : 'System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(ar ? 'فاتح' : 'Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(ar ? 'داكن' : 'Dark'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              _save(
                                () => ref
                                    .read(appThemeModeProvider.notifier)
                                    .setThemeMode(value),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: FixoSpacing.md),

            ListTile(
              leading: const Icon(Icons.support_agent),
              title: Text(ar ? 'خدمة العملاء' : 'Customer support'),
              onTap: () => context.push('/support'),
            ),
            // 6. Sign Out & Editorial Brand Metadata
            FixoSurfaceCard(
              padding: const EdgeInsets.symmetric(
                horizontal: FixoSpacing.md,
                vertical: FixoSpacing.xs,
              ),
              borderRadius: FixoRadius.borderRadiusLg,
              child: TextButton.icon(
                key: const Key('profile-sign-out'),
                style: TextButton.styleFrom(foregroundColor: FixoColors.error),
                onPressed: _saving
                    ? null
                    : () {
                        context.push(AppRoutes.logout);
                      },
                icon: const Icon(Icons.logout_rounded),
                label: Text(ar ? 'تسجيل الخروج' : 'Sign out'),
              ),
            ),
            const SizedBox(height: FixoSpacing.sm),
            FixoSurfaceCard(
              padding: const EdgeInsets.symmetric(
                horizontal: FixoSpacing.md,
                vertical: FixoSpacing.xs,
              ),
              borderRadius: FixoRadius.borderRadiusLg,
              child: TextButton.icon(
                key: const Key('profile-delete-account'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                onPressed: _saving ? null : _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever_outlined, size: 20),
                label: Text(
                  ar
                      ? 'حذف الحساب والبيانات الشخصية'
                      : 'Delete account & privacy data',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: FixoSpacing.lg),
            Center(
              child: Text(
                ar
                    ? 'فيكسو مصر • الحرفية والعناية بالمنزل'
                    : 'FIXO EGYPT • NILOTIC CRAFT & HOME',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: palette.mutedText,
                  letterSpacing: ar ? 0 : 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
