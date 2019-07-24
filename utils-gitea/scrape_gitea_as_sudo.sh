#!/bin/bash
# 
# This stupid script needs too be scaled back,
# because sudo and ssh can't play nicely together.
#
# This entire idiotic adventure in docker land
# has been chock full of the most inane, stupid
# landmines that containers cannot avoid,
# like this one - if you try and run ssh through sudo,
# you can't deal with keys or passphrases.
# 
# Seriously. Gimme a fucking break.
#
#
# This script scrapes repository logs
# from the docker volume holding gitea.
# 
# It assembles a commit count for use 
# in visualizing git commits.
# 
# It commits the new commit count data
# to https://git.charlesreid1.com/data/charlesreid1-data

if [ "$(id -u)" != "0" ]; then
    echo ""
    echo ""
    echo "This script should be run as root."
    echo ""
    echo ""
    exit 1;
fi

WORKDIR="/tmp/gitea-temp"
GITDIR="/tmp/gitea-temp/charlesreid1-data"

rm -rf ${WORKDIR}
mkdir -p ${WORKDIR} 

sudo chown -R charles:charles ${WORKDIR}

rm -rf ${GITDIR}
mkdir -p ${GITDIR} 


# Because sudo and ssh are too stupid to play nicely,
# we're forced to use this sudo script to dump out
# information every hour,
# and leave it up to some user script somewhere
# to grab the latest whenever they need it.
#
# This is the most idiotic problem yet.


# don't clone data repo, that's the whole stupid problem

### sudo -H -u charles git clone ssh://git@gitdatabot:222/data/charlesreid1-data.git ${GITDIR}



# Step 2: extract commit dates



for dir in `find /var/lib/docker/volumes/podcharlesreid1_stormy_gitea_data/_data/git/repositories -mindepth 2 -maxdepth 2 -type d`; do
    git --git-dir=$dir --work-tree=${WORKDIR} \
        log \
        --all --author="harles" --oneline --pretty="%H %ai" \
        | cut -f 2 -d " " >> ${GITDIR}/commit_dates
done


# Step 3: bin commit dates

words=$( cat ${GITDIR}/commit_dates )

echo "date,commits" > ${GITDIR}/commit_counts.csv

echo $words | sort | python -c 'import sys; 
from collections import Counter; c=Counter(sys.stdin.read().strip().split(" "));
print("\n".join(("%s,%s"%(k, c[k]) for k in c.keys())));' | sort | awk 'NF' >> ${GITDIR}/commit_counts.csv

rm -f ${GITDIR}/commit_dates
chown charles:charles ${GITDIR}/commit_counts.csv


# Step 4: commit new commit count data as databot
# 
# Instead of doing this here,
# run the script 
# assemble_gitea_counts.sh
# as a regular user.

