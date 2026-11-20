-- ============================================================================
-- 2026-11-20 — تحصين أمني (Security hardening)
--
-- 1) صلاحية السوبر أدمن تُقرأ من app_metadata (لا يعدّلها إلا السيرفر)
--    بدل user_metadata (يعدّلها أي مستخدم لنفسه عبر auth.updateUser).
-- 2) الشاشة (Kiosk) تدخل بحساب مجهول (Anonymous sign-in) وتُربط بجلسة
--    عبر kiosk_uid؛ لا يقرأ أحد بيانات الأطفال بلا تسجيل دخول.
-- 3) التخزين: كل مستخدم يكتب في مجلده فقط، صور فقط، 5 MB حداً أقصى.
-- 4) search_path ثابت لكل دوال SECURITY DEFINER.
--
-- متطلب: ENABLE_ANONYMOUS_USERS=true في خدمة Supabase على Coolify.
-- الأثر: جلسات الشاشة القديمة تُحذف — تحتاج كل شاشة إعادة ربط مرة واحدة.
-- آمن لإعادة التشغيل (idempotent).
-- ============================================================================
BEGIN;

-- ----------------------------------------------------------------------------
-- 1) السوبر أدمن
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql STABLE
SET search_path = ''
AS $$
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'is_super_admin')::boolean, false);
$$;

-- نقل العلامة من user_metadata إلى app_metadata ثم حذفها من user_metadata
UPDATE auth.users
SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"is_super_admin": true}'::jsonb
WHERE (raw_user_meta_data ->> 'is_super_admin')::boolean IS TRUE;

UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data - 'is_super_admin'
WHERE raw_user_meta_data ? 'is_super_admin';

