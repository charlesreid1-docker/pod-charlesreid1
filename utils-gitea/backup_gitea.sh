#!/bin/bash

function usage {
    echo ""
    echo "backup_gitea.sh script"
    echo ""
    echo "This script will create a gitea dump file in the"
    echo "target directory specified by the user."
    echo "The gitea dump file will be called gitea-dump.zip."
    echo ""
    echo "       ./backup_gitea.sh <target-dir>"
    echo ""
    exit 1;
}

if [[ "$#" -eq 1 ]];
then

    echo ""
    echo "Backup Gitea:"
    echo "----------------"
    echo ""

    NAME="pod-charlesreid1_stormy_gitea_1"

    # If this script is being run from a cron job,
    # don't use -i flag with docker
    CRON="$( pstree -s $$ | /bin/grep -c cron )"
    DOCKERX=""
    if [[ "$CRON" -eq 1 ]]; 
    then
        DOCKERX="docker exec -t"
    else
        DOCKERX="docker exec -it"
    fi

    echo "Step 1: Run gitea dump command inside docker machine"
    set -x
    ${DOCKERX} $NAME /bin/bash -c 'cd /app/gitea && /app/gitea/gitea dump --file gitea-dump.zip --skip-repository'
    set +x

    echo "Step 2: Copy gitea dump file out of docker machine"
    set -x
    docker cp $NAME:/app/gitea/gitea-dump.zip $1/.
    set +x

    echo "Step 3: Clean up gitea dump file"
    set -x
    ${DOCKERX} $NAME /bin/bash -c "rm /app/gitea/gitea-dump.zip"
    set +x
    
    echo "   ~ ~ ~ ~ PEACE OUT ~ ~ ~ ~"

else
    usage
fi

