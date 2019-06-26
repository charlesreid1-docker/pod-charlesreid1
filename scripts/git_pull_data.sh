#!/bin/bash
#
# pull the charlesreid1.com data repo
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
    echo "git_pull_data.sh takes 0 or 1 input arguments, you provided $#"
    exit 1;
fi

git -C /www/${DOMAIN} \
    --git-dir=git.data --work-tree=htdocs/data \
    pull origin master

