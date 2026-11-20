import rabbitSvg from '../../assets/rabbit-kick-scooter.svg?raw';
import { isValidHue, recolorRabbit } from '../../lib/rabbitColor';

// رابط صورة لكل لون يُبنى مرة واحدة ويُعاد استخدامه (عدد الألوان صغير)
const urlCache = new Map();
const rabbitUrl = (hue) => {
  const key = isValidHue(hue) ? hue : 'original';
  if (!urlCache.has(key)) {
    const svg = recolorRabbit(rabbitSvg, hue);
    urlCache.set(key, URL.createObjectURL(new Blob([svg], { type: 'image/svg+xml' })));
  }
  return urlCache.get(key);
};

/** أرنب السكوتر بلون فرو الطفل (rabbit_hue)؛ بلا لون يظهر الأرنب الأصلي. */
const RabbitImg = ({ hue, alt = 'Rabbit', ...imgProps }) => (
  <img {...imgProps} src={rabbitUrl(hue)} alt={alt} />
);

export default RabbitImg;
