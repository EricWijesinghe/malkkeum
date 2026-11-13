# Multi-stage: build the API once, ship a small runtime image.
# Base images are pinned by digest (Dependabot bumps them); the Rust version matches backend/rust-toolchain.toml.
FROM rust:1.99.1-trixie@sha256:8a4e90c7946b74626488b1446f712c0fe0ed1a596cbd3d871684bc9c5433ae07 AS build
WORKDIR /src
COPY . .
ARG APP_VERSION=dev
# Optional: --build-arg CARGO_BUILD_JOBS=2 caps compile memory on small machines (unset = all cores).
ARG CARGO_BUILD_JOBS
RUN cargo build --release --locked -p api

FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --no-create-home --shell /usr/sbin/nologin --uid 10001 app \
 && mkdir -p /data/uploads && chown app /data/uploads
COPY --from=build /src/target/release/api /usr/local/bin/api
ARG APP_VERSION=dev
LABEL org.opencontainers.image.source=https://github.com/EricWijesinghe/malkkeum-install org.opencontainers.image.version=$APP_VERSION
USER app
ENV BIND_ADDR=0.0.0.0:8080 UPLOAD_DIR=/data/uploads
EXPOSE 8080
# Same probe as deploy/docker-compose.yml (API up and its database reachable).
HEALTHCHECK --interval=15s --retries=10 --start-period=20s CMD ["api", "--ready"]
CMD ["api"]
