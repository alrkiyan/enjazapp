<div dir="rtl">

# دليل النشر على Coolify + Supabase المستضاف ذاتياً

هذا الدليل يشرح خطوة بخطوة كيفية نشر تطبيق **Enjazy** على سيرفرك عبر **Coolify** وربطه بـ **Supabase المستضاف ذاتياً**، ثم نقل بياناتك من Supabase السحابي إلى المستضاف.

> **قبل البدء تحتاج:**
> - سيرفر Coolify يعمل ومربوط بالإنترنت.
> - خدمة **Supabase** منشورة على Coolify (بوابة Kong تعمل عبر HTTPS على دومين).
> - هذا الريبو مرفوع على **GitHub**.
> - أداتا `pg_dump` و `psql` على جهازك (من حزمة `postgresql-client`)، ويُفضّل إصدار 15 أو أحدث.

---

## المرحلة B1 — نشر التطبيق على Coolify

1. في Coolify: **+ New Resource** → اختر مصدر **GitHub** → اختر هذا الريبو والفرع.
2. **Build Pack**: اختر **Dockerfile** (الريبو يحتوي `Dockerfile` جاهزاً).
3. **Port**: `80`.
4. **Domain**: عيّن دومين التطبيق (مثال `app.your-domain.com`) — سيصدر Coolify شهادة **TLS** تلقائياً.
5. **Health Check Path**: `/health` (منفذ جاهز في `nginx.conf`).
6. **Environment Variables**: أضِف المتغيّرين التاليين، **وعلّم خانة "Build Variable" لكلٍّ منهما**:

   | Key | Value |
   |---|---|
   | `VITE_SUPABASE_URL` | `https://<دومين-Kong-لسوبابيز-لديك>` |
   | `VITE_SUPABASE_ANON_KEY` | `<anon key المستضاف>` |

   > ⚠️ **الأهم:** إن نسيت تعليم "Build Variable"، سيُبنى التطبيق بقيمة `undefined` ولن يتصل بـ Supabase (شاشة فارغة أو فشل تسجيل دخول). هذا أشهر خطأ في Coolify + Vite.
   >
   > 🔒 لا تضع `SERVICE_ROLE_KEY` هنا إطلاقاً — مفتاح `anon` فقط.

7. اضغط **Deploy** وانتظر اكتمال البناء.

> **من أين آتي بالقيم؟** من خدمة Supabase على Coolify: رابط Kong هو `VITE_SUPABASE_URL`، ومفتاح `anon` تجده ضمن متغيّرات خدمة Supabase (`ANON_KEY`).

---

## المرحلة B2 — تطبيق مخطط قاعدة البيانات (المستضاف فارغ)

افتح **Supabase Studio** الخاص بك (من Coolify) → **SQL Editor**، وشغّل الملف الموحّد **`supabase/schema.sql`** مرة واحدة. يحتوي كل شيء: الجداول، RLS، السياسات، الدوال والـTriggers، التخزين (حاوية `uploads`)، دوال السوبر أدمن، وتفعيل Realtime لكل الجداول الخمسة.

> ℹ️ في نهاية الملف قسمٌ اختياري (القسم 8) لإنشاء سوبر أدمن افتراضي (`saleh@isaleh.dev`). **تخطَّ هذا القسم إذا كنت ستستورد بياناتك الموجودة** في B3 (سيأتي الأدمن معها) — إمّا احذفه قبل التشغيل أو تجاهله (فهو محميّ بشرط «إن لم يكن الإيميل موجوداً»).

### تأكيدات بعد التطبيق

**أ) تفعيل تأكيد الإيميل التلقائي (بدون SMTP):** في خدمة Supabase على Coolify، تأكّد أن متغيّر البيئة:
```
GOTRUE_MAILER_AUTOCONFIRM=true
# (أو ENABLE_EMAIL_AUTOCONFIRM=true حسب نسخة القالب)
```
هذا يطابق سلوك السحابي الحالي (تسجيل الدخول يعمل مباشرة دون رسالة تأكيد). أعِد تشغيل خدمة auth إن غيّرته.

**ب) تحقّق من نشر Realtime** — نفّذ في SQL Editor:
```sql
SELECT schemaname, tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```
المتوقّع 5 جداول: `children`, `achievements`, `child_achievements`, `daily_records`, `kiosk_sessions`.

---

## المرحلة B3 — نقل البيانات (سحابي → مستضاف)

### 1) احصل على سلسلة اتصال السحابي
من لوحة Supabase السحابية → **Project Settings → Database → Connection string → URI**. استخدم الاتصال **المباشر** (منفذ `5432`)، مثال:
```
postgresql://postgres:[PASSWORD]@db.<ref>.supabase.co:5432/postgres
```
سنشير إليه بـ `$CLOUD_URL`.

### 2) صدّر البيانات من السحابي (على جهازك)
```bash
# بيانات schema العام فقط (بدون بنية — البنية طُبِّقت في B2)
pg_dump --data-only --no-owner --schema=public "$CLOUD_URL" > public_data.sql

# مستخدمو المصادقة وهوياتهم (كلمات المرور bcrypt تُنقل كما هي)
pg_dump --data-only --no-owner -t auth.users -t auth.identities "$CLOUD_URL" > auth_data.sql
```

