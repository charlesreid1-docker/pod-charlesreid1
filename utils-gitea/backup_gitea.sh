#!/bin/bash

function usage {
    echo ""
    echo "backup_gitea.sh script:"
    echo "Run a gitea dump from the gitea container,"
    echo "and put the results into a target zip file."
    echo ""
    echo "       ./backup_gitea.sh <zip-file>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./backup_gitea.sh /path/to/gitea.zip"
    echo ""
    echo ""
    exit 1;
}

if [[ "$#" -eq 1 ]];
then

    docker exec -it dgitea_server_1 /bin/bash -c 'mkdir /backup && cd /backup && /app/gitea/gitea dump'
    docker cp dgitea_server_1:/backup .
    docker exec -it dgitea_server_1 /bin/bash -c 'rm -rf /backup'
    mv backup/*.zip $1
    rm -r backup/

else
    usage
fi

