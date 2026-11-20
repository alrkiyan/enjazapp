// تلوين أرنب الكشك بلون خاص لكل طفل.
// درجات الفرو في src/assets/rabbit-kick-scooter.svg (كلها بنّية بدرجة 22°) — تحقّقنا بصرياً
// أنها الفرو والأذنان فقط؛ الوشاح والسكوتر والذيل والخدود بألوان أخرى لا تتغير.
const FUR_COLORS = ['#a88977', '#bf9e8b', '#997d6d', '#b3927f', '#9e8170', '#b49381', '#a08372'];

// الفرو الأصلي باهت (تشبّع 0.18–0.29)؛ نرفعه ليظهر اللون الجديد واضحاً.
const SATURATION_BOOST = 2.2;
const MAX_SATURATION = 0.7;

const hexToHsl = (hex) => {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return { h: 0, s: 0, l };
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
  else if (max === g) h = ((b - r) / d + 2) / 6;
  else h = ((r - g) / d + 4) / 6;
  return { h: h * 360, s, l };
};

const hslToHex = (h, s, l) => {
  const a = s * Math.min(l, 1 - l);
  const channel = (n) => {
    const k = (n + h / 30) % 12;
    const c = l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1));
    return Math.round(c * 255).toString(16).padStart(2, '0');
  };
  return `#${channel(0)}${channel(8)}${channel(4)}`;
};

export const isValidHue = (hue) => Number.isInteger(hue) && hue >= 0 && hue < 360;

// يستبدل درجات الفرو بدرجات من اللون المطلوب مع الحفاظ على فاتحها وغامقها (الظل والتجسيم)
export const recolorRabbit = (svgText, hue) => {
  if (!isValidHue(hue)) return svgText;
  return FUR_COLORS.reduce((text, color) => {
    const { s, l } = hexToHsl(color);
    const next = hslToHex(hue, Math.min(MAX_SATURATION, s * SATURATION_BOOST), l);
    return text.replaceAll(color, next).replaceAll(color.toUpperCase(), next);
  }, svgText);
};

// نتجنّب الأصفر (46°–75°) لأنه يذوب في الوشاح الأصفر. نفس المدى في قيمة
// قاعدة البيانات الافتراضية: (76 + floor(random()*330)) % 360
const randomHue = () => (76 + Math.floor(Math.random() * 330)) % 360;

const hueDistance = (a, b) => {
  const d = Math.abs(a - b) % 360;
  return d > 180 ? 360 - d : d;
};

// لون عشوائي بعيد قدر الإمكان عن ألوان الإخوة (أفضل مرشّح من 24 محاولة)
export const pickDistinctHue = (existingHues = [], exclude = null) => {
  const taken = existingHues.filter(isValidHue);
  if (isValidHue(exclude)) taken.push(exclude);
  let best = randomHue();
  if (taken.length === 0) return best;
  let bestScore = -1;
  for (let i = 0; i < 24; i += 1) {
    const candidate = randomHue();
    const score = Math.min(...taken.map((h) => hueDistance(candidate, h)));
    if (score > bestScore) {
      best = candidate;
      bestScore = score;
    }
  }
  return best;
};
