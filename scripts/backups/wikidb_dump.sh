#!/bin/bash
#
# Run the mysql dump command to back up wikidb table, and send the
# resulting SQL file to the specified backup directory.
set -eux

CONTAINER_NAME="stormy_mysql"
DATESTAMP="`date +"%Y%m%d"`"
TIMESTAMP="`date +"%Y%m%d_%H%M%S"`"

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
    echo "       (creates ${POD_CHARLESREID1_BACKUP_DIR}/YYYYMMDD/wikidb_YYYYMMDD_HHMMSS.sql)"
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

    TARGET="wikidb_${TIMESTAMP}.sql"
    BACKUP_DIR="${POD_CHARLESREID1_BACKUP_DIR}/${DATESTAMP}"
    BACKUP_TARGET="${BACKUP_DIR}/${TARGET}"

    echo ""
    echo "pod-charlesreid1: wikidb_dump.sh"
    echo "--------------------------------"
    echo ""
    echo "Backup directory: ${BACKUP_DIR}"
    echo "Backup target: ${BACKUP_TARGET}"
    echo ""

    mkdir -p ${BACKUP_DIR}

    DOCKER=$(which docker)
    DOCKERX="${DOCKER} exec -t"

    echo "Running mysqldump inside the mysql container"

    # this works, except the first line is a stupid warning about passwords
    ${DOCKERX} ${CONTAINER_NAME} sh -c 'exec mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=binary' > ${BACKUP_TARGET}

    # trim stupid first line warning
    tail -n +2 ${BACKUP_TARGET} > ${BACKUP_TARGET}.tmp
    mv ${BACKUP_TARGET}.tmp ${BACKUP_TARGET}

    echo "Successfully wrote SQL dump to file: ${BACKUP_TARGET}"
    echo "Done."

else
    usage
fi
