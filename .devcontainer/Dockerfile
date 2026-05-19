# Chroma development container.
# Matches the toolchain pinned in /rust/Dockerfile so local builds reproduce CI.
FROM mcr.microsoft.com/devcontainers/rust:1-bookworm

# Pin Rust to match Chroma's rust/Dockerfile (FROM rust:1.92.0).
# devcontainers/rust ships a recent stable; install 1.92.0 alongside and default it.
RUN rustup toolchain install 1.92.0 \
    && rustup default 1.92.0 \
    && rustup component add clippy rustfmt rust-analyzer rust-src \
    && rustup target add wasm32-unknown-unknown

# System build deps the audit identified as missing on the host.
# unzip is needed to extract the protoc release tarball below.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        protobuf-compiler \
        cmake \
        pkg-config \
        libssl-dev \
        build-essential \
        unzip \
        jq \
        postgresql-client \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Bookworm's apt protoc (~3.21) is too old; Chroma's rust/Dockerfile pins 31.1.
ENV PROTOC_VERSION=31.1
RUN curl -fsSL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip" \
        -o /tmp/protoc.zip \
    && unzip -oq /tmp/protoc.zip -d /usr/local 'bin/protoc' 'include/*' \
    && rm /tmp/protoc.zip \
    && chmod +x /usr/local/bin/protoc \
    && protoc --version

# kubectl
ENV KUBECTL_VERSION=v1.31.3
RUN curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client --output=yaml | head -3

# helm
ENV HELM_VERSION=v3.16.2
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
        | tar -xz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && rm -rf /tmp/linux-amd64 \
    && helm version --short

# tilt
ENV TILT_VERSION=0.33.21
RUN curl -fsSL "https://github.com/tilt-dev/tilt/releases/download/v${TILT_VERSION}/tilt.${TILT_VERSION}.linux.x86_64.tar.gz" \
        | tar -xz -C /usr/local/bin tilt \
    && tilt version

# kind (Kubernetes-in-Docker) for the local production-grade cluster
ENV KIND_VERSION=v0.27.0
RUN curl -fsSLo /usr/local/bin/kind \
        "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" \
    && chmod +x /usr/local/bin/kind \
    && kind --version

# cargo-nextest as a prebuilt to avoid a several-minute compile inside the container
RUN curl -fsSL https://get.nexte.st/latest/linux \
        | tar -xz -C /usr/local/bin cargo-nextest \
    && cargo nextest --version

# uv for the Python client smoke test (Phase 7).
# Installer drops the binary in $HOME/.local/bin; relocate so it's PATH-wide.
RUN curl -fsSL https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && mv /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv --version

# Drop privileges. The base image creates user `vscode` (uid 1000).
USER vscode
