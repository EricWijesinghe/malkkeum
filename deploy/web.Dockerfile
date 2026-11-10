# Web image: Caddy serving the website (/), the customer web app (/app/), the console (/admin/) and proxying the API.
# Build context: repository root.
FROM ghcr.io/cirruslabs/flutter:stable AS console
WORKDIR /src/app
COPY app/ .
# Web builds self-host CanvasKit/skwasm (--no-web-resources-cdn) so the CSP needs no Google CDN.
RUN python3 -I tool/gen_arb.py \
 && flutter pub get \
 && (cd packages/core && flutter gen-l10n) \
 && cd apps/console && flutter build web --release --base-href /admin/ \
 && cd ../customer && flutter build web --release --wasm --no-web-resources-cdn --base-href /app/

FROM caddy:2
ARG APP_VERSION=dev
LABEL org.opencontainers.image.source=https://github.com/EricWijesinghe/malkkeum-install org.opencontainers.image.version=$APP_VERSION
COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY website/ /srv/website/
COPY --from=console /src/app/apps/console/build/web/ /srv/console/
COPY --from=console /src/app/apps/customer/build/web/ /srv/app/
# One domain for everything, HTTPS certificates issued and renewed automatically:
#   https://DOMAIN/          website
#   https://DOMAIN/app/      customer web app (no install)
#   https://DOMAIN/admin/    operations console (setup wizard on first visit)
#   https://DOMAIN/v1, /files, /health   API
