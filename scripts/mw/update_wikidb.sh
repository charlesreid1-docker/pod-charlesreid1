#!/bin/bash
#
# Run the update.php script to update the database
# after a version upgrade.
set -eux

function usage {
    echo ""
    echo "update_wikidb.sh script:"
    echo "Run update.php to update a database"
    echo "after a MediaWiki version upgrade."
    echo "Runs in the stormy_mw container"
    echo ""
    echo "       ./update_wikidb.sh"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./update_wikidb.sh"
    echo ""
    echo ""
    exit 1;
}

if [[ "$#" -eq 0 ]];
then

    NAME="stormy_mw"

	echo "Checking that container exists"
	docker ps --format '{{.Names}}' | grep ${NAME} || exit 1;

	echo "Updating wiki database for version upgrade"
    docker exec -it ${NAME} php /var/www/html/maintenance/update.php

else
    usage
fi
