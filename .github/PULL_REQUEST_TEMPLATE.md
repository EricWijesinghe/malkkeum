## What and why

<!-- What changes, and the problem it solves. Link the issue if there is one. -->

## How it was tested

<!-- Commands run and their result, e.g. `cargo test`, `flutter test`, manual check on Android. -->

## Checklist

- [ ] Title follows `<type>: <description>` (feat, fix, refactor, docs, test, chore, perf, ci)
- [ ] Tests added or updated for new logic
- [ ] Migrations are additive (expand/contract), never edit a released one, and pass `scripts/ci/check-migrations.py`
- [ ] Installer or compose change: `bash scripts/ci/installer-selftest.sh` passes, and `deploy/install.sh`'s embedded compose matches `deploy/docker-compose.yml`
- [ ] User-visible strings go through `app/tool/strings_*.py` (Korean and English)
- [ ] Legal pages regenerated with `scripts/build_legal.py` if their text changed
- [ ] Visual change: golden baselines regenerated with the `goldens` workflow
- [ ] No secrets, keystores, `.env` files, real personal data or machine-specific paths
