# Web image: Caddy serving the website (/), the console (/admin/) and proxying the API.
# Build context: repository root.
FROM ghcr.io/cirruslabs/flutter:stable AS console
WORKDIR /src/app
COPY app/ .
RUN python3 -I tool/gen_arb.py \
 && flutter pub get \
 && (cd packages/core && flutter gen-l10n) \
 && cd apps/console && flutter build web --release --base-href /admin/

FROM caddy:2
ARG APP_VERSION=dev
LABEL org.opencontainers.image.source=https://github.com/EricWijesinghe/malkkeum-install org.opencontainers.image.version=$APP_VERSION
COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY website/ /srv/website/
COPY --from=console /src/app/apps/console/build/web/ /srv/console/
