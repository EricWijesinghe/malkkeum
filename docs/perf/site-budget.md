# Website performance budget

Measured with `scripts/perf/measure_site.js` (headless Chrome, local static server, `/v1/*` stubbed 404).
Budget: LCP 2500 ms, FCP 1800 ms, CLS 0.1, JS 300 KB, transfer 1200 KB. Single local samples: treat LCP/FCP as ±300 ms.

| Page state | Mobile LCP | CLS | JS (KB) | Transfer (KB) | three.js |
|---|---|---|---|---|---|
| Mobile 390px, capable device | 260 ms | 0.000 | 544 | 837 | loaded after `load`, when idle |
| Desktop 1280px | 304 ms | 0.021 | 544 | 837 | loaded after `load`, when idle |
| Reduced motion, 390px | 232 ms | 0.000 | 27 | 320 | not loaded |

Previous run (CDN font, full three.js loaded at `DOMContentLoaded`): JS 709 KB, transfer 754 KB, plus the
render-blocking Pretendard CSS from a third-party CDN.

What changed:

- Font: self-hosted "Dahae Sans" (a Pretendard subset, `scripts/build_fonts.py`), three weights of about 52 KB
  each, the two above-the-fold weights preloaded. No third-party request on any page.
- three.js: `website/vendor/three.hero.min.js` holds only the classes the hero uses (about 510 KB instead of
  690 KB), and `site.js` imports it after the `load` event when the browser is idle, so it never delays first
  paint or LCP. Visitors with reduced motion, few cores, little memory or data saver never download it.

Still over budget: JS on capable devices (544 KB > 300 KB), all of it the deferred hero. Getting under 300 KB
needs a different renderer (for example a pre-rendered video or image sequence of the hero), not a smaller
three.js build: `WebGLRenderer` alone is most of the bundle.

Not measured: a Lighthouse score (no Lighthouse install here), real-device numbers, and the dynamic `/c/` pages
(they need Postgres). Accessibility was checked with axe-core 4.10 (WCAG 2.1 AA + best practice) on every
static page in dark and light themes and at 360 px: no violations except "page has no h1" on the two
transient pages `/pay/done.html` and `/auth/naver/callback.html`.