CREATE OR REPLACE FUNCTION public.admin_get_users()
RETURNS TABLE (
  id UUID,
  email VARCHAR,
  created_at TIMESTAMP WITH TIME ZONE,
  last_sign_in_at TIMESTAMP WITH TIME ZONE,
  is_banned BOOLEAN,
  is_super_admin BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    u.email::VARCHAR,
    u.created_at,
    u.last_sign_in_at,
    (u.banned_until IS NOT NULL AND u.banned_until > now()) AS is_banned,
    COALESCE((u.raw_app_meta_data ->> 'is_super_admin')::boolean, false) AS is_super_admin
  FROM auth.users u
  WHERE u.is_anonymous IS NOT TRUE
  ORDER BY u.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_toggle_user_ban(target_uid UUID, ban BOOLEAN)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
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
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_user(target_uid UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF target_uid = auth.uid() THEN
    RAISE EXCEPTION 'لا يمكنك حذف نفسك!';
  END IF;

  DELETE FROM auth.users WHERE id = target_uid;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_change_user_password(target_uid UUID, new_password TEXT)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF target_uid = auth.uid() THEN
    RAISE EXCEPTION 'استخدم خيار "تغيير كلمة المرور" في إعدادات حسابك الشخصي.';
  END IF;

  IF length(new_password) < 6 THEN
    RAISE EXCEPTION 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
  END IF;

  UPDATE auth.users
  SET
    encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf')),
    updated_at = now()
  WHERE id = target_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم غير موجود.';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_platform_stats()
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT json_build_object(
    'families_count', (
      SELECT COUNT(*) FROM auth.users
      WHERE (raw_app_meta_data->>'is_super_admin')::boolean IS NOT TRUE
        AND is_anonymous IS NOT TRUE
    ),
    'total_achievements', (SELECT COUNT(*) FROM public.achievements),
    'total_kiosks',       (SELECT COUNT(*) FROM public.kiosk_sessions WHERE parent_id IS NOT NULL),
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
      WHERE (u.raw_app_meta_data->>'is_super_admin')::boolean IS NOT TRUE
        AND u.is_anonymous IS NOT TRUE
    )
  ) INTO result;

  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_unlink_kiosk(session_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  DELETE FROM public.kiosk_sessions WHERE id = session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الجلسة غير موجودة.';
  END IF;
END;
$$;

-- search_path ثابت للدالتين الباقيتين (المحتوى دون تغيير)
ALTER FUNCTION public.get_parent_child_stats() SET search_path = public, auth, extensions;

-- الإنجازات الافتراضية للأب الجديد فقط — لا لحسابات الشاشة المجهولة
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF new.is_anonymous IS TRUE THEN
    RETURN new;
  END IF;

  INSERT INTO public.achievements (title, icon_url, parent_id)
  VALUES
    ('الصلاة في وقتها', '/assets/icons/prayer-mat.png', new.id),
    ('قراءة القرآن', '/assets/icons/quran.png', new.id),
    ('تفريش الأسنان', '/assets/icons/toothbrush.png', new.id);
  RETURN new;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2) الشاشة (Kiosk)
-- ----------------------------------------------------------------------------
ALTER TABLE public.kiosk_sessions
  ADD COLUMN IF NOT EXISTS kiosk_uid UUID DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS kiosk_sessions_kiosk_uid_idx ON public.kiosk_sessions (kiosk_uid);
CREATE INDEX IF NOT EXISTS kiosk_sessions_parent_id_idx ON public.kiosk_sessions (parent_id);

-- الجلسات القديمة بلا هوية جهاز لا يمكن تأمينها — تُحذف (الشاشات تعيد الربط)
DELETE FROM public.kiosk_sessions WHERE kiosk_uid IS NULL;

-- معرّفات الآباء المرتبطين بشاشة المستخدم الحالي (SECURITY DEFINER لتفادي تداخل RLS)
CREATE OR REPLACE FUNCTION public.kiosk_parent_ids()
RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT ks.parent_id FROM public.kiosk_sessions ks
  WHERE ks.kiosk_uid = auth.uid() AND ks.parent_id IS NOT NULL;
$$;

-- ربط شاشة بكود من حساب الأب
CREATE OR REPLACE FUNCTION public.kiosk_claim(p_code TEXT)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL OR (auth.jwt() ->> 'is_anonymous')::boolean IS TRUE THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.kiosk_sessions
  SET parent_id = auth.uid()
  WHERE code = p_code
    AND parent_id IS NULL
    AND created_at > now() - interval '24 hours'
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'الكود غير صحيح أو انتهت صلاحيته';
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.kiosk_claim(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.kiosk_claim(TEXT) TO authenticated;
REVOKE ALL ON FUNCTION public.kiosk_parent_ids() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.kiosk_parent_ids() TO authenticated;

-- سياسات kiosk_sessions
DROP POLICY IF EXISTS "Anyone can insert kiosk_sessions"  ON public.kiosk_sessions;
DROP POLICY IF EXISTS "Anyone can view kiosk_sessions"    ON public.kiosk_sessions;
DROP POLICY IF EXISTS "Parents can update kiosk_sessions" ON public.kiosk_sessions;
DROP POLICY IF EXISTS "Parents can delete kiosk_sessions" ON public.kiosk_sessions;
DROP POLICY IF EXISTS "Kiosk can create its session"      ON public.kiosk_sessions;
DROP POLICY IF EXISTS "Kiosk or parent can view session"  ON public.kiosk_sessions;
DROP POLICY IF EXISTS "Kiosk or parent can delete session" ON public.kiosk_sessions;

CREATE POLICY "Kiosk can create its session" ON public.kiosk_sessions
  FOR INSERT TO authenticated
  WITH CHECK (kiosk_uid = auth.uid() AND parent_id IS NULL);
CREATE POLICY "Kiosk or parent can view session" ON public.kiosk_sessions
  FOR SELECT TO authenticated
  USING (kiosk_uid = auth.uid() OR parent_id = auth.uid());
CREATE POLICY "Kiosk or parent can delete session" ON public.kiosk_sessions
  FOR DELETE TO authenticated
  USING (kiosk_uid = auth.uid() OR parent_id = auth.uid());
-- لا سياسة UPDATE: الربط عبر kiosk_claim() فقط

-- سياسات القراءة للشاشة على بقية الجداول
DROP POLICY IF EXISTS "Kiosk can view children" ON public.children;
CREATE POLICY "Kiosk can view children" ON public.children
  FOR SELECT TO authenticated
  USING (parent_id IN (SELECT public.kiosk_parent_ids()));

DROP POLICY IF EXISTS "Kiosk can view achievements" ON public.achievements;
CREATE POLICY "Kiosk can view achievements" ON public.achievements
  FOR SELECT TO authenticated
  USING (parent_id IN (SELECT public.kiosk_parent_ids()));

DROP POLICY IF EXISTS "Kiosk can view child_achievements" ON public.child_achievements;
CREATE POLICY "Kiosk can view child_achievements" ON public.child_achievements
  FOR SELECT TO authenticated
  USING (child_id IN (SELECT c.id FROM public.children c WHERE c.parent_id IN (SELECT public.kiosk_parent_ids())));

DROP POLICY IF EXISTS "Kiosk can view daily_records" ON public.daily_records;
CREATE POLICY "Kiosk can view daily_records" ON public.daily_records
  FOR SELECT TO authenticated
  USING (child_id IN (SELECT c.id FROM public.children c WHERE c.parent_id IN (SELECT public.kiosk_parent_ids())));

-- ----------------------------------------------------------------------------
-- 3) التخزين
-- ----------------------------------------------------------------------------
UPDATE storage.buckets
SET file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/gif']
WHERE id = 'uploads';

DROP POLICY IF EXISTS "Auth Users Upload" ON storage.objects;
DROP POLICY IF EXISTS "Auth Users Update" ON storage.objects;
DROP POLICY IF EXISTS "Auth Users Delete" ON storage.objects;
DROP POLICY IF EXISTS "Users upload to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Users update own files"     ON storage.objects;
DROP POLICY IF EXISTS "Users delete own files"     ON storage.objects;

-- المسار: avatars/<uid>/<file> أو icons/<uid>/<file>
CREATE POLICY "Users upload to own folder" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'uploads'
    AND (storage.foldername(name))[1] IN ('avatars', 'icons')
    AND (storage.foldername(name))[2] = (SELECT auth.uid())::text
    AND (auth.jwt() ->> 'is_anonymous')::boolean IS NOT TRUE
  );
CREATE POLICY "Users update own files" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'uploads' AND (storage.foldername(name))[2] = (SELECT auth.uid())::text)
  WITH CHECK (bucket_id = 'uploads' AND (storage.foldername(name))[2] = (SELECT auth.uid())::text);
CREATE POLICY "Users delete own files" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'uploads' AND (storage.foldername(name))[2] = (SELECT auth.uid())::text);

COMMIT;
