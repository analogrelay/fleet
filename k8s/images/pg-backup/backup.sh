#!/usr/bin/env bash

set -x

fatal() {
  local msg="$1"
  echo "$msg" 1>&2
  exit 1
}

[ -z "$PGHOST" ] && fatal "missing env var: 'PGHOST'"
[ -z "$PGUSER" ] && fatal "missing env var: 'PGUSER'"
[ -z "$PGPASSWORD" ] && fatal "missing env var: 'PGPASSWORD'"
[ -z "$PGDATABASE" ] && fatal "missing env var: 'PGDATABASE'"
[ -z "$BACKUP_ROOT" ] && fatal "missing env var: 'BACKUP_ROOT'"

RID=$(uuidgen)

[ -n "$HEALTHCHECK_URL" ] && curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/start?rid=$RID"

echo "Preparing to back up"

TIMESTAMP="$(date +"%m-%d-%Y-%H-%M")"
BACKUP_BASENAME="$PGDATABASE.$TIMESTAMP"
BACKUP_DIRECTORY="$BACKUP_ROOT/$BACKUP_BASENAME.backup"
BACKUP_ARCHIVE="$BACKUP_ROOT/$BACKUP_BASENAME.backup.tar.gz"
BACKUP_ARCHIVE_LATEST="$BACKUP_ROOT/$PGDATABASE.latest.backup.tar.gz"

echo "Making backup..."
pg_dump --file="$BACKUP_DIRECTORY" --format=directory 

echo "Compressing backup..."
tar -czvf "$BACKUP_ARCHIVE" -C "$BACKUP_DIRECTORY" .

echo "Deleting directory..."
rm -Rf "$BACKUP_DIRECTORY"

echo "Updating latest backup"
rm "$BACKUP_ARCHIVE_LATEST"
mv "$BACKUP_ARCHIVE" "$BACKUP_ARCHIVE_LATEST"

[ -n "$HEALTHCHECK_URL" ] && curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL?rid=$RID"