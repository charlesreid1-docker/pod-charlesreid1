#!/bin/bash
# 
# fix LocalSettings.php in the mediawiki container.
set -eux

NAME="stormy_mw"

MW_DIR="${POD_CHARLESREID1_DIR}/d-mediawiki"
MW_CONF_DIR="${MW_DIR}/charlesreid1-config/mediawiki"

echo "Checking that container exists"
docker ps --format '{{.Names}}' | grep ${NAME} || exit 1;

echo "Checking that LocalSettings.php exists"
test -f ${MW_CONF_DIR}/LocalSettings.php

echo "Installing LocalSettings.php into $NAME"
docker cp ${MW_CONF_DIR}/LocalSettings.php $NAME:/var/www/html/LocalSettings.php
docker exec -it $NAME /bin/bash -c "chown www-data:www-data /var/www/html/LocalSettings.php"
docker exec -it $NAME /bin/bash -c "chmod 600 /var/www/html/LocalSettings.php"
echo "Finished installing LocalSettings.php into $NAME"

DIRS="/var/www/html/docs
/var/www/html/includes
/var/www/html/languages
/var/www/html/maintenance
/var/www/html/mw-config
/var/www/html/tests
/var/www/html/vendor"

for dir in $DIRS
do
    echo "Fixing permissions on $dir"
    docker exec -it $NAME /bin/bash -c "chown -R www-data:www-data $dir"
    docker exec -it $NAME /bin/bash -c "chmod 755 $dir"
    docker exec -it $NAME /bin/bash -c "chmod -R 755 $dir"
    echo "Finished fixing permissions on $dir"
done
