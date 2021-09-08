#!/bin/bash
#
# Clean any files older than N days
# from the backup directory.
set -eu

# Number of days of backups to retain.
# Everything older than this many days will be deleted
N="30"

BACKUP_DIR="$HOME/backups"

if [ "$(id -u)" == "0" ]; then
    echo ""
    echo ""
    echo "This script should NOT be run as root!"
    echo ""
    echo ""
    exit 1;
fi

if [ "$#" == "0" ]; then

    echo "Cleaning backups directory $BACKUP_DIR"
    echo "Files older than $N days will be deleted"
    find $BACKUP_DIR -mtime +${N} -delete

fi
