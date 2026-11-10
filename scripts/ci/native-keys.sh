#!/usr/bin/env bash
# Writes per-build native key files from CI env vars (Codemagic group "malkkeum"). Never commit outputs.
#   scripts/ci/native-keys.sh customer|partner
# Outputs:
#   app/apps/<app>/keys.json                  -> flutter build ... --dart-define-from-file=keys.json
#   app/apps/<app>/ios/Flutter/Keys.xcconfig  -> URL schemes / GIDClientID (Info.plist reads these)
#   android/app/google-services.json, ios/Runner/GoogleService-Info.plist -> Firebase push (optional)
# Every key is optional: a missing key hides that sign-in button or disables push, the build still passes.
set -euo pipefail
app="${1:?customer or partner}"
case "$app" in customer|partner) ;; *) echo "unknown app: $app" >&2; exit 2 ;; esac
root="$(cd "$(dirname "$0")/../.." && pwd)/app/apps/$app"
up=$(printf '%s' "$app" | tr '[:lower:]' '[:upper:]')

# Partner Firebase files have their own vars (separate Firebase apps); everything else is shared.
pick() { local own="${up}_$1"; printf '%s' "${!own:-${!1:-}}"; }

python3 -I - "$root/keys.json" <<'PY'
import json, os, sys
names = ["API_BASE", "KAKAO_NATIVE_KEY", "NAVER_CLIENT_ID", "NAVER_CLIENT_SECRET", "NAVER_CLIENT_NAME",
         "GOOGLE_SERVER_CLIENT_ID", "GOOGLE_IOS_CLIENT_ID", "SOCIAL_PROVIDERS"]
keys = {n: os.environ[n] for n in names if os.environ.get(n)}
if "API_BASE" not in keys or not keys["API_BASE"].startswith("https://"):
    sys.exit("API_BASE must be set to https://<client domain>")
json.dump(keys, open(sys.argv[1], "w"), indent=1)
print("dart-defines:", ", ".join(sorted(keys)))
PY

gid="${GOOGLE_IOS_CLIENT_ID:-}"
reversed="google-unset"
[ -n "$gid" ] && reversed="com.googleusercontent.apps.${gid%.apps.googleusercontent.com}"
cat > "$root/ios/Flutter/Keys.xcconfig" <<EOF
KAKAO_URL_SCHEME = kakao${KAKAO_NATIVE_KEY:-unset}
GOOGLE_IOS_CLIENT_ID = ${gid:-google-unset}
GOOGLE_REVERSED_CLIENT_ID = $reversed
EOF

json=$(pick GOOGLE_SERVICES_JSON_B64)
plist=$(pick GOOGLE_SERVICE_INFO_PLIST_B64)
if [ -n "$json" ]; then printf '%s' "$json" | base64 -d > "$root/android/app/google-services.json"; echo "firebase android: on"; else echo "firebase android: off"; fi
if [ -n "$plist" ]; then printf '%s' "$plist" | base64 -d > "$root/ios/Runner/GoogleService-Info.plist"; echo "firebase ios: on"; else echo "firebase ios: off"; fi
