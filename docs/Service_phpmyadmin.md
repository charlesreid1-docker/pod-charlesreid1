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

The phpMyAdmin service is a web interface that is available
on port 80. The container should only be bound to the
Docker container network (default behavior). Then any
container on the network can reach the container's 
phpMyAdmin service on port 80.

This allows the phpMyAdmin service to be made available at
a URL like `/phpMyAdmin` and have all requests reverse-proxied 
by the nginx container and passed to port 80 on the back end.

The phpMyAdmin service can also be disabled/enabled by 
commenting it out of the nginx configuration files containing
HTTPS rules for the charlesreid1.com domains.

See the configuration section of the [Nginx](Service_nginx.md) 
container page for more information about the nginx configuration
files.

