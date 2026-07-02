#!/usr/bin/env bash
set -euo pipefail
DB_PATH=${DB_PATH:-/opt/madmallard-platform/app/db.sqlite3}
BUCKET=${BUCKET:?Set BUCKET to your backup bucket name}
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
TMP="/tmp/madmallard-db-$STAMP.sqlite3"
cp "$DB_PATH" "$TMP"
aws s3 cp "$TMP" "s3://$BUCKET/sqlite/$STAMP.sqlite3"
rm -f "$TMP"
