#!/bin/bash
#
# Create a tar file containing wiki files
# from the stormy_mw container.

function usage {
    echo ""
    echo "backup_wikifiles.sh script:"
    echo "Create a tar file containing wiki files"
    echo "from the stormy_mw container"
    echo ""
    echo "       ./backup_wikifiles.sh <tar-file>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./backup_wikifiles.sh /path/to/wikifiles.tar.gz"
    echo ""
    echo ""
    exit 1;
}

if [[ "$#" -gt 0 ]];
then

    echo ""
    echo "Backup MediaWiki Files:"
    echo "------------------------"
    echo ""

    NAME="pod-charlesreid1_stormy_mw_1"
    TAR="wikifiles.tar.gz"

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

    # zip to temp dir inside container
    ${DOCKER} ${NAME} /bin/tar czf /tmp/${TAR} /var/www/html/images 

    # copy from container to target $1
    mkdir -p $(dirname "$1")
    docker cp ${NAME}:/tmp/${TAR} $1

    # clean up container
    ${DOCKER} ${NAME} /bin/rm -f /tmp/${TAR}

    set +x

else
    usage
fi

