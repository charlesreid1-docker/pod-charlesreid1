#!/usr/bin/env bash
#
# Find the last backup created, and copy it
# to an S3 bucket.
set -eux

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
    echo "pod-charlesreid1: aws_backup.sh"
    echo "-----------------------------------"
    echo ""
    echo "Backup directory: ${POD_CHARLESREID1_BACKUP_DIR}"
    echo "Backup bucket: ${POD_CHARLESREID1_BACKUP_S3BUCKET}"
    echo ""

    echo "Checking that directory exists"
    /usr/bin/test -d ${POD_CHARLESREID1_BACKUP_DIR}

    echo "Checking that we can access the S3 bucket"
    aws s3 ls s3://${POD_CHARLESREID1_BACKUP_S3BUCKET} > /dev/null
    
    # Get name of last backup, to copy to AWS
    LAST_BACKUP=$(/bin/ls -1 -t ${POD_CHARLESREID1_BACKUP_DIR} | /usr/bin/head -n1)
    echo "Last backup found: ${LAST_BACKUP}"
    echo "Last backup directory: ${POD_CHARLESREID1_BACKUP_DIR}/${LAST_BACKUP}"

    BACKUP_SIZE=$(du -hs ${POD_CHARLESREID1_BACKUP_DIR}/${LAST_BACKUP})
    echo "Backup directory size: ${BACKUP_SIZE}"

    # Copy to AWS
    echo "Backing up directory ${POD_CHARLESREID1_BACKUP_DIR}/${LAST_BACKUP}"
    aws s3 cp --only-show-errors --recursive ${POD_CHARLESREID1_BACKUP_DIR}/${LAST_BACKUP} s3://${POD_CHARLESREID1_BACKUP_S3BUCKET}/backups/${LAST_BACKUP}
    echo "Done."

else
    usage
fi
