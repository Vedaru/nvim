#!/usr/bin/env bash
# build.sh — Create a self-contained, zero-network Neovim config package.
# Output: nvim-portable.tar.gz — unpack and run ./install.sh on any Linux/WSL machine.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-$SCRIPT_DIR/nvim-portable.tar.gz}"
BUILD_DIR="$(mktemp -d)"
trap "rm -rf $BUILD_DIR" EXIT

echo "==> Building nvim-portable package..."

# 1. Copy config files (exclude .git, lazy-lock.json if not needed)
echo "  Copying config..."
mkdir -p "$BUILD_DIR/nvim-config"
cp "$SCRIPT_DIR/init.lua" "$BUILD_DIR/nvim-config/"
cp "$SCRIPT_DIR/lazy-lock.json" "$BUILD_DIR/nvim-config/"
cp "$SCRIPT_DIR/install.sh" "$BUILD_DIR/nvim-config/"
cp -r "$SCRIPT_DIR/lua" "$BUILD_DIR/nvim-config/"

# 2. Copy all 20 plugins (strip .git to save space)
echo "  Copying plugins (stripping .git)..."
mkdir -p "$BUILD_DIR/nvim-data/lazy"
LAZY_SRC="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
if [ ! -d "$LAZY_SRC" ]; then
  echo "ERROR: Plugins not found at $LAZY_SRC. Run nvim once first."
  exit 1
fi

for plugin in "$LAZY_SRC"/*/; do
  name=$(basename "$plugin")
  if [[ "$name" == *.cloning ]]; then continue; fi
  echo "    $name"
  rsync -a --exclude='.git' --exclude='.github' "$plugin" "$BUILD_DIR/nvim-data/lazy/$name/"
done

# 3. Package
echo "==> Compressing..."
tar czf "$OUTPUT" -C "$BUILD_DIR" nvim-config nvim-data

SIZE=$(du -h "$OUTPUT" | cut -f1)
echo ""
echo "===== DONE ====="
echo "  Package: $OUTPUT"
echo "  Size:    $SIZE"
echo ""
echo "To install on another machine:"
echo "  tar xzf nvim-portable.tar.gz -C ~/"
echo "  mv ~/nvim-config ~/.config/nvim"
echo "  mv ~/nvim-data ~/.local/share/nvim"
echo "  nvim"
