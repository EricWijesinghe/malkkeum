# Contributing

## Setup

Requirements: Rust (stable), Flutter (stable), PostgreSQL 17, Python 3.11+, Docker (for image builds).

1. Copy `scripts/local.env.example` to `scripts/local.env` and set the tool locations for your machine
   (optional when everything is on `PATH`). `source scripts/env.sh` loads it.
2. `scripts/dev-api.sh` starts Postgres on port 5433 and the API on `:8080` in `DEV_MODE` (all external
   services faked). It creates `backend/.env` on the first run.
3. Apps: `cd app && flutter pub get`, then `python -I tool/gen_arb.py && (cd packages/core && flutter gen-l10n)`,
   then `cd apps/customer && flutter run --dart-define=API_BASE=http://localhost:8080`.

User-visible strings live in `app/tool/strings_*.py`; never edit the `.arb` files or generated
localisation code by hand.

## Branches and commits

- Branch from `master`: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`.
- Commit messages: `<type>: <description>` with `type` one of
  `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`. Imperative, lower case, no trailing period.
- Keep pull requests focused; describe what changed, why, and how it was tested (see the PR template).
- Database migrations are additive (expand/contract) so a rollback can run the previous release:
  see [docs/DEPLOY.md](docs/DEPLOY.md#2-releases-and-channels). `python -I scripts/ci/check-migrations.py` must pass.

## Tests

Run before opening a pull request:

```bash
cd backend && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
cd app && dart analyze --fatal-infos
cd app/apps/customer && flutter test        # likewise partner, console, packages/core, packages/ui
python -I scripts/ci/check-native.py
python -I scripts/ci/check-migrations.py
python -I scripts/build_legal.py website --check
```

New logic comes with a test (Rust integration tests in `backend/crates/api/tests`, Flutter widget or
unit tests). Fix the code, not the test, unless the test is wrong.

## Security

Never commit secrets, keystores or `.env` files. Report vulnerabilities privately: see [SECURITY.md](SECURITY.md).
