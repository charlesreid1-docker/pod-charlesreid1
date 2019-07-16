#!/bin/bash
#
# clone the charlesreid1.com data repo
# master branch to the /www/${DOMAIN}
# directory structure

DOMAIN="{{ server_name_default }}"

REPOURL="https://git.charlesreid1.com/data/charlesreid1-data.git"

# Only run the clone command if
# /www/<domain>/htdocs exists
# and /www/<domain>/htdocs/data does not exist
if [ -d "/www/${DOMAIN}/htdocs" ]; then
    if [ ! -d "/www/${DOMAIN}/htdocs/data" ]; then

        git -C /www/${DOMAIN} \
            clone \
            --separate-git-dir=git.data \
            -b master \
            $REPOURL htdocs/data

    fi
fi

