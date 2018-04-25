#!/bin/bash
set -x

:'
Scrape Gitea Statics

This script dumps the gitea database,
counts and scrapes commit data across
all repos, and aggregates the info
into a final, simple commit count CSV.

Once the gitea dump is complete, the repos
have the following directory structure:

/tmp/dump/orgname/reponame
'

function usage {
    echo ""
    echo "scrape_gitea.sh script:"
    echo "Scrape commit statistics from gitea."
    echo ""
    echo "       ./backup_gitea.sh <target-csv>"
    echo ""
    exit 1;
}

if [[ "$#" -eq 0 ]];
then

    echo ""
    echo "Scrape Gitea:"
    echo "----------------"
    echo ""

    NAME="podcharlesreid1_stormy_gitea_1"

    # If this script is being run from a cron job,
    # don't use -i flag with docker
    CRON="$( pstree -s $$ | /bin/grep -c cron )"
    DOCKER=""
    if [[ "$CRON" -eq 1 ]]; 
    then
        DOCKER="docker exec -t"
    else
        DOCKER="docker exec -it"
    fi

    echo " - Creating backup target"
    ${DOCKER} $NAME \
        /bin/bash -c 'mkdir /backup'
    
    echo " - Creating gitea backup zip file:"
    ${DOCKER} $NAME \
        /bin/bash -c 'cd /backup && /app/gitea/gitea dump'

    echo " - Unzipping gitea backup zip file:"
    ${DOCKER} $NAME \
        /bin/bash -c 'unzip /backup/gitea-dump-*.zip -d /backup'

    echo " - Unzipping gitea backup *repos* zip file:"
    ${DOCKER} $NAME \
        /bin/bash -c 'mkdir -p /backup/repos && unzip /backup/gitea-repo.zip -d /backup/repos'

    echo " - Prepare your anus for horrendous one-liners"

    echo "   - First one. Nice and easy. Create a long file with one line per commit "
    echo "     (each line is a commit hash and a datetime stamp)"
    ${DOCKER} $NAME \
        /bin/bash -c 'for dir in `find /backup -maxdepth 0 -type d`; do git --git-dir=$dir --work-tree=. log --oneline --pretty="%H %ai" | cut -f 2 -d " " >> loglog; done'

    ###echo "   - HERE COMES THE PAIN"
    ###${DOCKER} $NAME \
    ###    /bin/bash -c 'words=$( cat loglog ); echo $words | python -c "import sys; from collections import Counter; c=Counter(sys.stdin.read().strip().split(\" \")); print(\"\\n\".join((\"%s,  %s\"%(k,c[k]) for k in c.keys())));" > commit_counts.csv'

    echo "   - Copying data to local file..."
    docker cp $NAME:/backup/commit_counts.csv .

    echo "   - Made a mess. Cleaning up..."
    ${DOCKER} $NAME \
        rm -rf /backup/

    echo " - All done"


else
    usage
fi

#for dir in `find * -maxdepth 1 -type d`; do
#    git \
#        --git-dir=apollospacejunk/.git \
#        --work-tree=apollospacejunk \
#        log --oneline^C
#
#
#
