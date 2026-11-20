-- ============================================================================
-- 2026-11-20 — لون أرنب خاص لكل طفل (children.rabbit_hue)
-- درجة لون (Hue) من 0 إلى 359 تُطبَّق على فرو أرنب السكوتر في الكشك والتقييم.
-- الافتراضي عشوائي ويتجنّب الأصفر 46°–75° (يذوب في الوشاح الأصفر)؛ لأن الدالة
-- متغيّرة (volatile) يحصل كل طفل موجود على لون عشوائي مختلف عند الإضافة.
-- الواجهة تختار عند الإنشاء لوناً بعيداً عن ألوان الإخوة (src/lib/rabbitColor.js).
-- آمن لإعادة التشغيل (idempotent).
-- ============================================================================
BEGIN;

ALTER TABLE public.children
  ADD COLUMN IF NOT EXISTS rabbit_hue SMALLINT
  DEFAULT (((76 + floor(random() * 330))::int % 360)::smallint);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'children_rabbit_hue_range') THEN
    ALTER TABLE public.children
      ADD CONSTRAINT children_rabbit_hue_range CHECK (rabbit_hue BETWEEN 0 AND 359);
  END IF;
END $$;

COMMIT;
