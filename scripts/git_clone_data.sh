#!/bin/bash
#
# clone the charlesreid1.com data repo
# master branch to the /www/${DOMAIN}
# directory structure

if [[ "$#" -eq "0" ]]; then
    # default value
    DOMAIN="charlesreid1.com"
elif [[ "$#" -eq "1" ]]; then
    # user-provided value
    DOMAIN="$1"
else
    # huh?
    echo "git_clone_data.sh takes 0 or 1 input arguments, you provided $#"
    exit 1;
fi

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

