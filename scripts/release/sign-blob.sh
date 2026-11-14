#!/usr/bin/env bash
# Keyless cosign signature of one published file (SHA256SUMS, the install page): writes <file>.bundle.
# Runs only in release.yml (GitHub OIDC identity of the tagged workflow). Usage: sign-blob.sh <file>
set -euo pipefail
file=${1:?usage: sign-blob.sh <file>}
[ -f "$file" ] || { echo "::error::$file missing" >&2; exit 1; }
command -v cosign >/dev/null || { echo "::error::cosign is not installed; refusing to publish unsigned files" >&2; exit 1; }
cosign sign-blob --yes --bundle "$file.bundle" "$file" >/dev/null
echo "signed: $file"
