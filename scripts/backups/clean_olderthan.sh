#!/bin/bash
#
# Clean any files older than N days
# from the backup directory.
set -eux

# Number of days of backups to retain.
# Everything older than this many days will be deleted
N="30"

function usage {
    set +x
    echo ""
    echo "aws_backup.sh script:"
    echo ""
    echo "Find the last backup that was created,"
    echo "and copy it to the backups bucket."
    echo ""
    echo "       ./aws_backup.sh"
    echo ""
    exit 1;
}

if [ "$(id -u)" == "0" ]; then
    echo ""
    echo ""
    echo "This script should NOT be run as root!"
    echo ""
    echo ""
    exit 1;
fi

if [ "$#" == "0" ]; then

    echo ""
    echo "pod-charlesreid1: clean_olderthan.sh"
    echo "------------------------------------"
    echo ""
    echo "Backup directory: ${POD_CHARLESREID1_BACKUP_DIR}"
    echo ""

    echo "Cleaning backups directory $BACKUP_DIR"
    echo "The following files older than $N days will be deleted:"
    find ${POD_CHARLESREID1_BACKUP_DIR} -mtime +${N}

    echo "Deleting files"
    find ${POD_CHARLESREID1_BACKUP_DIR} -mtime +${N} -delete
    echo "Done"

else
    usage
fi
