#!/bin/bash
#
# Create a tar file containing wiki files
# from the mediawiki docker container.
#
# Backup directory:
#       /home/user/backups/mediawiki

BACKUP_DIR="$HOME/backups/mediawiki"
CONTAINER_NAME="pod-charlesreid1_stormy_mw_1"
STAMP="`date +"%Y-%m-%d"`"

function usage {
    set +x
    echo ""
    echo "wikifiles_dump.sh script:"
    echo ""
    echo "Create a tar file containing wiki files"
    echo "from the mediawiki docker container."
    echo "The resulting tar file will be timestamped."
    echo ""
    echo "       ./wikifiles_dump.sh"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./wikifiles_dump.sh"
    echo "       (creates ${BACKUP_DIR}/wikifiles_20200101_000000.tar.gz)"
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

    echo ""
    echo "pod-charlesreid1: wikifiles_dump.sh"
    echo "-----------------------------------"
    echo ""
    echo "Backup target: ${BACKUP_DIR}/${TARGET}"
    echo ""

    mkdir -p $BACKUP_DIR

    # If this script is being run from a cron job,
    # don't use -i flag with docker
    CRON="$( pstree -s $$ | /bin/grep -c cron )"
    DOCKERX=""
    if [[ "$CRON" -eq 1 ]]; 
    then
        DOCKERX="docker exec -t"
    else
        DOCKERX="docker exec -it"
    fi

    echo "Step 1: Compress wiki files inside container"
    set -x
    ${DOCKERX} ${CONTAINER_NAME} /bin/tar czf /tmp/${TARGET} /var/www/html/images
    set +x

    echo "Step 2: Copy tar.gz file out of container"
    mkdir -p $(dirname "$1")
    set -x
    docker cp ${CONTAINER_NAME}:/tmp/${TARGET} ${BACKUP_DIR}/${TARGET}
    set +x

    echo "Step 3: Clean up tar.gz file"
    set -x
    ${DOCKERX} ${CONTAINER_NAME} /bin/rm -f /tmp/${TARGET}
    set +x

    echo "Done."
else
    usage
fi