### 3) جهّز اتصال المستضاف
أسهل طريقة: نفّذ `psql` داخل حاوية قاعدة بيانات Supabase على السيرفر:
```bash
# على سيرفر Coolify — استبدل اسم الحاوية باسم حاوية Postgres لخدمة Supabase لديك
docker ps | grep -i supabase-db     # لمعرفة اسم/معرّف الحاوية
```
سنشير لاتصال المستضاف بـ `$SELF_URL` (مثلاً `postgresql://postgres:[PASSWORD]@localhost:5432/postgres` إن كان المنفذ مكشوفاً، أو استخدم `docker exec -i <db> psql -U postgres`).

### 4) استورد البيانات (بالترتيب، مع تعطيل الـtrigger)
```bash
# عطّل trigger إنشاء المستخدم حتى لا تتكرّر الإنجازات الافتراضية 3 مرات لكل والد
psql "$SELF_URL" -c "ALTER TABLE auth.users DISABLE TRIGGER on_auth_user_created;"

# استورد المصادقة أولاً (بسبب مفاتيح FK من children.parent_id → auth.users)
psql "$SELF_URL" -f auth_data.sql

# ثم بيانات التطبيق
psql "$SELF_URL" -f public_data.sql

# أعِد تفعيل الـtrigger
psql "$SELF_URL" -c "ALTER TABLE auth.users ENABLE TRIGGER on_auth_user_created;"
```

> إن ظهرت أخطاء ترتيب FK في `public_data.sql`، أضِف `--disable-triggers` إلى أمر `pg_dump` الخاص بالبيانات العامة، أو استورد بترتيب: `children` → `achievements` → `child_achievements` → `daily_records` → `kiosk_sessions`.

---

## المرحلة B4 — نقل ملفات التخزين + إعادة كتابة روابط الصور

الصور الفعلية (صور الأبناء، صور المكافآت، أيقونات الإنجازات المرفوعة) مُخزّنة في حاوية `uploads` على السحابي، وقاعدة البيانات تخزّن **رابطها الكامل** فقط. لذلك خطوتان:

### 1) انقل الملفات الفعلية (مع الحفاظ على نفس المسار)
المسارات داخل الحاوية تكون بالشكل: `avatars/<user_id>/<file>` و `icons/<user_id>/<file>`. يجب أن تبقى **مطابقة تماماً** حتى تعمل الروابط بعد إعادة الكتابة.

- **لو الصور قليلة (الأرجح):** من **Studio السحابي → Storage → uploads** نزّل الملفات، ثم من **Studio المستضاف → Storage → uploads** ارفعها بنفس بنية المجلدات.
- **لو كثيرة:** استخدم سكربت عبر Storage API ينزّل من السحابي ويرفع للمستضاف بنفس المسار (أخبرني وأجهّزه لك).

### 2) أعِد كتابة الروابط المخزّنة (في SQL Editor للمستضاف)
استبدل `<ref>` بمعرّف مشروعك السحابي القديم، و `<دومين-سوبابيز-المستضاف>` برابط Kong المستضاف:
```sql
UPDATE children     SET avatar_url       = replace(avatar_url,       'https://<ref>.supabase.co', 'https://<دومين-سوبابيز-المستضاف>');
UPDATE children     SET reward_image_url = replace(reward_image_url, 'https://<ref>.supabase.co', 'https://<دومين-سوبابيز-المستضاف>');
UPDATE achievements SET icon_url         = replace(icon_url,         'https://<ref>.supabase.co', 'https://<دومين-سوبابيز-المستضاف>');
```
> الأيقونات الافتراضية للإنجازات (مثل `/assets/icons/quran.png`) روابط نسبية داخل التطبيق ولا تحتاج تعديلاً.

---

## المرحلة B5 — التحقق الشامل

افتح دومين تطبيقك على Coolify وتحقّق:

1. **تسجيل الدخول** بحساب موجود → الوصول للوحة التحكم.
2. **الصور تظهر**: الأبناء والإنجازات والصور المرفوعة (بعد إعادة كتابة الروابط).
3. **التقييم اليومي**: الضغط على نجمة/خطأ يُحفَظ ويُسمع الصوت.
4. **الشاشة (Kiosk)**: افتح `/kiosk`، اقترن من لوحة التحكم، وتحقّق أن الاقتران ينتقل تلقائياً؛ ثم أضِف سجلاً وتحقّق من ظهور القصاصات والصوت **لحظياً** على `/kiosk/display`.
5. **لوحة السوبر أدمن**: عرض المستخدمين + حظر/حذف يعمل.

---

## ملاحظات أمان ونسخ احتياطي

- **النسخ الاحتياطي أصبح مسؤوليتك:** جدوِل `pg_dump` دورياً، وانسخ حجم تخزين الملفات وملف `.env` الخاص بـ Supabase. **فقدان `JWT_SECRET` يُبطل كل جلسات ومفاتيح المستخدمين.**
- **`SERVICE_ROLE_KEY`** يبقى على السيرفر فقط — لا يدخل حزمة الواجهة إطلاقاً.
- استخدم **HTTPS** لرابط Supabase دائماً كي يعمل Realtime عبر `wss` (المحتوى المختلط يكسر التحديث اللحظي بصمت).
- الملف `supabase/create_super_admin.sql` يحوي كلمة مرور نصّية قديمة — لا تشغّله، ويُنصح بتدوير تلك الكلمة إن كانت مستخدمة.

</div>
