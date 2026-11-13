#!/usr/bin/env bash
# Pinned tool versions agree everywhere they are written. Raise each pin in all of its places together
# (a Dependabot bump of one file fails here until the others follow). Usage: bash scripts/ci/check-pins.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
fail=0
same() { # same 무엇 기준값 값... : 모든 값이 기준값과 같아야 해요
  local what="$1" want="$2" v; shift 2
  [ -n "$want" ] || { echo "::error::$what: pin not found"; fail=1; return; }
  for v in "$@"; do
    [ "$v" = "$want" ] || { echo "::error::$what: found '$v', expected '$want'"; fail=1; }
  done
}

same "Rust: backend/rust-toolchain.toml vs backend/Dockerfile" \
  "$(sed -n 's/^channel = "\(.*\)"$/\1/p' backend/rust-toolchain.toml)" \
  "$(sed -n 's/^FROM rust:\([0-9.]*\)-.*/\1/p' backend/Dockerfile)"
same "Flutter: .github/actions/flutter-setup vs deploy/web.Dockerfile vs codemagic.yaml" \
  "$(sed -n 's/.*flutter-version: \([0-9.]*\),.*/\1/p' .github/actions/flutter-setup/action.yml)" \
  "$(sed -n 's/^ARG FLUTTER_VERSION=//p' deploy/web.Dockerfile)" \
  "$(sed -n 's/^    flutter: //p' codemagic.yaml)"
# shellcheck disable=SC2046 # one word per cosign-release line
same "cosign: deploy/install.sh vs .github/workflows/release.yml" \
  "$(sed -n 's/^COSIGN_VERSION=//p' deploy/install.sh)" \
  $(sed -n 's/.*cosign-release: \(v[0-9.]*\) .*/\1/p' .github/workflows/release.yml)

[ "$fail" = 0 ] && echo "pins agree"
exit "$fail"
