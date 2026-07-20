#!/usr/bin/env bash
# install-nvim.sh — Hybrid Neovim bootstrapper (online → offline)
# ------------------------------------------------------------------
# Two modes:
#   ONLINE  (default):  clone plugins from GitHub/Codeberg, compile
#                        treesitter parsers, then optionally bundle
#                        everything into vendor/ for offline reuse.
#   OFFLINE (--offline): restore plugins + parsers + config from a
#                        pre-built vendor/ directory — zero network.
#
# Typical workflow:
#   1. Run once online:        ./install-nvim.sh
#   2. (optional) Bundle:      ./install-nvim.sh --bundle
#   3. Distribute the repo + vendor/ to air-gapped machines.
#   4. On the air-gapped box:  ./install-nvim.sh --offline
#
# Usage:
#   ./install-nvim.sh              # online full install
#   ./install-nvim.sh --offline    # offline restore from vendor/
#   ./install-nvim.sh --bundle     # bundle plugins+parsers into vendor/
#   ./install-nvim.sh --help       # show this help
#
# Requirements (online mode only):
#   - git, curl, tar
#   - Network access to GitHub / Codeberg
#   - tree-sitter CLI (for parser compilation; npm i -g tree-sitter-cli)
# ------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NVIM_CONFIG="${NVIM_CONFIG:-$HOME/.config/nvim}"
NVIM_DATA="${NVIM_DATA:-$HOME/.local/share/nvim}"
LAZY_DIR="$NVIM_DATA/lazy"
PARSER_DIR="$NVIM_DATA/site/parser"
VENDOR_DIR="$SCRIPT_DIR/vendor"

# ── plugin list (name → URL) ──────────────────────────────────────
declare -A PLUGINS=(
  ["lazy.nvim"]="https://github.com/folke/lazy.nvim.git"
  ["LazyVim"]="https://github.com/LazyVim/LazyVim.git"
  ["tokyonight.nvim"]="https://github.com/folke/tokyonight.nvim.git"
  ["snacks.nvim"]="https://github.com/folke/snacks.nvim.git"
  ["oil.nvim"]="https://github.com/stevearc/oil.nvim.git"
  ["nvim-web-devicons"]="https://github.com/nvim-tree/nvim-web-devicons.git"
  ["nvim-treesitter"]="https://github.com/nvim-treesitter/nvim-treesitter.git"
  ["nvim-cmp"]="https://github.com/hrsh7th/nvim-cmp.git"
  ["cmp-buffer"]="https://github.com/hrsh7th/cmp-buffer.git"
  ["cmp-path"]="https://github.com/hrsh7th/cmp-path.git"
  ["git-conflict.nvim"]="https://github.com/akinsho/git-conflict.nvim.git"
  ["gitsigns.nvim"]="https://github.com/lewis6991/gitsigns.nvim.git"
  ["grug-far.nvim"]="https://github.com/MagicDuck/grug-far.nvim.git"
  ["persistence.nvim"]="https://github.com/folke/persistence.nvim.git"
  ["mini.icons"]="https://github.com/echasnovski/mini.icons.git"
  ["mini.statusline"]="https://github.com/echasnovski/mini.statusline.git"
  ["leap.nvim"]="https://codeberg.org/andyg/leap.nvim"
)

# ── config files to install ───────────────────────────────────────
CONFIG_FILES=("init.lua" "lazy-lock.json" "lazyvim.json" "lua")

# ── banner ────────────────────────────────────────────────────────
banner() {
  cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║         Neovim Hybrid Installer (online → offline)       ║
╚══════════════════════════════════════════════════════════╝
EOF
}

# ── helpers ───────────────────────────────────────────────────────
clone_one() {
  local name="$1" url="$2" dest="$LAZY_DIR/$name"
  if [[ -d "$dest" ]]; then echo "  [skip] $name"; return 0; fi
  echo "  [clone] $name ← $url"
  GIT_TERMINAL_PROMPT=0 git clone --depth 1 --filter=blob:none "$url" "$dest" 2>&1 | sed 's/^/    /'
  rm -rf "$dest/.git"
}

