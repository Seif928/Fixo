'use client';

import { useState } from 'react';
import Link from 'next/link';
import type { LiveOffering } from '@/utils/api';

export interface WebBookingItem {
  id: string;
  orderCode: string;
  status: string;
  totalEgp: number;
  scheduledDate: string | null;
  timeWindow: string;
  serviceTitleAr: string;
  serviceTitleEn: string;
  addressLabel: string;
}

type BookingTab = 'ALL' | 'ACTIVE' | 'COMPLETED' | 'CANCELLED';

const ACTIVE_STATUSES = new Set([
  'DRAFT',
  'PENDING_DISPATCH',
  'OFFERED_TO_PRO',
  'ACCEPTED',
  'EN_ROUTE',
  'ARRIVED',
  'IN_PROGRESS',
]);

function getStatusBadge(status: string) {
  if (status === 'COMPLETED') {
    return {
      label: 'مكتمل بنجاح',
      className: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    };
  }
  if (status === 'CANCELLED') {
    return {
      label: 'ملغى',
      className: 'bg-rose-50 text-rose-700 border-rose-200',
    };
  }
  return {
    label: status === 'DRAFT' ? 'مسودة' : 'قيد المتابعة والتنفيذ',
    className: 'bg-amber-50 text-amber-700 border-amber-200',
  };
}

