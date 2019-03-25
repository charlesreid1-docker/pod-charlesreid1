#!/bin/bash

declare -a DOMAINS=("charlesreid1.com" "charlesreid1.blue" "charlesreid1.red")

for DOMAIN in "${DOMAINS[@]}"; do

    ## git.charlesreid1.com:
    #REPOURL="https://git.charlesreid1.com/charlesreid1/${DOMAIN}.git"

    # github.com:
    REPOURL="https://github.com/charlesreid1-docker/${DOMAIN}.git"

    echo "Cloning repo for ${DOMAIN} to /wwww"

    git -C /www/${DOMAIN} \
        clone \
        --separate-git-dir=git \
        -b gh-pages \
        $REPOURL htdocs

done

