#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; O="${1:-$D/install-nvim}"; B="$(mktemp -d)"; trap "rm -rf $B" EXIT
mkdir -p "$B/c/lua" "$B/d/lazy" "$B/d/parser"
cp "$D/init.lua" "$D/lazy-lock.json" "$B/c/"
cp -r "$D/lua"/* "$B/c/lua/"
for p in "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"/*/; do
  n=$(basename "$p"); [[ "$n" == *.cloning ]] && continue
  rsync -a --exclude='.git' --exclude='.github' "$p" "$B/d/lazy/$n/"
done
if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser" ]; then
  cp -r "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser" "$B/d/"
fi
tar czf "$B/p.tar.gz" -C "$B" c d
cat>"$O"<<'S'
#!/usr/bin/env bash
set -euo pipefail
C="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"; D="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"; L="$D/lazy"
T=$(mktemp -d); trap "rm -rf $T" EXIT
echo -e "\n\033[0;32m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[0;32m║   Vedaru Neovim Config — Installer      ║\033[0m"
echo -e "\033[0;32m╚══════════════════════════════════════════╝\033[0m\n"
command -v nvim &>/dev/null || { echo -e "\033[0;31mERROR: Install nvim >= 0.11\033[0m"; exit 1; }
A=$(awk '/^__P__/{print NR+1;exit 0}' "$0"); tail -n+${A} "$0"|base64 -d|tar xz -C "$T"
echo -e "\033[0;32m==>\033[0m Config -> $C"
[ -d "$C" ] && mv "$C" "${C}.bak.$(date +%Y%m%d_%H%M%S)"
mkdir -p "$(dirname "$C")"; cp -r "$T/c" "$C"
echo -e "\033[0;32m==>\033[0m Plugins -> $L"
[ -d "$L" ] && mv "$L" "${L}.bak.$(date +%Y%m%d_%H%M%S)"
mkdir -p "$(dirname "$L")"; cp -r "$T/d/lazy" "$L"
if [ -d "$T/d/parser" ]; then
  echo -e "\033[0;32m==>\033[0m Treesitter parsers -> $D/site/parser"
  [ -d "$D/site/parser" ] && mv "$D/site/parser" "$D/site/parser.bak.$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$D/site"
  cp -r "$T/d/parser" "$D/site/"
fi
echo -e "\n\033[0;32m===== DONE =====\033[0m\n  nvim"
exit 0
__P__
S
base64 "$B/p.tar.gz" >> "$O"; chmod +x "$O"
echo "Done: $(du -h "$O"|cut -f1)"