export function BookingsClient({
  bookings,
  catalogOfferings,
  isPro,
  dbNotice,
}: {
  bookings: WebBookingItem[];
  catalogOfferings: LiveOffering[];
  isPro: boolean;
  dbNotice: string | null;
}) {
  const [tab, setTab] = useState<BookingTab>('ALL');
  const [selected, setSelected] = useState<WebBookingItem | null>(null);

  const activeItems = bookings.filter((b) => ACTIVE_STATUSES.has(b.status));
  const completedItems = bookings.filter((b) => b.status === 'COMPLETED');
  const cancelledItems = bookings.filter((b) => b.status === 'CANCELLED');

  const visibleItems =
    tab === 'ACTIVE'
      ? activeItems
      : tab === 'COMPLETED'
      ? completedItems
      : tab === 'CANCELLED'
      ? cancelledItems
      : bookings;

  return (
    <div>
      {dbNotice && (
        <div className="mb-6 p-4 rounded-2xl bg-amber-50 border border-amber-200 text-amber-900 text-xs sm:text-sm">
          {dbNotice}
        </div>
      )}

      {/* Interactive Filter Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-3 mb-6 overflow-x-auto text-sm font-semibold">
        <button
          type="button"
          onClick={() => setTab('ALL')}
          className={`px-4 py-2 rounded-lg transition cursor-pointer shrink-0 ${
            tab === 'ALL'
              ? 'bg-amber-600 text-white shadow-sm'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          الكل ({bookings.length})
        </button>
        <button
          type="button"
          onClick={() => setTab('ACTIVE')}
          className={`px-4 py-2 rounded-lg transition cursor-pointer shrink-0 ${
            tab === 'ACTIVE'
              ? 'bg-amber-600 text-white shadow-sm'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          قيد التنفيذ ({activeItems.length})
        </button>
        <button
          type="button"
          onClick={() => setTab('COMPLETED')}
          className={`px-4 py-2 rounded-lg transition cursor-pointer shrink-0 ${
            tab === 'COMPLETED'
              ? 'bg-amber-600 text-white shadow-sm'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          المكتملة ({completedItems.length})
        </button>
        <button
          type="button"
          onClick={() => setTab('CANCELLED')}
          className={`px-4 py-2 rounded-lg transition cursor-pointer shrink-0 ${
            tab === 'CANCELLED'
              ? 'bg-amber-600 text-white shadow-sm'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          الملغاة ({cancelledItems.length})
        </button>
      </div>

      {/* Bookings List or Empty State */}
      {visibleItems.length > 0 ? (
        <div className="space-y-4">
          {visibleItems.map((item) => {
            const badge = getStatusBadge(item.status);
            return (
              <div
                key={item.id}
                className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm hover:border-amber-400 transition"
              >
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center shrink-0 font-black">
                      🔧
                    </div>
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-xs font-mono font-bold text-slate-500">
                          #{item.orderCode}
                        </span>
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${badge.className}`}
                        >
                          {badge.label}
                        </span>
                      </div>
                      <h3 className="text-lg font-bold text-slate-900">
                        {item.serviceTitleAr || item.serviceTitleEn}
                      </h3>
                      <p className="text-xs text-slate-500 mt-0.5">
                        {item.scheduledDate
                          ? new Date(item.scheduledDate).toLocaleDateString('ar-EG', {
                              year: 'numeric',
                              month: 'long',
                              day: 'numeric',
                            })
                          : 'غير محدد'}{' '}
                        • {item.timeWindow} • {item.addressLabel}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center justify-between md:justify-end gap-6 pt-3 md:pt-0 border-t md:border-0 border-slate-100">
                    <div className="text-left md:text-right">
                      <span className="text-xs text-slate-400 block">الإجمالي</span>
                      <span className="text-lg font-black text-slate-900">
                        {item.totalEgp} ج.م
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => setSelected(item)}
                      className="px-4 py-2 text-xs font-bold text-amber-700 bg-amber-50 hover:bg-amber-100 rounded-xl transition border border-amber-200 cursor-pointer"
                    >
                      عرض التفاصيل
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="bg-white p-8 rounded-3xl border border-slate-200/80 shadow-sm text-center">
          <div className="w-14 h-14 mx-auto rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center text-2xl mb-4">
            📋
          </div>
          <h3 className="text-lg font-black text-slate-900 mb-2">
            {isPro
              ? 'لا توجد طلبات مسندة في هذا التبويب حالياً'
              : 'لا توجد حجوزات مسجلة في هذا التبويب'}
          </h3>
          <p className="text-sm text-slate-500 max-w-md mx-auto mb-6">
            عندما تقوم بحجز أي خدمة صيانة منزلية عبر تطبيق فيكسو أو الموقع، ستظهر تفاصيل الطلب وحالة التنفيذ هنا مباشرة.
          </p>
          <Link
            href="/"
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-amber-600 hover:bg-amber-700 text-white text-sm font-bold rounded-xl shadow-sm transition"
          >
            استعراض الخدمات المتاحة ←
          </Link>
        </div>
      )}

      {/* Live Services Catalog Quick View */}
      {catalogOfferings.length > 0 && (
        <div className="mt-10">
          <h2 className="text-lg font-black text-slate-900 mb-4">
            الخدمات المتاحة للحجز السريع
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {catalogOfferings.slice(0, 6).map((off) => (
              <div
                key={off.id}
                className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full">
                      {off.categorySlug}
                    </span>
                    <span className="text-xs font-mono font-bold text-emerald-700">
                      {off.flatPriceEgp} ج.م
                    </span>
                  </div>
                  <h3 className="font-bold text-slate-900 text-sm mb-1">
                    {off.titleAr}
                  </h3>
                  <p className="text-xs text-slate-500 line-clamp-2">
                    {off.descriptionAr}
                  </p>
                </div>
                <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                  <span>المدة التقديرية: {off.estimatedDurationMins} دقيقة</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Booking Details Modal */}
      {selected && (
        <div
          className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setSelected(null)}
        >
          <div
            className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-4">
              <span className="text-xs font-mono font-bold text-slate-500">
                #{selected.orderCode}
              </span>
              <button
                type="button"
                onClick={() => setSelected(null)}
                className="text-slate-400 hover:text-slate-700 text-sm font-bold px-2 py-1 rounded-lg cursor-pointer"
              >
                إغلاق ✕
              </button>
            </div>
            <h3 className="text-xl font-black text-slate-900 mb-2">
              {selected.serviceTitleAr || selected.serviceTitleEn}
            </h3>
            <div className="space-y-2.5 text-sm text-slate-600 mt-4 bg-slate-50 p-4 rounded-2xl border border-slate-100">
              <div className="flex justify-between">
                <span className="text-slate-400">الحالة:</span>
                <span className="font-bold text-slate-900">
                  {getStatusBadge(selected.status).label} ({selected.status})
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">الموعد:</span>
                <span className="font-semibold">
                  {selected.scheduledDate
                    ? new Date(selected.scheduledDate).toLocaleDateString('ar-EG')
                    : 'غير محدد'}{' '}
                  ({selected.timeWindow})
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">العنوان:</span>
                <span className="font-semibold">{selected.addressLabel}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">الإجمالي:</span>
                <span className="font-black text-emerald-700">
                  {selected.totalEgp} ج.م
                </span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
