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

    # Pull the root password out of the container so we don't duplicate the
    # secret on the host, and forward it in via MYSQL_PWD (which mysqldump
    # reads automatically). No -t: a PTY corrupts --default-character-set=binary
    # output (LF→CRLF translation on binary blobs) and its small kernel buffer
    # can deadlock on large dumps.
    set +x
    MYSQL_PWD="$(docker exec "${CONTAINER_NAME}" printenv MYSQL_ROOT_PASSWORD)"
    export MYSQL_PWD
    set -x

    docker exec -i \
        -e MYSQL_PWD \
        "${CONTAINER_NAME}" \
        sh -c 'exec mysqldump \
                  --user=root \
                  --single-transaction \
                  --quick \
                  --routines \
                  --triggers \
                  --events \
                  --default-character-set=binary \
                  --databases wikidb' \
        > "${BACKUP_TARGET}"

    unset MYSQL_PWD

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
