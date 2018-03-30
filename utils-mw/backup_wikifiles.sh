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

if [[ "$#" -eq 1 ]];
then

    NAME="podcharlesreid1_stormy_mw_1"
    TAR="wikifiles.tar.gz"
    docker exec -it ${NAME} tar czf /tmp/${TAR} /var/www/html/images 
    docker cp ${NAME}:/tmp/${TAR} $1
    docker exec -it ${NAME} rm /tmp/${TAR}

else
    usage
fi

