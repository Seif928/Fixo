import Link from 'next/link';
import { createClient } from '@/utils/supabase/server';
import { fetchLiveCatalog } from '@/utils/api';

const FALLBACK_CATEGORIES = [
  {
    id: 'cat-ac',
    slug: 'ac-maintenance',
    nameAr: 'صيانة التكييف',
    nameEn: 'AC Maintenance',
    subtitleAr: 'شحن فريون، صيانة دورية، تنظيف وغسيل التكييفات وحل مشاكل التسريب.',
    startingPriceEgp: 150,
  },
  {
    id: 'cat-electrical',
    slug: 'electrical',
    nameAr: 'الأعمال الكهربائية',
    nameEn: 'Electrical',
    subtitleAr: 'تأسيس وصيانة اللوحات الكهربائية، تركيب وحدات الإنارة وإصلاح الأعطال الطارئة.',
    startingPriceEgp: 120,
  },
  {
    id: 'cat-plumbing',
    slug: 'plumbing',
    nameAr: 'السباكة ومعالجة المياه',
    nameEn: 'Plumbing',
    subtitleAr: 'تصليح تسريبات المياه، تركيب الأدوات الصحية، وصيانة سخانات المياه والفلاتر.',
    startingPriceEgp: 120,
  },
  {
    id: 'cat-carpentry',
    slug: 'carpentry',
    nameAr: 'النجارة وتركيب الأثاث',
    nameEn: 'Carpentry',
    subtitleAr: 'تركيب وصيانة الأبواب والشبابيك، تجميع وتعديل الأثاث المنزلي والمكتبي.',
    startingPriceEgp: 150,
  },
];

const CATEGORY_ICONS: Record<string, string> = {
  'ac-maintenance': '❄️',
  electrical: '⚡',
  plumbing: '🔧',
  carpentry: '🚪',
  cleaning: '✨',
  appliances: '🔌',
};

