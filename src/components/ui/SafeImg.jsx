import { useState } from 'react';
import { resolveStorageUrl } from '../../lib/supabase';

/**
 * صورة آمنة: تُصلح رابط Storage على السيرفر الحالي، وعند غياب الرابط أو فشل
 * تحميله تعرض fallbackSrc (صورة بديلة) أو fallback (عنصر بديل) بدل أيقونة مكسورة.
 */
const SafeImg = ({ src, fallback = null, fallbackSrc, alt = '', ...imgProps }) => {
  const resolved = resolveStorageUrl(src);
  // نحفظ الرابط الذي فشل، فإن تغيّر src تُعاد المحاولة تلقائياً
  const [failedSrc, setFailedSrc] = useState(null);

  const finalSrc = resolved && failedSrc !== resolved ? resolved : fallbackSrc;
  if (!finalSrc) return fallback;

  return (
    <img
      {...imgProps}
      src={finalSrc}
      alt={alt}
      onError={() => { if (finalSrc === resolved) setFailedSrc(resolved); }}
    />
  );
};

export default SafeImg;
