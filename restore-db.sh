#!/bin/bash
# restore-db.sh - Script to restore a Dodo Payments database backup

set -e

# Check if backup file was provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup_file>"
  echo "Example: $0 ./backups/dodo_payments_20250522_120000.sql"
  exit 1
fi

BACKUP_FILE=$1
DB_USER="postgres"
DB_PASS="password"
DB_NAME="dodo_payments"
DB_HOST="localhost"
DB_PORT="5433"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Restoring database $DB_NAME from $BACKUP_FILE"
echo "⚠️ WARNING: This will overwrite the current database!"
echo "Press CTRL+C to cancel or ENTER to continue..."
read

# Set PGPASSWORD environment variable
export PGPASSWORD=$DB_PASS

# First, terminate all connections to the database
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "postgres" -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
  AND pid <> pg_backend_pid();"

# Drop and recreate the database
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "postgres" -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "postgres" -c "CREATE DATABASE $DB_NAME;"

# Restore the backup
pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "$BACKUP_FILE"

# Check if restore was successful
if [ $? -eq 0 ]; then
  echo "✅ Database restore completed successfully"
else
  echo "❌ Database restore failed"
  exit 1
fi

# Unset PGPASSWORD for security
unset PGPASSWORD
