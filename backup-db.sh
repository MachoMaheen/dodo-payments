#!/bin/bash
# backup-db.sh - Script to backup the Dodo Payments database

set -e

# Default values
BACKUP_DIR="./backups"
BACKUP_FILE="dodo_payments_$(date +%Y%m%d_%H%M%S).sql"
DB_USER="postgres"
DB_PASS="password"
DB_NAME="dodo_payments"
DB_HOST="localhost"
DB_PORT="5433"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "Creating backup of database $DB_NAME to $BACKUP_DIR/$BACKUP_FILE"

# Set PGPASSWORD environment variable
export PGPASSWORD=$DB_PASS

# Perform the backup using pg_dump
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -F c -f "$BACKUP_DIR/$BACKUP_FILE"

# Check if backup was successful
if [ $? -eq 0 ]; then
  echo "✅ Backup completed successfully: $BACKUP_DIR/$BACKUP_FILE"
  echo "Backup size: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"
else
  echo "❌ Backup failed"
  exit 1
fi

# List existing backups
echo "Available backups:"
ls -lh $BACKUP_DIR

# Unset PGPASSWORD for security
unset PGPASSWORD
