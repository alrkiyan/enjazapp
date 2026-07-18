-- ============================================================================
-- Enjazy — مخطط قاعدة البيانات الكامل (ملف موحّد)
-- شغّل هذا الملف مرة واحدة على قاعدة بيانات Supabase فارغة عبر SQL Editor.
-- يجمع كل ملفات supabase/*.sql السابقة في مصدر واحد بالحالة النهائية:
-- الجداول + RLS + السياسات + الدوال والـTriggers + التخزين + دوال الأدمن + Realtime.
-- ============================================================================

-- الامتدادات المطلوبة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- 1) الجداول
-- ============================================================================

-- الأطفال
CREATE TABLE IF NOT EXISTS children (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  avatar_url TEXT,
  reward_image_url TEXT,
  parent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  kiosk_duration INTEGER DEFAULT 10,
  weekly_star_goal INTEGER DEFAULT 10,
  path_reset_timestamp TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- الإنجازات
CREATE TABLE IF NOT EXISTS achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  icon_url TEXT,
  parent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ربط الطفل بالإنجاز
CREATE TABLE IF NOT EXISTS child_achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  child_id UUID REFERENCES children(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
  UNIQUE(child_id, achievement_id)
);

-- التقييمات اليومية
CREATE TABLE IF NOT EXISTS daily_records (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  child_id UUID REFERENCES children(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT CHECK (status IN ('star', 'cross')) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(child_id, achievement_id, date)
);

-- جلسات الشاشة (Kiosk)
CREATE TABLE IF NOT EXISTS kiosk_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  parent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_info TEXT DEFAULT 'غير معروف',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================================
-- 2) تفعيل RLS (Row Level Security)
-- ============================================================================
ALTER TABLE children          ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements       ENABLE ROW LEVEL SECURITY;
ALTER TABLE child_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_records      ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiosk_sessions     ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3) سياسات الأمان (Policies)
-- ============================================================================

-- الأطفال — الأب
CREATE POLICY "Parents can view their own children"   ON children FOR SELECT USING (auth.uid() = parent_id);
CREATE POLICY "Parents can insert their own children" ON children FOR INSERT WITH CHECK (auth.uid() = parent_id);
CREATE POLICY "Parents can update their own children" ON children FOR UPDATE USING (auth.uid() = parent_id);
CREATE POLICY "Parents can delete their own children" ON children FOR DELETE USING (auth.uid() = parent_id);
-- الأطفال — الشاشة (قراءة فقط لمن لديه جلسة شاشة نشطة)
CREATE POLICY "Kiosk can view children" ON children FOR SELECT USING (
  parent_id IN (SELECT parent_id FROM kiosk_sessions)
);

-- الإنجازات — الأب
CREATE POLICY "Parents can view their own achievements"   ON achievements FOR SELECT USING (auth.uid() = parent_id);
CREATE POLICY "Parents can insert their own achievements" ON achievements FOR INSERT WITH CHECK (auth.uid() = parent_id);
CREATE POLICY "Parents can update their own achievements" ON achievements FOR UPDATE USING (auth.uid() = parent_id);
CREATE POLICY "Parents can delete their own achievements" ON achievements FOR DELETE USING (auth.uid() = parent_id);
-- الإنجازات — الشاشة
CREATE POLICY "Kiosk can view achievements" ON achievements FOR SELECT USING (
  parent_id IN (SELECT parent_id FROM kiosk_sessions)
);

-- ربط الإنجازات — الأب
CREATE POLICY "Parents can view child_achievements" ON child_achievements FOR SELECT USING (
  EXISTS (SELECT 1 FROM children WHERE children.id = child_achievements.child_id AND children.parent_id = auth.uid())
);
CREATE POLICY "Parents can insert child_achievements" ON child_achievements FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM children WHERE children.id = child_id AND children.parent_id = auth.uid())
);
CREATE POLICY "Parents can delete child_achievements" ON child_achievements FOR DELETE USING (
  EXISTS (SELECT 1 FROM children WHERE children.id = child_id AND children.parent_id = auth.uid())
);
-- ربط الإنجازات — الشاشة
CREATE POLICY "Kiosk can view child_achievements" ON child_achievements FOR SELECT USING (
  child_id IN (SELECT id FROM children WHERE parent_id IN (SELECT parent_id FROM kiosk_sessions))
);

-- التقييم اليومي — الأب
CREATE POLICY "Parents can view daily_records" ON daily_records FOR SELECT USING (
  EXISTS (SELECT 1 FROM children WHERE children.id = daily_records.child_id AND children.parent_id = auth.uid())
);
CREATE POLICY "Parents can insert daily_records" ON daily_records FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM children WHERE children.id = child_id AND children.parent_id = auth.uid())
);
CREATE POLICY "Parents can update daily_records" ON daily_records FOR UPDATE USING (
  EXISTS (SELECT 1 FROM children WHERE children.id = child_id AND children.parent_id = auth.uid())
);
CREATE POLICY "Parents can delete daily_records" ON daily_records FOR DELETE USING (
  EXISTS (SELECT 1 FROM children WHERE children.id = daily_records.child_id AND children.parent_id = auth.uid())
);
-- التقييم اليومي — الشاشة
CREATE POLICY "Kiosk can view daily_records" ON daily_records FOR SELECT USING (
  child_id IN (SELECT id FROM children WHERE parent_id IN (SELECT parent_id FROM kiosk_sessions))
);

-- جلسات الشاشة
CREATE POLICY "Anyone can insert kiosk_sessions"  ON kiosk_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can view kiosk_sessions"    ON kiosk_sessions FOR SELECT USING (true);
CREATE POLICY "Parents can update kiosk_sessions" ON kiosk_sessions FOR UPDATE USING (true);
CREATE POLICY "Parents can delete kiosk_sessions" ON kiosk_sessions FOR DELETE USING (auth.uid() = parent_id);

-- ============================================================================
-- 4) الدوال والـTriggers
-- إدخال 3 إنجازات افتراضية عند تسجيل أب جديد
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.achievements (title, icon_url, parent_id)
  VALUES
    ('الصلاة في وقتها', '/assets/icons/prayer-mat.png', new.id),
    ('قراءة القرآن', '/assets/icons/quran.png', new.id),
    ('تفريش الأسنان', '/assets/icons/toothbrush.png', new.id);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================================================
-- 5) دوال السوبر أدمن لإدارة المستخدمين (SECURITY DEFINER)
-- ============================================================================

-- جلب قائمة المستخدمين
CREATE OR REPLACE FUNCTION public.admin_get_users()
RETURNS TABLE (
  id UUID,
  email VARCHAR,
  created_at TIMESTAMP WITH TIME ZONE,
  last_sign_in_at TIMESTAMP WITH TIME ZONE,
  is_banned BOOLEAN,
  is_super_admin BOOLEAN
) AS $$
BEGIN
  IF (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    u.email::VARCHAR,
    u.created_at,
    u.last_sign_in_at,
    (u.banned_until IS NOT NULL AND u.banned_until > now()) AS is_banned,
    (u.raw_user_meta_data ->> 'is_super_admin')::boolean AS is_super_admin
  FROM auth.users u
  ORDER BY u.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- حظر / فك حظر المستخدم
CREATE OR REPLACE FUNCTION public.admin_toggle_user_ban(target_uid UUID, ban BOOLEAN)
RETURNS void AS $$
BEGIN
  IF (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF target_uid = auth.uid() THEN
    RAISE EXCEPTION 'لا يمكنك حظر نفسك!';
  END IF;

  IF ban THEN
    UPDATE auth.users SET banned_until = '2100-01-01'::timestamp WHERE id = target_uid;
  ELSE
    UPDATE auth.users SET banned_until = NULL WHERE id = target_uid;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- حذف المستخدم نهائياً
CREATE OR REPLACE FUNCTION public.admin_delete_user(target_uid UUID)
RETURNS void AS $$
BEGIN
  IF (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF target_uid = auth.uid() THEN
    RAISE EXCEPTION 'لا يمكنك حذف نفسك!';
  END IF;

  DELETE FROM auth.users WHERE id = target_uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- تغيير كلمة مرور مستخدم (من قِبَل السوبر أدمن)
CREATE OR REPLACE FUNCTION public.admin_change_user_password(target_uid UUID, new_password TEXT)
RETURNS void AS $$
BEGIN
  -- التحقق من صلاحية السوبر أدمن
  IF (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  -- لا يُسمح بتغيير كلمة مرور السوبر أدمن نفسه عبر هذه الدالة
  IF target_uid = auth.uid() THEN
    RAISE EXCEPTION 'استخدم خيار "تغيير كلمة المرور" في إعدادات حسابك الشخصي.';
  END IF;

  -- التحقق من الحد الأدنى لطول كلمة المرور
  IF length(new_password) < 6 THEN
    RAISE EXCEPTION 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
  END IF;

  -- تحديث كلمة المرور المشفّرة مباشرةً في جدول auth.users
  UPDATE auth.users
  SET
    encrypted_password = crypt(new_password, gen_salt('bf')),
    updated_at = now()
  WHERE id = target_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم غير موجود.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5b) دوال الإحصائيات
-- ============================================================================

-- إحصائيات المنصة الكاملة (سوبر أدمن فقط)
CREATE OR REPLACE FUNCTION public.admin_get_platform_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT json_build_object(
    'families_count', (
      SELECT COUNT(*) FROM auth.users
      WHERE (raw_user_meta_data->>'is_super_admin')::boolean IS NOT TRUE
    ),
    'total_achievements', (SELECT COUNT(*) FROM public.achievements),
    'total_kiosks',       (SELECT COUNT(*) FROM public.kiosk_sessions),
    'families', (
      SELECT COALESCE(json_agg(
        json_build_object(
          'id',                u.id,
          'email',             u.email,
          'last_sign_in_at',   u.last_sign_in_at,
          'created_at',        u.created_at,
          'children_count',    (SELECT COUNT(*) FROM public.children c  WHERE c.parent_id  = u.id),
          'achievements_count',(SELECT COUNT(*) FROM public.achievements a WHERE a.parent_id = u.id),
          'children', (
            SELECT COALESCE(json_agg(
              json_build_object('id', c2.id, 'name', c2.name)
              ORDER BY c2.created_at
            ), '[]'::json)
            FROM public.children c2 WHERE c2.parent_id = u.id
          ),
          'kiosks', (
            SELECT COALESCE(json_agg(
              json_build_object('id', ks.id, 'device_info', ks.device_info, 'created_at', ks.created_at)
              ORDER BY ks.created_at DESC
            ), '[]'::json)
            FROM public.kiosk_sessions ks WHERE ks.parent_id = u.id
          )
        ) ORDER BY u.created_at DESC
      ), '[]'::json)
      FROM auth.users u
      WHERE (u.raw_user_meta_data->>'is_super_admin')::boolean IS NOT TRUE
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- فك ربط شاشة بواسطة السوبر أدمن
CREATE OR REPLACE FUNCTION public.admin_unlink_kiosk(session_id UUID)
RETURNS void AS $$
BEGIN
  IF (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  DELETE FROM public.kiosk_sessions WHERE id = session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الجلسة غير موجودة.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- إحصائيات الأبناء للوالد الحالي
CREATE OR REPLACE FUNCTION public.get_parent_child_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  v_uid  UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT COALESCE(json_agg(
    json_build_object(
      'id',                   c.id,
      'name',                 c.name,
      'avatar_url',           c.avatar_url,
      'weekly_star_goal',     COALESCE(c.weekly_star_goal, 10),
      'path_reset_timestamp', c.path_reset_timestamp,
      -- إجمالي النجوم والعلامات لهذا الابن
      'total_stars',   (SELECT COUNT(*) FROM public.daily_records dr WHERE dr.child_id = c.id AND dr.status = 'star'),
      'total_crosses', (SELECT COUNT(*) FROM public.daily_records dr WHERE dr.child_id = c.id AND dr.status = 'cross'),
      'last_star_date',(SELECT MAX(dr.date) FROM public.daily_records dr WHERE dr.child_id = c.id AND dr.status = 'star'),
      -- عدد المرات التي وصل فيها الابن للهدف الأسبوعي (تصفير)
      'path_completions', (
        SELECT COUNT(*)
        FROM (
          SELECT
            (DATE_TRUNC('week', dr2.date::timestamp + INTERVAL '1 day') - INTERVAL '1 day')::date AS week_sun,
            SUM(CASE WHEN dr2.status = 'star'  THEN 1 ELSE 0 END) -
            SUM(CASE WHEN dr2.status = 'cross' THEN 1 ELSE 0 END) AS net_stars
          FROM public.daily_records dr2
          WHERE dr2.child_id = c.id
          GROUP BY week_sun
          HAVING (
            SUM(CASE WHEN dr2.status = 'star'  THEN 1 ELSE 0 END) -
            SUM(CASE WHEN dr2.status = 'cross' THEN 1 ELSE 0 END)
          ) >= COALESCE(c.weekly_star_goal, 10)
        ) weeks_achieved
      ),
      -- إنجازات الابن مع إحصائياتها، مرتبة تنازلياً بعدد النجوم
      'achievements', (
        SELECT COALESCE(json_agg(
          json_build_object(
            'id',           a.id,
            'title',        a.title,
            'icon_url',     a.icon_url,
            'total_stars',  COALESCE(ach_s.stars,   0),
            'total_crosses',COALESCE(ach_s.crosses,  0),
            'last_star_date', ach_s.last_star
          ) ORDER BY COALESCE(ach_s.stars, 0) DESC
        ), '[]'::json)
        FROM public.child_achievements ca
        JOIN public.achievements a ON a.id = ca.achievement_id
        LEFT JOIN LATERAL (
          SELECT
            SUM(CASE WHEN dr3.status = 'star'  THEN 1 ELSE 0 END) AS stars,
            SUM(CASE WHEN dr3.status = 'cross' THEN 1 ELSE 0 END) AS crosses,
            MAX(CASE WHEN dr3.status = 'star'  THEN dr3.date END)  AS last_star
          FROM public.daily_records dr3
          WHERE dr3.child_id = c.id AND dr3.achievement_id = a.id
        ) ach_s ON true
        WHERE ca.child_id = c.id
      )
    ) ORDER BY c.created_at ASC
  ), '[]'::json)
  INTO result
  FROM public.children c
  WHERE c.parent_id = v_uid;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6) التخزين (Storage) — حاوية uploads العامة + سياساتها
-- ============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('uploads', 'uploads', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Access"     ON storage.objects FOR SELECT USING ( bucket_id = 'uploads' );
CREATE POLICY "Auth Users Upload" ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'uploads' AND auth.role() = 'authenticated' );
CREATE POLICY "Auth Users Update" ON storage.objects FOR UPDATE USING ( bucket_id = 'uploads' AND auth.role() = 'authenticated' );
CREATE POLICY "Auth Users Delete" ON storage.objects FOR DELETE USING ( bucket_id = 'uploads' AND auth.role() = 'authenticated' );

-- ============================================================================
-- 7) تفعيل Realtime للشاشة الرئيسية (TV Kiosk)
-- ============================================================================
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime;
ALTER PUBLICATION supabase_realtime ADD TABLE children, achievements, child_achievements, daily_records, kiosk_sessions;

-- ============================================================================
-- 8) (اختياري) إنشاء سوبر أدمن افتراضي
--    ⚠️ تخطَّ هذا القسم إذا كنت ستستورد بياناتك الموجودة (سيأتي الأدمن معها).
--    بيانات تنصيب افتراضية — غيّر كلمة المرور من التطبيق بعد أول دخول.
--    saleh@isaleh.dev / Saleh@123
-- ============================================================================
DO $$
DECLARE
  super_admin_id UUID := gen_random_uuid();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'saleh@isaleh.dev') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000', super_admin_id, 'authenticated', 'authenticated',
      'saleh@isaleh.dev', crypt('Saleh@123', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{"is_super_admin": true}', now(), now(),
      '', '', '', ''
    );

    INSERT INTO auth.identities (
      provider_id, user_id, identity_data, provider, created_at, updated_at, id
    )
    VALUES (
      super_admin_id::text, super_admin_id, format('{"sub":"%s","email":"%s"}', super_admin_id, 'saleh@isaleh.dev')::jsonb,
      'email', now(), now(), gen_random_uuid()
    );
  END IF;
END $$;
