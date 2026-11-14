import Link from 'next/link';
import { createClient } from '@/utils/supabase/server';
import { createAdminClient } from '@/utils/supabase/admin';
import { isVerifiedAdmin } from '@/utils/auth-role';
import { fetchLiveCatalog } from '@/utils/api';
import { redirect } from 'next/navigation';
import { SignOutButton } from '@/components/SignOutButton';

export default async function AdminPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login?redirectTo=/admin');
  }

  if (!isVerifiedAdmin(user)) {
    redirect('/dashboard');
  }

  const adminDb = createAdminClient();
  let totalUsersCount = 0;
  let prosCount = 0;
  let bookingsCount = 0;
  let complaintsCount = 0;
  let recentBookings: Array<{
    id: string;
    orderCode: string;
    status: string;
    totalEgp: number;
    scheduledDate: string | null;
    createdAt: string | null;
  }> = [];
  let usersList: Array<{
    id: string;
    fullName: string | null;
    email: string | null;
    phone: string | null;
    role: string;
    createdAt: string | null;
  }> = [];
  let dbNotice: string | null = null;

  if (adminDb) {
    const [
      usersRes,
      prosRes,
      bookingsRes,
      complaintsRes,
      recentRes,
      usersListRes,
    ] = await Promise.all([
      adminDb.from('User').select('*', { count: 'exact', head: true }),
      adminDb.from('ProProfile').select('*', { count: 'exact', head: true }),
      adminDb.from('Booking').select('*', { count: 'exact', head: true }),
      adminDb.from('Complaint').select('*', { count: 'exact', head: true }),
      adminDb
        .from('Booking')
        .select('id, orderCode, status, totalEgp, scheduledDate, createdAt')
        .order('createdAt', { ascending: false })
        .limit(8),
      adminDb
        .from('User')
        .select('id, fullName, email, phone, role, createdAt')
        .order('createdAt', { ascending: false })
        .limit(8),
    ]);

    const firstError =
      usersRes.error ||
      prosRes.error ||
      bookingsRes.error ||
      complaintsRes.error ||
      recentRes.error ||
      usersListRes.error;

    if (firstError) {
      dbNotice = `تعذر قراءة بعض سجلات قاعدة البيانات مباشرة: ${firstError.message}`;
    }

    totalUsersCount = usersRes.count ?? 0;
    prosCount = prosRes.count ?? 0;
    bookingsCount = bookingsRes.count ?? 0;
    complaintsCount = complaintsRes.count ?? 0;
    recentBookings = (recentRes.data as typeof recentBookings) ?? [];
    usersList = (usersListRes.data as typeof usersList) ?? [];
  } else {
    dbNotice =
      'مفتاح الخدمة الإداري (SUPABASE_SERVICE_ROLE_KEY) غير مُعد في بيئة الويب؛ لا يمكن عرض جداول PostgreSQL المحمية بنظام RLS مباشرة من هذا النطاق.';
  }

  const catalog = await fetchLiveCatalog();

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full">
      {/* Top Banner / Welcome */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-800 to-amber-950 rounded-3xl p-6 sm:p-8 text-white shadow-xl mb-8 relative overflow-hidden">
        <div className="absolute top-0 right-0 -mt-10 -mr-10 w-48 h-48 bg-amber-500/10 rounded-full blur-2xl pointer-events-none" />
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 relative z-10">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className="px-3 py-1 rounded-full bg-rose-500/20 border border-rose-500/30 text-rose-300 font-extrabold text-xs flex items-center gap-1.5">
                <span>👑</span>
                <span>لوحة تحكم المالك والإدارة العليا</span>
              </span>
              <span className="text-xs text-slate-400">FIXO Master Admin</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              أهلاً بك يا مدير النظام ({user.email})
            </h1>
            <p className="text-sm text-slate-300 mt-1">
              تم التحقق من الصلاحية الإدارية على السيرفر مع عزل الجداول بنظام Row-Level Security.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/dashboard"
              className="px-4 py-2 bg-white/10 hover:bg-white/20 border border-white/10 text-white rounded-xl text-sm font-semibold transition"
            >
              عرض كعميل
            </Link>
            <SignOutButton />
          </div>
        </div>
      </div>

      {dbNotice && (
        <div className="mb-6 p-4 rounded-2xl bg-amber-50 border border-amber-200 text-amber-900 text-xs sm:text-sm flex items-start gap-2.5">
          <span className="font-bold">⚠️ تنبيه:</span>
          <span>{dbNotice}</span>
        </div>
      )}

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-8">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-slate-500 uppercase">إجمالي المستخدمين</span>
            <span className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center text-sm font-black">👥</span>
          </div>
          <div className="text-2xl sm:text-3xl font-black text-slate-900">{totalUsersCount}</div>
          <div className="text-[11px] text-slate-400 mt-1">عملاء وفنيين مسجلين</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-slate-500 uppercase">الفنيين المحترفين (Pros)</span>
            <span className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center text-sm font-black">🛠️</span>
          </div>
          <div className="text-2xl sm:text-3xl font-black text-slate-900">{prosCount}</div>
          <div className="text-[11px] text-slate-400 mt-1">حرفيين معتمدين بالقاهرة والجيزة</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-slate-500 uppercase">إجمالي الحجوزات</span>
            <span className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center text-sm font-black">📋</span>
          </div>
          <div className="text-2xl sm:text-3xl font-black text-slate-900">{bookingsCount}</div>
          <div className="text-[11px] text-slate-400 mt-1">طلبات صيانة وخدمات</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-bold text-slate-500 uppercase">الشكاوى والبلاغات</span>
            <span className="w-8 h-8 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center text-sm font-black">⚠️</span>
          </div>
          <div className="text-2xl sm:text-3xl font-black text-slate-900">{complaintsCount}</div>
          <div className="text-[11px] text-slate-400 mt-1">تحت المتابعة والمراجعة</div>
        </div>
      </div>

      {/* Live API Telemetry */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-5 mb-8 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <span
            className={`w-2.5 h-2.5 rounded-full ${
              catalog.connected ? 'bg-emerald-500' : 'bg-rose-500'
            }`}
          />
          <div>
            <p className="text-sm font-bold text-slate-900">
              حالة الخادم الخلفي (FIXO API): {catalog.connected ? 'متصل وجاهز' : 'غير متصل'}
            </p>
            <p className="text-xs text-slate-500">
              عدد الأقسام النشطة: {catalog.categories.length} • عدد الخدمات المنشورة: {catalog.offerings.length}
            </p>
          </div>
        </div>
        <Link
          href="/bookings"
          className="px-4 py-2 text-xs font-bold text-amber-700 bg-amber-50 hover:bg-amber-100 border border-amber-200 rounded-xl transition"
        >
          مراجعة الحجوزات ←
        </Link>
      </div>

      {/* Main Tables Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* Recent Bookings */}
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-black text-slate-900 flex items-center gap-2">
              <span>📋</span>
              <span>أحدث الحجوزات والطلبات</span>
            </h2>
            <Link href="/bookings" className="text-xs font-bold text-amber-600 hover:underline">
              عرض الكل ←
            </Link>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead>
                <tr className="border-b border-slate-100 text-slate-400 font-bold">
                  <th className="pb-3">كود الطلب</th>
                  <th className="pb-3">الحالة</th>
                  <th className="pb-3">القيمة (EGP)</th>
                  <th className="pb-3">التاريخ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {recentBookings.length > 0 ? (
                  recentBookings.map((b) => (
                    <tr key={b.id} className="hover:bg-slate-50/80 transition">
                      <td className="py-3 font-mono font-bold text-slate-900">{b.orderCode}</td>
                      <td className="py-3">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700">
                          {b.status}
                        </span>
                      </td>
                      <td className="py-3 font-bold text-emerald-700 font-mono">{b.totalEgp} ج.م</td>
                      <td className="py-3 text-slate-500">
                        {b.scheduledDate ? new Date(b.scheduledDate).toLocaleDateString('ar-EG') : 'غير محدد'}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="py-6 text-center text-slate-400">
                      لا توجد حجوزات مسجلة حالياً
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Registered Users */}
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-black text-slate-900 flex items-center gap-2">
              <span>👥</span>
              <span>المستخدمين المسجلين بالمنصة</span>
            </h2>
            <span className="text-xs text-slate-400 font-bold">سجلات حية من الداتابيز</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead>
                <tr className="border-b border-slate-100 text-slate-400 font-bold">
                  <th className="pb-3">الاسم</th>
                  <th className="pb-3">البريد / الهاتف</th>
                  <th className="pb-3">الدور</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {usersList.length > 0 ? (
                  usersList.map((u) => (
                    <tr key={u.id} className="hover:bg-slate-50/80 transition">
                      <td className="py-3 font-bold text-slate-900">{u.fullName || 'بدون اسم'}</td>
                      <td className="py-3 font-mono text-slate-600">
                        {u.email || u.phone || 'غير مسجل'}
                      </td>
                      <td className="py-3">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                            u.role === 'ADMIN'
                              ? 'bg-rose-100 text-rose-800 border border-rose-200'
                              : u.role === 'PRO'
                              ? 'bg-blue-100 text-blue-800'
                              : 'bg-emerald-100 text-emerald-800'
                          }`}
                        >
                          {u.role === 'ADMIN' ? '👑 أدمن' : u.role === 'PRO' ? 'فني' : 'عميل'}
                        </span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={3} className="py-6 text-center text-slate-400">
                      لا يوجد مستخدمين
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
