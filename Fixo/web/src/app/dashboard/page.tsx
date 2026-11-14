import Link from 'next/link';
import { createClient } from '@/utils/supabase/server';
import { getUserDisplayRole } from '@/utils/auth-role';
import { fetchLiveCatalog } from '@/utils/api';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login?redirectTo=/dashboard');
  }

  const meta = user.user_metadata ?? {};
  const fullName = meta.full_name || user.email?.split('@')[0] || 'مستخدم فيكسو';
  const role = getUserDisplayRole(user);
  const isPro = role === 'PRO';
  const isAdmin = role === 'ADMIN';
  const catalog = await fetchLiveCatalog();

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-amber-600 to-amber-700 rounded-3xl p-8 text-white shadow-lg shadow-amber-600/15 mb-8">
        <div className="max-w-2xl">
          <span className="inline-block bg-white/20 text-white text-xs font-bold px-3 py-1 rounded-full mb-3 backdrop-blur-sm">
            {isAdmin
              ? 'لوحة الإدارة والعميل'
              : isPro
              ? 'لوحة تحكم الفني المحترف'
              : 'لوحة تحكم العميل'}
          </span>
          <h1 className="text-3xl sm:text-4xl font-black tracking-tight mb-2">
            أهلاً بك، {fullName} 👋
          </h1>
          <p className="text-amber-100 text-sm sm:text-base leading-relaxed">
            {isPro
              ? 'مرحباً بك في لوحة تحكم الفنيين! يمكنك استعراض طلبات الصيانة المتاحة، وإدارة جدول مواعيدك.'
              : 'أهلاً بك في فيكسو! اطلب خدمات الصيانة المنزلية الموثوقة بكل سهولة وسرعة وبأسعار شفافة.'}
          </p>
        </div>
      </div>

      {/* Stats & Overview Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold text-slate-500 uppercase">حالة الحساب</span>
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
          </div>
          <p className="text-2xl font-black text-slate-900">نشط وموثّق</p>
          <p className="text-xs text-slate-500 mt-1">{user.email || user.phone || user.id}</p>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold text-slate-500 uppercase">نوع العضوية</span>
            <span className="text-amber-600 text-xs font-bold">FIXO {role}</span>
          </div>
          <p className="text-2xl font-black text-slate-900">
            {isAdmin ? 'مدير النظام' : isPro ? 'فني معتمد' : 'عميل مميز'}
          </p>
          <p className="text-xs text-slate-500 mt-1">
            {isPro ? 'مؤهل لتلقي طلبات العمل' : 'جاهز لحجز الخدمات المنزلية'}
          </p>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold text-slate-500 uppercase">حالة الخدمة المباشرة</span>
            <span
              className={`text-xs font-bold ${
                catalog.connected ? 'text-emerald-600' : 'text-amber-600'
              }`}
            >
              {catalog.connected ? 'متصل بـ FIXO API' : 'جاهز للعمل'}
            </span>
          </div>
          <p className="text-2xl font-black text-slate-900">
            {catalog.offerings.length} خدمة متاحة
          </p>
          <p className="text-xs text-slate-500 mt-1">
            {catalog.categories.length} أقسام صيانة نشطة بالقاهرة والجيزة
          </p>
        </div>
      </div>

      {/* Quick Navigation Cards */}
      <h2 className="text-xl font-bold text-slate-900 mb-4">روابط سريعة</h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {isAdmin && (
          <Link
            href="/admin"
            className="group bg-rose-50/70 p-6 rounded-2xl border border-rose-200 shadow-sm hover:border-rose-400 hover:shadow-md transition"
          >
            <div className="w-12 h-12 rounded-xl bg-rose-100 text-rose-700 flex items-center justify-center mb-4 text-xl font-black">
              👑
            </div>
            <h3 className="font-bold text-rose-900 text-lg">لوحة تحكم الإدارة</h3>
            <p className="text-rose-700/80 text-sm mt-1">
              مراقبة المستخدمين، الحجوزات، الشكاوى، ومؤشرات المنصة.
            </p>
          </Link>
        )}

        <Link
          href="/bookings"
          className="group bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:border-amber-500 hover:shadow-md transition"
        >
          <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center mb-4 group-hover:scale-110 transition">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
          <h3 className="font-bold text-slate-900 text-lg group-hover:text-amber-600 transition">
            سجل الحجوزات
          </h3>
          <p className="text-slate-500 text-sm mt-1">
            استعراض طلبات الصيانة السابقة والحالية ومتابعة حالات التنفيذ.
          </p>
        </Link>

        <Link
          href="/profile"
          className="group bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:border-amber-500 hover:shadow-md transition"
        >
          <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mb-4 group-hover:scale-110 transition">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <h3 className="font-bold text-slate-900 text-lg group-hover:text-amber-600 transition">
            الملف الشخصي
          </h3>
          <p className="text-slate-500 text-sm mt-1">
            إدارة بيانات حسابك، تعديل الاسم، ومراجعة تفاصيل الجلسة.
          </p>
        </Link>
      </div>
    </div>
  );
}
