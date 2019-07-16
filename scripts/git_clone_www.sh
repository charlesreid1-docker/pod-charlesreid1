#!/bin/bash
#
# clone the charlesreid1.com repo,
# gh-pages branch, to the /www/${DOMAIN}
# directory structure

if [[ "$#" -eq "0" ]]; then
    # default value
    DOMAIN="charlesreid1.com"
elif [[ "$#" -eq "1" ]]; then
    # user-provided value
    DOMAIN="$1"
else
    # huh?
    echo "git_pull_www.sh takes 0 or 1 input arguments, you provided $#"
    exit 1;
fi

## git.charlesreid1.com:
#REPOURL="https://git.charlesreid1.com/charlesreid1/charlesreid1.com.git"

# github.com:
REPOURL="https://github.com/charlesreid1-docker/charlesreid1.com.git"

mkdir -p /www/${DOMAIN}

# Only run the clone command if 
# /www/<domain>/htdocs does not exist
if [ ! -d "/www/${DOMAIN}/htdocs" ]; then

    echo "Cloning repo for ${DOMAIN} to /www"

    git -C /www/${DOMAIN} \
        clone \
        --separate-git-dir=git \
        -b gh-pages \
        $REPOURL htdocs

fi

