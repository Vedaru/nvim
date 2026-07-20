#!/usr/bin/env bash
# install-nvim.sh — Zero-network Neovim bootstrapper
# ------------------------------------------------------------------
# Clones all required plugins + copies config files from this repo
# to ~/.config/nvim.  Run ONCE with network.
#
# After this script finishes, launch nvim once (online) so
# treesitter can auto-install parsers (ensure_installed).
# Then you're fully offline.
#
# Usage:
#   ./install-nvim.sh              # full install (config + plugins)
#   ./install-nvim.sh --plugins    # plugins only (skip config copy)
#   ./install-nvim.sh --help       # show this help
#
# Requirements:
#   - git, curl (or wget)
#   - Network access to GitHub / Codeberg
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
  ["persistence.nvim"]="https://github.com/folke/persistence.nvim.git"
  ["mini.icons"]="https://github.com/echasnovski/mini.icons.git"
  ["mini.statusline"]="https://github.com/echasnovski/mini.statusline.git"
  ["leap.nvim"]="https://codeberg.org/andyg/leap.nvim"
)

# ── files to copy from repo → ~/.config/nvim ─────────────────────
CONFIG_FILES=(
  "init.lua"
  "lazy-lock.json"
  "lazyvim.json"
  "lua"
)

# ── banner ────────────────────────────────────────────────────────
banner() {
  cat <<'EOF'
╔══════════════════════════════════════════════════════╗
║           Neovim Zero-Network Plugin Installer       ║
║                                                      ║
║  Clones all required plugins, copies config files,   ║
║  and sets up a fully offline Neovim environment.     ║
║  Run this script once, then go offline forever.      ║
╚══════════════════════════════════════════════════════╝
EOF
}

# ── helpers ───────────────────────────────────────────────────────
clone_one() {
  local name="$1"
  local url="$2"
  local dest="$LAZY_DIR/$name"

  if [[ -d "$dest" ]]; then
    echo "  [skip] $name (already exists)"
    return 0
  fi

  echo "  [clone] $name ← $url"
  GIT_TERMINAL_PROMPT=0 git clone --depth 1 --filter=blob:none "$url" "$dest" 2>&1 | sed 's/^/    /'
}

strip_git() {
  local dir="$1"
  if [[ -d "$dir/.git" ]]; then
    rm -rf "$dir/.git"
  fi
}

# ── main ──────────────────────────────────────────────────────────
main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    sed -n '2,/^$/p' "$0" | sed 's/^# //'
    exit 0
  fi

  banner

  # --- config ---
  if [[ "${1:-}" != "--plugins-only" ]]; then
    echo ""
    echo "── Installing config files ─────────────────────────"
    mkdir -p "$NVIM_CONFIG"

    for item in "${CONFIG_FILES[@]}"; do
      local src="$SCRIPT_DIR/$item"
      local dst="$NVIM_CONFIG/$item"

      if [[ ! -e "$src" ]]; then
        echo "  [warn] $item not found in repo — skipping"
        continue
      fi

      # If it's a directory, merge; if it's a file, copy
      if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        cp -r "$src"/* "$dst"/
      else
        cp "$src" "$dst"
      fi
      echo "  [copy] $item → $dst"
    done
  fi

  # --- plugins ---
  if [[ "${1:-}" != "--config-only" ]]; then
    echo ""
    echo "── Installing plugins ──────────────────────────────"
    mkdir -p "$LAZY_DIR"

    for name in "${!PLUGINS[@]}"; do
      clone_one "$name" "${PLUGINS[$name]}"
    done

    echo ""
    echo "── Stripping .git directories (zero-network) ───────"
    for d in "$LAZY_DIR"/*/; do
      strip_git "$d"
    done

    # Ensure leap.nvim has the lua/leap/init.lua entry point
    if [[ -d "$LAZY_DIR/leap.nvim" ]] && [[ ! -f "$LAZY_DIR/leap.nvim/lua/leap/init.lua" ]]; then
      echo "  [warn] leap.nvim cloned but missing lua/leap/init.lua —"
      echo "         the plugin may need a custom entry point."
      echo "         Copy your lua/leap/init.lua into $LAZY_DIR/leap.nvim/"
    fi
  fi

  # --- post-install ---
  echo ""
  echo "── Next steps ───────────────────────────────────────"
  echo ""
  echo "  1. Launch nvim once (online) so treesitter can"
  echo "     auto-install parsers (see ensure_installed in"
  echo "     lua/plugins/treesitter.lua)."
  echo "  2. Or run inside nvim: :TSInstall all"
  echo "  3. After that, Neovim is fully offline-capable."
  echo ""
  echo "Done."
  echo "Config:  $NVIM_CONFIG"
  echo "Plugins: $LAZY_DIR"
}

main "$@"
