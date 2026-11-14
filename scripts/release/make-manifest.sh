#!/usr/bin/env bash
# Writes installer_manifest.json (release tag and the SHA-256 of each published installer file) and
# installer_manifest.json.sig (ed25519 signature, base64). The public key is baked into the desktop helper,
# so an installer release never needs a new app build. Usage: make-manifest.sh <tag> <dir> <private-key.pem>
set -euo pipefail
tag=${1:?usage: make-manifest.sh <tag> <dir> <private-key.pem>}
dir=${2:?usage: make-manifest.sh <tag> <dir> <private-key.pem>}
key=${3:?usage: make-manifest.sh <tag> <dir> <private-key.pem>}

[[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]] || { echo "::error::bad release tag: $tag" >&2; exit 1; }
[ -f "$key" ] || { echo "::error::signing key not found" >&2; exit 1; }
cd "$dir"
[ -f install.sh ] || { echo "::error::install.sh is missing from $dir" >&2; exit 1; }

entries=""
for f in install.sh agent.sh; do # agent.sh is optional until the agent ships in the installer
  [ -f "$f" ] || continue
  entries+="${entries:+,}\"$f\":\"$(sha256sum "$f" | cut -d' ' -f1)\""
done
printf '{"tag":"%s","files":{%s}}\n' "$tag" "$entries" > installer_manifest.json

sig=$(mktemp)
trap 'rm -f "$sig"' EXIT
openssl pkeyutl -sign -rawin -inkey "$key" -in installer_manifest.json -out "$sig"
openssl base64 -A -in "$sig" -out installer_manifest.json.sig
echo "manifest written: $(cat installer_manifest.json)"
