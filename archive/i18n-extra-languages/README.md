# Archived app languages

**What:** 12 languages — zh, vi, ja, ru, ne, si, th, id, mn, uz, fil, km — removed from the shipped
product and kept here so they can be restored.

**Why:** owner decision 2026-11-13: Dahae is for Korean customers only. The product ships Korean
(default) and English. Nothing in this folder is built, bundled or deployed (it is outside `app/`,
`website/` and `backend/`, and listed in `.dockerignore`).

Archived from git `1f3d3b1`. Every place that used to list these languages carries the comment
`i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)`:
`git grep -n "i18n-archive"` lists them all.

## Contents

| Path here | Was | Content |
|---|---|---|
| `app/tool/lang_<code>.py` (12) | `app/tool/lang_*.py` (9) + the ja/zh/vi columns and `X` blocks of `app/tool/strings_*.py` | `T = {key: text}`, all 1575 app keys per language |
| `app/tool/check_lang.py`, `i18n_source.json` | `app/tool/` | translator check + ko/en source (stale: 654 keys) |
| `app/packages/core/lib/l10n/app_<code>.arb` (12) | same path | the generated ARBs (same texts as `lang_<code>.py`) |
| `app/apps/{customer,partner}/ios/Runner/<code>.lproj/` | same path | iOS permission texts (InfoPlist.strings) |
| `ios-pbxproj-removed-lines.txt` | `app/apps/*/ios/Runner.xcodeproj/project.pbxproj` | 72 lines: file refs, variant-group children, knownRegions |
| `backend/i18n_table_14.rs.txt` | `backend/crates/api/src/i18n.rs` | `LANGS` + 14-language `TABLE` (push/SMS/inbox texts) |
| `backend/ai_handoff_extra.rs.txt` | `backend/crates/api/src/ai.rs` | ja/zh/vi AI handoff lines |
| `backend/seed_extra.rs.txt` | `backend/crates/api/src/seed.rs` | ja/zh/vi seeded banner + FAQ |
| `website/site-js-extra.js` | `website/assets/site.js` | old `LANGS` + ja/zh/vi `COPY` blocks |
| `website/services.json`, `web_copy.json` | `website/assets/` | 14-language website data (regenerated, keep only for reference) |
| `docs/store/listing-{ja,zh,vi}.md`, `release-notes/{ja,zh,vi}.md`, `screenshots/captions.json` | `docs/store/` | store listings and screenshot captions |
| `tools/extract_extra_languages.py` | — | the one-shot script that did the extraction (asserts no row changed) |

Stored data is not touched: content items and accounts can still hold archived locales in the DB.
Accounts whose `locale` is an archived code are served English (`i18n::shipped` on the server,
`LocaleController.restore` in the apps, `pickLang` on the website); the console content editor
keeps archived-language texts when an item is edited.

## Restore (one or more languages)

Run from the repo root. `<code>` is the language; iOS uses `zh-Hans` for `zh`.

1. **App strings.** `git mv archive/i18n-extra-languages/app/tool/lang_<code>.py app/tool/`.
   `gen_arb.py` picks up every `app/tool/lang_*.py` (its `EXTRA` list) — no list to edit. Keys added
   since the archive are missing: `python -I app/tool/gen_arb.py` names them; add them to the
   `lang_<code>.py` (or as `X = {code: {...}}` in the area's `strings_*.py`) until it passes.
   Optionally move `check_lang.py` / `i18n_source.json` back to `app/tool/` for translators.
2. **Regenerate.** `python -I app/tool/gen_arb.py && python -I app/tool/gen_web_strings.py`, then
   `cd app/packages/core && flutter gen-l10n` (writes `app_<code>.arb` and `app_localizations_<code>.dart`).
3. **App language list.** `app/packages/core/lib/src/session.dart` `LocaleController.names`: add
   `'<code>': '<name in its own language>'` (old names: 中文, Tiếng Việt, 日本語, Русский, नेपाली,
   සිංහල, ไทย, Bahasa Indonesia, Монгол, Oʻzbekcha, Filipino, ខ្មែរ). Pickers, `supportedLocales`,
   the console content editor and every locale sweep test follow this map. In `restore()` the
   archived-language branch then only applies to codes still archived.
   A first-launch picker existed as `app/packages/core/lib/src/language_welcome.dart` (git `1f3d3b1`);
   restore it only if many languages come back.
4. **Backend.** `backend/crates/api/src/routes/me.rs` `SUPPORTED_LOCALES`: add the code.
   `backend/crates/api/src/i18n.rs`: put back the column for the code from `backend/i18n_table_14.rs.txt`
   (`LANGS` + per-row translations, plus the `LANGS` column lookup in `tr()`), and make `shipped()`
   return supported codes as they are. Optional: `ai.rs` handoff lines, `seed.rs` texts, `demo/people.rs`
   (`9 => "ja"`). Keep the English-segment rule in `marketing.rs` in line with `shipped()`.
5. **Website.** `website/assets/site.js`: add the code to `LANGS` and its `COPY` block from
   `website/site-js-extra.js` (only ja/zh/vi had their own copy; others fall back to English).
6. **iOS.** Move `app/apps/{customer,partner}/ios/Runner/<code>.lproj/` back and re-insert that code's
   three lines per app from `ios-pbxproj-removed-lines.txt` (next to the `en` siblings); add the code to
   `IOS_LANGS` in `scripts/ci/check-native.py`.
7. **Windows (msix).** `languages:` in `app/apps/{customer,partner}/pubspec.yaml` (old: `ja-jp, zh-cn,
   vi-vn, th-th, id-id, fil-ph, km-kh, mn-mn, ne-np, ru-ru, si-lk, uz-latn-uz`).
8. **Store.** Move `docs/store/listing-<code>.md` and `release-notes/<code>.md` back (ja/zh/vi only),
   add the code to the release-notes list in `scripts/ci/check-native.py`, re-add its entries to
   `docs/store/screenshots/captions.json`, `LANG_TAG` in `scripts/store/frame.js`, the `SHOT_LANGS`
   defaults in `scripts/store/generate.sh` and `app/packages/test_support/lib/src/store_shots.dart`,
   and the language lines of `listing-ko.md` / `listing-en.md` / `microsoft-store.md`.
9. **Tests.** Update the expected counts: `app/packages/core/test/core_test.dart` (picker list) and
   `error_codes_test.dart` (`hasLength`), and `table_has_no_blank_translation` in `i18n.rs`. The locale
   sweep tests (`app/apps/*/test/locale_sweep*_test.dart`) iterate `LocaleController.supported`, so
   they cover the restored language without edits.
10. **Verify.** `dart analyze --fatal-infos app/`, `flutter test` in packages/core, packages/ui and
    the three apps, `cargo test`, `python -I scripts/ci/check-native.py`, `python -I docs/store/check_listings.py`.

Formatting rules kept on purpose for ja/zh (`_hourLangs` in `app/packages/core/lib/src/i18n.dart`,
`_shortYearLangs` in `app/apps/customer/lib/screens/bookings.dart`) were left in the code.
