<div dir="rtl" style="text-align: right; font-family: 'Baloo Bhaijaan 2', sans-serif;">

<div align="center">
  <a href="https://ruman.sa">
    <picture>
      <source srcset="public/assets/img/H_Colored_LogoWhite@2x.png" media="(prefers-color-scheme: dark)">
      <img src="public/assets/img/H_Colored_Logo@2x.png" alt="Ruman Agency Logo" width="150" />
    </picture>
  </a>
</div>

# تطبيق إنجازي Enjazy App 🚀

[![Vite](https://img.shields.io/badge/Vite-B73BFE?style=for-the-badge&logo=vite&logoColor=FFD62E)](https://vitejs.dev/)
[![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Bun](https://img.shields.io/badge/Bun-000000?style=for-the-badge&logo=bun&logoColor=white)](https://bun.sh/)

<div align="center">
  <img src="public/assets/screenshots/enjazy_header.png" alt="إنجازي - منصة الآباء" width="100%" style="border-radius: 16px; margin: 20px 0; box-shadow: 0 4px 20px rgba(0,0,0,0.1);" />
</div>

**إنجازي** هو نظام تفاعلي متكامل يتكون من (لوحة تحكم ذكية للآباء + شاشة عرض تفاعلية للأطفال) صُمم خصيصاً لمساعدة الآباء على متابعة وتطوير إنجازات أطفالهم اليومية بأسلوب محفز، عصري، وطفولي مبهج.

## ✨ مميزات النظام والخصائص الكاملة

النظام مبني بهيكلية أدوار متعددة (سوبر أدمن، آباء، وشاشات عرض):

### 1. لوحة الإدارة العليا (Super Admin Dashboard)
- **إدارة الآباء:** السوبر أدمن هو الحساب الوحيد المخول بإنشاء حسابات جديدة للآباء وتعديلها أو حذفها.

### 2. لوحة تحكم الآباء (Parent Dashboard)

<div align="center">
  <img src="public/assets/screenshots/5.png" alt="شاشة تسجيل الدخول" width="400" style="border-radius: 12px; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1);" />
</div>

- **اللوحة الرئيسية (Dashboard Home):** واجهة متكاملة تعرض إحصائيات عامة عن الأبناء، وتتضمن تبويباً لإدارة الحساب (تعديل الإيميل وكلمة المرور)، وتبويباً مخصصاً لإدارة الشاشات.
  <br/><img src="public/assets/screenshots/1.png" alt="اللوحة الرئيسية" width="600" style="border-radius: 8px; margin-top: 10px;" />
  
- **إدارة الأبناء (Children Manager):** إمكانية إضافة حتى 5 أبناء، تحديد هدف النجوم الأسبوعي، مدة ظهور الابن على شاشة العرض (بالثواني)، وتخصيص صورة شخصية للابن وصورة للإنجاز (الميدالية النهائية).
  <br/><img src="public/assets/screenshots/3.png" alt="إدارة الأبناء" width="600" style="border-radius: 8px; margin-top: 10px;" />
- **تصفير مسار الإنجاز:** إمكانية إعادة ضبط مسار الإنجاز ليبدأ الأرنب من نقطة البداية دون حذف النجوم أو السجلات السابقة. المسار **لا يتصفّر تلقائياً بمرور الوقت أو بداية أسبوع جديد** — يعتمد فقط على آخر ضغطة لزر "تصفير المسار" من الأب لكل ابن على حدة.
- **إدارة الإنجازات (Achievements Manager):** إضافة مهام وإنجازات يومية مع صور تعبيرية، وتخصيص الإنجازات لأبناء محددين.
  <br/><img src="public/assets/screenshots/4.png" alt="إدارة الإنجازات" width="600" style="border-radius: 8px; margin-top: 10px;" />
- **التقييم اليومي (Daily Evaluation):** واجهة مريحة وسريعة لتقييم كل ابن يومياً (نجمة أو إكس) كحد أقصى 5 تقييمات للإنجاز الواحد في اليوم. وتتضمن الواجهة عرض حي لـ "مسار الإنجاز" متطابق مع الشاشة التفاعلية.
- **إدارة شاشات العرض (Kiosk Manager):** ربط أجهزة العرض بسهولة عبر رمز PIN أو QR Code، مدمجة الآن كعلامة تبويب داخل اللوحة الرئيسية لسهولة الوصول.
  <br/><img src="public/assets/screenshots/2.png" alt="ربط الشاشة الذكية" width="400" style="border-radius: 8px; margin-top: 10px;" />

### 3. شاشة العرض التفاعلية للأطفال (Kiosk Display)
- **شاشة عرض تلقائية الدوران:** تقوم بعرض إنجازات الأبناء بالتناوب حسب المدة الزمنية المخصصة لكل ابن.
- **مسار الإنجاز البصري (مع دعم الميداليات المخصصة):** مسار متجاوب يمتد بين صورة الطفل على اليمين وهدفه (صورة الإنجاز أو الميدالية) على اليسار، وتتحرك الشخصية نحوه بمرونة وتجاوب دقيق عبر الشاشات.
- **تحديثات لحظية (Realtime):** تظهر النجوم وتتحرك الشخصية بشكل حي ومباشر أمام الطفل لحظة إضافة التقييم من هاتف الأب، دون الحاجة لتحديث الصفحة.
- **مؤثرات بصرية وصوتية متجاوبة:** إطلاق تأثيرات "Confetti" وأصوات تشجيعية عند النجاح، وأصوات تنبيهية عند الإخفاق أو التراجع عن التقييم.
- **تصميم متجاوب بالكامل:** يعتمد التصميم على وحدات (`clamp` و `Grid`) ليتجاوب تماماً مع جميع الشاشات (تلفاز، جهاز لوحي، أو جوال).
- **نظام أمني للشاشات:** تعمل الشاشات عبر نظام جلسات `Sessions` لا يتطلب تسجيل الدخول بكلمة المرور في التلفاز.

---

## 🛠 التقنيات المستخدمة

- **الواجهات الأمامية:** React 19, Vite
- **التصميم:** TailwindCSS v4, Framer Motion (للحركات)
- **قاعدة البيانات والواجهة الخلفية:** Supabase (PostgreSQL, Auth, Storage, Realtime) — يعمل مع Supabase السحابي أو نسخة مستضافة ذاتياً (عبر Coolify مثلاً)
- **الأيقونات والتأثيرات:** Lucide React, Canvas Confetti
- **إدارة الحزم:** [Bun](https://bun.sh/) — الأداة الوحيدة المعتمدة لتثبيت الحزم وتشغيل السكربتات في هذا المشروع

---

## 📥 تعليمات التثبيت وإعداد بيئة العمل (Setup)

### المتطلبات الأساسية
- [Bun](https://bun.sh/) مثبّت على جهازك (هو مدير الحزم الوحيد المعتمد لهذا المشروع — **لا تستخدم npm أو yarn أو pnpm**، ولا تُنشئ `package-lock.json`؛ ملف القفل الرسمي هو `bun.lock`).
- مشروع **Supabase** (سحابي عبر [supabase.com](https://supabase.com)، أو مستضاف ذاتياً — راجع [`DEPLOYMENT.md`](DEPLOYMENT.md) لدليل النشر عبر Coolify).

### 1. استنساخ المستودع وتثبيت الحزم:
```bash
git clone https://github.com/alrkiyan/enjazapp.git
cd enjazapp
bun install
```

### 2. إعداد متغيرات البيئة:
انسخ ملف `.env.example` إلى `.env` في المسار الرئيسي، ثم عبّئ القيمتين من إعدادات مشروع Supabase الخاص بك (Project Settings → API):
```bash
cp .env.example .env
```
```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

> ⚠️ **مهم:**
> - هذان المتغيّران فقط لا غير — لا تضع `SERVICE_ROLE_KEY` هنا أو في أي متغيّر يبدأ بـ `VITE_` إطلاقاً، لأنه يُخبَز داخل حزمة المتصفح ويصبح مكشوفاً للجميع.
> - إن كنت تستخدم Supabase مستضافاً ذاتياً، استخدم رابط **HTTPS** العام (وليس عنوان IP داخلي) حتى يعمل التحديث اللحظي (Realtime) عبر `wss`.
> - عند النشر على Coolify، علِّم كلا المتغيّرين كـ **Build Variable** (تفاصيل كاملة في [`DEPLOYMENT.md`](DEPLOYMENT.md)).

### 3. إعداد قاعدة البيانات (Supabase Schema):
كل مخطط قاعدة البيانات موحّد الآن في ملف واحد. في منصة Supabase (السحابية أو المستضافة)، افتح **SQL Editor** وشغّل الملف التالي **مرة واحدة فقط** على قاعدة بيانات فارغة:

```
supabase/schema.sql
```

يحتوي هذا الملف على كل شيء بحالته النهائية: الجداول، تفعيل RLS والسياسات، الدوال والـ Triggers (بما فيها إنشاء 3 إنجازات افتراضية لكل أب جديد)، دوال السوبر أدمن، إعداد حاوية التخزين `uploads` وصلاحياتها، وتفعيل Realtime على الجداول الخمسة.

> 🔁 **تستورد بيانات موجودة من قبل؟** القسم الأخير من الملف (رقم 8) ينشئ سوبر أدمن افتراضياً فقط إذا لم يوجد مستخدم بنفس البريد — يمكنك تخطّيه بأمان إن كان السوبر أدمن سيأتي ضمن بياناتك المستوردة.

### 4. حساب الإدارة العليا (Super Admin) 👑:
إن لم تستورد بيانات موجودة، سيُنشئ القسم الأخير من `schema.sql` حساب سوبر أدمن افتراضياً:
- **البريد الإلكتروني:** `saleh@isaleh.dev`
- **كلمة المرور:** `Saleh@123`

سجّل دخولك بهذا الحساب **وغيّر كلمة المرور فوراً** من إعدادات الحساب (أو من ميزة "تغيير كلمة المرور عند أول تسجيل دخول" إن كانت مفعّلة)، ثم توجّه إلى شاشة "إدارة الآباء" لإنشاء حسابات لعملائك أو الآباء الآخرين.

### 5. تشغيل المشروع للبيئة التطويرية:
```bash
bun run dev
```
يعمل الخادم افتراضياً على المنفذ `5171` (مربوط على `0.0.0.0` ليصله أي جهاز على نفس الشبكة).

### الأوامر المتاحة
| الأمر | الوصف |
|---|---|
| `bun run dev` | تشغيل خادم التطوير مع Hot Reload |
| `bun run build` | بناء نسخة الإنتاج داخل مجلد `dist/` |
| `bun run preview` | معاينة نسخة الإنتاج المبنية محلياً |
| `bun run lint` | فحص الكود عبر ESLint |

---

## 📚 موارد إضافية

- [`DEPLOYMENT.md`](DEPLOYMENT.md): دليل نشر التطبيق على Coolify مع Supabase مستضاف ذاتياً، ونقل البيانات من السحابي للمستضاف.
- [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md): مدونة قواعد السلوك للمساهمين في المشروع.

---

## 📝 الحقوق والمطورين

تم تصميم وبرمجة هذا النظام بواسطة **صالح** من **وكالة رمان (Ruman Agency)**.

**المساهمون (Contributors):**
- [alrkiyan](https://github.com/alrkiyan)

- 📧 **البريد الإلكتروني:** [hi@ruman.sa](mailto:hi@ruman.sa)
- 📱 **واتساب:** [+966539294989](https://wa.me/966539294989)
- 🌐 **الموقع الإلكتروني:** [https://ruman.sa](https://ruman.sa)

---
<div align="center">
  صُنع بحب 💖 لدعم أبنائنا وتحفيزهم
</div>
</div>
