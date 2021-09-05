#!/bin/bash
#
# Run the mysql dump command to back up wikidb table, and send the
# resulting SQL file to the specified backup directory.
#
# Backup directory:
#       /home/user/backups/mysql

BACKUP_DIR="$HOME/backups/mysql"
CONTAINER_NAME="stormy_mysql"

function usage {
    set +x
    echo ""
    echo "wikidb_dump.sh script:"
    echo ""
    echo "Run the mysql dump command on the wikidb table in the container,"
    echo "and copy the resulting SQL file to the specified directory."
    echo "The resulting mysql dump SQL file will be timestamped."
    echo ""
    echo "       ./wikidb_dump.sh"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./wikidb_dump.sh"
    echo "       (creates ${BACKUP_DIR}/wikidb_20200101_000000.sql)"
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

    STAMP="`date +"%Y-%m-%d"`"
    TARGET="wikidb_${STAMP}.sql"

    echo ""
    echo "pod-charlesreid1: wikidb_dump.sh"
    echo "--------------------------------"
    echo ""
    echo "Backup target: ${BACKUP_DIR}/${TARGET}"
    echo ""

    mkdir -p $BACKUP_DIR

    # If this script is being run from a cron job,
    # don't use -i flag with docker
    CRON="$( pstree -s $$ | /bin/grep -c cron )"
    DOCKER="/usr/bin/docker"
    DOCKERX=""
    if [[ "$CRON" -eq 1 ]]; 
    then
        DOCKERX="${DOCKER} exec -t"
    else
        DOCKERX="${DOCKER} exec -it"
    fi

    echo "Running mysqldump"
    set -x
    ${DOCKERX} ${CONTAINER_NAME} sh -c 'exec mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > ${BACKUP_DIR}/${TARGET}
    set +x

    echo "Done."
else
    usage
fi
