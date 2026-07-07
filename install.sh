#!/usr/bin/env bash
# install.sh — One-command Neovim config installer (zero network).
#
# USAGE:
#   ./install.sh                     # install from extracted package
#   ./install.sh ~/backup            # install from backup directory
#   ./install.sh nvim-portable.tar.gz # install from tarball
#
# REQUIRES: Neovim >= 0.11, bash, tar

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
LAZY_DIR="$DATA_DIR/lazy"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

say()  { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}WARN:${NC} $*"; }
die()  { echo -e "${RED}ERROR:${NC} $*"; exit 1; }

# ─── Resolve source ────────────────────────────────────────────────
SOURCE="${1:-}"
TMPDIR=""

if [ -z "$SOURCE" ]; then
  # Running from inside the extracted package?
  if [ -f "$SCRIPT_DIR/init.lua" ] && [ -d "$SCRIPT_DIR/lua" ]; then
    SOURCE="$SCRIPT_DIR"
    say "Installing from current directory (self-contained mode)"
  else
    die "No source specified. Usage: ./install.sh [backup-dir|tarball.tar.gz]"
  fi
elif [ -f "$SOURCE" ] && [[ "$SOURCE" == *.tar.gz ]]; then
  say "Extracting tarball: $SOURCE"
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT
  tar xzf "$SOURCE" -C "$TMPDIR"
  SOURCE="$TMPDIR/nvim-config"
  if [ ! -d "$SOURCE" ]; then
    die "Tarball doesn't contain nvim-config/ directory"
  fi
elif [ -d "$SOURCE" ]; then
  say "Using source: $SOURCE"
else
  die "Source not found: $SOURCE"
fi

# ─── Check Neovim ──────────────────────────────────────────────────
if ! command -v nvim &>/dev/null; then
  warn "nvim not on PATH. Install Neovim >= 0.11 first."
fi
NVIM_VER=$(nvim --version 2>/dev/null | head -1 || echo "not found")
say "Neovim: $NVIM_VER"

# ─── Deploy config ─────────────────────────────────────────────────
say "Deploying config to $CONFIG_DIR"

# Back up existing
if [ -d "$CONFIG_DIR" ] && [ "$CONFIG_DIR" != "$SOURCE" ]; then
  BACKUP="${CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
  say "Backing up existing config → $BACKUP"
  mv "$CONFIG_DIR" "$BACKUP"
fi

if [ "$CONFIG_DIR" != "$SOURCE" ]; then
  mkdir -p "$(dirname "$CONFIG_DIR")"
  if [ -f "$SOURCE/init.lua" ]; then
    # Source is a config directory directly
    cp -r "$SOURCE" "$CONFIG_DIR"
  elif [ -d "$SOURCE/nvim-config" ]; then
    cp -r "$SOURCE/nvim-config" "$CONFIG_DIR"
  fi
  say "Config installed."
else
  say "Config already at destination."
fi

# ─── Deploy plugins ────────────────────────────────────────────────
PLUGIN_SRC=""
for candidate in "$SOURCE/../nvim-data/lazy" "$TMPDIR/nvim-data/lazy" "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"; do
  if [ -d "$candidate" ] && [ -d "$candidate/lazy.nvim" ]; then
    PLUGIN_SRC="$candidate"
    break
  fi
done

if [ -n "$PLUGIN_SRC" ]; then
  say "Deploying plugins from $PLUGIN_SRC → $LAZY_DIR"

  if [ -d "$LAZY_DIR" ] && [ "$LAZY_DIR" != "$PLUGIN_SRC" ]; then
    BACKUP="${LAZY_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
    say "Backing up existing plugins → $BACKUP"
    mv "$LAZY_DIR" "$BACKUP"
  fi

  mkdir -p "$(dirname "$LAZY_DIR")"
  cp -r "$PLUGIN_SRC" "$LAZY_DIR"
  say "Plugins deployed ($(ls "$LAZY_DIR" | wc -l) plugins)."
else
  warn "No plugin directory found — skipping."
  warn "Run nvim once with network to bootstrap, or provide plugin source."
fi

# ─── Verify ────────────────────────────────────────────────────────
echo ""
say "Verifying..."
CORE_PLUGINS=(lazy.nvim snacks.nvim tokyonight.nvim nvim-lspconfig nvim-treesitter)
MISSING=()
for p in "${CORE_PLUGINS[@]}"; do
  [ -d "$LAZY_DIR/$p" ] || MISSING+=("$p")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  warn "Missing plugins: ${MISSING[*]}"
else
  say "All core plugins present."
fi

[ -f "$CONFIG_DIR/lazy-lock.json" ] && say "Lockfile found (pinned versions)."

echo ""
echo -e "${GREEN}===== INSTALL COMPLETE =====${NC}"
echo "  Run 'nvim' to start."
echo "  First launch: bytecode compilation (~2-5 seconds)."
echo "  Subsequent launches: instant."
