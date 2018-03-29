#!/bin/bash

function usage {
    echo ""
    echo "restore_gitea.sh script:"
    echo "Restore a gitea site from a .zip dump file."
    echo ""
    echo "       ./restore_gitea.sh <zip-file>"
    echo ""
    echo "Example:"
    echo ""
    echo "       ./restore_gitea.sh /path/to/gitea.zip"
    echo ""
    echo ""
    exit 1;
}

if [[ "$#" -eq 1 ]];
then

    EXEC="docker exec -it dgitea_server_1"
    CP="docker cp"

    echo "Copying files into container"
    ${EXEC} /bin/bash -c 'mkdir /restore'
    ${CP} $1 dgitea_server_1:/restore/.

    echo "Unpacking files inside container"
    ${EXEC} /bin/bash -c 'unzip -qq /restore/*.zip -d /restore'

    echo "Unpacking repositories inside container"
    ${EXEC} /bin/bash -c 'unzip -qq /restore/gitea-repo.zip -d /restore'

    echo "Restoring 1/3: repositories"
    ${EXEC} /bin/bash -c 'rm -rf /data/git/repositories && cp -r /restore/repositories /data/git/repositories'

    echo "Restoring 2/3: custom files"
    ${EXEC} /bin/bash -c 'rm -rf /data/gitea && cp -r /restore/custom /data/gitea'

    echo "Restoring 3/3: sqlite database"
    ${EXEC} /bin/bash -c 'cat /restore/gitea-db.sql | sed "s/false/0/g" | sed "s/true/1/g" | sqlite3 /data/gitea/gitea.db'

    echo "Cleaning up"
    ${EXEC} /bin/bash -c 'rm -rf /restore'

else
    usage
fi


