#!/usr/bin/env bash
# install-nvim.sh — Zero-network Neovim plugin bootstrapper
# ------------------------------------------------------------------
# Run ONCE (with network) to populate ~/.local/share/nvim/lazy/ with
# all required plugins.  After this script finishes Neovim runs
# completely offline — no git fetches, no package downloads.
#
# Usage:
#   chmod +x install-nvim.sh
#   ./install-nvim.sh              # full install (config + plugins)
#   ./install-nvim.sh --plugins    # plugins only (skip config copy)
#   ./install-nvim.sh --help       # show this help
#
# Requirements:
#   - git, tar, curl (or wget)
#   - Network access to GitHub / Codeberg
# ------------------------------------------------------------------

set -euo pipefail

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
  ["leap.nvim"]="https://github.com/ggandor/leap.nvim.git"
)

# ── banner ────────────────────────────────────────────────────────
banner() {
  cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║           Neovim Zero-Network Plugin Installer           ║
║                                                        ║
║  Clones all required plugins, strips .git directories,  ║
║  and sets up a fully offline Neovim environment.        ║
║  Run this script once, then go offline forever.         ║
╚══════════════════════════════════════════════════════════╝
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

  # --- config ---
  if [[ "${1:-}" != "--plugins-only" ]]; then
    echo ""
    echo "── Config is at $NVIM_CONFIG ───────────────────────"
    echo "   (managed separately — copy your init.lua + lua/ tree)"
  fi

  echo ""
  echo "Done. Neovim is ready for zero-network use."
  echo "Plugins are at: $LAZY_DIR"
}

main "$@"
