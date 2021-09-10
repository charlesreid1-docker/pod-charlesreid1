#!/bin/bash
#
# Create a tar file containing wiki files
# from the mediawiki docker container.
#
# Backup directory:
#       /home/user/backups/mediawiki

BACKUP_DIR="$HOME/backups"
CONTAINER_NAME="stormy_mw"
STAMP="`date +"%Y%m%d"`"

function usage {
    set +x
    echo ""
    echo "wikifiles_dump.sh script:"
    echo ""
    echo "Create a tar file containing wiki files"
    echo "from the mediawiki docker container."
    echo ""
    echo "       ./wikifiles_dump.sh"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./wikifiles_dump.sh"
    echo "       (creates ${BACKUP_DIR}/20200101/wikifiles_20200101.tar.gz)"
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

    TARGET="wikifiles_${STAMP}.tar.gz"
    BACKUP_TARGET="${BACKUP_DIR}/${STAMP}/${TARGET}"

    echo ""
    echo "pod-charlesreid1: wikifiles_dump.sh"
    echo "-----------------------------------"
    echo ""
    echo "Backup target: ${BACKUP_TARGET}"
    echo ""

    mkdir -p ${BACKUP_DIR}/${STAMP}

    # If this script is being run from a cron job,
    # don't use -i flag with docker
    CRON="$( pstree -s $$ | /bin/grep -c cron )"
    DOCKER=$(which docker)
    DOCKERX=""
    if [[ "$CRON" -eq 1 ]]; 
    then
        DOCKERX="${DOCKER} exec -t"
    else
        DOCKERX="${DOCKER} exec -it"
    fi

    echo "Step 1: Compress wiki files inside container"
    set -x
    ${DOCKERX} ${CONTAINER_NAME} /bin/tar czf /tmp/${TARGET} /var/www/html/images
    set +x

    echo "Step 2: Copy tar.gz file out of container"
    mkdir -p $(dirname "$1")
    set -x
    ${DOCKER} cp ${CONTAINER_NAME}:/tmp/${TARGET} ${BACKUP_TARGET}
    set +x

    echo "Step 3: Clean up tar.gz file"
    set -x
    ${DOCKERX} ${CONTAINER_NAME} /bin/rm -f /tmp/${TARGET}
    set +x

    echo "Done."
else
    usage
fi
