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


# Step 1: clone repo

sudo -H -u charles git clone ssh://git@git.charlesreid1.com:222/data/charlesreid1-data.git ${GITDIR}


# Step 2: extract commit dates

rm -f ${GITDIR}/commit_dates

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



# Step 4: Commit New Data

(
cd ${GITDIR}
sudo -H -u charles git add commit_counts.csv
sudo -H -u charles git commit commit_counts.csv -m '[scrape_gitea_as_sudo.sh] updating git commit count data'
sudo -H -u charles git push origin master
)


# Step 5: Clean Up

sudo rm -rf ${WORKDIR}

