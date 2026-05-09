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

    mkdir -p "${BACKUP_DIR}"

    echo "Running mysqldump inside the mysql container"

    # The container already has MYSQL_ROOT_PASSWORD in its environment.
    # Use it directly inside the container via MYSQL_PWD so the password
    # never appears in the host process table.
    docker exec -i \
        "${CONTAINER_NAME}" \
        sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqldump \
                  --user=root \
                  --single-transaction \
                  --quick \
                  --routines \
                  --triggers \
                  --events \
                  --default-character-set=binary \
                  --databases wikidb' \
        > "${BACKUP_TARGET}"

    # A complete mysqldump always ends with "-- Dump completed on ...".
    # Missing trailer means the dump is truncated and not restorable.
    if ! tail -c 200 "${BACKUP_TARGET}" | grep -q 'Dump completed on'; then
        echo "ERROR: dump file ${BACKUP_TARGET} is missing the completion trailer." >&2
        echo "       mysqldump did not finish successfully." >&2
        exit 2
    fi

    size=$(stat -c %s "${BACKUP_TARGET}")
    if [ "${size}" -lt $((50 * 1024 * 1024)) ]; then
        echo "ERROR: dump file ${BACKUP_TARGET} is only ${size} bytes; suspicious." >&2
        exit 3
    fi

    echo "Dump OK: ${BACKUP_TARGET} (${size} bytes)"

else
    usage
fi
