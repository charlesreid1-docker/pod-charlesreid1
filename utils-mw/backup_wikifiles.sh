#!/bin/bash
#
# Create a tar file containing wiki files
# from the stormy_mw container.
set -x

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

    NAME="podcharlesreid1_stormy_mw_1"
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

    # zip to temp dir inside container
    ${DOCKER} ${NAME} tar czf /tmp/${TAR} /var/www/html/images 

    # copy from container to target $1
    mkdir -p $(dirname $TARGET)
    ${DOCKER} cp ${NAME}:/tmp/${TAR} $1

    # clean up container
    ${DOCKER} ${NAME} rm /tmp/${TAR}

else
    usage
fi

