#!/bin/bash
# Backup Neovim plugin source code (~/.local/share/nvim/lazy/) + lockfile.
# Output: ./plugins-backup.tar.gz (tracked by Git LFS)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_FILE="${SCRIPT_DIR}/plugins-backup.tar.gz"
LAZY_DIR="${HOME}/.local/share/nvim/lazy"

echo "==> Backing up plugins to ${BACKUP_FILE} ..."
cd "${HOME}/.local/share/nvim"

# Create archive: lazy/ directory + lockfile
tar -czf "${BACKUP_FILE}" \
  lazy/ \
  -C "${HOME}/.config/nvim" lazy-lock.json

SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
echo "==> Done: ${BACKUP_FILE} (${SIZE})"
echo "    Run: cd ~/.config/nvim && git add plugins-backup.tar.gz && git commit -m 'chore: update plugin backup'"
