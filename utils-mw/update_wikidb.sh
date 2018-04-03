#!/bin/bash
#
# Run the update.php script to update the database
# after a version upgrade.

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

    NAME="podcharlesreid1_stormy_mw_1"
    docker exec -it ${NAME} php /var/www/html/maintenance/update.php

else
    usage
fi
