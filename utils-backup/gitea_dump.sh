#!/bin/bash
#
# Run the gitea dump command and send the dump file
# to the specified backup directory.
#
# Backup directory:
#       /home/user/backups/gitea

BACKUP_DIR="$HOME/backups/gitea"
CONTAINER_NAME="pod-charlesreid1_stormy_gitea_1"

function usage {
    set +x
    echo ""
    echo "gitea_dump.sh script:"
    echo ""
    echo "Run the gitea dump command inside the gitea docker container,"
    echo "and copy the resulting zip file to the specified directory."
    echo "The resulting gitea dump zip file will be timestamped."
    echo ""
    echo "       ./gitea_dump.sh"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./gitea_dump.sh"
    echo "       (creates ${BACKUP_DIR}/gitea-dump_20200101_000000.zip)"
    echo ""
    exit 1;
}

if [ "$(id -u)" == "0" ]; then
    echo ""
    echo ""
    echo "This script should NOT be run as root!"
    echo ""
    echo ""
    exit 1;
fi

if [ "$#" == "0" ]; then

    STAMP="`date +"%Y-%m-%d"`"
    TARGET="gitea-dump_${STAMP}.zip"

    echo ""
    echo "pod-charlesreid1: gitea_dump.sh"
    echo "-------------------------------"
    echo ""
    echo "Backup target: ${BACKUP_DIR}/${TARGET}"
    echo ""

    mkdir -p $BACKUP_DIR

    # If this script is being run from a cron job,
    # don't use -i flag with docker
    CRON="$( pstree -s $$ | /bin/grep -c cron )"
    DOCKER="/usr/local/bin/docker"
    DOCKERX=""
    if [[ "$CRON" -eq 1 ]]; 
    then
        DOCKERX="${DOCKER} exec -t"
    else
        DOCKERX="${DOCKER} exec -it"
    fi

    echo "Step 1: Run gitea dump command inside docker machine"
    set -x
    ${DOCKERX} --user git ${CONTAINER_NAME} /bin/bash -c 'cd /app/gitea && /app/gitea/gitea dump --file gitea-dump.zip --skip-repository'
    set +x

    echo "Step 2: Copy gitea dump file out of docker machine"
    set -x
    ${DOCKER} cp ${CONTAINER_NAME}:/app/gitea/gitea-dump.zip ${BACKUP_DIR}/${TARGET}
    set +x

    echo "Step 3: Clean up gitea dump file"
    set -x
    ${DOCKERX} ${CONTAINER_NAME} /bin/bash -c "rm -f /app/gitea/gitea-dump.zip"
    set +x

    echo "Done."
else
    usage
fi
