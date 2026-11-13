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
sub() { ( "$@" ) >/dev/null 2>&1; } # die exits: run it in a subshell

# ---- restore-offsite only takes real backup names (no ../ paths) ----
t  "backup name"           valid_backup_name db-20261110-033000.sql.gz
t  "backup name .enc"      valid_backup_name db-20261110-033000.sql.gz.enc
nt "backup name traversal" valid_backup_name ../../etc/db-20261110-033000.sql.gz
nt "backup name dir"       valid_backup_name x/db-20261110-033000.sql.gz.enc
nt "backup name uploads"   valid_backup_name uploads-20261110-033000.tar.gz.enc
nt "backup name suffix"    valid_backup_name 'db-20261110-033000.sql.gz.enc;id'

# ---- uploads tar: checked first, then extracted beside the old files and swapped ----
mk_tar() { # mk_tar 이름 명령 : $SB/tsrc 에서 명령을 실행해 $SB/tar/<이름>.tar.gz 를 만들어요
  rm -rf "$SB/tsrc"; mkdir -p "$SB/tsrc/uploads/sub" "$SB/tar"
  (cd "$SB/tsrc" && sh -c "$2") || echo "mk_tar $1 failed"
}
export T="$SB/tar"
# shellcheck disable=SC2016 # $T and $PWD expand inside mk_tar's sh
{
  mk_tar good 'echo a > uploads/a.jpg; echo b > uploads/sub/b.jpg; tar czf "$T/good.tar.gz" uploads'
  mk_tar link 'ln -s /etc/passwd uploads/p; tar czf "$T/link.tar.gz" uploads'
  mk_tar hard 'echo a > uploads/a; ln uploads/a uploads/h; tar czf "$T/hard.tar.gz" uploads'
  mk_tar dotdot 'echo x > x; tar czPf "$T/dotdot.tar.gz" uploads uploads/../x'
  mk_tar abs 'echo x > uploads/a; tar czPf "$T/abs.tar.gz" uploads "$PWD/uploads/a"'
  mk_tar other 'mkdir etc; echo x > etc/x; tar czf "$T/other.tar.gz" uploads etc'
  mk_tar empty 'tar czf "$T/empty.tar.gz" -T /dev/null'
}
printf 'not a tar' | gzip > "$T/junk.tar.gz"
head -c 4096 /dev/urandom | gzip > "$T/noise.tar.gz"
nt "uploads tar empty"     uploads_tar_ok "$T/empty.tar.gz"
nt "uploads tar noise"     uploads_tar_ok "$T/noise.tar.gz"
t  "uploads tar ok"        uploads_tar_ok "$T/good.tar.gz"
nt "uploads tar symlink"   uploads_tar_ok "$T/link.tar.gz"
nt "uploads tar hardlink"  uploads_tar_ok "$T/hard.tar.gz"
nt "uploads tar .."        uploads_tar_ok "$T/dotdot.tar.gz"
nt "uploads tar absolute"  uploads_tar_ok "$T/abs.tar.gz"
nt "uploads tar outside uploads/" uploads_tar_ok "$T/other.tar.gz"
nt "uploads tar not a tar" uploads_tar_ok "$T/junk.tar.gz"
nt "uploads tar missing"   uploads_tar_ok "$T/none.tar.gz"
swap() { sh -c "${UPLOADS_SWAP//\/data\/uploads/$SB/vol}" < "$1" 2>/dev/null; } # the api container's script, on a sandbox dir
mkdir -p "$SB/vol"; echo old > "$SB/vol/old.jpg"
nt "swap: broken tar fails" swap "$T/noise.tar.gz"
t  "swap: old files kept when extract fails" test -f "$SB/vol/old.jpg"
t  "swap: no temp dir left after failure" test ! -e "$SB/vol/.restore-new"
t  "swap: good tar"        swap "$T/good.tar.gz"
t  "swap: new files in place" eq "$(cat "$SB/vol/a.jpg" "$SB/vol/sub/b.jpg" | tr '\n' ' ')" "a b "
t  "swap: old files gone"  test ! -e "$SB/vol/old.jpg"
t  "swap: temp dir gone"   test ! -e "$SB/vol/.restore-new"

# ---- uninstall --purge ignores --yes / DAHAE_YES: the domain must be typed or passed with --confirm ----
has_tty() { return 1; } # as under cron or CI: nobody to ask
nt "purge: --yes alone refused"  sub purge_ok ""
nt "purge: wrong domain refused" sub purge_ok wrong.co.kr
t  "purge: --confirm domain"     sub purge_ok other.co.kr
t  "plain uninstall still takes --yes" sub confirm "q" yes

