#!/usr/bin/env bash
# Self-test for deploy/install.sh and the `dahae` CLI it writes. No root, no Docker, nothing installed:
# sources both with DAHAE_SELFTEST=1 (main is skipped) and runs the pure functions in a sandbox dir.
# Usage: bash scripts/ci/installer-selftest.sh
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SB=$(mktemp -d)
trap 'rm -rf "$SB"' EXIT
PASS=0 FAIL=0

t()  { if "${@:2}"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL: $1"; fi; }    # t "what" cmd... : must succeed
nt() { if "${@:2}"; then FAIL=$((FAIL + 1)); echo "FAIL (should fail): $1"; else PASS=$((PASS + 1)); fi; }
eq() { [ "$1" = "$2" ] || { echo "   got [$1] want [$2]"; return 1; }; }

bash -n "$ROOT/deploy/install.sh"
# shellcheck source=deploy/install.sh
DAHAE_SELFTEST=1 . "$ROOT/deploy/install.sh"
set +e # the sourced installer turned on -e; failures are counted below, not fatal

# ---- installer: input checks ----
t  "domain plain"          valid_domain myshop.co.kr
t  "domain with scheme"    valid_domain https://MyShop.co.kr/admin/
t  "norm_domain"           eq "$(norm_domain 'https://MyShop.co.kr/x')" myshop.co.kr
nt "domain empty"          valid_domain ""
nt "domain no dot"         valid_domain localhost
nt "domain shell chars"    valid_domain 'a.com;rm -rf /'
t  "email empty ok"        valid_email ""
t  "email ok"              valid_email owner@myshop.co.kr
nt "email bad"             valid_email 'owner@shop'
t  "heartbeat url"         valid_hb_url https://hc-ping.com/1f2e3d4c-aaaa-bbbb-cccc-123456789abc
nt "heartbeat http"        valid_hb_url http://hc-ping.com/x
nt "heartbeat ampersand"   valid_hb_url 'https://x.io/a?b=1&c=2'
# shellcheck disable=SC2016 # literal $(id) on purpose
nt "heartbeat subshell"    valid_hb_url 'https://x.io/$(id)'

# ---- installer: version compare ----
t  "ver_ge newer"          ver_ge 2.29.1 2.20
t  "ver_ge equal"          ver_ge 2.20 2.20
t  "ver_ge v prefix"       ver_ge v2.27.0 2.20
t  "ver_ge numeric order"  ver_ge 2.100.0 2.20
nt "ver_ge older"          ver_ge 2.17.3 2.20
nt "ver_ge v1"             ver_ge 1.29.2 2.20

# ---- installer: preflight parsing ----
cat > "$SB/meminfo" <<'EOF'
MemTotal:        1004532 kB
MemFree:          201220 kB
SwapTotal:             0 kB
EOF
t  "mem_kb MemTotal"       eq "$(mem_kb MemTotal "$SB/meminfo")" 1004532
t  "mem_kb SwapTotal"      eq "$(mem_kb SwapTotal "$SB/meminfo")" 0
t  "mem_kb missing key"    eq "$(mem_kb Nope "$SB/meminfo")" 0
t  "1 GB host needs swap"  test "$(mem_kb MemTotal "$SB/meminfo")" -lt "$SWAP_BELOW_KB"
t  "1 GB host allowed"     test "$(mem_kb MemTotal "$SB/meminfo")" -ge "$MIN_RAM_KB"
is_num() { case "$1" in ''|*[!0-9]*) return 1 ;; esac; }
t  "disk_free_kb number"   is_num "$(disk_free_kb "$SB")"
t  "arch x86_64"           arch_ok x86_64
t  "arch aarch64"          arch_ok aarch64
nt "arch armv7"            arch_ok armv7l
SS='LISTEN 0 511 0.0.0.0:80 0.0.0.0:* users:(("nginx",pid=812,fd=6),("nginx",pid=811,fd=6))
LISTEN 0 4096 0.0.0.0:443 0.0.0.0:* users:(("docker-proxy",pid=1200,fd=4))
LISTEN 0 511 [::]:443 [::]:* users:(("apache2",pid=900,fd=4))'
t  "ports: non-docker holders" eq "$(printf '%s\n' "$SS" | port_holders | tr '\n' ' ')" "apache2 nginx "
t  "ports: docker only"    eq "$(printf '%s\n' 'LISTEN 0 4096 0.0.0.0:80 0.0.0.0:* users:(("docker-proxy",pid=1,fd=4))' | port_holders)" ""
t  "ports: unknown holder" eq "$(printf '%s\n' 'LISTEN 0 4096 0.0.0.0:80 0.0.0.0:*' | port_holders)" "?"
t  "ports: none"           eq "$(printf '' | port_holders)" ""
t  "ipv4 filter (CNAME dropped)" eq "$(printf 'shop.example.net.\n203.0.113.7\n' | only_ipv4)" 203.0.113.7
t  "ip in list"            ip_in_list 203.0.113.7 "$(printf '198.51.100.1\n203.0.113.7')"
nt "ip not in list"        ip_in_list 203.0.113.70 "$(printf '203.0.113.7')"
nt "empty ip"              ip_in_list "" ""

