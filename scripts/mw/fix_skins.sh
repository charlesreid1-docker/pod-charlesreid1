#!/bin/bash
# 
# fix skins in the mediawiki container.
# 
# docker is stupid, so it doesn't let you bind mount
# a single file into a docker volume.
#
# so, rather than rebuilding the entire goddamn container
# just to update the skin when it changes, we just
# use a docker cp command to copy it into the container.
set -eux

NAME="stormy_mw"

MW_DIR="${POD_CHARLESREID1_DIR}/d-mediawiki"
MW_CONF_DIR="${MW_DIR}/charlesreid1-config/mediawiki"
SKINS_DIR="${MW_CONF_DIR}/skins"

echo "Checking that container exists"
docker ps --format '{{.Names}}' | grep ${NAME} || exit 1;

echo "Checking that skins dir exists"
test -d ${SKINS_DIR}

echo "Installing skins into $NAME"
docker exec -it $NAME /bin/bash -c 'rm -rf /var/www/html/skins'
docker cp ${SKINS_DIR} $NAME:/var/www/html/skins
docker exec -it $NAME /bin/bash -c 'chown -R www-data:www-data /var/www/html/skins'

echo "Finished installing skins into $NAME"
