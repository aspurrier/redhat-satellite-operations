#!/bin/bash

# Source the setup file
source ./setup.rc

# Verify BACKUP_DIR variable has a value
if [ -z "$BACKUP_DIR" ]; then
    echo "Error: BACKUP_DIR variable is not set or is empty" >&2
    exit 1
fi

# Check if directory exists, create it if it doesn't with 0700 permissions
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
fi

# Verify directory exists and has correct permissions
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Failed to create backup directory $BACKUP_DIR" >&2
    exit 1
fi

# Run the satellite-maintain backup command
echo "Running satellite-maintain backup..."
satellite-maintain backup offline --skip-pulp-content --assumeyes "$BACKUP_DIR"

# Check if command executed successfully
if [ $? -eq 0 ]; then
    echo "Backup completed successfully"
else
    echo "Error: Backup failed" >&2
    exit 1
fi