export default async function HomePage() {
  const supabase = await createClient();
  const [{ data: { user } }, catalog] = await Promise.all([
    supabase.auth.getUser(),
    fetchLiveCatalog(),
  ]);

  const meta = user?.user_metadata ?? {};
  const fullName = meta.full_name || user?.email?.split('@')[0];
  const categories =
    catalog.categories.length > 0 ? catalog.categories : FALLBACK_CATEGORIES;

  return (
    <div className="flex-1 flex flex-col">
      {/* Hero Section */}
      <section className="relative overflow-hidden bg-gradient-to-b from-amber-500/10 via-slate-50 to-slate-50 py-20 sm:py-28">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10">
          <div className="inline-flex items-center gap-2 bg-amber-100 text-amber-800 text-xs font-bold px-3 py-1.5 rounded-full mb-6 border border-amber-200 shadow-xs">
            <span>🚀</span>
            <span>المنصة الرائدة لخدمات الصيانة والتشطيبات المنزلية في مصر</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black text-slate-900 tracking-tight leading-tight sm:leading-tight max-w-4xl mx-auto mb-6">
            صيانة منزلك بكل سهولة وأمان مع{' '}
            <span className="text-amber-600 underline decoration-amber-300 underline-offset-8">
              فيكسو (FIXO)
            </span>
          </h1>

          <p className="text-base sm:text-lg text-slate-600 max-w-2xl mx-auto mb-10 leading-relaxed">
            نربطك بأفضل الفنيين المعتمدين والمحترفين في صيانة الكهرباء، السباكة، التكييف، والنجارة
            مع أسعار معلنة وضمان شامل للخدمة.
          </p>

          {/* Action CTAs */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            {user ? (
              <>
                <Link
                  href="/dashboard"
                  className="w-full sm:w-auto px-8 py-3.5 bg-amber-600 hover:bg-amber-700 text-white font-bold rounded-xl shadow-lg shadow-amber-600/25 transition active:scale-[0.99] flex items-center justify-center gap-2"
                >
                  <span>أهلاً {fullName} — افتح لوحة التحكم</span>
                  <span>←</span>
                </Link>
                <Link
                  href="/bookings"
                  className="w-full sm:w-auto px-8 py-3.5 bg-white hover:bg-slate-50 text-slate-800 font-bold rounded-xl border border-slate-200 shadow-sm transition flex items-center justify-center"
                >
                  عرض سجل الحجوزات
                </Link>
              </>
            ) : (
              <>
                <Link
                  href="/register"
                  className="w-full sm:w-auto px-8 py-3.5 bg-amber-600 hover:bg-amber-700 text-white font-bold rounded-xl shadow-lg shadow-amber-600/25 transition active:scale-[0.99] flex items-center justify-center gap-2"
                >
                  <span>ابدأ الآن - حساب جديد</span>
                  <span>←</span>
                </Link>
                <Link
                  href="/login"
                  className="w-full sm:w-auto px-8 py-3.5 bg-white hover:bg-slate-50 text-slate-800 font-bold rounded-xl border border-slate-200 shadow-sm transition flex items-center justify-center"
                >
                  تسجيل الدخول
                </Link>
              </>
            )}
          </div>
        </div>
      </section>

      {/* Services Grid */}
      <section className="py-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full">
        <div className="text-center mb-12">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-900">خدماتنا المتميزة</h2>
          <p className="text-slate-500 text-sm mt-2">
            اختر الخدمة التي تحتاجها وسنوصلك بالفني الأنسب فوراً
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {categories.slice(0, 8).map((cat) => (
            <div
              key={cat.id}
              className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:border-amber-400 hover:shadow-md transition group flex flex-col justify-between"
            >
              <div>
                <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center mb-4 text-2xl group-hover:scale-110 transition">
                  {CATEGORY_ICONS[cat.slug] ?? '🛠️'}
                </div>
                <h3 className="font-bold text-slate-900 text-lg mb-1">{cat.nameAr}</h3>
                <p className="text-xs text-slate-500 leading-relaxed">
                  {cat.subtitleAr || cat.nameEn}
                </p>
              </div>
              <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-400">تبدأ من</span>
                <span className="font-black text-emerald-700 font-mono">
                  {cat.startingPriceEgp} ج.م
                </span>
              </div>
            </div>
          ))}
        </div>

        {catalog.offerings.length > 0 && (
          <div className="mt-14">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-xl font-black text-slate-900">أشهر الباقات والخدمات الفورية</h3>
                <p className="text-xs text-slate-500 mt-1">
                  أسعار معلنة ومحدثة مباشرة من قاعدة بيانات FIXO
                </p>
              </div>
              <Link
                href={user ? '/bookings' : '/register'}
                className="text-xs font-bold text-amber-600 hover:underline"
              >
                {user ? 'عرض الحجوزات ←' : 'سجل الآن للحجز ←'}
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {catalog.offerings.slice(0, 4).map((off) => (
                <div
                  key={off.id}
                  className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs"
                >
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-[11px] font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-full">
                      {off.badgeAr || off.categorySlug}
                    </span>
                    <span className="font-mono font-black text-emerald-700 text-sm">
                      {off.flatPriceEgp} ج.م
                    </span>
                  </div>
                  <h4 className="font-bold text-slate-900 text-sm mb-1">{off.titleAr}</h4>
                  <p className="text-xs text-slate-500 line-clamp-2">{off.descriptionAr}</p>
                </div>
              ))}
            </div>
          </div>
        )}
      </section>

      {/* Footer */}
      <footer className="mt-auto border-t border-slate-200/80 bg-white py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500">
          <p>© {new Date().getFullYear()} FIXO Home Services — جميع الحقوق محفوظة.</p>
          <div className="flex items-center gap-4">
            <span>القاهرة والجيزة • EGP</span>
            <Link href="/login" className="hover:text-amber-600 font-semibold">
              تسجيل الدخول
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
