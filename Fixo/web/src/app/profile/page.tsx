import Link from 'next/link';
import { createClient } from '@/utils/supabase/server';
import { getUserDisplayRole } from '@/utils/auth-role';
import { redirect } from 'next/navigation';
import { SignOutButton } from '@/components/SignOutButton';
import { ProfileEditor } from '@/components/ProfileEditor';

export default async function ProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login?redirectTo=/profile');
  }

  const meta = user.user_metadata ?? {};
  const fullName = meta.full_name || user.email?.split('@')[0] || 'مستخدم فيكسو';
  const role = getUserDisplayRole(user);
  const isPro = role === 'PRO';
  const isAdmin = role === 'ADMIN';
  const phone = user.phone || meta.phone || 'غير مسجل';
  const initial = (fullName.trim()[0] || 'F').toUpperCase();
  const createdAt = user.created_at
    ? new Date(user.created_at).toLocaleDateString('ar-EG', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      })
    : 'غير محدد';
  const lastSignIn = user.last_sign_in_at
    ? new Date(user.last_sign_in_at).toLocaleDateString('ar-EG', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      })
    : 'الجلسة الحالية';

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <span className="text-xs font-bold text-amber-600 bg-amber-50 border border-amber-200 px-3 py-1 rounded-full inline-block mb-2">
            إعدادات الحساب
          </span>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            الملف الشخصي
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            إدارة بياناتك الشخصية وحسابك في منصة FIXO.
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

      {/* Profile Card */}
      <div className="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden mb-8">
        <div className="h-32 bg-gradient-to-r from-amber-500 to-amber-700" />
        <div className="px-6 sm:px-8 pb-8 pt-0 relative">
          <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 -mt-14 mb-6">
            <div className="flex items-end gap-4">
              <div className="w-24 h-24 rounded-2xl bg-white p-1.5 shadow-md">
                <div className="w-full h-full rounded-xl bg-gradient-to-br from-amber-500 to-amber-700 text-white font-black text-3xl flex items-center justify-center shadow-inner">
                  {initial}
                </div>
              </div>
              <div className="mb-2">
                <h2 className="text-xl sm:text-2xl font-black text-slate-900">{fullName}</h2>
                <div className="flex items-center gap-2 mt-1">
                  <span
                    className={`inline-block text-xs font-bold px-2.5 py-0.5 rounded-full ${
                      isAdmin
                        ? 'bg-rose-50 text-rose-700 border border-rose-200'
                        : isPro
                        ? 'bg-blue-50 text-blue-700 border border-blue-200'
                        : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                    }`}
                  >
                    {isAdmin
                      ? '👑 مدير النظام (ADMIN)'
                      : isPro
                      ? 'فني محترف (PRO)'
                      : 'عميل (CUSTOMER)'}
                  </span>
                  <span className="text-xs text-slate-400">• حساب موثق بـ Supabase</span>
                </div>
              </div>
            </div>

            <div className="sm:self-center">
              <SignOutButton />
            </div>
          </div>

          <div className="border-t border-slate-100 pt-6">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4">
              بيانات الحساب الأساسية
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                <span className="text-xs text-slate-500 block mb-1">البريد الإلكتروني</span>
                <span className="font-semibold text-slate-900 text-sm font-mono">
                  {user.email || 'تسجيل برقم الهاتف'}
                </span>
              </div>

              <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                <span className="text-xs text-slate-500 block mb-1">رقم الهاتف المحمول</span>
                <span className="font-semibold text-slate-900 text-sm font-mono" dir="ltr">
                  {phone}
                </span>
              </div>

              <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                <span className="text-xs text-slate-500 block mb-1">معرّف المستخدم (Supabase UID)</span>
                <span className="font-semibold text-slate-900 text-xs font-mono break-all">
                  {user.id}
                </span>
              </div>

              <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                <span className="text-xs text-slate-500 block mb-1">تاريخ الإنشاء / آخر دخول</span>
                <span className="font-semibold text-slate-900 text-sm block">{createdAt}</span>
                <span className="text-[11px] text-slate-500 mt-0.5 block">آخر دخول: {lastSignIn}</span>
              </div>
            </div>

            <ProfileEditor initialName={fullName} />
          </div>
        </div>
      </div>
    </div>
  );
}
