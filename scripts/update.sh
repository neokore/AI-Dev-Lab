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
  printf '%s\n' "Source checkout not found: $SOURCE_PATH. Run scripts/install.sh first." >&2
  exit 1
fi

git -C "$SOURCE_PATH" pull
docker compose build --pull
docker compose up -d
