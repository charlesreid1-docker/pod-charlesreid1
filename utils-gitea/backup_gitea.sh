#!/bin/bash
set -x

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

if [[ "$#" -gt 0 ]];
then

    echo ""
    echo "Backup Gitea:"
    echo "----------------"
    echo ""

    NAME="podcharlesreid1_stormy_gitea_1"

    # If this script is being run from a cron job,
    # don't use -i flag with docker
    CRON="$( pstree -s $$ | /bin/grep -c cron )"
    DOCKER=""
    if [[ "$CRON" -eq 1 ]]; 
    then
        DOCKER="docker exec -t"
    else
        DOCKER="docker exec -it"
    fi

    echo " - Creating backup target"
    ${DOCKER} $NAME /bin/bash -c 'mkdir /backup'
    
    echo " - Creating backup zip files:"
    echo "     - gitea dump zip"
    ${DOCKER} $NAME /bin/bash -c 'cd /backup && /app/gitea/gitea dump'
    echo "     - gitea avatars zip"
    ${DOCKER} $NAME /bin/bash -c 'cd /data/gitea/ && tar czf /backup/gitea-avatars.tar.gz avatars'

    echo " - Copying backup directory (with zip files) to temporary backup location ${TEMP_BACKUP}"
    TEMP_BACKUP=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
    mkdir -p $TEMP_BACKUP
    docker cp $NAME:/backup $TEMP_BACKUP

    echo " - Cleaning up container"
    ${DOCKER} $NAME /bin/bash -c 'rm -rf /backup'

    /bin/ls -l ${TEMP_BACKUP}

    # TODO: check if $1 is a directory. 
    # if not, at least stuff will still be left at backup/
    echo " - Copy zip backup from ${TEMP_BACKUP} to target"
    mkdir -p $1 && mv $TEMP_BACKUP/backup/*.{zip,gz} $1/.

    echo " - Peace out"
    rm -rf $TEMP_BACKUP

else
    usage
fi

