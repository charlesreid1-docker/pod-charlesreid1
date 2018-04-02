#!/bin/bash

function usage {
    echo ""
    echo "backup_gitea.sh script:"
    echo "Run a gitea dump from the gitea container,"
    echo "and back up the gitea avatars."
    echo "Gitea backups are dumped to gitea-dump-*.zip"
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
    echo "      /path/to/backups/gitea-dump-*.zip"
    echo "      /path/to/backups/gitea-avatars.zip"
    echo ""
    echo ""
    exit 1;
}

echo ""
echo "Backup Gitea:"
echo "----------------"
echo ""

NAME="podcharlesreid1_stormy_gitea_1"

if [[ "$#" -eq 1 ]];
then

    echo " - Creating backup target"
    docker exec -it $NAME /bin/bash -c 'mkdir /backup'
    
    echo " - Creating backup zip files:"
    echo "     - gitea dump zip"
    docker exec -it $NAME /bin/bash -c 'cd /backup && /app/gitea/gitea dump'
    echo "     - gitea avatars zip"
    docker exec -it $NAME /bin/bash -c 'cd /data/gitea/ && zip /backup/gitea-avatars.zip avatars'

    echo " - Copying backup directory (with zip files) to ."
    docker cp $NAME:/backup .

    echo " - Cleaning up container"
    docker exec -it $NAME /bin/bash -c 'rm -rf /backup'

    # todo: check if $1 is a directory. 
    # if not, at least stuff will still be left at backup/
    echo " - Copy zip backup to target"
    mkdir -p $1 && mv backup/*.zip $1/. && rm -rf backup

else
    usage
fi

