#!/usr/bin/env bash
# scripts/bootstrap_tools.sh
#
# Install Mise, then install Bazel, Bun, and Node.js via Mise.
# Allows overriding versions with environment variables.

set -euo pipefail

# Pin versions; can be overridden via environment variables.
BAZEL_VERSION="${BAZEL_VERSION:-8.3.1}"
BUN_VERSION="${BUN_VERSION:-latest}"
NODE_VERSION="${NODE_VERSION:-lts}"

MiseInstaller() {
  echo "Installing mise tool manager..."
  curl -fsSL https://mise.jdx.dev/install.sh | sh
}

# Ensure ~/.local/bin is on PATH for mise CLI.
export PATH="$HOME/.local/bin:$PATH"

if ! command -v mise >/dev/null 2>&1; then
  MiseInstaller
  if ! command -v mise >/dev/null 2>&1; then
    echo "mise installation failed; ensure ~/.local/bin is on PATH." >&2
    exit 1
  fi
else
  echo "mise already installed; skipping installer."
fi

# Install requested tools.
TOOLS=(
  "bazel@${BAZEL_VERSION}"
  "node@${NODE_VERSION}"
  "bun@${BUN_VERSION}"
)

echo "Installing tools: ${TOOLS[*]}"
mise install "${TOOLS[@]}"

# Set global defaults so the tools are ready in new shells.
for tool in "${TOOLS[@]}"; do
  mise use -g "$tool"
done

echo "Bootstrap complete."
