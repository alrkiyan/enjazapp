import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import Card from './Card';
import { Star, X, TrendingUp, TrendingDown, Trophy, Calendar } from 'lucide-react';

/* ─── helpers ─────────────────────────────────────────────────── */
const fmtDate = (d) =>
  d
    ? new Date(d + 'T00:00:00').toLocaleDateString('ar-SA', {
        year: 'numeric', month: 'short', day: 'numeric',
      })
    : '—';

/* ─── Single achievement bar row ──────────────────────────────── */
const AchBar = ({ ach, maxStars, rank, total }) => {
  const pct = maxStars > 0 ? Math.round((ach.total_stars / maxStars) * 100) : 0;
  const strength = pct >= 66 ? 'strong' : pct >= 33 ? 'mid' : 'weak';
  const barColor =
    strength === 'strong'
      ? 'from-[#488b40] to-[#6dbf65]'
      : strength === 'mid'
      ? 'from-[#f0a63e] to-[#f4c88a]'
      : 'from-[#c15b40] to-[#e08070]';

  return (
    <div className="group">
      <div className="flex items-center gap-3 mb-1">
        {/* Rank badge */}
        <span
          className={`w-6 h-6 flex-none flex items-center justify-center rounded-full text-xs font-black ${
            rank === 1
              ? 'bg-[#f0a63e] text-white'
              : rank === total
              ? 'bg-[#c15b40]/20 text-[#c15b40]'
              : 'bg-[#f0e6de] text-[#a99c92]'
          }`}
        >
          {rank}
        </span>

        {/* Icon + title */}
        <div className="flex items-center gap-2 flex-1 min-w-0">
          {ach.icon_url ? (
            <img src={ach.icon_url} className="w-6 h-6 object-contain shrink-0" alt="" />
          ) : (
            <Star size={15} className="text-[#f0a63e] shrink-0" />
          )}
          <span className="text-sm font-bold text-[#352c3c] truncate">{ach.title}</span>
        </div>

        {/* Counts */}
        <div className="flex items-center gap-3 shrink-0 text-xs font-bold">
          <span className="text-[#488b40]">⭐ {ach.total_stars}</span>
          {ach.total_crosses > 0 && (
            <span className="text-[#c15b40]">✗ {ach.total_crosses}</span>
          )}
          {ach.last_star_date && (
            <span className="text-[#a99c92] hidden sm:inline">{fmtDate(ach.last_star_date)}</span>
          )}
        </div>
      </div>

      {/* Bar */}
      <div className="h-2.5 bg-[#f0e6de] rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full bg-gradient-to-l ${barColor} transition-all duration-700`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
};

/* ─── Per-child stats panel ───────────────────────────────────── */
const ChildPanel = ({ child }) => {
  const achievements = child.achievements || [];
  const maxStars = achievements.length > 0 ? Math.max(...achievements.map((a) => a.total_stars), 1) : 1;
  const top3    = achievements.slice(0, 3);
  const bottom3 = [...achievements].reverse().slice(0, 3);

  return (
    <div className="space-y-5">
      {/* ── Summary stat cards ── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          { label: 'إجمالي النجوم', value: child.total_stars,     color: '#f0a63e', icon: '⭐' },
          { label: 'إجمالي العلامات', value: child.total_crosses, color: '#c15b40', icon: '✗' },
          { label: 'مرات التصفير', value: child.path_completions, color: '#488b40', icon: '🏆' },
          { label: 'آخر نجمة', value: fmtDate(child.last_star_date), color: '#49b5d0', icon: '📅', small: true },
        ].map(({ label, value, color, icon, small }) => (
          <Card
            key={label}
            className="p-4 text-center bg-white border-2 border-[#e2d5cc] hover:shadow-md transition-shadow"
          >
            <div className="text-2xl mb-1">{icon}</div>
            <div
              className={`font-black ${small ? 'text-base leading-tight' : 'text-3xl'}`}
              style={{ color }}
            >
              {value ?? '—'}
            </div>
            <div className="text-xs font-bold text-[#a99c92] mt-1">{label}</div>
          </Card>
        ))}
      </div>

      {/* ── Achievement chart ── */}
      {achievements.length === 0 ? (
        <div className="text-center text-[#a99c92] py-10 border-2 border-dashed border-[#e2d5cc] rounded-2xl font-bold">
          لا توجد إنجازات مسندة لهذا الابن بعد.
        </div>
      ) : (
        <Card className="p-6 bg-white border-2 border-[#e2d5cc]">
          <h3 className="font-bold text-[#352c3c] text-lg mb-5 border-b border-[#f0e6de] pb-3 flex items-center gap-2">
            <Trophy size={20} className="text-[#f0a63e]" />
            إحصائيات الإنجازات ({achievements.length})
          </h3>

          {/* Bars */}
          <div className="space-y-5">
            {achievements.map((ach, i) => (
              <AchBar
                key={ach.id}
                ach={ach}
                maxStars={maxStars}
                rank={i + 1}
                total={achievements.length}
              />
            ))}
          </div>

          {/* Highlights: best / needs work */}
          {achievements.length >= 3 && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6 pt-5 border-t border-[#f0e6de]">
              {/* Best */}
              <div className="bg-[#488b40]/6 rounded-2xl p-4 border border-[#488b40]/20">
                <div className="flex items-center gap-2 mb-3">
                  <TrendingUp size={18} className="text-[#488b40]" />
                  <span className="font-bold text-[#488b40] text-sm">أبرز الإنجازات 🌟</span>
                </div>
                {top3.map((a, i) => (
                  <div key={a.id} className="flex items-center gap-2 mb-2 text-sm">
                    <span className="w-5 h-5 flex-none rounded-full bg-[#488b40] text-white text-xs font-black flex items-center justify-center">
                      {i + 1}
                    </span>
                    {a.icon_url && (
                      <img src={a.icon_url} className="w-4 h-4 object-contain shrink-0" alt="" />
                    )}
                    <span className="text-[#352c3c] font-bold truncate flex-1">{a.title}</span>
                    <span className="text-[#488b40] font-bold shrink-0">⭐ {a.total_stars}</span>
                  </div>
                ))}
              </div>

              {/* Needs work */}
              <div className="bg-[#c15b40]/6 rounded-2xl p-4 border border-[#c15b40]/20">
                <div className="flex items-center gap-2 mb-3">
                  <TrendingDown size={18} className="text-[#c15b40]" />
                  <span className="font-bold text-[#c15b40] text-sm">تحتاج اهتماماً 💪</span>
                </div>
                {bottom3.map((a, i) => (
                  <div key={a.id} className="flex items-center gap-2 mb-2 text-sm">
                    <span className="w-5 h-5 flex-none rounded-full bg-[#c15b40] text-white text-xs font-black flex items-center justify-center">
                      {i + 1}
                    </span>
                    {a.icon_url && (
                      <img src={a.icon_url} className="w-4 h-4 object-contain shrink-0" alt="" />
                    )}
                    <span className="text-[#352c3c] font-bold truncate flex-1">{a.title}</span>
                    <span className="text-[#c15b40] font-bold shrink-0">⭐ {a.total_stars}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </Card>
      )}
    </div>
  );
};

/* ─── Main ParentStats ────────────────────────────────────────── */
const ParentStats = () => {
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeId, setActiveId] = useState(null);

  useEffect(() => { fetchStats(); }, []);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('get_parent_child_stats');
      if (error) throw error;
      const list = data || [];
      setChildren(list);
      if (list.length > 0) setActiveId(list[0].id);
    } catch (err) {
      console.error('get_parent_child_stats:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="text-center text-[#a99c92] font-bold py-16 animate-pulse">
        جاري تحميل الإحصائيات...
      </div>
    );
  }

  if (children.length === 0) {
    return (
      <div className="text-center py-12 text-[#a99c92] border-2 border-dashed border-[#e2d5cc] rounded-3xl font-bold">
        لم يتم إضافة أبناء بعد. أضف أبناءك أولاً لمشاهدة الإحصائيات.
      </div>
    );
  }

  const active = children.find((c) => c.id === activeId) || children[0];

  return (
    <div className="space-y-5" dir="rtl">
      {/* ── Child tab selector ── */}
      {children.length > 1 && (
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          {children.map((child) => (
            <button
              key={child.id}
              onClick={() => setActiveId(child.id)}
              className={`flex-none flex items-center gap-2 px-5 py-2.5 rounded-full font-bold transition-all border-2 ${
                activeId === child.id
                  ? 'border-[#49b5d0] bg-[#49b5d0]/10 text-[#49b5d0] scale-105 shadow-sm'
                  : 'border-[#e2d5cc] bg-white text-[#a99c92] hover:border-[#49b5d0]/40'
              }`}
            >
              {child.avatar_url ? (
                <img
                  src={child.avatar_url}
                  className="w-6 h-6 rounded-full object-cover"
                  alt=""
                />
              ) : (
                <div className="w-6 h-6 rounded-full bg-[#f0e6de] flex items-center justify-center text-xs font-bold text-[#a99c92]">
                  {child.name.charAt(0)}
                </div>
              )}
              {child.name}
            </button>
          ))}
        </div>
      )}

      {/* ── Active child panel ── */}
      {active && <ChildPanel child={active} />}
    </div>
  );
};

export default ParentStats;
