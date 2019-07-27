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

function problem {
    set +x
    echo ""
    echo "backup_gitea.sh script:"
    echo "This script is temporarily out of service."
    echo "The gitea dump command is broken, which renders"
    echo "this script useless."
    echo ""
    exit 0;
}

problem

if [[ "$#" -gt 0 ]];
then

    echo ""
    echo "Backup Gitea:"
    echo "----------------"
    echo ""

    NAME="pod-charlesreid1_stormy_gitea_1"

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

    set -x
    echo "Step 1: Creating backup target (inside docker machine)"
    ${DOCKER} $NAME /bin/bash -c 'mkdir -p /backup'
    
    echo "Step 2: Creating backup zip files:"

    echo "     Step 2A: gitea dump zip to temp (inside docker machine)"
    ${DOCKER} -u git $NAME /bin/bash -c "/app/gitea/gitea dump"

    # above command leading to
    # empty folder only
    # (???????)

    echo "     Step 2B: gitea zip up avatars (inside docker machine)"
    ${DOCKER} $NAME /bin/bash -c 'cd /data/gitea/ && tar czf /backup/gitea-avatars.tar.gz avatars'

    echo "Step 3: Moving gitea dump to backup directory (inside docker machine)"
    ${DOCKER} $NAME /bin/bash -c "mv /tmp/gitea-dump-${stamp}.zip /backup/."

    echo "Step 4: Copying backup directory (in container) to backup location $1 (on docker host)"
    docker cp $NAME:/backup/* $1/.

    TAR_PREFIX="$(echo $V | sed 's+/$++g')"

    echo "Step 5: Compressing contents of $1 into tar file ${TAR_PREFIX}.tar"
    tar -cvf ${TAR_PREFIX}.tar $1
    ### rm -fr $1

    echo "Step 6: Cleaning up container"
    ${DOCKER} $NAME /bin/bash -c 'rm -rf /backup'
    ${DOCKER} $NAME /bin/bash -c 'rm -rf /tmp/gitea-dump-*'

    echo "Step 7: Cleaning up local host"
    #rm -rf $TEMP_BACKUP

    echo "    ~ ~ ~ ~ PEACE OUT ~ ~ ~ ~"
    ### set +x

else
    usage
fi

