FROM docker.io/library/rust:1-bookworm as builder
ARG CARGO_LOG
RUN apt-get update && apt-get install -y cmake protobuf-compiler && rm -rf /var/lib/apt/lists/*
RUN USER=root cargo install cargo-auditable
RUN USER=root cargo new --bin nostr-rs-relay
WORKDIR ./nostr-rs-relay
COPY ./Cargo.toml ./Cargo.toml
COPY ./Cargo.lock ./Cargo.lock
RUN cargo auditable build --release --locked
RUN rm src/*.rs
COPY ./src ./src
COPY ./proto ./proto
COPY ./build.rs ./build.rs
RUN rm ./target/release/deps/nostr*relay*
RUN cargo auditable build --release --locked

FROM docker.io/library/debian:bookworm-slim
ARG APP=/usr/src/app
ARG APP_DATA=/usr/src/app/db
RUN apt-get update && apt-get install -y ca-certificates tzdata sqlite3 libc6 && rm -rf /var/lib/apt/lists/*
EXPOSE 8080
ENV TZ=Etc/UTC
RUN mkdir -p ${APP} && mkdir -p ${APP_DATA}
COPY --from=builder /nostr-rs-relay/target/release/nostr-rs-relay ${APP}/nostr-rs-relay
COPY config.toml /config.toml
WORKDIR ${APP}
ENV RUST_LOG=info,nostr_rs_relay=info
ENV APP_DATA=${APP_DATA}
CMD ./nostr-rs-relay --db ${APP_DATA} --config /config.toml
