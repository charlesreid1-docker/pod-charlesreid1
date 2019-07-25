#!/bin/bash

function usage {
    set +x
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

    echo "Step 1: Creating backup target"
    set -x
    ${DOCKER} $NAME /bin/bash -c 'mkdir /backup'
    set +x
    
    echo "Step 2: Creating backup zip files:"

    echo "     Step 2A: gitea dump zip"
    set -x
    ${DOCKER} $NAME /bin/bash -c '/app/gitea/gitea dump'
    set +x

    echo "     Step 2B: gitea avatars zip"
    set -x
    ${DOCKER} $NAME /bin/bash -c 'cd /data/gitea/ && tar czf /backup/gitea-avatars.tar.gz avatars'
    set +x

    echo "Step 3: Moving gitea dump to /backup directory"
    set -x
    ${DOCKER} $NAME /bin/bash -c 'mv /tmp/gitea-dump-*/* /backup/.'
    set +x

    TEMP_BACKUP=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

    echo "Step 4: Copying backup directory (with zip files) to backup location $1"

    echo "     Step 4A: Making temporary backup location"
    #mkdir -p $TEMP_BACKUP

    echo "     Step 4B: Copying /backup directory to temporary backup location $1"
    set -x
    docker cp $NAME:/backup/* $1/.
    set +x

    TAR_PREFIX="$(echo $V | sed 's+/$++g')"

    set -x
    tar -cvf ${TAR_PREFIX}.tar $1
    rm -fr $1
    set +x

    echo "Step 6: Cleaning up container"
    set -x
    ${DOCKER} $NAME /bin/bash -c 'rm -rf /backup'
    ${DOCKER} $NAME /bin/bash -c 'rm -rf /tmp/gitea-dump-*'
    set +x

    echo "Step 7: Cleaning up local host"
    #rm -rf $TEMP_BACKUP

    echo "    ~ ~ ~ ~ PEACE OUT ~ ~ ~ ~"

else
    usage
fi

