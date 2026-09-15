#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ ! -f .env ]; then
  printf '%s\n' "Missing .env. Copy .env.example to .env and set OPENCHAMBER_UI_PASSWORD." >&2
  exit 1
fi

. ./.env
SOURCE_DIR=${OPENCHAMBER_SOURCE_DIR:-./openchamber}
case "$SOURCE_DIR" in
  /*) SOURCE_PATH=$SOURCE_DIR ;;
  *) SOURCE_PATH=$ROOT_DIR/${SOURCE_DIR#./} ;;
esac

if [ ! -d "$SOURCE_PATH/.git" ]; then
  if [ -e "$SOURCE_PATH" ]; then
    printf '%s\n' "Source path exists but is not a Git checkout: $SOURCE_PATH" >&2
    exit 1
  fi
  git clone https://github.com/openchamber/openchamber.git "$SOURCE_PATH"
fi

mkdir -p "${OPENCHAMBER_CONFIG_DIR:-./data/openchamber}" \
  "${OPENCODE_SHARE_DIR:-./data/opencode/share}" \
  "${OPENCODE_STATE_DIR:-./data/opencode/state}" \
  "${OPENCODE_CONFIG_DIR:-./data/opencode/config}" \
  "${OPENCHAMBER_SSH_DIR:-./data/ssh}" \
  "${OPENCHAMBER_WORKSPACES_DIR:-./workspaces}"

docker compose build --pull
docker compose up -d
docker compose ps
