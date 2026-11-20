import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// عميل منفصل للشاشة (Kiosk): يدخل بحساب مجهول ويحفظ جلسته بمفتاح مستقل،
// حتى لا يمسح جلسة الأب لو فُتحت الشاشة ولوحة التحكم في نفس المتصفح.
let kioskClient = null
export const getKioskClient = () => {
  if (!kioskClient) {
    kioskClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { storageKey: 'enjazy-kiosk-auth', detectSessionInUrl: false },
    })
  }
  return kioskClient
}

const STORAGE_PUBLIC_PATH = '/storage/v1/object/public/'

// يعيد بناء روابط Supabase Storage على السيرفر الحالي (VITE_SUPABASE_URL)،
// فلا تنكسر الصور إن تغيّر عنوان السيرفر. الروابط المحلية (/assets/...) كما هي.
export const resolveStorageUrl = (url) => {
  if (!url || url.startsWith('/')) return url || null
  const idx = url.indexOf(STORAGE_PUBLIC_PATH)
  if (idx === -1) return url
  return `${supabaseUrl}${url.slice(idx)}`
}

// صلاحية السوبر أدمن في app_metadata (يضبطها السيرفر فقط، لا المستخدم)
export const isSuperAdmin = (user) => user?.app_metadata?.is_super_admin === true
