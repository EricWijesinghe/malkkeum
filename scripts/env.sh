# shellcheck shell=bash
# Source before any build. Machine-specific locations come from scripts/local.env (gitignored; see
# scripts/local.env.example). Without it, the tools and caches already on PATH are used.
_dahae_scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Plain KEY=VALUE lines (no shell expansion, same parser as scripts/local-env.ps1); variables already set win.
if [ -f "$_dahae_scripts/local.env" ]; then
  while IFS='=' read -r _k _v || [ -n "$_k" ]; do
    case "$_k" in ''|\#*|*[!A-Za-z0-9_]*) continue ;; esac
    [ -n "${!_k+x}" ] && continue
    _v="${_v%$'\r'}"; _v="${_v%\"}"; _v="${_v#\"}"
    export "$_k=$_v"
  done < "$_dahae_scripts/local.env"
  unset _k _v
fi
unset _dahae_scripts
if [ -n "${DAHAE_TOOLS:-}" ]; then
  export FLUTTER_ROOT="$DAHAE_TOOLS/flutter"
  export PATH="$DAHAE_TOOLS/flutter/bin:$PATH"
  export CARGO_HOME="$DAHAE_TOOLS/cargo-home"
  export PUB_CACHE="$DAHAE_TOOLS/pub-cache"
  export GRADLE_USER_HOME="$DAHAE_TOOLS/gradle"
  export npm_config_cache="$DAHAE_TOOLS/npm-cache"
  export TMP="$DAHAE_TOOLS/tmp" TEMP="$DAHAE_TOOLS/tmp" TMPDIR="$DAHAE_TOOLS/tmp"
  export PLAYWRIGHT_BROWSERS_PATH="$DAHAE_TOOLS/ms-playwright"
fi
export FLUTTER_SUPPRESS_ANALYTICS=true