# ---- image signatures: verified by digest, no silent skip ----
t  "signer ok"             valid_signer EricWijesinghe/malkkeum
nt "signer regex chars"    valid_signer 'a/b|.*'
nt "signer no repo"        valid_signer EricWijesinghe
t  "signer identity regex" eq "$(signer_re Eric.W/mal.keum)" '(?i)^https://github\.com/Eric\.W/mal\.keum/\.github/workflows/release\.yml@refs/tags/v[0-9]'
printf 'abc' > "$SB/sum"
t  "sha256_is match"       sha256_is "$SB/sum" ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
nt "sha256_is mismatch"    sha256_is "$SB/sum" 0000000000000000000000000000000000000000000000000000000000000000
t  "cosign sha amd64"      eq "$(cosign_sha256 x86_64)" "$COSIGN_SHA256_AMD64"
t  "cosign sha arm64"      eq "$(cosign_sha256 aarch64)" "$COSIGN_SHA256_ARM64"
nt "cosign sha other arch" cosign_sha256 armv7l
mkdir -p "$SB/bin"
cat > "$SB/bin/cosign" <<'COS'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$(dirname "$0")/args"
[ "${FAKE_COSIGN:-}" = ok ] || { echo "Error: no matching signatures" >&2; exit 1; }
echo 'Verification for x --' >&2
echo '[{"critical":{"image":{"docker-manifest-digest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}}}]'
COS
chmod 755 "$SB/bin/cosign"
env_set SIGNER_REPO EricWijesinghe/malkkeum
export FAKE_COSIGN=ok
t  "verify -> pinned digest" eq "$(verify_image ghcr.io/o/malkkeum-api:stable)" ghcr.io/o/malkkeum-api@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
t  "verify pins the OIDC issuer" grep -q -- "--certificate-oidc-issuer https://token.actions.githubusercontent.com" "$SB/bin/args"
t  "verify pins release.yml on tags" grep -qF 'EricWijesinghe/malkkeum/\.github/workflows/release\.yml@refs/tags/v' "$SB/bin/args"
FAKE_COSIGN=bad
nt "unsigned image refused" sub verify_image ghcr.io/o/malkkeum-api:stable
FAKE_COSIGN=ok; env_set SIGNER_REPO 'bad repo'
nt "bad signer refused"    sub verify_image ghcr.io/o/malkkeum-api:stable
env_set SIGNER_REPO EricWijesinghe/malkkeum; rm -f "$SB/bin/cosign"
nt "missing cosign refused (no silent skip)" sub verify_image ghcr.io/o/malkkeum-api:stable

# ---- app DB role: not a superuser; restores drop owner/extension lines ----
SQL=$(db_roles_sql 0123456789abcdef0123456789abcdef)
t  "role is not superuser" grep -q 'NOSUPERUSER NOCREATEDB NOCREATEROLE' <<< "$SQL"
t  "role password set"     grep -q "PASSWORD '0123456789abcdef0123456789abcdef'" <<< "$SQL"
nt "no placeholders left"  grep -q '__ROLE__\|__PW__' <<< "$SQL"
t  "extensions made by the superuser" grep -q 'CREATE EXTENSION IF NOT EXISTS pg_trgm' <<< "$SQL"
DUMP="ALTER TABLE public.x OWNER TO app;
DROP EXTENSION IF EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'x';
CREATE TABLE public.x (a int);"
t  "restore filter drops owner and extension lines" eq "$(restore_filter <<< "$DUMP")" 'CREATE TABLE public.x (a int);'

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

# ---- .env is set to root-only on every installer run, even if it was loosened ----
chmod 644 .env
lock_env
t  ".env locked to 600"    eq "$(stat -c %a .env)" 600

# ---- the compose file install.sh writes = deploy/docker-compose.yml (minus comments, build and app image lines) ----
norm_compose() { sed -E -e '/^[[:space:]]*#/d' -e 's/[[:space:]]+#[[:space:]].*$//' -e '/^[[:space:]]*build:/d' \
  -e '/^[[:space:]]*image: \$\{(API|WEB)_IMAGE/d' -e '/^[[:space:]]*$/d' "$1"; }
mkdir -p "$SB/compose" && (cd "$SB/compose" && write_compose)
t  "embedded compose = deploy/docker-compose.yml" diff <(norm_compose "$ROOT/deploy/docker-compose.yml") <(norm_compose "$SB/compose/docker-compose.yml")
# shellcheck disable=SC2016 # literal ${...} on purpose
t  "embedded compose pins images from .env" eq "$(grep -c 'image: ${\(API\|WEB\)_IMAGE:?set by install.sh}' "$SB/compose/docker-compose.yml")" 2
t  "every service hardened" eq "$(grep -c '<<: \*hardened' "$ROOT/deploy/docker-compose.yml")" 3
for k in 'no-new-privileges:true' 'cap_drop: \[ALL\]' 'read_only: true'; do
  t "hardening has $k" grep -q "^  .*$k" "$ROOT/deploy/docker-compose.yml"
done
t  "every service memory-capped" eq "$(grep -c '^    mem_limit:' "$ROOT/deploy/docker-compose.yml")" 3

