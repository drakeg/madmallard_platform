#!/usr/bin/env bash
set -euo pipefail
APP_DIR=${APP_DIR:-/opt/madmallard-platform}
REPO_URL=${REPO_URL:?Set REPO_URL to your GitHub repo SSH/HTTPS URL}
if [ ! -d "$APP_DIR/.git" ]; then
  sudo mkdir -p "$APP_DIR"
  sudo chown "$USER:$USER" "$APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi
cd "$APP_DIR"
git pull
cd app
docker compose up -d --build
