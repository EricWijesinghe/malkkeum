# Multi-stage: build the API once, ship a small runtime image.
FROM rust:1-bookworm AS build
WORKDIR /src
COPY . .
RUN cargo build --release -p api

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 10001 app && mkdir -p /data/uploads && chown app /data/uploads
COPY --from=build /src/target/release/api /usr/local/bin/api
USER app
ENV BIND_ADDR=0.0.0.0:8080 UPLOAD_DIR=/data/uploads
EXPOSE 8080
CMD ["api"]
