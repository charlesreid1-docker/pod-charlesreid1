#!/bin/bash
#
# This stupid script is needed because
# ssh and and sudo don't play nice together.
#
# the sudo cron script already extracts 
# stats from the repo, which lives in a docker
# volume and hence requires sudo to access.
# also fixes ownership to charles:charles.
# 
# now we use non sudo to check new data in.

if [ "$(id -u)" == "0" ]; then
    echo ""
    echo ""
    echo "This script should be run as a  regular user."
    echo ""
    echo ""
    exit 1;
fi

WORKDIR="/tmp/gitea-temp"
GITDIR="/tmp/gitea-temp/charlesreid1-data"

git clone ssh://git@gitdatabot:222/data/charlesreid1-data.git ${GITDIR}

(
cd ${GITDIR}
sudo -H -u charles git config user.name "databot"
sudo -H -u charles git config user.email "databot@charlesreid1.com"
sudo -H -u charles git add commit_counts.csv
sudo -H -u charles git commit commit_counts.csv -m '[scrape_gitea_as_sudo.sh] updating gitea commit count data'
sudo -H -u charles git push origin master
)


