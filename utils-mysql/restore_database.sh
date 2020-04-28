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
    echo ""
    echo "Restores a database from an SQL dump."
    echo "Restores the database into the "
    echo "stormy_msyql container."
    echo ""
    echo "Obtains MySQL password from"
    echo "MYSQL_ROOT_PASSWORD env var"
    echo "inside mysql container."
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

# what a damn mess.
# docker exec does not support reading from stdin.
# that means we can't run the command with bash or exec,
# which means we don't have access to the container's 
# env variables, which means we can't access the root
# mysql password via environment variable, which we 
# specifically chose because of how universal it was.
# 
# docker makes dealing with secrets 
# a complete and utterpain in the ass
# because of all these one-off 
# "whoopsie we don't do that" problems.

CONTAINER_NAME="pod-charlesreid1_stormy_mysql_1"
TARGET=$(basename $1)
TARGET_DIR=$(dirname $1)


if [[ "$#" -eq 1 ]];
then

    # Step 1: Copy the sql dump into the container
    set -x
    docker cp $1 ${CONTAINER_NAME}:/tmp/${TARGET}
    set +x

    # Step 2: Run sqldump inside the container
    set -x
    docker exec -i ${CONTAINER_NAME} sh -c "/usr/bin/mysql --defaults-file=/root/.mysql.rootpw.cnf < /tmp/${TARGET}"
    set +x

    # Step 3: Clean up sql dump from inside container
    set -x
    docker exec -i ${CONTAINER_NAME} sh -c "/bin/rm -fr /tmp/${TARGET}.sql"
    set +x


    set +x
else
    usage
fi