# ---- the CLI the installer writes ----
DIR=$SB
write_cli "$SB/dahae"
write_heartbeat "$SB/heartbeat"
t  "CLI path substituted"  grep -q "^DIR=$SB\$" "$SB/dahae"
t  "CLI bash -n"           bash -n "$SB/dahae"
t  "heartbeat bash -n"     bash -n "$SB/heartbeat"
if command -v shellcheck >/dev/null; then
  t "CLI shellcheck"       shellcheck -S warning "$SB/dahae" "$SB/heartbeat"
else
  echo "skip: shellcheck not installed"
fi
cd "$SB"
printf 'DOMAIN=myshop.co.kr\nIMAGE_SOURCE=local\n' > .env
# shellcheck source=/dev/null
DAHAE_SELFTEST=1 . "$SB/dahae"
set +e
t  "uploads_for"           eq "$(uploads_for backups/db-20261110-033000.sql.gz)" backups/uploads-20261110-033000.tar.gz
t  "fingerprint ok"        valid_fingerprints "$(printf 'AB:%.0s' $(seq 31))CD"
t  "two fingerprints"      valid_fingerprints "$(printf 'ab:%.0s' $(seq 31))cd,$(printf 'AB:%.0s' $(seq 31))EF"
nt "fingerprint short"     valid_fingerprints AB:CD
nt "fingerprint not hex"   valid_fingerprints "$(printf 'ZZ:%.0s' $(seq 31))CD"
t  "team id"               valid_team_id ABCDE12345
nt "team id short"         valid_team_id ABCDE
t  "env_get"               eq "$(env_get DOMAIN)" myshop.co.kr
env_set DOMAIN other.co.kr; env_set NEWKEY v=1
t  "env_set replace"       eq "$(env_get DOMAIN)" other.co.kr
t  "env_set add"           eq "$(env_get NEWKEY)" v=1
export YES=1 # read by confirm() in the sourced CLI
t  "confirm --yes"         confirm "q" yes

# digest_ref with a fake docker: loaded (tar) images have no RepoDigests, so they get a keep- tag
ID=sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
# shellcheck disable=SC2317 # called indirectly by digest_ref
docker() {
  case "$*" in
    "image inspect -f {{.Id}} "*) [ "$5" = gone:tag ] && return 1; echo "$ID" ;;
    "image inspect -f {{index .RepoDigests 0}} "*) [ -n "${FAKE_DIGEST:-}" ] && echo "$FAKE_DIGEST" || return 1 ;;
    "tag "*) echo "$2 $3" >> "$SB/tags" ;;
    *) echo "unexpected docker $*" >&2; return 1 ;;
  esac
}
t  "digest_ref local -> keep tag" eq "$(digest_ref r/malkkeum-api:local r/malkkeum-api)" r/malkkeum-api:keep-0123456789ab
t  "keep tag created"      grep -qx "$ID r/malkkeum-api:keep-0123456789ab" "$SB/tags"
env_set IMAGE_SOURCE remote
FAKE_DIGEST=r/malkkeum-api@sha256:feed
t  "digest_ref remote -> digest" eq "$(digest_ref r/malkkeum-api:stable r/malkkeum-api)" r/malkkeum-api@sha256:feed
FAKE_DIGEST=
t  "digest_ref remote, no digest -> keep tag" eq "$(digest_ref r/malkkeum-api:stable r/malkkeum-api)" r/malkkeum-api:keep-0123456789ab
t  "digest_ref unknown image -> as given" eq "$(digest_ref gone:tag r/x)" gone:tag
unset -f docker

echo "installer self-test: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
