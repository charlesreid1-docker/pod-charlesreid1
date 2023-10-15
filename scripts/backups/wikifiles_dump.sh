#!/bin/bash
#
# Create a tar file containing wiki files
# from the mediawiki docker container.
set -eux

CONTAINER_NAME="stormy_mw"
DATESTAMP="`date +"%Y%m%d"`"
TIMESTAMP="`date +"%Y%m%d_%H%M%S"`"

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
    echo "       (creates ${POD_CHARLESREID1_BACKUP_DIR}/YYYYMMDD/wikifiles_YYYYMMDD_HHMMSS.tar.gz)"
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

    TARGET="wikifiles_${TIMESTAMP}.tar.gz"
    BACKUP_DIR="${POD_CHARLESREID1_BACKUP_DIR}/${DATESTAMP}"
    BACKUP_TARGET="${BACKUP_DIR}/${TARGET}"

    echo ""
    echo "pod-charlesreid1: wikifiles_dump.sh"
    echo "-----------------------------------"
    echo ""
    echo "Backup directory: ${BACKUP_DIR}"
    echo "Backup target: ${BACKUP_TARGET}"
    echo ""

    mkdir -p ${BACKUP_DIR}

    DOCKER=$(which docker)
    DOCKERX="${DOCKER} exec -t"

    echo "Step 1: Compress wiki files inside container"
    ${DOCKERX} ${CONTAINER_NAME} /bin/tar czf /tmp/${TARGET} /var/www/html/images

    echo "Step 2: Copy tar.gz file out of container"
    mkdir -p $(dirname "${BACKUP_TARGET}")
    ${DOCKER} cp ${CONTAINER_NAME}:/tmp/${TARGET} ${BACKUP_TARGET}

    echo "Step 3: Clean up tar.gz file"
    ${DOCKERX} ${CONTAINER_NAME} /bin/rm -f /tmp/${TARGET}

    echo "Successfully wrote wikifiles dump to file: ${BACKUP_TARGET}"
    echo "Done."

else
    usage
fi
