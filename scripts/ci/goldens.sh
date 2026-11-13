#!/usr/bin/env bash
# Golden (pixel) tests. Baselines are made on the CI runner only (Linux, Flutter pinned in
# .github/actions/flutter-setup, fonts from test/support): local renders differ, so dart_test.yaml skips
# the `golden` tag outside CI.
#   goldens.sh check    compare every package that has golden tests with its committed PNGs (ci.yml)
#   goldens.sh update   write new baselines (.github/workflows/goldens.yml uploads them as an artifact)
# Rule: until the first baseline PNG is committed anywhere, a package without baselines only warns.
# Once any baseline exists, a package with golden tests but no PNG fails, so baselines never go missing
# silently. A missing PNG for one test in a package that has others fails inside `flutter test`.
set -euo pipefail
mode=${1:-}
case "$mode" in check|update) ;; *) echo "usage: goldens.sh check|update" >&2; exit 2 ;; esac
cd "$(dirname "$0")/../../app"
PKGS=(packages/ui packages/core apps/customer apps/partner apps/console)

has_tests() { [ -d "$1/test" ] && grep -rlqE "@Tags\(\[[^]]*'golden'" "$1/test"; }
has_pngs() { [ -d "$1/test" ] && [ -n "$(find "$1/test" -path '*goldens*' -name '*.png' -print -quit)" ]; }

any=0
for p in "${PKGS[@]}"; do if has_pngs "$p"; then any=1; fi; done

rc=0
for p in "${PKGS[@]}"; do
  has_tests "$p" || continue
  if [ "$mode" = update ]; then
    (cd "$p" && flutter test --run-skipped --tags golden --update-goldens) || rc=1
  elif has_pngs "$p"; then
    (cd "$p" && flutter test --run-skipped --tags golden) || rc=1
  elif [ "$any" = 1 ]; then
    echo "::error::$p has golden tests but no committed baselines. Run the goldens workflow and commit its PNGs."
    rc=1
  else
    echo "::warning::$p: golden tests not compared yet (no baselines committed). Run the goldens workflow once."
  fi
done
exit "$rc"
