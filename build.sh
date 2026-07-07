#!/usr/bin/env bash
# build.sh — Create a self-contained, zero-network Neovim config installer.
# Output: install-nvim — a single executable that installs everything.
# Run:   ./install-nvim
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-$SCRIPT_DIR/install-nvim}"
BUILD_DIR="$(mktemp -d)"
trap "rm -rf $BUILD_DIR" EXIT

echo "==> Building self-contained installer..."

# 1. Package config + plugins into tarball
echo "  Packaging config..."
mkdir -p "$BUILD_DIR/nvim-config"
cp "$SCRIPT_DIR/init.lua" "$BUILD_DIR/nvim-config/"
cp "$SCRIPT_DIR/lazy-lock.json" "$BUILD_DIR/nvim-config/"
cp -r "$SCRIPT_DIR/lua" "$BUILD_DIR/nvim-config/"

echo "  Packaging plugins..."
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

echo "  Compressing payload..."
PAYLOAD="$BUILD_DIR/payload.tar.gz"
tar czf "$PAYLOAD" -C "$BUILD_DIR" nvim-config nvim-data

# 2. Build self-extracting script
echo "  Building self-extracting executable..."
cat > "$OUTPUT" << 'SCRIPT_HEADER'
#!/usr/bin/env bash
# install-nvim — Self-contained Neovim config installer (zero network).
# One file. One command. Double-click or run from terminal.
#
# curl -O https://... && chmod +x install-nvim && ./install-nvim  # (when network)
# scp install-nvim user@host: && ssh user@host ./install-nvim     # (air-gapped)
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
LAZY_DIR="$DATA_DIR/lazy"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
say()  { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}WARN:${NC} $*"; }
die()  { echo -e "${RED}ERROR:${NC} $*"; exit 1; }

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Vedaru Neovim Config — Installer      ║${NC}"
echo -e "${GREEN}║   Zero network • 20 plugins • ~21 MB    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""

# Check Neovim
if ! command -v nvim &>/dev/null; then
  die "Neovim not found. Install nvim >= 0.11 first: sudo apt install neovim"
fi
NVIM_VER=$(nvim --version 2>/dev/null | head -1 || echo "?")
say "Neovim: $NVIM_VER"

# Extract embedded payload
say "Extracting payload ($(du -h "$0" | cut -f1))..."
ARCHIVE=$(awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' "$0")
tail -n +${ARCHIVE} "$0" | base64 -d | tar xz -C "$TMPDIR"
say "Payload extracted."

# Deploy config
say "Deploying config to $CONFIG_DIR"
if [ -d "$CONFIG_DIR" ]; then
  BACKUP="${CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
  say "Backing up existing → $BACKUP"
  mv "$CONFIG_DIR" "$BACKUP"
fi
mkdir -p "$(dirname "$CONFIG_DIR")"
cp -r "$TMPDIR/nvim-config" "$CONFIG_DIR"
say "Config installed."

# Deploy plugins
if [ -d "$TMPDIR/nvim-data/lazy" ]; then
  say "Deploying plugins to $LAZY_DIR"
  if [ -d "$LAZY_DIR" ]; then
    BACKUP="${LAZY_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$LAZY_DIR" "$BACKUP"
  fi
  mkdir -p "$(dirname "$LAZY_DIR")"
  cp -r "$TMPDIR/nvim-data/lazy" "$LAZY_DIR"
  PLUGIN_COUNT=$(ls "$LAZY_DIR" | wc -l)
  say "Plugins deployed ($PLUGIN_COUNT plugins)."
fi

# Verify
echo ""
CORE=(lazy.nvim snacks.nvim tokyonight.nvim nvim-lspconfig nvim-treesitter)
MISSING=()
for p in "${CORE[@]}"; do
  [ -d "$LAZY_DIR/$p" ] || MISSING+=("$p")
done
if [ ${#MISSING[@]} -gt 0 ]; then
  warn "Missing: ${MISSING[*]}"
else
  say "All core plugins verified."
fi

echo ""
echo -e "${GREEN}===== INSTALL COMPLETE =====${NC}"
echo ""
echo "  Run 'nvim' to start."
echo "  First launch compiles bytecode (~3 seconds)."
echo "  Subsequent launches are instant."
echo ""
exit 0
__PAYLOAD_BELOW__
SCRIPT_HEADER

# 3. Append base64-encoded tarball
echo "  Encoding payload (base64)..."
base64 "$PAYLOAD" >> "$OUTPUT"
chmod +x "$OUTPUT"

SIZE=$(du -h "$OUTPUT" | cut -f1)
echo ""
echo "===== DONE ====="
echo "  Installer: $OUTPUT"
echo "  Size:      $SIZE"
echo ""
echo "To install on ANY Linux/WSL machine (zero network):"
echo "  ./install-nvim"
echo ""
echo "Can be transferred via:"
echo "  USB, scp, LAN share, even email (if <25MB limit)"
echo ""
