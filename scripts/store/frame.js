// Frames the raw store screenshots (written by the Flutter store-shot tests) into store images:
// brand gradient, headline caption, device frame. Also renders the Play feature graphic (1024x500)
// and a 1080x1920 poster. Rendered by Chromium through Playwright, so Korean, Japanese, Chinese and
// Vietnamese text uses the same shaping the browser uses.
//
//   node scripts/store/frame.js            (run through scripts/store/generate.sh)
//
// Inputs:  app/build/store_shots/raw/<app>/<device>/<lang>/<NN-name>.png
//          docs/store/screenshots/captions.json
// Outputs: docs/store/screenshots/<app>/<device>/<lang>/<NN-name>.png
//          docs/store/graphics/<app>-feature-<lang>.png, docs/store/graphics/customer-poster-<lang>.png
// Playwright is loaded from SHOT_PLAYWRIGHT (default: the F:/tools/shot install).
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const { chromium } = require(process.env.SHOT_PLAYWRIGHT || 'F:/tools/shot/node_modules/playwright');

const ROOT = path.resolve(__dirname, '..', '..');
const RAW = path.join(ROOT, 'app', 'build', 'store_shots', 'raw');
const STORE = path.join(ROOT, 'docs', 'store');
const SHOTS = path.join(STORE, 'screenshots');
const GRAPHICS = path.join(STORE, 'graphics');
const FONTS = path.join(ROOT, 'app', 'packages', 'ui', 'assets', 'fonts');
const HTML_DIR = path.join(ROOT, 'app', 'build', 'store_shots', 'html');

const LANG_TAG = { ko: 'ko', en: 'en', ja: 'ja', zh: 'zh-Hans', vi: 'vi' };
const CAPTIONS = JSON.parse(fs.readFileSync(path.join(SHOTS, 'captions.json'), 'utf8'));

const fontFaces = [400, 500, 600, 700, 800]
  .map((w) => `@font-face{font-family:'Dahae Sans';font-weight:${w};src:url('${pathToFileURL(path.join(FONTS, `DahaeSans-${{ 400: 'Regular', 500: 'Medium', 600: 'SemiBold', 700: 'Bold', 800: 'ExtraBold' }[w]}.otf`)).href}') format('opentype');}`)
  .join('\n');

const STACK = "'Dahae Sans','Apple SD Gothic Neo','Noto Sans KR','Noto Sans JP','Noto Sans SC','Hiragino Sans','Yu Gothic','Microsoft YaHei','Malgun Gothic',sans-serif";

/** One HTML document: gradient canvas, two headline lines, device frame cropped by the bottom edge. */
function framePage({ w, h, colors, lang, lines, imgUrl, imgRatio, phoneWidth = 0.78, phoneTop = 0.3 }) {
  const headSize = Math.round(w * 0.075);
  const phoneW = Math.round(w * phoneWidth);
  const radius = Math.round(w * 0.075);
  return `<!doctype html><html lang="${lang}"><head><meta charset="utf-8"><style>
${fontFaces}
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:${w}px;height:${h}px;overflow:hidden}
body{font-family:${STACK};background:linear-gradient(160deg,${colors.a} 0%,${colors.b} 100%);color:#fff;position:relative}
.glow{position:absolute;inset:0;background:radial-gradient(circle at 20% 12%,rgba(255,255,255,.32),transparent 45%),radial-gradient(circle at 90% 80%,rgba(255,255,255,.18),transparent 40%)}
.head{position:absolute;top:${Math.round(h * 0.065)}px;left:0;right:0;text-align:center;font-weight:800;letter-spacing:-.02em;line-height:1.14}
.head div{font-size:${headSize}px}
.head div+div{font-weight:600;opacity:.92;font-size:${Math.round(headSize * 0.8)}px;margin-top:${Math.round(headSize * 0.2)}px}
.phone{position:absolute;left:50%;transform:translateX(-50%);top:${Math.round(h * phoneTop)}px;width:${phoneW}px;padding:${Math.round(w * 0.013)}px;background:#0B1022;border-radius:${radius}px;box-shadow:0 ${Math.round(w * 0.04)}px ${Math.round(w * 0.08)}px rgba(6,10,30,.45)}
.phone img{display:block;width:100%;height:auto;border-radius:${Math.round(radius * 0.72)}px}
</style></head><body><div class="glow"></div>
<div class="head"><div>${lines[0]}</div><div>${lines[1]}</div></div>
<div class="phone"><img src="${imgUrl}" style="aspect-ratio:${imgRatio.w} / ${imgRatio.h}"></div>
</body></html>`;
}

