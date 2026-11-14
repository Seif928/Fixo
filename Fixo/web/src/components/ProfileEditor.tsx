'use client';

import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/utils/supabase/client';

export function ProfileEditor({ initialName }: { initialName: string }) {
  const router = useRouter();
  const [fullName, setFullName] = useState(initialName);
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState<{ type: 'ok' | 'err'; text: string } | null>(null);

  async function handleSave(e: FormEvent) {
    e.preventDefault();
    const trimmed = fullName.trim();
    if (trimmed.length < 2) {
      setStatus({ type: 'err', text: 'الاسم الكامل يجب أن يكون حرفين على الأقل.' });
      return;
    }

    setSaving(true);
    setStatus(null);
    try {
      const supabase = createClient();
      const { error } = await supabase.auth.updateUser({
        data: { full_name: trimmed },
      });
      if (error) {
        setStatus({ type: 'err', text: error.message });
        return;
      }
      setStatus({ type: 'ok', text: 'تم تحديث الاسم بنجاح.' });
      router.refresh();
    } catch (err: unknown) {
      setStatus({
        type: 'err',
        text: err instanceof Error ? err.message : 'تعذر حفظ التغييرات.',
      });
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSave} className="mt-6 pt-6 border-t border-slate-100">
      <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">
        تعديل البيانات الشخصية
      </h3>
      <div className="flex flex-col sm:flex-row gap-3">
        <input
          type="text"
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          maxLength={80}
          placeholder="الاسم الكامل"
          className="flex-1 px-4 py-2.5 rounded-xl border border-slate-300 focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20 outline-none text-slate-900 text-sm"
        />
        <button
          type="submit"
          disabled={saving}
          className="px-5 py-2.5 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold text-sm shadow-xs transition disabled:opacity-50 cursor-pointer"
        >
          {saving ? 'جاري الحفظ...' : 'حفظ الاسم'}
        </button>
      </div>
      {status && (
        <p
          className={`mt-2 text-xs font-semibold ${
            status.type === 'ok' ? 'text-emerald-700' : 'text-rose-600'
          }`}
        >
          {status.text}
        </p>
      )}
    </form>
  );
}
