#!/usr/bin/env bash
# install.sh — Deploy Vedaru's Neovim config with ZERO network access
# Usage: ./install.sh [BACKUP_SOURCE]
#
# BACKUP_SOURCE can be:
#   - A directory containing lazy/ subdirectory (e.g., ~/nvim-backup)
#   - A tarball (.tar.gz) of the backup
#   - Omitted: looks for ~/nvim-backup, ../nvim-backup, or the included ./lazy-backup/
#
# The backup must contain:
#   lazy/                — all plugin directories (20 plugins + lazy.nvim)
#   lazy/lazy-lock.json  — (optional) pinned versions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SRC="$SCRIPT_DIR"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
LAZY_DIR="$DATA_DIR/lazy"

# ——— Resolve backup source ———
BACKUP_SRC="${1:-}"
if [ -z "$BACKUP_SRC" ]; then
  for candidate in "$HOME/nvim-backup" "$SCRIPT_DIR/../nvim-backup" "$SCRIPT_DIR/lazy-backup"; do
    if [ -d "$candidate/lazy" ]; then
      BACKUP_SRC="$candidate"
      break
    fi
  done
fi

if [ -z "$BACKUP_SRC" ]; then
  echo "ERROR: No backup source found."
  echo "  Provide one: ./install.sh ~/nvim-backup"
  echo "  Or place a 'lazy-backup/' next to this script."
  exit 1
fi

# Handle tarball
if [ -f "$BACKUP_SRC" ] && [[ "$BACKUP_SRC" == *.tar.gz ]]; then
  echo "==> Extracting backup tarball: $BACKUP_SRC"
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT
  tar xzf "$BACKUP_SRC" -C "$TMPDIR"
  BACKUP_SRC="$TMPDIR"
fi

if [ ! -d "$BACKUP_SRC/lazy" ]; then
  echo "ERROR: Backup at '$BACKUP_SRC' has no 'lazy/' subdirectory."
  echo "  Expected layout:"
  echo "    backup/"
  echo "      lazy/"
  echo "        lazy.nvim/"
  echo "        snacks.nvim/"
  echo "        ..."
  exit 1
fi

# ——— Check Neovim ———
if ! command -v nvim &>/dev/null; then
  echo "WARNING: nvim not found on PATH. Install Neovim >= 0.11 separately."
fi
NVIM_VERSION=$(nvim --version 2>/dev/null | head -1 || echo "unknown")
echo "==> Neovim: $NVIM_VERSION"

# ——— Deploy config ———
echo "==> Deploying config to $CONFIG_DIR"

if [ -d "$CONFIG_DIR" ] && [ "$CONFIG_DIR" != "$CONFIG_SRC" ]; then
  BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_PATH="${CONFIG_DIR}.bak.${BACKUP_TIMESTAMP}"
  echo "  Existing config found, backing up to $BACKUP_PATH"
  mv "$CONFIG_DIR" "$BACKUP_PATH"
fi

if [ "$CONFIG_DIR" != "$CONFIG_SRC" ]; then
  mkdir -p "$(dirname "$CONFIG_DIR")"
  # Copy, don't symlink — makes the config portable
  cp -r "$CONFIG_SRC" "$CONFIG_DIR"
  echo "  Config copied to $CONFIG_DIR"
else
  echo "  Config already at $CONFIG_DIR (running from installed location)"
fi

# ——— Deploy plugins from backup ———
echo "==> Deploying plugins from $BACKUP_SRC/lazy/ to $LAZY_DIR"

if [ -d "$LAZY_DIR" ]; then
  BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_PATH="${LAZY_DIR}.bak.${BACKUP_TIMESTAMP}"
  echo "  Existing plugins found, backing up to $BACKUP_PATH"
  mv "$LAZY_DIR" "$BACKUP_PATH"
fi

mkdir -p "$(dirname "$LAZY_DIR")"
cp -r "$BACKUP_SRC/lazy" "$LAZY_DIR"
echo "  Plugins deployed."

# ——— Verify ———
echo ""
echo "==> Verifying..."
REQUIRED_PLUGINS=(lazy.nvim snacks.nvim tokyonight.nvim nvim-lspconfig nvim-treesitter)
MISSING=()
for plugin in "${REQUIRED_PLUGINS[@]}"; do
  if [ ! -d "$LAZY_DIR/$plugin" ]; then
    MISSING+=("$plugin")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "  WARNING: Missing plugins: ${MISSING[*]}"
  echo "  Some functionality may not work."
else
  echo "  All core plugins present."
fi

if [ -f "$CONFIG_DIR/lazy-lock.json" ]; then
  echo "  Lockfile found (version pinning active)."
fi

echo ""
echo "===== INSTALL COMPLETE ====="
echo "  Run 'nvim' to start."
echo "  First start may take a few seconds (bytecode compilation)."
echo "  Subsequent starts will be fast."
echo ""
echo "To create a portable backup of this install:"
echo "  tar czf nvim-backup.tar.gz -C ~/.local/share/nvim lazy/"
echo "  # include this config too:"
echo "  tar czf nvim-full-backup.tar.gz -C ~/.config nvim/ -C ~/.local/share/nvim lazy/"