install_config() {
  echo ""
  echo "── Config ───────────────────────────────────────────"
  mkdir -p "$NVIM_CONFIG"
  for item in "${CONFIG_FILES[@]}"; do
    local src="$SCRIPT_DIR/$item" dst="$NVIM_CONFIG/$item"
    if [[ ! -e "$src" ]]; then echo "  [warn] $item missing"; continue; fi
    if [[ -d "$src" ]]; then mkdir -p "$dst"; cp -r "$src"/* "$dst"/
    else cp "$src" "$dst"; fi
    echo "  [copy] $item"
  done
}

install_config_offline() {
  echo ""
  echo "── Config (offline) ─────────────────────────────────"
  mkdir -p "$NVIM_CONFIG"
  local cfg_src="$VENDOR_DIR/config"
  if [[ ! -d "$cfg_src" ]]; then
    echo "  [FAIL] vendor/config/ not found — no config to restore"
    exit 1
  fi
  cp -r "$cfg_src"/* "$NVIM_CONFIG"/
  echo "  [restore] $cfg_src → $NVIM_CONFIG"
}

install_plugins_offline() {
  echo ""
  echo "── Plugins (offline) ────────────────────────────────"
  local src="$VENDOR_DIR/plugins"
  if [[ ! -d "$src" ]]; then
    echo "  [FAIL] vendor/plugins/ not found — run --bundle first"
    exit 1
  fi
  mkdir -p "$LAZY_DIR"
  for d in "$src"/*/; do
    local name="$(basename "$d")"
    local dst="$LAZY_DIR/$name"
    if [[ -d "$dst" ]]; then echo "  [skip] $name"; continue; fi
    cp -r "$d" "$dst"
    echo "  [restore] $name"
  done
}

install_parsers_offline() {
  echo ""
  echo "── Parsers (offline) ────────────────────────────────"
  local src="$VENDOR_DIR/parsers"
  if [[ ! -d "$src" ]]; then
    echo "  [warn] vendor/parsers/ not found — no parsers to restore"
    echo "         treesitter will still work, just without offline parsers"
    return 0
  fi
  mkdir -p "$PARSER_DIR"
  local count=0
  for so in "$src"/*.so; do
    [[ -f "$so" ]] || continue
    local name="$(basename "$so")"
    cp "$so" "$PARSER_DIR/$name"
    count=$((count + 1))
  done
  echo "  [restore] $count parser(s)"
}

bundle_plugins() {
  echo ""
  echo "── Bundling plugins → vendor/ ───────────────────────"
  local dest="$VENDOR_DIR/plugins"
  rm -rf "$dest"
  mkdir -p "$dest"
  for d in "$LAZY_DIR"/*/; do
    local name="$(basename "$d")"
    cp -r "$d" "$dest/$name"
    rm -rf "$dest/$name/.git"
    echo "  [bundle] $name"
  done
}

bundle_parsers() {
  echo ""
  echo "── Bundling parsers → vendor/ ───────────────────────"
  local dest="$VENDOR_DIR/parsers"
  rm -rf "$dest"
  if [[ -d "$PARSER_DIR" ]]; then
    mkdir -p "$dest"
    cp "$PARSER_DIR"/*.so "$dest"/ 2>/dev/null || true
    echo "  [bundle] $(ls "$dest"/*.so 2>/dev/null | wc -l) parser(s)"
  else
    echo "  [warn] no parsers to bundle"
  fi
}

bundle_config() {
  echo ""
  echo "── Bundling config → vendor/ ────────────────────────"
  local dest="$VENDOR_DIR/config"
  rm -rf "$dest"
  mkdir -p "$dest"
  for item in "${CONFIG_FILES[@]}"; do
    local src="$SCRIPT_DIR/$item"
    if [[ -d "$src" ]]; then cp -r "$src" "$dest/$item"
    elif [[ -f "$src" ]]; then cp "$src" "$dest/$item"; fi
    echo "  [bundle] $item"
  done
}

# ── main ──────────────────────────────────────────────────────────
main() {
  local mode="${1:-}"

  case "$mode" in
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# //'
      exit 0
      ;;
    --bundle)
      bundle_plugins
      bundle_parsers
      bundle_config
      echo ""
      echo "Done. vendor/ is ready for offline distribution."
      echo "On the target machine: ./install-nvim.sh --offline"
      exit 0
      ;;
    --offline)
      banner
      install_config_offline
      install_plugins_offline
      install_parsers_offline
      echo ""
      echo "Done. Neovim is ready for zero-network use."
      exit 0
      ;;
  esac

  # ── online mode ────────────────────────────────────────────────
  banner

  # config
  if [[ "$mode" != "--plugins-only" ]]; then
    install_config
  fi

  # plugins
  if [[ "$mode" != "--config-only" ]]; then
    echo ""
    echo "── Plugins (online) ─────────────────────────────────"
    mkdir -p "$LAZY_DIR"
    for name in "${!PLUGINS[@]}"; do
      clone_one "$name" "${PLUGINS[$name]}"
    done
  fi

  # parsers — nvim-treesitter handles this via ensure_installed
  # on first nvim launch.  Just remind the user.
  echo ""
  echo "── Treesitter parsers ───────────────────────────────"
  echo "   Launch nvim once (online) and it will auto-install"
  echo "   all parsers from the ensure_installed list."
  echo ""
  echo "   Then run:  ./install-nvim.sh --bundle"
  echo "   to freeze everything into vendor/ for offline use."

  echo ""
  echo "Done."
  echo "Config:  $NVIM_CONFIG"
  echo "Plugins: $LAZY_DIR"
  echo "Parsers: $PARSER_DIR (after first nvim launch)"
}

main "$@"
