#!/bin/bash

function usage {
    echo ""
    echo "backup_gitea.sh script:"
    echo "Run a gitea dump from the gitea container,"
    echo "and back up the gitea avatars."
    echo "Gitea backups are dumped to gitea-dump-000000.zip"
    echo "and gitea-avatars.zip and copied to the target directory."
    echo ""
    echo "       ./backup_gitea.sh <target-dir>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./backup_gitea.sh /path/to/backups/"
    echo ""
    echo "creates the files:"
    echo""
    echo "      /path/to/backups/gitea-dump-000000.zip"
    echo "      /path/to/backups/gitea-avatars.zip"
    echo ""
    echo ""
    exit 1;
}

if [[ "$#" -eq 1 ]];
then

    # create a backup target
    docker exec -it dgitea_server_1 /bin/bash -c 'mkdir /backup'
    
    # create the backup zip files
    docker exec -it dgitea_server_1 /bin/bash -c 'cd /backup && /app/gitea/gitea dump'
    docker exec -it dgitea_server_1 /bin/bash -c 'm/data/gitea/ && zip /backup/gitea-avatars.zip avatars'

    # copy the backup dir, containing the zip files, to .
    docker cp dgitea_server_1:/backup .

    # clean up in the container
    docker exec -it dgitea_server_1 /bin/bash -c 'rm -rf /backup'

    # todo: check if $1 is a directory. 
    # if not, at least stuff will still be left at backup/
    mkdir -p $1 && mv backup/*.zip $1/. && rm -rf backup

else
    usage
fi

