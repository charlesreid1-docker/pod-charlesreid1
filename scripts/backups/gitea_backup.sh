#!/bin/bash
#
# Bcak up the Gitea custom/ and data/ directories.
# These are needed to restore the site
# (as well as repository data, which is not backed up
# by this script, it is a separate drive).
set -eux

CONTAINER_NAME="stormy_gitea"
STAMP="`date +"%Y%m%d"`"


function usage {
    set +x
    echo ""
    echo "gitea_backup.sh script:"
    echo ""
    echo "Create a tar file containing gitea"
    echo "custom/ and data/ directories."
    echo ""
    echo "       ./gitea_backup.sh"
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

    CUSTOM_NAME="gitea_custom_${STAMP}.tar.gz"
    DATA_NAME="gitea_data_${STAMP}.tar.gz"

    CUSTOM_TARGET="${POD_CHARLESREID1_BACKUP_DIR}/${STAMP}/${CUSTOM_NAME}"
    DATA_TARGET="${POD_CHARLESREID1_BACKUP_DIR}/${STAMP}/${DATA_NAME}"

    echo ""
    echo "pod-charlesreid1: gitea_backup.sh"
    echo "-----------------------------------"
    echo ""
    echo "Backup target: custom: ${CUSTOM_TARGET}"
    echo "Backup target: data: ${DATA_TARGET}"
    echo ""

    mkdir -p ${POD_CHARLESREID1_BACKUP_DIR}/${STAMP}

    # We don't need to use docker, since these directories
    # are both bind-mounted into the Docker container
    echo "Backing up custom directory"
    tar --ignore-failed-read -czf ${CUSTOM_TARGET} ${POD_CHARLESREID1_DIR}/d-gitea/custom
    echo "Backing up data directory"
    tar czf ${DATA_TARGET} ${POD_CHARLESREID1_DIR}/d-gitea/data

    echo "Done."

else
    usage
fi
