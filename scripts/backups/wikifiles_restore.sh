#!/bin/bash
#
# Restore wiki files from a tar file
# into the stormy_mw container.
set -eu

function usage {
    echo ""
    echo "restore_wikifiles.sh script:"
    echo "Restore wiki files from a tar file"
    echo "into the stormy_mw container"
    echo ""
    echo "       ./restore_wikifiles.sh <tar-file>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./restore_wikifiles.sh /path/to/wikifiles.tar.gz"
    echo ""
    echo ""
    exit 1;
}

# NOTE:
# I assume images/ is the only directory to back up/restore.
# If there are more I forgot, add them back in here.
# (skins and extensions are static, added into image at build time.)

if [[ "$#" -eq 1 ]];
then

    NAME="stormy_mw"
    TAR=$(basename "$1")

    echo "Checking that container ${NAME} exists"
    docker ps --format '{{.Names}}' | grep ${NAME} || exit 1;

    echo "Copying dir $1 into container ${NAME}"
    set -x
    docker cp $1 ${NAME}:/tmp/${TAR}
    docker exec -it ${NAME} rm -rf /var/www/html/images.old
    docker exec -it ${NAME} mv /var/www/html/images /var/www/html/images.old
    docker exec -it ${NAME} tar -xf /tmp/${TAR} -C / && rm -f /tmp/${TAR}
    docker exec -it ${NAME} chown -R www-data:www-data /var/www/html/images

else
    usage
fi
