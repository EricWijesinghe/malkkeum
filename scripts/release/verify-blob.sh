#!/usr/bin/env bash
# Verifies a sign-blob.sh bundle: the signer must be the release workflow of <owner/repo> on a v* tag, issued
# through GitHub Actions OIDC (the same identity rule as signer_re in deploy/install.sh).
# Usage: verify-blob.sh <file> <owner/repo>
set -euo pipefail
file=${1:?usage: verify-blob.sh <file> <owner/repo>}
repo=${2:?usage: verify-blob.sh <file> <owner/repo>}
[[ $repo =~ ^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$ ]] || { echo "::error::bad repo: $repo" >&2; exit 1; }
[ -f "$file" ] && [ -f "$file.bundle" ] || { echo "::error::$file or its bundle is missing" >&2; exit 1; }
esc=$(printf '%s' "$repo" | sed 's/\./\\./g')
re="(?i)^https://github\\.com/${esc}/\\.github/workflows/release\\.yml@refs/tags/v[0-9]"
cosign verify-blob --bundle "$file.bundle" --certificate-identity-regexp "$re" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com "$file" >/dev/null 2>&1 \
  || { echo "::error::$file is not signed by the release workflow of $repo" >&2; exit 1; }
echo "ok: $file signed by the $repo release workflow"
