import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import Card from '../../components/ui/Card';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import KioskManager from './KioskManager';
import SuperAdminStats from '../../components/ui/SuperAdminStats';
import ParentStats from '../../components/ui/ParentStats';
import { Settings, BarChart2, MonitorPlay, Save } from 'lucide-react';

const Home = () => {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('overview');

  const isSuperAdmin = user?.user_metadata?.is_super_admin === true;

  // Account state
  const [email, setEmail] = useState(user?.email || '');
  const [password, setPassword] = useState('');
  const [updatingAccount, setUpdatingAccount] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });

  const handleUpdateAccount = async (e) => {
    e.preventDefault();
    setUpdatingAccount(true);
    setMessage({ type: '', text: '' });

    try {
      const updates = {};
      if (email !== user.email) updates.email = email;
      if (password) updates.password = password;

      if (Object.keys(updates).length === 0) {
        setMessage({ type: 'info', text: 'لا يوجد تغييرات للحفظ' });
        setUpdatingAccount(false);
        return;
      }

      const { error } = await supabase.auth.updateUser(updates);
      if (error) throw error;

      setMessage({ type: 'success', text: 'تم تحديث البيانات بنجاح!' });
      setPassword('');
    } catch (err) {
      setMessage({ type: 'error', text: err.message });
    } finally {
      setUpdatingAccount(false);
    }
  };

  const tabs = [
    { id: 'overview', label: 'إحصائيات وحسابي',  icon: BarChart2 },
    { id: 'kiosk',    label: 'ربط الشاشة الذكية', icon: MonitorPlay },
  ];

  return (
    <div className="space-y-6 animate-fade-in h-full flex flex-col min-h-0" dir="rtl">
      <div className="flex justify-between items-center shrink-0">
        <h1 className="text-3xl font-bold text-[#352c3c]">اللوحة الرئيسية</h1>
      </div>

      {/* ── Tab bar ───────────────────────────────────────── */}
      <div className="flex gap-2 border-b-2 border-[#f0e6de] pb-0 shrink-0 overflow-x-auto scrollbar-hide">
        {tabs.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => setActiveTab(id)}
            className={`flex items-center gap-2 px-6 py-3 font-bold text-lg rounded-t-xl transition-all whitespace-nowrap ${
              activeTab === id
                ? 'bg-white text-[#49b5d0] border-t-2 border-r-2 border-l-2 border-[#f0e6de] relative top-[2px]'
                : 'bg-transparent text-[#a99c92] hover:bg-white/50 border-t-2 border-r-2 border-l-2 border-transparent'
            }`}
          >
            <Icon size={20} />
            {label}
          </button>
        ))}
      </div>

      {/* ── Tab content ───────────────────────────────────── */}
      <div className="flex-1 min-h-0">

        {/* ── Overview tab ── */}
        {activeTab === 'overview' && (
          <div className="space-y-8 animate-fade-in pb-8">

            {/* Stats section — super admin vs parent */}
            {isSuperAdmin ? <SuperAdminStats /> : <ParentStats />}

            {/* ── Account settings (both roles) ── */}
            <Card className="bg-white border-2 border-[#e2d5cc] p-6 max-w-2xl">
              <div className="flex items-center gap-3 mb-6 pb-4 border-b-2 border-[#f0e6de]">
                <Settings className="text-[#f0a63e]" size={28} />
                <h2 className="text-2xl font-bold text-[#352c3c]">إعدادات الحساب</h2>
              </div>

              <form onSubmit={handleUpdateAccount} className="space-y-6">
                {message.text && (
                  <div
                    className={`p-4 rounded-xl font-bold text-center ${
                      message.type === 'error'
                        ? 'bg-red-50 text-red-600 border border-red-200'
                        : message.type === 'success'
                        ? 'bg-green-50 text-green-600 border border-green-200'
                        : 'bg-blue-50 text-blue-600 border border-blue-200'
                    }`}
                  >
                    {message.text}
                  </div>
                )}

                <div>
                  <label className="block text-[#a99c92] font-bold mb-2">البريد الإلكتروني</label>
                  <Input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    dir="ltr"
                    className="text-left bg-[#faece3]/30"
                  />
                  <p className="text-sm text-[#a99c92] mt-2">
                    يمكنك تعديل البريد الإلكتروني وسيتم تغييره مباشرة
                  </p>
                </div>

                <div>
                  <label className="block text-[#a99c92] font-bold mb-2">كلمة المرور الجديدة</label>
                  <Input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="اترك الحقل فارغاً إذا لم ترغب بتغييرها"
                    dir="ltr"
                    className="text-left bg-[#faece3]/30"
                  />
                </div>

                <div className="pt-4">
                  <Button
                    type="submit"
                    disabled={updatingAccount}
                    className="w-full md:w-auto gap-2 text-lg py-3 px-8"
                  >
                    <Save size={24} />
                    {updatingAccount ? 'جاري الحفظ...' : 'حفظ التعديلات'}
                  </Button>
                </div>
              </form>
            </Card>
          </div>
        )}

        {/* ── Kiosk tab ── */}
        {activeTab === 'kiosk' && (
          <div className="animate-fade-in h-full">
            <div className="bg-white rounded-3xl overflow-hidden min-h-[600px] border-2 border-[#e2d5cc]">
              <style>{`.kiosk-manager-header { display: none !important; }`}</style>
              <div className="p-4 md:p-8">
                <KioskManager />
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Home;
