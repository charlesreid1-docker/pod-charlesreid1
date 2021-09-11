#!/bin/bash
#
# Run the mysql dump command to back up wikidb table, and send the
# resulting SQL file to the specified backup directory.
set -eux

CONTAINER_NAME="stormy_mysql"
STAMP="`date +"%Y%m%d"`"

function usage {
    set +x
    echo ""
    echo "wikidb_dump.sh script:"
    echo ""
    echo "Run the mysql dump command on the wikidb table in the container,"
    echo "and copy the resulting SQL file to the specified directory."
    echo ""
    echo "       ./wikidb_dump.sh"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./wikidb_dump.sh"
    echo "       (creates ${POD_CHARLESREID1_BACKUP_DIR}/20200101/wikidb_20200101.sql)"
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

    TARGET="wikidb_${STAMP}.sql"
    BACKUP_TARGET="${POD_CHARLESREID1_BACKUP_DIR}/${STAMP}/${TARGET}"

    echo ""
    echo "pod-charlesreid1: wikidb_dump.sh"
    echo "--------------------------------"
    echo ""
    echo "Backup directory: ${POD_CHARLESREID1_BACKUP_DIR}"
    echo "Backup target: ${BACKUP_TARGET}"
    echo ""

    mkdir -p ${POD_CHARLESREID1_BACKUP_DIR}/${STAMP}

    DOCKER=$(which docker)
    DOCKERX="${DOCKER} exec -t"

    echo "Running mysqldump inside the mysql container"
    ${DOCKERX} ${CONTAINER_NAME} sh -c 'exec mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > ${BACKUP_TARGET}

    echo "Done."

else
    usage
fi
