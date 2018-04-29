#!/bin/bash
#
# This script scrapes repository logs
# from the docker volume holding gitea.
# 
# It assembles a commit count for use 
# in visualizing git commits.
# 
# It commits the new commit count data
# to https://git.charlesreid1.com/data/charlesreid1-data

WORKDIR="/tmp/gitea-temp"
mkdir -p $WORDIR && cd $WORKDIR


# Step 1: clone repo

sudo -H -u charles git clone https://git.charlesreid1.com/data/charlesreid1-data.git
cd charlesreid1-data


# Step 2: extract commit dates

rm -f ${WORKDIR}/commit_dates
for dir in `find /var/lib/docker/volumes/podcharlesreid1_stormy_gitea_data/_data/git/repositories -mindepth 2 -maxdepth 2 -type d`; do
    git --git-dir=$dir --work-tree=${WORKDIR} \
        log \
        --all --author="harles" --oneline --pretty="%H %ai" \
        | cut -f 2 -d " " >> commit_dates
done


# Step 3: bin commit dates

words=$( cat commit_dates )

echo $words | sort | python -c 'import sys; 
from collections import Counter; c=Counter(sys.stdin.read().strip().split(" "));
print("\n".join(("%s, %s"%(k, c[k]) for k in c.keys())));' | sort > ${WORKDIR}/commit_counts.csv

rm -f commit_dates


# Step 4: Commit New Data

sudo -H -u charles git add commit_counts.csv
sudo -H -u charles git commit commit_counts.csv -m '[scrape_gitea_as_sudo.sh] updating git commit count data'
sudo -H -u charles git push origin master


# Step 5: Clean Up

cd /tmp
rm -rf $WORKDIR

