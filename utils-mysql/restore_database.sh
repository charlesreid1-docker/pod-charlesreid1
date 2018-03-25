#!/bin/bash
#
# Restores the database into the 
# stormy_mysql container.
# 
# Note that this expects the .sql dump
# to create its own databases.
# Use the --databases flag with mysqldump.

function usage {
    echo ""
    echo "restore_database.sh script:"
    echo "Restores a database from an SQL dump."
    echo "Restores the database into the "
    echo "stormy_msyql container."
    echo ""
    echo "       ./restore_database.sh <sql-dump-file>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./restore_database.sh /path/to/wikidb_dump.sql"
    echo ""
    echo ""
    exit 1;
}

# FIXME: use secrets
MYSQL_ROOT_PASSWORD="`cat ../../root.password`"

if [[ "$#" -eq 1 ]];
then
    docker exec -it podcharlesreid1wiki_stormy_mysql_1 \
        mysql -uroot -p$MYSQL_ROOT_PASSWORD \
        < $1 
else
    usage
fi

