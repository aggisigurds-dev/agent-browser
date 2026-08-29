#!/usr/bin/env bash
# Idempotent bootstrap for the agent-browser Cloud Agent environment.
#
# The default Cloud Agent base image already ships nvm, rustup, corepack, git,
# and system Chrome (/usr/local/bin/google-chrome). This script pins the
# toolchains the project requires and warms the build caches so a booted agent
# is immediately productive.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- Node 24 (package.json engines: node >=24) via nvm, with pnpm 11 through corepack ---
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
nvm install 24
nvm alias default 24
nvm use 24
corepack enable
corepack prepare pnpm@11.1.3 --activate

# --- Rust: base image ships 1.83, but some transitive crates need edition 2024 (>= 1.85) ---
rustup default stable

# --- JS workspace dependencies (root, packages/dashboard, packages/@agent-browser/*, docs) ---
pnpm install --frozen-lockfile

# --- Compile the Rust CLI so the target cache is warm in the snapshot ---
cargo build --manifest-path cli/Cargo.toml

echo "agent-browser environment bootstrap complete:"
echo "  node    $(node --version)"
echo "  pnpm    $(pnpm --version)"
echo "  rustc   $(rustc --version)"
echo "  chrome  $(command -v google-chrome || echo 'not found')"
