# Web image: Caddy serving the website (/), the customer web app (/app/), the console (/admin/) and proxying the API.
# Build context: repository root.
# Flutter web output is the same for every CPU, so this stage always runs natively on the build machine
# (no QEMU for the linux/arm64 image); only the Caddy stage below is per-platform.
FROM --platform=$BUILDPLATFORM ghcr.io/cirruslabs/flutter:stable AS console
# The :stable image can lag the Flutter/Dart SDK that app/pubspec.lock needs (Dart >= 3.13), so pin the SDK here.
ARG FLUTTER_VERSION=3.47.9
RUN cd /sdks/flutter && git fetch -q --depth 1 origin "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}" && git checkout -q "${FLUTTER_VERSION}" && flutter --version
# Mirror the engine's fallback fonts (Roboto + Noto, URL list read from the pinned SDK) so browsers never call
# fonts.gstatic.com: the apps bundle no text font, so without this every glyph is fetched from Google at runtime.
# Build-time fetch only; curl -f fails the build if a pinned font URL disappears.
RUN grep -rhoE "[a-z0-9]+/v[0-9]+/[A-Za-z0-9_.-]+\.woff2" /sdks/flutter/engine/src/flutter/lib/web_ui/lib/src/engine | sort -u > /tmp/webfonts.txt \
 && test "$(wc -l < /tmp/webfonts.txt)" -ge 700 \
 && mkdir /webfonts && cd /webfonts \
 && xargs -P 8 -I{} curl -fsS --retry 3 --create-dirs -o {} "https://fonts.gstatic.com/s/{}" < /tmp/webfonts.txt
WORKDIR /src/app
COPY app/ .
# Same bootstrap for both apps: points the engine's fallback fonts at /webfonts/ (see deploy/flutter_bootstrap.js).
COPY deploy/flutter_bootstrap.js apps/console/web/flutter_bootstrap.js
COPY deploy/flutter_bootstrap.js apps/customer/web/flutter_bootstrap.js
# Both web builds self-host CanvasKit/skwasm (--no-web-resources-cdn) so the CSP needs no Google CDN,
# and compile with --wasm (JavaScript fallback included) so the CSP needs no 'unsafe-eval'.
RUN python3 -I tool/gen_arb.py \
 && flutter pub get \
 && (cd packages/core && flutter gen-l10n) \
 && cd apps/console && flutter build web --release --wasm --no-web-resources-cdn --base-href /admin/ \
 && cd ../customer && flutter build web --release --wasm --no-web-resources-cdn --base-href /app/

FROM caddy:2
ARG APP_VERSION=dev
LABEL org.opencontainers.image.source=https://github.com/EricWijesinghe/malkkeum-install org.opencontainers.image.version=$APP_VERSION
COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY website/ /srv/website/
COPY --from=console /src/app/apps/console/build/web/ /srv/console/
COPY --from=console /src/app/apps/customer/build/web/ /srv/app/
COPY --from=console /webfonts/ /srv/webfonts/
# One domain for everything, HTTPS certificates issued and renewed automatically:
#   https://DOMAIN/          website
#   https://DOMAIN/app/      customer web app (no install)
#   https://DOMAIN/admin/    operations console (setup wizard on first visit)
#   https://DOMAIN/v1, /health   API (uploads: /v1/files, signed URLs only)
