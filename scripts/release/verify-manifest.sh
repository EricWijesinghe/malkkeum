#!/usr/bin/env bash
# Checks installer_manifest.json against its ed25519 signature, then the files and SHA256SUMS against it.
# Fails closed on any mismatch. Usage: verify-manifest.sh <dir> <public-key.pem> [expected-tag]
set -euo pipefail
dir=${1:?usage: verify-manifest.sh <dir> <public-key.pem> [expected-tag]}
pub=${2:?usage: verify-manifest.sh <dir> <public-key.pem> [expected-tag]}
want_tag=${3:-}

fail() { echo "::error::$*" >&2; exit 1; }
cd "$dir"
[ -f installer_manifest.json ] && [ -f installer_manifest.json.sig ] || fail "manifest or signature missing"
sig=$(mktemp)
trap 'rm -f "$sig"' EXIT
openssl base64 -d -A -in installer_manifest.json.sig -out "$sig" || fail "signature is not base64"
openssl pkeyutl -verify -rawin -pubin -inkey "$pub" -sigfile "$sig" -in installer_manifest.json >/dev/null 2>&1 \
  || fail "manifest signature does not match: refusing these installer files"

tag=$(grep -oE '"tag":"v[^"]*"' installer_manifest.json | head -n 1 | cut -d'"' -f4)
[ -n "$tag" ] || fail "manifest has no tag"
if [ -n "$want_tag" ] && [ "$tag" != "$want_tag" ]; then fail "manifest is for $tag, expected $want_tag"; fi

grep -qE '"install\.sh":"[0-9a-f]{64}"' installer_manifest.json || fail "manifest has no install.sh hash"
while IFS= read -r entry; do
  name=$(printf '%s' "$entry" | cut -d'"' -f2)
  want=$(printf '%s' "$entry" | cut -d'"' -f4)
  [ -f "$name" ] || fail "$name is listed in the manifest but missing"
  got=$(sha256sum "$name" | cut -d' ' -f1)
  [ "$got" = "$want" ] || fail "$name does not match the signed manifest"
done < <(grep -oE '"[A-Za-z0-9_]+\.sh":"[0-9a-f]{64}"' installer_manifest.json)

[ -f SHA256SUMS ] || fail "SHA256SUMS missing"
sha256sum -c --strict SHA256SUMS >/dev/null 2>&1 || fail "SHA256SUMS does not match the files"
echo "ok: $tag manifest signature and file hashes verified"
