import 'package:flutter/material.dart';
import '../data/admin_repository.dart';

class AdminSummaryPanel extends StatelessWidget {
  const AdminSummaryPanel({super.key, required this.summary, required this.ar});
  final AdminSummary summary;
  final bool ar;
  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.people_outline, ar ? 'الحسابات' : 'Accounts', '${summary.users}'),
      (
        Icons.handyman_outlined,
        ar ? 'ملفات الفنيين' : 'Professional profiles',
        '${summary.professionals}',
      ),
      (
        Icons.fact_check_outlined,
        ar ? 'في انتظار المراجعة' : 'Awaiting review',
        '${summary.pendingReviews}',
      ),
      (
        Icons.receipt_long_outlined,
        ar ? 'الحجوزات النشطة' : 'Active bookings',
        '${summary.activeBookings}',
      ),
      (
        Icons.payments_outlined,
        ar ? 'التحصيل النقدي المسجل' : 'Recorded cash collected',
        '${summary.collectedCashEgp} ${ar ? 'ج.م' : 'EGP'}',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'نظرة عامة' : 'Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'إجماليات فعلية من قاعدة البيانات. الحجوزات النشطة لا تشمل المسودات أو المكتملة أو الملغاة.'
              : 'Live database totals. Active bookings exclude drafts, completed and cancelled bookings.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 950
                ? 3
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: cards
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                item.$1,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                item.$3,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Text(item.$2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          ar
              ? 'التحصيل النقدي يعرض مبالغ الدفع النقدي المسجلة «مدفوعة» بتاريخ تحصيل، بدون البقشيش. ده مش رصيد المنصة أو أرباحها.'
              : 'Cash includes cash payments recorded as paid with a collection date, excluding tips. This is not platform balance or profit.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class AdminAuditPanel extends StatelessWidget {
  const AdminAuditPanel({super.key, required this.items, required this.ar});
  final List<AdminAuditEvent> items;
  final bool ar;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        ar ? 'سجل التغييرات' : 'Activity log',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        ar
            ? 'آخر ٢٠ تغييرًا إداريًا مسجلًا.'
            : 'The latest 20 recorded administration changes.',
      ),
      const SizedBox(height: 24),
      if (items.isEmpty)
        Text(ar ? 'لا توجد تغييرات مسجلة بعد.' : 'No changes recorded yet.'),
      for (final item in items)
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const Icon(Icons.history_rounded),
            title: Text(switch (item.action) {
              'OWNER_INITIALIZED' =>
                ar ? 'تفعيل حساب المالك' : 'Owner access initialized',
              'BOOKING_DETAILS_ACCESSED' =>
                ar ? 'عرض تفاصيل حجز' : 'Booking details accessed',
              'BOOKING_CANCELLED' =>
                ar
                    ? 'إلغاء حجز إداريًا'
                    : 'Booking cancelled by administration',
              'BOOKING_OFFER_SENT' =>
                ar ? 'إرسال عرض حجز لفني' : 'Job offer sent to a professional',
              'ADMIN_INVITED' =>
                ar ? 'منح دعوة للمسؤول الثاني' : 'Second administrator invited',
              'ADMIN_INVITE_ACCEPTED' =>
                ar ? 'قبول دعوة الإدارة' : 'Administrator invitation accepted',
              'ADMIN_REVOKED' =>
                ar
                    ? 'إلغاء صلاحيات المسؤول الثاني'
                    : 'Second administrator access revoked',
              'CATALOG_DRAFT_UPDATED' =>
                ar ? 'تعديل مسودة خدمة' : 'Service draft updated',
              'CATALOG_PUBLISHED' =>
                ar ? 'نشر خدمة وسعرها' : 'Service and price published',
              'PRO_DOSSIER_ACCESSED' =>
                ar ? 'فتح ملف فني للمراجعة' : 'Professional dossier accessed',
              'PRO_DOCUMENT_ACCESS_GRANTED' =>
                ar
                    ? 'السماح بعرض مستند خاص'
                    : 'Private document access granted',
              'PRO_PROFILE_REVIEWED' =>
                ar
                    ? 'تسجيل قرار مراجعة فني'
                    : 'Professional review decision recorded',
              _ => ar ? 'تغيير إداري' : 'Administration change',
            }),
            subtitle: Text(
              '${MaterialLocalizations.of(context).formatFullDate(item.createdAt.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(item.createdAt.toLocal()))}',
            ),
          ),
        ),
    ],
  );
}
