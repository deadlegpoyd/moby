# syntax=docker/dockerfile:1

# Moby build Dockerfile
# This file is used to build the Moby daemon and related binaries.

ARG GO_VERSION=1.21
ARG DEBIAN_VERSION=bookworm

# Base image for building
FROM golang:${GO_VERSION}-${DEBIAN_VERSION} AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    btrfs-progs \
    build-essential \
    cmake \
    curl \
    git \
    libapparmor-dev \
    libdevmapper-dev \
    libseccomp-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /go/src/github.com/docker/docker

# Download dependencies
FROM base AS vendor
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/root/.cache/go \
    go mod download

# Build the Docker daemon (dockerd)
FROM vendor AS builder
COPY . .
RUN --mount=type=cache,target=/root/.cache/go \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=1 \
    go build \
        -o /usr/local/bin/dockerd \
        -tags 'apparmor seccomp' \
        ./cmd/dockerd

# Build the Docker CLI client
RUN --mount=type=cache,target=/root/.cache/go \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 \
    go build \
        -o /usr/local/bin/docker \
        ./cmd/docker

# Final runtime image
FROM debian:${DEBIAN_VERSION}-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    e2fsprogs \
    iproute2 \
    iptables \
    libapparmor1 \
    libdevmapper1.02.1 \
    libseccomp2 \
    pigz \
    xfsprogs \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/dockerd /usr/local/bin/dockerd
COPY --from=builder /usr/local/bin/docker  /usr/local/bin/docker

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd"]
