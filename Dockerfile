# ---- build ----
FROM golang:1.25-bookworm AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
ARG COMMIT=unknown
RUN make build VERSION=$VERSION COMMIT=$COMMIT BUILDDIR=/out

# ---- runtime ----
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /out/potatod /usr/local/bin/potatod
# P2P, CometBFT RPC, REST, gRPC, JSON-RPC, JSON-RPC WS
EXPOSE 26656 26657 1317 9090 8545 8546
ENTRYPOINT ["potatod"]
CMD ["start", "--home", "/root/.potatod"]
