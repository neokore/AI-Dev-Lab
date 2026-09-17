#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  curl -fsSL https://dokploy.com/install.sh | bash -s update
else
  exec sudo -E sh -c 'curl -fsSL https://dokploy.com/install.sh | bash -s update'
fi
