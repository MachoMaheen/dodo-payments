#!/bin/bash
# Script to clean up redundant files in the Dodo Payments project

echo "Cleaning up redundant files..."

# Ensure backup directory exists
mkdir -p backup_files

# Move redundant Dockerfiles to backup if they exist
for file in Dockerfile.prod Dockerfile.simple Dockerfile.working; do
    if [ -f "$file" ]; then
        echo "Moving $file to backup_files/"
        mv "$file" backup_files/
    fi
done

# Move redundant docker-compose files to backup if they exist
for file in docker-compose.prod.yml docker-compose.working.yml; do
    if [ -f "$file" ]; then
        echo "Moving $file to backup_files/"
        mv "$file" backup_files/
    fi
done

# Move redundant run scripts to backup if they exist
for file in run-app.sh run-app.bat run-prod.sh run-prod.bat build-and-run-windows.bat; do
    if [ -f "$file" ]; then
        echo "Moving $file to backup_files/"
        mv "$file" backup_files/
    fi
done

# Move redundant SQLx preparation scripts to backup if they exist
for file in prepare-sqlx.sh prepare-sqlx.bat fix_sqlx_data.sh fix_sqlx_data.bat; do
    if [ -f "$file" ]; then
        echo "Moving $file to backup_files/"
        mv "$file" backup_files/
    fi
done

# Create a simple README note for the backup directory if it doesn't exist
if [ ! -f "backup_files/README.md" ]; then
    echo "Creating backup directory README.md"
    cat > backup_files/README.md << EOL
# Backup Files

This directory contains previous versions of Docker configuration files, scripts, and other files that were part of 
the original project setup but have been superseded by the simplified configuration.

These files are kept for reference purposes but are not actively used in the current project setup.
EOL
fi

echo "Cleanup completed successfully!"
