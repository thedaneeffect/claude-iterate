#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — Install claude-iterate into the current project
# Usage: curl -sL https://raw.githubusercontent.com/thedaneeffect/claude-iterate/main/bootstrap.sh | bash

REPO="https://github.com/thedaneeffect/claude-iterate.git"
TMP_DIR="/tmp/claude-iterate"

# --- Clone ---

rm -rf "$TMP_DIR"
git clone --quiet "$REPO" "$TMP_DIR"

# --- Copy files ---

cp "$TMP_DIR/iterate.sh" ./iterate.sh
cp "$TMP_DIR/SPEC.md" ./SPEC.md
chmod +x ./iterate.sh

# --- Create specs directory ---

mkdir -p specs

# --- Update .gitignore (idempotent) ---

touch .gitignore

if ! grep -qxF 'logs/' .gitignore; then
    echo 'logs/' >> .gitignore
fi

if ! grep -qxF 'specs/.sessions/' .gitignore; then
    echo 'specs/.sessions/' >> .gitignore
fi

# --- Cleanup ---

rm -rf "$TMP_DIR"

# --- Summary ---

echo "claude-iterate bootstrapped into $(pwd)"
echo ""
echo "  iterate.sh    — Autonomous spec executor"
echo "  SPEC.md       — Spec format reference"
echo "  specs/        — Put your spec files here"
echo ""
echo "Usage:"
echo "  1. Create a spec:  specs/my_feature.md"
echo "  2. Run it:         ./iterate.sh my_feature"
