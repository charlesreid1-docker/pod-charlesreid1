#!/bin/bash
#
# Clean any files older than N days
# from the backup directory.

BACKUP_DIR="$HOME/backups"
N="30"

if [ "$(id -u)" == "0" ]; then
    echo ""
    echo ""
    echo "This script should NOT be run as root!"
    echo ""
    echo ""
    exit 1;
fi

if [ "$#" == "0" ]; then

    find $BACKUP_DIR -mtime +${N} -delete

fi
