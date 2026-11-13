#!/usr/bin/env bash
# deploy/Caddyfile parses with every environment the installer can write (ACME_EMAIL empty or set,
# TLS_MODE empty or internal), with the exact Caddy image from deploy/web.Dockerfile. The install e2e only
# covers the internal-CA case, so a public-HTTPS parse error would otherwise first show up on a real server.
# Needs Docker. Usage: bash scripts/ci/caddy-check.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
img=$(sed -n 's/^FROM \(caddy:[^ ]*\)$/\1/p' deploy/web.Dockerfile)
[ -n "$img" ] || { echo "::error::no FROM caddy line in deploy/web.Dockerfile"; exit 1; }
fail=0
for email in "" owner@example.com; do
  for mode in "" internal; do
    if ! json=$(docker run --rm -e DOMAIN=shop.example.com -e "ACME_EMAIL=$email" -e "TLS_MODE=$mode" \
        -v "$PWD/deploy/Caddyfile:/etc/caddy/Caddyfile:ro" "$img" caddy adapt --config /etc/caddy/Caddyfile 2>/dev/null); then
      echo "::error::deploy/Caddyfile does not parse with ACME_EMAIL='$email' TLS_MODE='$mode'"; fail=1; continue
    fi
    internal=0; grep -q '"module":"internal"' <<< "$json" && internal=1
    if [ "$mode" = internal ] && [ "$internal" = 0 ]; then echo "::error::TLS_MODE=internal but no internal issuer"; fail=1; fi
    if [ -z "$mode" ] && [ "$internal" = 1 ]; then echo "::error::TLS_MODE empty but the internal CA is used"; fail=1; fi
    echo "ok: ACME_EMAIL='$email' TLS_MODE='$mode'"
  done
done
exit "$fail"
