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

# Behaviour, not only parsing: requests carrying the secrets must reach the access log redacted, and /ready must be
# 404 from outside. TLS_MODE=internal because CI has no public DNS; the parse loop above covers the public case.
ticket=SECRETTICKET123 token=SECRETTOKEN456 sig=SECRETSIG789 progress=0123456789abcdef0123456789abcdef
probe='mkdir -p /var/log/caddy
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile >/tmp/caddy.log 2>&1 &
st() { wget -S -O /dev/null --no-check-certificate "https://shop.example.com$1" 2>&1 | sed -n "s/^ *HTTP\/[0-9.]* \([0-9]*\).*/\1/p" | head -1; }
i=0; while [ -z "$(st /health)" ] && [ "$i" -lt 30 ]; do sleep 1; i=$((i + 1)); done
st "/v1/ws?ticket=$TICKET" >/dev/null
st "/v1/files?token=$TOKEN&sig=$SIG" >/dev/null
st "/ops-progress/$PROGRESS" >/dev/null
echo "READY=$(st /ready)"
cat /var/log/caddy/access.log'
if ! out=$(docker run --rm --add-host shop.example.com:127.0.0.1 \
    -e DOMAIN=shop.example.com -e ACME_EMAIL=owner@example.com -e TLS_MODE=internal \
    -e "TICKET=$ticket" -e "TOKEN=$token" -e "SIG=$sig" -e "PROGRESS=$progress" \
    -v "$PWD/deploy/Caddyfile:/etc/caddy/Caddyfile:ro" "$img" sh -c "$probe"); then
  echo "::error::edge redaction check could not run Caddy"; exit 1
fi
for s in "$ticket" "$token" "$sig" "$progress"; do
  if grep -qF "$s" <<< "$out"; then echo "::error::edge access log keeps secret $s"; fail=1; fi
done
for r in 'ticket=REDACTED' 'token=REDACTED' 'sig=REDACTED' '/ops-progress/REDACTED'; do
  grep -qF "$r" <<< "$out" || { echo "::error::edge access log lacks $r"; fail=1; }
done
grep -qxF 'READY=404' <<< "$out" || { echo "::error::/ready is not 404 at the edge"; fail=1; }
[ "$fail" = 0 ] && echo "ok: edge access log redacts secrets, /ready is 404"
exit "$fail"
