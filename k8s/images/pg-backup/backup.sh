#!/usr/bin/env bash

fatal() {
  local msg="$1"
  echo "$msg" 1>&2
  exit 1
}

[ -z "$PGHOST" ] && fatal "missing env var: 'PGHOST'"
[ -z "$PGPORT" ] && fatal "missing env var: 'PGPORT'"
[ -z "$PGUSER" ] && fatal "missing env var: 'PGUSER'"
[ -z "$PGPASSWORD" ] && fatal "missing env var: 'PGPASSWORD'"
[ -z "$PGDATABASE" ] && fatal "missing env var: 'PGDATABASE'"
[ -z "$BACKUP_ROOT" ] && fatal "missing env var: 'BACKUP_ROOT'"

TIMESTAMP="$(date +"%m-%d-%Y-%H-%M")"
BACKUP_BASENAME="$PGDATABASE.$TIMESTAMP"
BACKUP_DIRECTORY="$BACKUP_ROOT/$BACKUP_BASENAME.backup"
BACKUP_ARCHIVE="$BACKUP_ROOT/$BACKUP_BASENAME.backup.tar.gz"

echo "Making backup..."
pg_dump --file="$BACKUP_DIRECTORY" --format=directory 

echo "Compressing backup..."
tar -czvf "$BACKUP_ARCHIVE" -C "$BACKUP_DIRECTORY" .

echo "Deleting directory..."
rm -Rf "$BACKUP_DIRECTORY"

echo "Rotating out old files..."
find . -name '*.backup.tar.gz" -maxdepth 1 -type f -mtime +7 -delete
