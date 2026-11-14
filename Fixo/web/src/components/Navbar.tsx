import Link from 'next/link';
import { Suspense } from 'react';
import { createClient } from '@/utils/supabase/server';
import { getUserDisplayRole, isVerifiedAdmin } from '@/utils/auth-role';
import { SignOutButton } from './SignOutButton';

function NavbarSkeleton() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-slate-200/80 bg-white/90 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        <div className="flex items-center gap-8">
          <Link href="/" className="flex items-center gap-2">
            <span className="w-8 h-8 rounded-lg bg-amber-600 text-white font-black flex items-center justify-center text-lg shadow-sm">
              F
            </span>
            <span className="text-xl font-extrabold tracking-tight text-slate-900">
              FIXO <span className="text-amber-600 text-xs font-semibold px-1.5 py-0.5 rounded bg-amber-50 border border-amber-200">خدمات</span>
            </span>
          </Link>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-20 h-8 bg-slate-100 rounded-lg animate-pulse" />
        </div>
      </div>
    </header>
  );
}

async function NavbarServer() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const meta = user?.user_metadata ?? {};
  const isAdmin = isVerifiedAdmin(user);
  const role = getUserDisplayRole(user);
  const isPro = role === 'PRO';

  const fullName: string =
    meta.full_name || user?.email?.split('@')[0] || (isAdmin ? 'مدير النظام' : 'مستخدم فيكسو');
  const roleBadge: string = isAdmin
    ? '👑 مدير النظام (ADMIN)'
    : isPro
    ? 'فني محترف (PRO)'
    : 'عميل (CUSTOMER)';
  const avatarUrl: string | undefined =
    typeof meta.avatar_url === 'string' && meta.avatar_url.startsWith('https://')
      ? meta.avatar_url
      : undefined;
  const initial = (fullName.trim()[0] || 'F').toUpperCase();

  return (
    <header className="sticky top-0 z-50 w-full border-b border-slate-200/80 bg-white/90 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand & Desktop Nav links */}
        <div className="flex items-center gap-6 sm:gap-8">
          <Link href={isAdmin ? '/admin' : user ? '/dashboard' : '/'} className="flex items-center gap-2 group">
            <span className="w-8 h-8 rounded-lg bg-amber-600 text-white font-black flex items-center justify-center text-lg shadow-sm group-hover:bg-amber-700 transition">
              F
            </span>
            <span className="text-xl font-extrabold tracking-tight text-slate-900">
              FIXO <span className="text-amber-600 text-xs font-semibold px-1.5 py-0.5 rounded bg-amber-50 border border-amber-200">خدمات</span>
            </span>
          </Link>

          {user && (
            <nav className="hidden md:flex items-center gap-1.5 text-sm font-medium text-slate-700">
              {isAdmin && (
                <Link
                  href="/admin"
                  className="px-3 py-1.5 rounded-lg text-rose-700 bg-rose-50 border border-rose-200 hover:bg-rose-100 font-extrabold transition flex items-center gap-1 shadow-xs"
                >
                  <span>👑</span>
                  <span>لوحة الإدارة</span>
                </Link>
              )}
              <Link
                href="/dashboard"
                className="px-3 py-1.5 rounded-lg hover:text-amber-600 hover:bg-slate-50 transition"
              >
                لوحة التحكم
              </Link>
              <Link
                href="/bookings"
                className="px-3 py-1.5 rounded-lg hover:text-amber-600 hover:bg-slate-50 transition"
              >
                الحجوزات
              </Link>
              <Link
                href="/profile"
                className="px-3 py-1.5 rounded-lg hover:text-amber-600 hover:bg-slate-50 transition"
              >
                الملف الشخصي
              </Link>
            </nav>
          )}
        </div>

        {/* Right Section: User Profile or Login/Register buttons */}
        <div className="flex items-center gap-3">
          {user ? (
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-2.5 text-right">
                {avatarUrl ? (
                  /* eslint-disable-next-line @next/next/no-img-element */
                  <img
                    src={avatarUrl}
                    alt={fullName}
                    referrerPolicy="no-referrer"
                    className="w-9 h-9 rounded-full object-cover border border-slate-200 shadow-sm"
                  />
                ) : (
                  <div
                    className={`w-9 h-9 rounded-full font-bold text-sm flex items-center justify-center shadow-sm text-white ${
                      isAdmin
                        ? 'bg-gradient-to-br from-rose-500 to-rose-700'
                        : 'bg-gradient-to-br from-amber-500 to-amber-700'
                    }`}
                  >
                    {initial}
                  </div>
                )}
                <div className="hidden sm:block text-right">
                  <p className="text-xs font-bold text-slate-900 leading-tight">{fullName}</p>
                  <span
                    className={`inline-block text-[10px] font-semibold px-1.5 py-0.2 rounded ${
                      isAdmin
                        ? 'bg-rose-50 text-rose-700 border border-rose-200'
                        : isPro
                        ? 'bg-blue-50 text-blue-700 border border-blue-200'
                        : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                    }`}
                  >
                    {roleBadge}
                  </span>
                </div>
              </div>
              <div className="h-6 w-px bg-slate-200 mx-1 hidden sm:block" />
              <SignOutButton />
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="px-3.5 py-2 text-sm font-semibold text-slate-700 hover:text-amber-600 hover:bg-slate-50 rounded-lg transition"
              >
                تسجيل الدخول
              </Link>
              <Link
                href="/register"
                className="px-4 py-2 text-sm font-semibold text-white bg-amber-600 hover:bg-amber-700 rounded-lg shadow-sm transition"
              >
                إنشاء حساب
              </Link>
            </div>
          )}
        </div>
      </div>

      {/* Responsive Mobile Navigation for authenticated users */}
      {user && (
        <nav className="md:hidden border-t border-slate-100 bg-slate-50/90 px-4 py-2 flex items-center gap-2 overflow-x-auto text-xs font-bold text-slate-700">
          {isAdmin && (
            <Link
              href="/admin"
              className="px-3 py-1.5 rounded-lg text-rose-700 bg-rose-50 border border-rose-200 shrink-0"
            >
              👑 الإدارة
            </Link>
          )}
          <Link href="/dashboard" className="px-3 py-1.5 rounded-lg bg-white border border-slate-200 shrink-0">
            لوحة التحكم
          </Link>
          <Link href="/bookings" className="px-3 py-1.5 rounded-lg bg-white border border-slate-200 shrink-0">
            الحجوزات
          </Link>
          <Link href="/profile" className="px-3 py-1.5 rounded-lg bg-white border border-slate-200 shrink-0">
            الملف الشخصي
          </Link>
        </nav>
      )}
    </header>
  );
}

export function Navbar() {
  return (
    <Suspense fallback={<NavbarSkeleton />}>
      <NavbarServer />
    </Suspense>
  );
}
