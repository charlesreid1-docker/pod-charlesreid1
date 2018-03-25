#!/bin/bash
#
# Dump a database to an .sql file
# from the stormy_mysql container.

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

# FIXME: use value defined in container 

if [[ "$#" -eq 1 ]];
then
    docker exec -it podcharlesreid1wiki_stormy_mysql_1 \
        sh -c 'exec mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD"' \
        > $1
else
    usage
fi

