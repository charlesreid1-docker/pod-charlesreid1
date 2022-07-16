#!/bin/bash
# 
# fix extensions dir in the mediawiki container
set -eux

NAME="stormy_mw"

EXTENSIONS="SyntaxHighlight_GeSHi ParserFunctions EmbedVideo Math Fail2banlog"

MW_DIR="${POD_CHARLESREID1_DIR}/d-mediawiki"
MW_CONF_DIR="${MW_DIR}/charlesreid1-config/mediawiki"
EXT_DIR="${MW_CONF_DIR}/extensions"

echo "Checking that container exists..."
docker ps --format '{{.Names}}' | grep ${NAME} || exit 1;

echo "Checking that extensions exist..."
for EXTENSION in $EXTENSIONS; do
	test -d ${EXT_DIR}/${EXTENSION}
done

echo "Replacing existing versions of MediaWiki extensions..."
for EXTENSION in $EXTENSIONS; do
    echo "Removing old extension ${EXTENSION} from /var/www/html/extensions"
    docker exec -it $NAME /bin/bash -c "mv /var/www/html/extensions/${EXTENSION} /var/www/html/extensions/_${EXTENSION}"

    echo "Copying new extension ${EXTENSION} from pod-charlesreid1 MediaWiki extensions dir ${EXT_DIR}"
    docker cp ${EXT_DIR}/${EXTENSION} ${NAME}:/var/www/html/extensions

    echo "Fixing permissions on ${EXTENSION}"
    docker exec -it $NAME /bin/bash -c "chown www-data:www-data /var/www/html/extensions/${EXTENSION}"
    docker exec -it $NAME /bin/bash -c "chmod 755 /var/www/html/extensions/${EXTENSION}"
done

echo "Finished replacing extensions!"