/** Feature graphic: wordmark and tagline on the left, the home screen on the right. */
function featurePage({ lang, colors, title, tagline, imgUrl, imgRatio }) {
  return `<!doctype html><html lang="${lang}"><head><meta charset="utf-8"><style>
${fontFaces}
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:1024px;height:500px;overflow:hidden}
body{font-family:${STACK};background:linear-gradient(120deg,${colors.a},${colors.b});color:#fff;position:relative}
.glow{position:absolute;inset:0;background:radial-gradient(circle at 15% 15%,rgba(255,255,255,.3),transparent 50%)}
.txt{position:absolute;left:64px;top:0;bottom:0;width:520px;display:flex;flex-direction:column;justify-content:center}
.title{font-size:104px;font-weight:800;letter-spacing:-.03em;line-height:1}
.tag{font-size:36px;font-weight:600;margin-top:24px;opacity:.95;line-height:1.3}
.phone{position:absolute;right:90px;top:50px;height:400px;width:${Math.round((400 * imgRatio.w) / imgRatio.h)}px;padding:12px;background:#0B1022;border-radius:44px;box-shadow:0 30px 60px rgba(6,10,30,.45)}
.phone img{display:block;width:100%;height:100%;object-fit:cover;object-position:top;border-radius:34px}
</style></head><body><div class="glow"></div>
<div class="txt"><div class="title">${title}</div><div class="tag">${tagline}</div></div>
<div class="phone"><img src="${imgUrl}"></div>
</body></html>`;
}

function writeHtml(name, html) {
  fs.mkdirSync(HTML_DIR, { recursive: true });
  const file = path.join(HTML_DIR, name);
  fs.writeFileSync(file, html, 'utf8');
  return pathToFileURL(file).href;
}

function imageRatio(file) {
  // PNG IHDR: width at byte 16, height at byte 20.
  // readFileSync has no start/end options, so read the header bytes from the whole buffer.
  const buf = fs.readFileSync(file);
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
}

function listDirs(p) {
  return fs.existsSync(p) ? fs.readdirSync(p, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name) : [];
}

const DEVICES = {
  'ios-6.9': [1320, 2868],
  'ios-6.5': [1284, 2778],
  'ipad-13': [2064, 2752],
  android: [1080, 2400],
};

async function main() {
  const browser = await chromium.launch();
  let count = 0;
  const shoot = async (w, h, url, out) => {
    const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
    await page.goto(url, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    await page.screenshot({ path: out, type: 'png', clip: { x: 0, y: 0, width: w, height: h } });
    await page.close();
    count += 1;
  };

  for (const app of ['customer', 'partner']) {
    const colors = CAPTIONS.brand[app];
    const shots = CAPTIONS[app];
    for (const device of listDirs(path.join(RAW, app))) {
      const [w, h] = DEVICES[device] ?? [null, null];
      if (!w) throw new Error(`unknown device folder ${device}`);
      for (const lang of listDirs(path.join(RAW, app, device))) {
        for (const file of fs.readdirSync(path.join(RAW, app, device, lang)).filter((f) => f.endsWith('.png'))) {
          const key = file.replace(/\.png$/, '');
          const caption = shots[key]?.[lang];
          if (!caption) throw new Error(`no caption for ${app}/${key} (${lang}) in captions.json`);
          const raw = path.join(RAW, app, device, lang, file);
          const url = writeHtml(`${app}-${device}-${lang}-${key}.html`, framePage({
            w, h, colors, lang: LANG_TAG[lang], lines: caption, imgUrl: pathToFileURL(raw).href, imgRatio: imageRatio(raw),
          }));
          await shoot(w, h, url, path.join(SHOTS, app, device, lang, `${key}.png`));
        }
      }
    }
  }

  // Feature graphic and poster use the Android raw set, so they need that device folder.
  for (const app of ['customer', 'partner']) {
    const colors = CAPTIONS.brand[app];
    const home = app === 'customer' ? '01-home' : '01-jobs';
    for (const lang of listDirs(path.join(RAW, app, 'android'))) {
      const raw = path.join(RAW, app, 'android', lang, `${home}.png`);
      if (!fs.existsSync(raw)) continue;
      const f = CAPTIONS.feature[lang];
      const url = writeHtml(`${app}-feature-${lang}.html`, featurePage({
        lang: LANG_TAG[lang], colors, title: f.title, tagline: f.tagline, imgUrl: pathToFileURL(raw).href, imgRatio: imageRatio(raw),
      }));
      await shoot(1024, 500, url, path.join(GRAPHICS, `${app}-feature-${lang}.png`));
      if (app !== 'customer') continue;
      const cap = CAPTIONS.customer['01-home'][lang];
      const posterUrl = writeHtml(`customer-poster-${lang}.html`, framePage({
        w: 1080, h: 1920, colors, lang: LANG_TAG[lang], lines: cap, imgUrl: pathToFileURL(raw).href, imgRatio: imageRatio(raw), phoneWidth: 0.82, phoneTop: 0.25,
      }));
      await shoot(1080, 1920, posterUrl, path.join(GRAPHICS, `customer-poster-${lang}.png`));
    }
  }

  await browser.close();
  console.log(`framed ${count} images`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
