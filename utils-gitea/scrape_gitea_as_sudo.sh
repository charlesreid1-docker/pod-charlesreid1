#!/bin/bash
#
# This script scrapes repository logs
# from the docker volume holding gitea.
# It assembles a commit count for use 
# in visualizing git commits.

WORKDIR="/tmp/gitea-temp"
mkdir -p $WORDIR && cd $WORKDIR


# Step 1: extract commit dates

rm -f ${WORKDIR}/commit_dates
for dir in `find /var/lib/docker/volumes/podcharlesreid1_stormy_gitea_data/_data/git/repositories -mindepth 2 -maxdepth 2 -type d`; do
    git --git-dir=$dir --work-tree=${WORKDIR} \
        log \
        --all --author="harles" --oneline --pretty="%H %ai" \
        | cut -f 2 -d " " >> commit_dates
done


# Step 2: bin commit dates

words=$( cat commit_dates )

echo $words | sort | python -c 'import sys; 
from collections import Counter; c=Counter(sys.stdin.read().strip().split(" "));
print("\n".join(("%s, %s"%(k, c[k]) for k in c.keys())));' | sort > ${WORKDIR}/commit_counts.csv