# ---- secret key copy (dahae keys-backup / keys-restore) ----
printf 'DB_PASSWORD=%s\nDATA_KEY=%s\nJWT_SECRET=%s\n' "$(printf 'a%.0s' $(seq 48))" "$(printf 'b%.0s' $(seq 64))" "$(printf 'c%.0s' $(seq 64))" > "$SB/keys.env"
keys_seal 'correct horse battery' < "$SB/keys.env" > "$SB/keys.enc"
t  "sealed copy is not plain text" sh -c "! grep -q DATA_KEY '$SB/keys.enc'"
t  "sealed copy opens with its passphrase" eq "$(keys_open 'correct horse battery' < "$SB/keys.enc")" "$(cat "$SB/keys.env")"
opens() { keys_open "$1" < "$SB/keys.enc" >/dev/null; } # a wrong passphrase can print bytes before it fails
nt "wrong passphrase refused" opens 'wrong horse battery'
t  "DATA_KEY read back" eq "$(keys_field DATA_KEY < "$SB/keys.env")" "$(printf 'b%.0s' $(seq 64))"
# shellcheck disable=SC2016 # literal $(id) on purpose
t  "non-hex value ignored" eq "$(printf 'DATA_KEY=$(id)\n' | keys_field DATA_KEY)" ""

# ---- failed unattended jobs alert through the heartbeat URL ----
t  "fail url"              eq "$(fail_url https://hc-ping.com/abc)" https://hc-ping.com/abc/fail
t  "fail url, trailing /"  eq "$(fail_url https://hc-ping.com/abc/)" https://hc-ping.com/abc/fail
t  "fail url keeps query"  eq "$(fail_url 'https://x.io/p?k=1')" 'https://x.io/p/fail?k=1'
nt "alert takes update|backup only" sub cmd_alert ../../etc
for job in update backup; do
  t "cron alerts on a failed $job" grep -qF "dahae $job >> \$DIR/backups/$job.log 2>&1 || \$BIN/dahae alert $job" "$ROOT/deploy/install.sh"
done

# ---- publish-delivery.sh: channel branches + immutable annotated tag (a local bare repo stands in for DIST_REPO) ----
DIST=EricWijesinghe/malkkeum-install
git init -q --bare "$SB/dist.git"
pub() { # pub 태그 : the release job's delivery step, pushing to $SB/dist.git instead of GitHub
  GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.$SB/dist.git.insteadOf" GIT_CONFIG_VALUE_0="git@github.com:$DIST.git" \
    DIST_REPO=$DIST VER="$1" IMAGE_REPO=ghcr.io/o SIGNER_REPO=o/src bash "$ROOT/deploy/publish-delivery.sh" >/dev/null 2>&1
}
g() { git -C "$SB/dist.git" "$@"; }
has() { grep -qF -- "$2" <<< "$(g show "$1")"; } # has 태그:파일 문자열 (no pipe: grep -q + pipefail = SIGPIPE)
sums_ok() { [ "$(g show "$1:install.sh" | sha256sum | cut -d' ' -f1)" = "$(g show "$1:SHA256SUMS" | cut -d' ' -f1)" ]; }
t  "publish stable"        pub v1.0.0
t  "tag is annotated"      eq "$(g cat-file -t v1.0.0)" tag
t  "tag = main commit"     eq "$(g rev-parse 'v1.0.0^{commit}')" "$(g rev-parse main)"
t  "tag installer is stable" has v1.0.0:install.sh DEFAULT_CHANNEL=stable
t  "tag installer names the signer" has v1.0.0:install.sh SIGNER_REPO_DEFAULT=o/src
t  "tag SHA256SUMS matches" sums_ok v1.0.0
t  "tag guide uses the tag URL" has "v1.0.0:guide/01-서버-설치.md" "raw.githubusercontent.com/$DIST/v1.0.0/install.sh"
t  "tag README uses the tag URL" has v1.0.0:README.md "raw.githubusercontent.com/$DIST/v1.0.0/SHA256SUMS"
t  "beta branch keeps the stable-branch line" has "beta:guide/01-서버-설치.md" "raw.githubusercontent.com/$DIST/main/install.sh"
nt "developer-only guide not shipped" sub g cat-file -e v1.0.0:guide/05-demo-install.md
nt "no link to the developer-only guide" sh -c "git -C '$SB/dist.git' grep -q 05-demo-install v1.0.0 -- guide"
t  "re-run is a no-op"     pub v1.0.0
t  "publish beta"          pub v1.1.0-beta.1
t  "beta tag = beta commit" eq "$(g rev-parse 'v1.1.0-beta.1^{commit}')" "$(g rev-parse beta)"
t  "beta tag installer is beta" has v1.1.0-beta.1:install.sh DEFAULT_CHANNEL=beta
t  "beta tag SHA256SUMS matches" sums_ok v1.1.0-beta.1
t  "stable tag unchanged by beta" eq "$(g rev-parse 'v1.0.0^{commit}')" "$(g rev-parse main)"
g -c user.name=t -c user.email=t@t tag -f -a v1.0.0 -m moved beta >/dev/null
nt "moved tag is refused"  pub v1.0.0

echo "installer self-test: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
