import Link from 'next/link';
import { createClient } from '@/utils/supabase/server';
import { createAdminClient } from '@/utils/supabase/admin';
import { getUserDisplayRole } from '@/utils/auth-role';
import { fetchLiveCatalog } from '@/utils/api';
import {
  BookingsClient,
  type WebBookingItem,
} from '@/components/BookingsClient';
import { redirect } from 'next/navigation';

export default async function BookingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login?redirectTo=/bookings');
  }

  const role = getUserDisplayRole(user);
  const isPro = role === 'PRO';
  const adminDb = createAdminClient();

  let bookings: WebBookingItem[] = [];
  let dbNotice: string | null = null;

  if (adminDb) {
    const email = (user.email ?? '').trim().toLowerCase();
    const phone = (user.phone || (user.user_metadata?.phone as string) || '').trim();

    let dbUserId: string | null = null;
    if (email) {
      const { data: uByEmail } = await adminDb
        .from('User')
        .select('id')
        .eq('email', email)
        .maybeSingle();
      dbUserId = uByEmail?.id ?? null;
    }
    if (!dbUserId && phone) {
      const { data: uByPhone } = await adminDb
        .from('User')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();
      dbUserId = uByPhone?.id ?? null;
    }

    if (dbUserId) {
      const { data: rows, error } = await adminDb
        .from('Booking')
        .select(
          'id, orderCode, status, totalEgp, scheduledDate, timeWindow, offering:ServiceOffering(titleAr, titleEn), address:CustomerAddress(label, districtLine)',
        )
        .eq('customerId', dbUserId)
        .order('createdAt', { ascending: false })
        .limit(30);

      if (error) {
        dbNotice = `تعذر تحميل حجوزاتك حالياً: ${error.message}`;
      } else if (rows) {
        bookings = rows.map((row: Record<string, unknown>) => {
          const offering = (row.offering as Record<string, string> | null) ?? {};
          const address = (row.address as Record<string, string> | null) ?? {};
          return {
            id: String(row.id),
            orderCode: String(row.orderCode),
            status: String(row.status),
            totalEgp: Number(row.totalEgp ?? 0),
            scheduledDate: row.scheduledDate ? String(row.scheduledDate) : null,
            timeWindow: String(row.timeWindow ?? ''),
            serviceTitleAr: offering.titleAr ?? 'خدمة صيانة فيكسو',
            serviceTitleEn: offering.titleEn ?? 'FIXO Service',
            addressLabel:
              [address.label, address.districtLine].filter(Boolean).join(' - ') ||
              'القاهرة / الجيزة',
          };
        });
      }
    }
  } else {
    dbNotice =
      'عرض سجل الحجوزات المباشر يتطلب إعداد SUPABASE_SERVICE_ROLE_KEY على السيرفر. يمكنك استعراض كتالوج الخدمات المباشر بالأسفل.';
  }

  const catalog = await fetchLiveCatalog();

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <span className="text-xs font-bold text-amber-600 bg-amber-50 border border-amber-200 px-3 py-1 rounded-full inline-block mb-2">
            {isPro ? 'طلبات العمل المسندة' : 'سجل طلبات الصيانة'}
          </span>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            الحجوزات والطلبات
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            متابعة حالة الحجوزات الفعلية، المواعيد، والتفاصيل المالية.
          </p>
        </div>

        <div>
          <Link
            href="/dashboard"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-slate-700 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition shadow-sm"
          >
            ← العودة للوحة التحكم
          </Link>
        </div>
      </div>

      <BookingsClient
        bookings={bookings}
        catalogOfferings={catalog.offerings}
        isPro={isPro}
        dbNotice={dbNotice}
      />
    </div>
  );
}
