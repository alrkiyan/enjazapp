import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import Card from './Card';
import {
  Users, Star, Monitor, Trash2,
  ChevronDown, ChevronUp, Clock, ShieldCheck
} from 'lucide-react';

/* ─── Small helpers ─────────────────────────────────────────── */
const StatCard = ({ icon: Icon, color, label, value }) => (
  <Card className="p-6 text-center bg-white border-2 border-[#e2d5cc] hover:shadow-md transition-shadow">
    <div
      className="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-3"
      style={{ background: `${color}18` }}
    >
      <Icon size={26} style={{ color }} />
    </div>
    <div className="text-[#a99c92] font-bold text-sm mb-1">{label}</div>
    <div className="text-4xl font-black" style={{ color }}>
      {value ?? '—'}
    </div>
  </Card>
);

const formatDate = (iso) =>
  iso
    ? new Date(iso).toLocaleDateString('ar-SA', { year: 'numeric', month: 'short', day: 'numeric' })
    : 'لم يسجّل دخولاً بعد';

/* ─── Main component ────────────────────────────────────────── */
const SuperAdminStats = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(null); // family id that is expanded

  useEffect(() => { fetchStats(); }, []);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('admin_get_platform_stats');
      if (error) throw error;
      setStats(data);
    } catch (err) {
      console.error('admin_get_platform_stats:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleUnlink = async (sessionId) => {
    if (!window.confirm('فك ربط هذه الشاشة؟')) return;
    try {
      const { error } = await supabase.rpc('admin_unlink_kiosk', { session_id: sessionId });
      if (error) throw error;
      fetchStats();
    } catch (err) {
      alert('خطأ: ' + err.message);
    }
  };

  if (loading) {
    return (
      <div className="text-center text-[#a99c92] font-bold py-16 animate-pulse">
        جاري تحميل إحصائيات المنصة...
      </div>
    );
  }

  if (!stats) return null;
  const families = stats.families || [];

  return (
    <div className="space-y-6" dir="rtl">
      {/* ── Header stats row ──────────────────────────────────── */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard
          icon={Users}
          color="#49b5d0"
          label="عدد العوائل (الآباء المسجلين)"
          value={stats.families_count}
        />
        <StatCard
          icon={Star}
          color="#f0a63e"
          label="إجمالي الإنجازات بالمنصة"
          value={stats.total_achievements}
        />
        <StatCard
          icon={Monitor}
          color="#488b40"
          label="الشاشات المربوطة"
          value={stats.total_kiosks}
        />
      </div>

      {/* ── Families accordion ────────────────────────────────── */}
      <Card className="p-0 overflow-hidden border-2 border-[#e2d5cc] bg-white">
        <div className="px-6 py-4 border-b border-[#f0e6de] flex items-center gap-3">
          <ShieldCheck size={22} className="text-[#49b5d0]" />
          <h2 className="text-xl font-bold text-[#352c3c]">تفاصيل العوائل</h2>
        </div>

        {families.length === 0 ? (
          <div className="text-center text-[#a99c92] py-12 font-bold">
            لا توجد عوائل مسجلة بعد.
          </div>
        ) : (
          <div className="divide-y divide-[#f0e6de]">
            {families.map((fam) => {
              const isOpen = expanded === fam.id;
              const kiosks   = fam.kiosks   || [];
              const children = fam.children  || [];

              return (
                <div key={fam.id}>
                  {/* ── Row header ── */}
                  <button
                    onClick={() => setExpanded(isOpen ? null : fam.id)}
                    className="w-full flex items-center gap-4 px-6 py-4 hover:bg-[#faece3]/40 transition-colors text-right"
                  >
                    {/* Avatar letter */}
                    <div className="w-11 h-11 rounded-full bg-[#49b5d0]/10 flex items-center justify-center text-[#49b5d0] font-black text-lg shrink-0">
                      {fam.email.charAt(0).toUpperCase()}
                    </div>

                    {/* Email + last login */}
                    <div className="flex-1 min-w-0 text-right">
                      <p className="font-bold text-[#352c3c] truncate">{fam.email}</p>
                      <p className="text-xs text-[#a99c92] flex items-center gap-1 mt-0.5">
                        <Clock size={11} />
                        آخر دخول: {formatDate(fam.last_sign_in_at)}
                      </p>
                    </div>

                    {/* Badges */}
                    <div className="hidden md:flex items-center gap-2 shrink-0">
                      <span className="text-xs font-bold bg-[#49b5d0]/10 text-[#49b5d0] px-2.5 py-1 rounded-full">
                        {fam.children_count} {fam.children_count === 1 ? 'ابن' : 'أبناء'}
                      </span>
                      <span className="text-xs font-bold bg-[#f0a63e]/10 text-[#f0a63e] px-2.5 py-1 rounded-full">
                        {fam.achievements_count} إنجاز
                      </span>
                      <span className="text-xs font-bold bg-[#488b40]/10 text-[#488b40] px-2.5 py-1 rounded-full">
                        {kiosks.length} شاشة
                      </span>
                    </div>

                    {isOpen
                      ? <ChevronUp size={18} className="text-[#a99c92] shrink-0" />
                      : <ChevronDown size={18} className="text-[#a99c92] shrink-0" />}
                  </button>

                  {/* ── Expanded details ── */}
                  {isOpen && (
                    <div className="bg-[#faece3]/25 px-6 py-5 space-y-5 border-t border-[#f0e6de]">
                      {/* Mobile badges */}
                      <div className="flex md:hidden flex-wrap gap-2">
                        <span className="text-xs font-bold bg-[#49b5d0]/10 text-[#49b5d0] px-2.5 py-1 rounded-full">
                          {fam.children_count} أبناء
                        </span>
                        <span className="text-xs font-bold bg-[#f0a63e]/10 text-[#f0a63e] px-2.5 py-1 rounded-full">
                          {fam.achievements_count} إنجاز
                        </span>
                        <span className="text-xs font-bold bg-[#488b40]/10 text-[#488b40] px-2.5 py-1 rounded-full">
                          {kiosks.length} شاشة
                        </span>
                      </div>

                      {/* Children list */}
                      {children.length > 0 && (
                        <div>
                          <p className="text-xs font-bold text-[#a99c92] uppercase tracking-wide mb-2">
                            الأبناء
                          </p>
                          <div className="flex flex-wrap gap-2">
                            {children.map((ch) => (
                              <span
                                key={ch.id}
                                className="bg-white border-2 border-[#f0e6de] text-[#352c3c] font-bold text-sm px-3 py-1 rounded-full"
                              >
                                {ch.name}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Kiosks list */}
                      {kiosks.length > 0 ? (
                        <div>
                          <p className="text-xs font-bold text-[#a99c92] uppercase tracking-wide mb-2">
                            الشاشات المربوطة
                          </p>
                          <div className="space-y-2">
                            {kiosks.map((k) => (
                              <div
                                key={k.id}
                                className="flex items-center justify-between bg-white rounded-xl px-4 py-3 border-2 border-[#f0e6de]"
                              >
                                <div className="flex items-center gap-3">
                                  <Monitor size={16} className="text-[#49b5d0]" />
                                  <div>
                                    <p className="text-sm font-bold text-[#352c3c]">
                                      {k.device_info || 'جهاز غير معروف'}
                                    </p>
                                    <p className="text-xs text-[#a99c92]">
                                      {formatDate(k.created_at)}
                                    </p>
                                  </div>
                                </div>
                                <button
                                  onClick={() => handleUnlink(k.id)}
                                  title="فك الربط"
                                  className="w-8 h-8 flex items-center justify-center rounded-full bg-[#c15b40]/10 hover:bg-[#c15b40] text-[#c15b40] hover:text-white transition-all duration-200"
                                >
                                  <Trash2 size={14} />
                                </button>
                              </div>
                            ))}
                          </div>
                        </div>
                      ) : (
                        <p className="text-sm text-[#a99c92] italic">لا توجد شاشات مربوطة.</p>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </div>
  );
};

export default SuperAdminStats;
