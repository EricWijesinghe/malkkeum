#!/usr/bin/env bash
# One command to regenerate every store image from the current app screens:
#   1. raw screenshots of both apps at the store sizes (Flutter tests tagged store_screenshots)
#   2. framed store images, Play feature graphics and a poster (Chromium via Playwright)
#   3. listing length check (docs/store/check_listings.py)
# Usage: scripts/store/generate.sh            (all languages and devices)
#        SHOT_LANGS=ko,en SHOT_DEVICES=android scripts/store/generate.sh
# Every heavy step goes through build-slot.sh, so it shares the 2 build slots on this PC.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/env.sh"

LANGS="${SHOT_LANGS:-ko,en,ja,zh,vi}"
DEVICES="${SHOT_DEVICES:-ios-6.9,ios-6.5,ipad-13,android}"
mkdir -p "$ROOT/app/build/store_shots/raw"
RAW="$(cd "$ROOT/app/build/store_shots/raw" && pwd -W 2>/dev/null || pwd)"

for app in customer partner; do
  (
    cd "$ROOT/app/apps/$app"
    "$ROOT/scripts/build-slot.sh" flutter test test/store_screenshots \
      --tags store_screenshots \
      --dart-define=SHOT_LANGS="$LANGS" \
      --dart-define=SHOT_DEVICES="$DEVICES" \
      --dart-define=SHOT_OUT="$RAW" 2>&1 | tail -n 15
  )
done

"$ROOT/scripts/build-slot.sh" node "$ROOT/scripts/store/frame.js"
python -I "$ROOT/docs/store/check_listings.py"
