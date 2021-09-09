#!/bin/bash
#
# change the password for the Admin user.

function usage {
    echo ""
    echo "change_passwd.sh script:"
    echo "This changes the password for the Admin user."
    echo ""
    echo "       ./change_passwd.sh <password>"
    echo ""
    echo "Inside the container it runs the "
    echo "changePassword.php script included "
    echo "with MediaWiki."
    echo ""
    exit 1;
}

if [[ "$#" -eq 0 ]];
then

    NAME="stormy_mw"
    docker exec -it ${NAME} php /var/www/html/maintenance/changePassword.php --user="Admin"

else
    usage
fi
