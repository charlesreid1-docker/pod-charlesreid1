#!/bin/bash
set -x

function usage {
    echo ""
    echo "restore_gitea.sh script:"
    echo "Restore a gitea site from a .zip dump file and a .zip avatars file."
    echo ""
    echo "       ./restore_gitea.sh <dump-zip-file> <avatars-zip-file>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./restore_gitea.sh /path/to/gitea-dump.zip /path/to/gitea-avatars.zip"
    echo ""
    echo ""
    exit 1;
}

echo ""
echo "Restore Gitea:"
echo "----------------"
echo ""

NAME="pod-charlesreid1_stormy_gitea_1"

if [[ "$#" -eq 2 ]];
then

    EXEC="docker exec -it $NAME"
    CP="docker cp"

    echo "- Copying files into container"
    ${EXEC} /bin/bash -c 'mkdir /restore'
    ${CP} $1 $NAME:/restore/gitea-dump.zip
    ${CP} $2 $NAME:/restore/gitea-avatars.zip

    echo "- Unpacking files inside container"
    ${EXEC} /bin/bash -c 'unzip -qq /restore/gitea-dump.zip -d /restore'
    ${EXEC} /bin/bash -c 'unzip -qq /restore/gitea-avatars.zip -d /restore'

    echo " - Unpacking repositories inside container"
    ${EXEC} /bin/bash -c 'unzip -qq /restore/gitea-repo.zip -d /restore'

    echo " - Restoring 1/5: repositories"
    ${EXEC} /bin/bash -c 'rm -rf /data/git/repositories && cp -r /restore/repositories /data/git/repositories'

    # We are actually just gonna skip this whole step,
    # since everything here should be in d-gitea repo
    echo " - Restoring 2/5: (skipping custom files)"
    #echo " - Restoring 2/5: custom files"
    #echo "     - Moving old app.ini"
    #${EXEC} /bin/bash -c 'mv /data/gitea/conf/app.ini /data/gitea/conf/app.ini.old'
    #echo "     - Restoring custom files"
    #${EXEC} /bin/bash -c 'rm -rf /data/gitea && cp -r /restore/custom /data/gitea'

    echo " - Restoring 3/5: sqlite database"
    ${EXEC} /bin/bash -c 'cat /restore/gitea-db.sql | sed "s/false/0/g" | sed "s/true/1/g" | sqlite3 /data/gitea/gitea.db'

    echo " - Restoring 4/5: avatars"
    ${EXEC} /bin/bash -c 'rm -rf /data/gitea/avatars && cp -r /restore/avatars /data/gitea/avatars'

    echo " - Restoring 5/5: repairing paths in .git/hooks"
    ###################
    # NOTE: This is entirely case-dependent.
    #       If backup/restore happened from same gitea dir structure,
    #       this section should be removed entirely.
    #
    #       Example below swaps out /www/gitea with /data/gitea
    #
    #${EXEC} /bin/bash -c 'find /data/git/repositories -type f -exec sed -i -e "s%/www/gitea/bin/custom/conf%/data/gitea/conf%g" {} \;'
    #${EXEC} /bin/bash -c 'find /data/git/repositories -type f -exec sed -i -e "s%/www/gitea/bin/gitea%/app/data/gitea%g" {} \;'
    #
    ###################

    echo " - Cleaning up"
    ${EXEC} /bin/bash -c 'rm -rf /restore'

else
    usage
fi


