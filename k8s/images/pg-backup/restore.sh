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

# Optional: BACKUP_FILE environment variable to specify which backup to restore
# If not specified, defaults to the latest backup
BACKUP_FILE="${BACKUP_FILE:-$BACKUP_ROOT/$PGDATABASE.latest.backup.tar.gz}"

[ ! -f "$BACKUP_FILE" ] && fatal "backup file does not exist: '$BACKUP_FILE'"

RID=$(uuidgen)

[ -n "$HEALTHCHECK_URL" ] && curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/start?rid=$RID"

echo "Preparing to restore from backup: $BACKUP_FILE"

# Create a temporary directory for extraction
RESTORE_DIRECTORY=$(mktemp -d)
trap "rm -rf $RESTORE_DIRECTORY" EXIT

echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIRECTORY"

echo "Checking if database exists..."
DB_EXISTS=$(psql -h "$PGHOST" -U "$PGUSER" -lqt | cut -d \| -f 1 | grep -qw "$PGDATABASE" && echo "yes" || echo "no")

if [ "$DB_EXISTS" = "no" ]; then
  echo "Database '$PGDATABASE' does not exist. Creating it..."
  psql -h "$PGHOST" -U "$PGUSER" -d postgres -c "CREATE DATABASE \"$PGDATABASE\";"
else
  echo "Database '$PGDATABASE' already exists."
  
  # Optional: Drop and recreate if RESTORE_DROP_EXISTING is set
  if [ -n "$RESTORE_DROP_EXISTING" ]; then
    echo "RESTORE_DROP_EXISTING is set. Dropping existing database..."
    psql -h "$PGHOST" -U "$PGUSER" -d postgres -c "DROP DATABASE \"$PGDATABASE\";"
    psql -h "$PGHOST" -U "$PGUSER" -d postgres -c "CREATE DATABASE \"$PGDATABASE\";"
  else
    echo "Warning: Database already exists. Restore will merge/overwrite data."
    echo "Set RESTORE_DROP_EXISTING=1 to drop and recreate the database first."
  fi
fi

echo "Restoring backup..."
pg_restore --host="$PGHOST" --username="$PGUSER" --dbname="$PGDATABASE" --format=directory --clean --if-exists "$RESTORE_DIRECTORY"

echo "Restore complete!"

[ -n "$HEALTHCHECK_URL" ] && curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL?rid=$RID"
