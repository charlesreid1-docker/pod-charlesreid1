#!/bin/bash
#
# Dump a database to an .sql file
# from the stormy_mysql container.
set -x

function usage {
    echo ""
    echo "dump_database.sh script:"
    echo "Dump a database to an .sql file "
    echo "from the stormy_mysql container."
    echo ""
    echo "       ./dump_database.sh <sql-dump-file>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./dump_database.sh /path/to/wikidb_dump.sql"
    echo ""
    echo ""
    exit 1;
}

CONTAINER_NAME="pod-charlesreid1_stormy_mysql_1"

if [[ "$#" -gt 0 ]];
then

    TARGET="$1"
    mkdir -p $(dirname $TARGET)
    docker exec -i ${CONTAINER_NAME} sh -c 'exec mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > $TARGET

else
    usage
fi

