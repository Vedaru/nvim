#!/bin/bash
# Restore Neovim plugins from backup archive (plugins-backup.tar.gz in same dir).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_FILE="${SCRIPT_DIR}/plugins-backup.tar.gz"
TARGET_DIR="${HOME}/.local/share/nvim"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "ERROR: Backup not found at ${BACKUP_FILE}"
  exit 1
fi

echo "==> Restoring plugins from ${BACKUP_FILE} ..."

if [ -d "${TARGET_DIR}/lazy" ]; then
  rm -rf "${TARGET_DIR}/lazy"
fi

tar -xzf "${BACKUP_FILE}" -C "${TARGET_DIR}"

# Move lockfile back to config dir
if [ -f "${TARGET_DIR}/lazy-lock.json" ]; then
  cp "${TARGET_DIR}/lazy-lock.json" "${HOME}/.config/nvim/lazy-lock.json"
  rm -f "${TARGET_DIR}/lazy-lock.json"
fi

echo "==> Restore complete. $(ls ${TARGET_DIR}/lazy/ | wc -l) plugins restored."
