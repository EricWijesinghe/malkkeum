## What and why

<!-- One or two sentences. Link the issue if there is one. -->

## Checks

- [ ] Tests added or updated for new behaviour
- [ ] New migration follows `scripts/ci/check-migrations.py` (never edit a released one)
- [ ] Installer or compose change: `bash scripts/ci/installer-selftest.sh` passes, and `deploy/install.sh`'s embedded compose matches `deploy/docker-compose.yml`
- [ ] No secrets, real personal data or machine-specific paths
- [ ] Visual change: golden baselines regenerated with the `goldens` workflow
