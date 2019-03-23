#!/bin/bash

declare -a DOMAINS=("charlesreid1.com" "charlesreid1.blue" "charlesreid1.red")

for DOMAIN in "${DOMAINS[@]}"; do

    echo "Cloning repo for ${DOMAIN} to /wwww"

    git -C /www/${DOMAIN} \
        --git-dir=git --work-tree=htdocs \
        pull origin gh-pages

done
