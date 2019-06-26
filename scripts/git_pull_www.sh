#!/bin/bash
# 
# pull the charlesreid1.com repo,
# gh-pages branch, in the /www/${DOMAIN}
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

git -C /www/${DOMAIN} \
    --git-dir=git --work-tree=htdocs \
    pull origin gh-pages

