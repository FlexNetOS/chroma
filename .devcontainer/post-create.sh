#!/usr/bin/env bash
# Runs once after the devcontainer is created. Confirms every tool is present
# at the expected version and warms the cargo registry so the first build is
# faster.
set -euo pipefail

cd /workspaces/chroma

# Named-volume mounts come up root-owned on first attach; chown so the unprivileged
# vscode user can write to them. Idempotent — no-op once already owned by vscode.
# Targets: cargo registry/git caches and the build-output mount.
echo "=== fixing volume ownership ==="
for path in /usr/local/cargo/registry /usr/local/cargo/git /workspaces/chroma/target; do
    if [ -d "$path" ] && [ "$(stat -c %U "$path" 2>/dev/null)" != "vscode" ]; then
        sudo chown -R vscode:vscode "$path"
        echo "chowned: $path"
    fi
done

echo
echo "=== devcontainer toolchain ==="
{
  rustc --version
  cargo --version
  rustup show active-toolchain
  protoc --version
  cmake --version | head -1
  pkg-config --version
  kubectl version --client --output=yaml | sed -n '1,5p'
  helm version --short
  tilt version | head -1
  kind --version
  cargo nextest --version
  uv --version
  python3 --version
  docker --version
} 2>&1

echo
echo "=== warming cargo registry (chroma workspace) ==="
# --locked refuses to update Cargo.lock; safer than a plain fetch.
cargo fetch --locked || {
    echo "cargo fetch failed; check network and Cargo.lock state"
    exit 1
}

echo
echo "Devcontainer ready. Next steps:"
echo "  cargo build --workspace --exclude chromadb_rust_bindings \\"
echo "    --exclude chromadb-js-bindings --exclude chroma-benchmark"
echo "  cargo nextest run --profile ci"
echo "  kind create cluster --name chroma-dev && tilt up"
