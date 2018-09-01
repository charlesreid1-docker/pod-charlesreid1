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

This service can also be enabled or disabled via the
nginx configuration file in the `d-nginx` submodule
by commenting out the section that directs users to
the phpMyAdmin instance -
see the [Nginx](Service_nginx.md) page and [configuration
file](https://git.charlesreid1.com/docker/d-nginx-charlesreid1/src/branch/master/conf.d/https.com.charlesreid1.conf#L50-L55)
for details.



