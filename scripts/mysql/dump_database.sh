#!/bin/bash
echo "this script is deprecated, see ../backups/wikidb_dump.sh"
##
## Dump a database to an .sql file
## from the stormy_mysql container.
#set -eu
#
#function usage {
#    echo ""
#    echo "dump_database.sh script:"
#    echo "Dump a database to an .sql file "
#    echo "from the stormy_mysql container."
#    echo ""
#    echo "       ./dump_database.sh <sql-dump-file>"
#    echo ""
#    echo "Example:"
#    echo ""
#    echo "       ./dump_database.sh /path/to/wikidb_dump.sql"
#    echo ""
#    echo ""
#    exit 1;
#}
#
#CONTAINER_NAME="stormy_mysql"
#
#if [[ "$#" -gt 0 ]];
#then
#
#    TARGET="$1"
#    mkdir -p $(dirname $TARGET)
#	set -x
#    docker exec -i ${CONTAINER_NAME} sh -c 'exec mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > $TARGET
#
#else
#    usage
#fi
