#!/usr/bin/env bash
set -euo pipefail

trap 'printf "\nError en install.sh (línea %s): %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

if [[ "${EUID}" -ne 0 ]]; then
  if [[ ! -t 0 || ! -t 1 ]]; then
    printf '%s\n' 'Dokploy necesita un terminal interactivo para pedir la contraseña de sudo.' >&2
    exit 1
  fi
  sudo -v
  RUNNER=(sudo bash)
else
  RUNNER=(bash)
fi

INSTALLER_FILE=$(mktemp)
trap 'rm -f "$INSTALLER_FILE"' EXIT
curl -L --fail-with-body https://dokploy.com/install.sh -o "$INSTALLER_FILE"

if [[ "${DOKPLOY_INSTALL_TRACE:-}" == "1" ]]; then
  "${RUNNER[@]}" -x "$INSTALLER_FILE"
else
  "${RUNNER[@]}" "$INSTALLER_FILE"
fi
