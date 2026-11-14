#!/usr/bin/env bash
# Builds the cloud-init generator page for one release: copies deploy/install-page/index.html with the SHA-256 of
# that release's install.sh and its raw URL embedded. The page runs only in the owner's browser; the cloud-init
# it generates downloads install.sh and refuses to run it unless the hash matches.
# Usage: build-install-page.sh <install.sh> <raw install.sh URL> <out dir>
set -euo pipefail
install=${1:?usage: build-install-page.sh <install.sh> <url> <out dir>}
url=${2:?usage: build-install-page.sh <install.sh> <url> <out dir>}
out=${3:?usage: build-install-page.sh <install.sh> <url> <out dir>}
root=$(cd "$(dirname "$0")/../.." && pwd)
src="$root/deploy/install-page/index.html"

[[ $url =~ ^https://raw\.githubusercontent\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/v[0-9][A-Za-z0-9._+-]*/install\.sh$ ]] \
  || { echo "::error::install URL must be a pinned tag URL on raw.githubusercontent.com: $url" >&2; exit 1; }
[ -f "$install" ] || { echo "::error::$install missing" >&2; exit 1; }
[ -f "$src" ] || { echo "::error::$src missing" >&2; exit 1; }
hash=$(sha256sum "$install" | cut -d' ' -f1)
[[ $hash =~ ^[0-9a-f]{64}$ ]] || { echo "::error::could not hash $install" >&2; exit 1; }

mkdir -p "$out"
sed -e "s|__INSTALL_SH_SHA256__|$hash|g" -e "s|__INSTALL_URL__|$url|g" "$src" > "$out/index.html"
if grep -q '__INSTALL_' "$out/index.html"; then
  echo "::error::placeholder left in $out/index.html" >&2
  exit 1
fi
echo "install page written: $out/index.html (install.sh sha256 $hash)"
