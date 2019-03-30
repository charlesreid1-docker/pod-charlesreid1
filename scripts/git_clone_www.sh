#!/bin/bash

DOMAIN="charlesreid1.com"
## git.charlesreid1.com:
#REPOURL="https://git.charlesreid1.com/charlesreid1/${DOMAIN}.git"

# github.com:
REPOURL="https://github.com/charlesreid1-docker/${DOMAIN}.git"

mkdir -p /www/${DOMAIN}

if [ ! -d "/www/${DOMAIN}/htdocs" ]; then

    # Only do this if /www/<domain>/htdocs does not exist

    echo "Cloning repo for ${DOMAIN} to /wwww"

    git -C /www/${DOMAIN} \
        clone \
        --separate-git-dir=git \
        -b gh-pages \
        $REPOURL htdocs

fi

