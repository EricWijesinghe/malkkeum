// Headless Chromium measurement of the public website against a Lighthouse-style budget.
// Usage: node scripts/perf/measure_site.js http://127.0.0.1:8099/ [out.json]
// Playwright comes from SHOT_PLAYWRIGHT (default: the `playwright` package, as scripts/store/frame.js does).
// External CDN requests (fonts, portone) are aborted so numbers reflect our own files; API calls are stubbed 404.
const fs = require('fs');
const { chromium } = require(process.env.SHOT_PLAYWRIGHT || 'playwright');

const BUDGET = { lcpMs: 2500, fcpMs: 1800, cls: 0.1, jsKb: 300, totalKb: 1200 };

async function measure(url, device) {
  // CHROME_PATH: an installed Chrome/Edge, used when Playwright's own browser download is absent.
  const browser = await chromium.launch(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {});
  const context = await browser.newContext({ ...device, reducedMotion: device.reducedMotion || 'no-preference' });
  const page = await context.newPage();
  const origin = new URL(url).origin;
  await page.route('**/*', (route) => {
    const u = route.request().url();
    if (u.startsWith(origin)) return route.continue();
    if (u.includes('/v1/')) return route.fulfill({ status: 404, body: '{}' });
    return route.abort();
  });
  await page.addInitScript(() => {
    window.__cls = 0;
    window.__lcp = 0;
    new PerformanceObserver((list) => { for (const e of list.getEntries()) if (!e.hadRecentInput) window.__cls += e.value; }).observe({ type: 'layout-shift', buffered: true });
    new PerformanceObserver((list) => { for (const e of list.getEntries()) window.__lcp = e.startTime; }).observe({ type: 'largest-contentful-paint', buffered: true });
  });
  await page.goto(url, { waitUntil: 'load' });
  await page.waitForTimeout(1500);
  const m = await page.evaluate(() => {
    const nav = performance.getEntriesByType('navigation')[0];
    const paint = performance.getEntriesByType('paint').find((p) => p.name === 'first-contentful-paint');
    const res = performance.getEntriesByType('resource');
    const sizeOf = (pred) => res.filter(pred).reduce((s, r) => s + (r.encodedBodySize || 0), 0);
    return {
      fcpMs: paint ? Math.round(paint.startTime) : null,
      lcpMs: Math.round(window.__lcp),
      cls: Number(window.__cls.toFixed(4)),
      domContentLoadedMs: Math.round(nav.domContentLoadedEventEnd),
      jsKb: Math.round(sizeOf((r) => r.name.endsWith('.js') || r.initiatorType === 'script') / 1024),
      totalKb: Math.round(sizeOf(() => true) / 1024 + (nav.encodedBodySize || 0) / 1024),
      threeLoaded: res.some((r) => r.name.includes('/vendor/three')),
      requests: res.length,
    };
  });
  await browser.close();
  return m;
}

function verdict(m) {
  const fails = [];
  if (m.lcpMs > BUDGET.lcpMs) fails.push(`LCP ${m.lcpMs}ms > ${BUDGET.lcpMs}`);
  if (m.fcpMs !== null && m.fcpMs > BUDGET.fcpMs) fails.push(`FCP ${m.fcpMs}ms > ${BUDGET.fcpMs}`);
  if (m.cls > BUDGET.cls) fails.push(`CLS ${m.cls} > ${BUDGET.cls}`);
  if (m.jsKb > BUDGET.jsKb) fails.push(`JS ${m.jsKb}KB > ${BUDGET.jsKb}`);
  if (m.totalKb > BUDGET.totalKb) fails.push(`transfer ${m.totalKb}KB > ${BUDGET.totalKb}`);
  return fails;
}

(async () => {
  const url = process.argv[2];
  if (!url) throw new Error('usage: measure_site.js <url> [out.json]');
  const devices = {
    mobile: { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
    desktop: { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 },
    reduced_motion: { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, reducedMotion: 'reduce' },
  };
  const report = { url, budget: BUDGET, measuredAt: new Date().toISOString(), results: {} };
  let failed = 0;
  for (const [name, device] of Object.entries(devices)) {
    const m = await measure(url, device);
    const fails = verdict(m);
    failed += fails.length ? 1 : 0;
    report.results[name] = { ...m, budgetFailures: fails };
    console.log(`${name}: ${JSON.stringify(report.results[name])}`);
  }
  if (process.argv[3]) fs.writeFileSync(process.argv[3], JSON.stringify(report, null, 2));
  process.exitCode = failed ? 1 : 0;
})().catch((e) => { console.error(e); process.exitCode = 2; });
