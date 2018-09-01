# phpMyAdmin

This page describes the container-specific details
of the phpMyAdmin container.

phpMyAdmin provides a web interface for interacting with MySQL
databases and can be connected to the MySQL container to ensure
the backup/restore process proceeds smoothly.

This is run as a stock phpMyAdmin container - run script
is [here](https://git.charlesreid1.com/docker/d-phpmyadmin/src/branch/master/run_stock_phpmyadmin.sh)
in the [docker/d-phpmyadmin](https://git.charlesreid1.com/docker/d-phpmyadmin)
repository on git.charlesreid1.com.

Inside the container, the phpMyAdmin service is available
on port 80, so this should be mapped to the outside of the 
container to a different port that is unique to phpMyAdmin
on the Docker pod's network, for example on port 8080.

This enables requests for `/phpMyAdmin` to be reverse-proxied
by the nginx container and sent to the phpMyAdmin service 
container on pot 8080, and will ensure that phpMyAdmin is
only bound to the Docker pod network.

The phpMyAdmin service can also be disabled/enabled by 
commenting it out of the nginx configuration files containing
HTTPS rules for the charlesreid1.com domains.

See the configuration section of the [Nginx](Service_nginx.md) 
container page for more information about the nginx configuration
files.

