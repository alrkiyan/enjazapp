import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { ShieldCheck, Eye, EyeOff, KeyRound } from 'lucide-react';
import Button from './Button';
import Input from './Input';

/**
 * ForceChangePassword
 * Shown when user_metadata.must_change_password === true.
 * Blocks the entire UI — cannot be dismissed without setting a new password.
 */
const ForceChangePassword = ({ onDone }) => {
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (newPassword.length < 6) {
      setError('كلمة المرور يجب أن تكون 6 أحرف على الأقل.');
      return;
    }
    if (newPassword === 'Aa123321') {
      setError('يرجى اختيار كلمة مرور مختلفة عن كلمة المرور الافتراضية.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setError('كلمتا المرور غير متطابقتين.');
      return;
    }

    setLoading(true);
    try {
      // تغيير كلمة المرور وإزالة علامة الإجبار دفعةً واحدة
      const { error: updateError } = await supabase.auth.updateUser({
        password: newPassword,
        data: { must_change_password: false },
      });
      if (updateError) throw updateError;
      onDone();
    } catch (err) {
      setError(err.message || 'حدث خطأ أثناء تغيير كلمة المرور.');
    } finally {
      setLoading(false);
    }
  };

  return (
    /* طبقة التعتيم — لا يُغلق عند النقر خارجها */
    <div
      className="fixed inset-0 z-[9999] flex items-center justify-center"
      style={{ background: 'rgba(53,44,60,0.7)', backdropFilter: 'blur(6px)' }}
    >
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md mx-4 p-8 animate-[fadeInUp_0.3s_ease]">
        {/* الرأس */}
        <div className="text-center mb-6">
          <div className="w-20 h-20 bg-[#c15b40]/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <ShieldCheck className="text-[#c15b40]" size={40} />
          </div>
          <h2 className="text-2xl font-bold text-[#352c3c]">تغيير كلمة المرور مطلوب</h2>
          <p className="text-[#a99c92] text-sm mt-2 leading-relaxed">
            هذه أول مرة تسجّل فيها الدخول. يجب عليك تغيير كلمة المرور الافتراضية قبل المتابعة.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* كلمة المرور الجديدة */}
          <div className="relative">
            <Input
              id="force-new-password"
              type={showPassword ? 'text' : 'password'}
              label="كلمة المرور الجديدة"
              placeholder="••••••••"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
              dir="ltr"
              className="text-left"
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              className="absolute left-3 top-[38px] text-[#a99c92] hover:text-[#49b5d0] transition-colors"
            >
              {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>

          {/* تأكيد كلمة المرور */}
          <Input
            id="force-confirm-password"
            type={showPassword ? 'text' : 'password'}
            label="تأكيد كلمة المرور"
            placeholder="••••••••"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
            dir="ltr"
            className="text-left"
          />

          {/* متطلبات */}
          <ul className="text-xs text-[#a99c92] space-y-1 pr-2">
            <li className={`flex items-center gap-1.5 ${newPassword.length >= 6 ? 'text-[#488b40]' : ''}`}>
              <KeyRound size={12} />
              6 أحرف على الأقل
            </li>
            <li className={`flex items-center gap-1.5 ${newPassword && newPassword !== 'Aa123321' ? 'text-[#488b40]' : ''}`}>
              <KeyRound size={12} />
              مختلفة عن كلمة المرور الافتراضية
            </li>
            <li className={`flex items-center gap-1.5 ${newPassword && newPassword === confirmPassword ? 'text-[#488b40]' : ''}`}>
              <KeyRound size={12} />
              كلتا الكلمتين متطابقتان
            </li>
          </ul>

          {error && (
            <div className="p-3 bg-[#c15b40]/10 border border-[#c15b40]/20 rounded-2xl text-[#c15b40] font-bold text-center text-sm">
              {error}
            </div>
          )}

          <Button
            type="submit"
            variant="primary"
            className="w-full text-lg h-14"
            disabled={loading}
          >
            {loading ? 'جاري الحفظ...' : 'حفظ كلمة المرور الجديدة والمتابعة'}
          </Button>
        </form>
      </div>
    </div>
  );
};

export default ForceChangePassword;
