# Multi-stage: build the API once, ship a small runtime image.
FROM rust:1-bookworm AS build
WORKDIR /src
COPY . .
ARG APP_VERSION=dev
# Optional: --build-arg CARGO_BUILD_JOBS=2 caps compile memory on small machines (unset = all cores).
ARG CARGO_BUILD_JOBS
RUN cargo build --release -p api

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 10001 app && mkdir -p /data/uploads && chown app /data/uploads
COPY --from=build /src/target/release/api /usr/local/bin/api
ARG APP_VERSION=dev
LABEL org.opencontainers.image.source=https://github.com/EricWijesinghe/malkkeum-install org.opencontainers.image.version=$APP_VERSION
USER app
ENV BIND_ADDR=0.0.0.0:8080 UPLOAD_DIR=/data/uploads
EXPOSE 8080
CMD ["api"]
