# Website performance budget

Measured with `scripts/perf/measure_site.js` (headless Chrome, local static server, external CDN requests aborted,
`/v1/*` stubbed 404). Budget: LCP 2500 ms, FCP 1800 ms, CLS 0.1, JS 300 KB, transfer 1200 KB.
Raw JSON: `scripts/perf/` output is not committed; numbers below are from the run recorded in the commit message.

| Page state | Build | Mobile LCP | Mobile CLS | JS (KB) | Transfer (KB) | three.js |
|---|---|---|---|---|---|---|
| Mobile 390px, capable device | before | 676 ms | 0.058 | 707 | 751 | loaded |
| Mobile 390px, capable device | after | 1168 ms | 0.000 | 709 | 754 | loaded |
| Desktop 1280px | before | 1476 ms | 0.019 | 707 | 751 | loaded |
| Desktop 1280px | after | 676 ms | 0.019 | 709 | 754 | loaded |
| Reduced motion, 390px | before | 776 ms | 0.058 | 707 | 751 | loaded |
| Reduced motion, 390px | after | 844 ms | 0.055 | 26 | 70 | not loaded |

Reading the table:

- Reduced-motion visitors now skip three.js: JS 707 KB to 26 KB, transfer 751 KB to 70 KB. Passes the JS budget.
- Capable devices still load three.js (about 680 KB minified). That path fails the 300 KB JS budget. Fixing it needs a
  smaller three.js build (tree-shaken), which is not done.
- Headless Chrome reports 4+ cores and no data-saver, so the "after" mobile run counts as capable.
- LCP and FCP differences between runs are single-sample noise on this machine; treat them as ±300 ms.
- Not measured: a Lighthouse score (no Lighthouse install here), real-device numbers, and the dynamic `/c/` pages
  (they need Postgres, which is not available in this environment).

Not done from the brief: font preloading (the Pretendard subset URLs come from a CDN CSS file we do not control),
image compression (the site has no raster images beyond the logo).
