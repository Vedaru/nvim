#!/usr/bin/env bash
# install-nvim.sh — Neovim config installer
# ------------------------------------------------------------------
# Clones plugins and copies config to the right places.
#
# Usage:
#   ./install-nvim.sh        # install everything
#   ./install-nvim.sh --help # show this help
#
# Requirements:
#   - git, curl, tar
#   - Network access to GitHub / Codeberg
#   - tree-sitter CLI (for parser compilation; npm i -g tree-sitter-cli)
# ------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NVIM_CONFIG="${NVIM_CONFIG:-$HOME/.config/nvim}"
NVIM_DATA="${NVIM_DATA:-$HOME/.local/share/nvim}"
LAZY_DIR="$NVIM_DATA/lazy"

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
║              Neovim Config Installer                      ║
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

patch_snacks() {
  local sc="$LAZY_DIR/snacks.nvim/lua/snacks/statuscolumn.lua"
  if [[ -f "$sc" ]] && grep -q '%T"' "$sc"; then
    sed -i 's/%T"/%X"/' "$sc"
    echo "  [patch] snacks statuscolumn %T → %X"
  fi
}

# ── main ──────────────────────────────────────────────────────────
main() {
  local mode="${1:-}"

  case "$mode" in
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# //'
      exit 0
      ;;
  esac

  banner

  install_config

  echo ""
  echo "── Plugins ──────────────────────────────────────────"
  mkdir -p "$LAZY_DIR"
  for name in "${!PLUGINS[@]}"; do
    clone_one "$name" "${PLUGINS[$name]}"
  done

  patch_snacks

  echo ""
  echo "── Treesitter parsers ───────────────────────────────"
  echo "   Launch nvim once (online) and it will auto-install"
  echo "   all parsers from the ensure_installed list."

  echo ""
  echo "Done."
  echo "Config:  $NVIM_CONFIG"
  echo "Plugins: $LAZY_DIR"
}

main "$@"
