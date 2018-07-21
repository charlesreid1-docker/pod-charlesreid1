# Domains and Ports

## Domains 

There are three domains pointing to this server:

```
charlesreid1.com
charlesreid1.red
charlesreid1.blue
```

These are pointing to the server's IP address
using an A NAME DNS record.

There are also various subdomains set up
(www, git, files), all pointing to the 
same location.

### nginx domain handling

Nginx handles all of the domains by specifying 
a different `domain_name` in each `server{}` block
of the nginx config files.

For example:

```
server {
    listen 80;
    listen [::]:80;
    server_name charlesreid1.com;
    ...
}

server {
    listen 80;
    listen [::]:80;
    server_name charlesreid1.blue;
    ...
}

server {
    listen 80;
    listen [::]:80;
    server_name charlesreid1.red;
    ...
}
```

See the `conf.d` dir of
[d-nginx-charlesreid1](https://git.charlesreid1.com/docker/d-nginx-charlesreid1).

We will cover this in the nginx ports section,
but all http urls are redirected to https urls.




## Ports

### nginx ports

Also see [nginx service](Service_nginx.md).

Nginx has two main public-facing ports:
port 80 (HTTP) and port 443 (HTTPS).

All requests to `http://` urls go to port 80,
and all requests to `https://` urls go to port 443.

The server will automatically redirect all 
requests to port 80 to port 443, turning all
http requests into https requests.

Nginx also exposes port 3000 and forwards it
along to `git.charlesreid1.com`. This is for 
legacy reasons.

To work with MediaWiki, nginx must implement 
rewrite rules: nginx listens for requests going 
to wiki URLs (prefixed with `/w/` or `/wiki`)
and proxies those to the correct container.




### mediawiki/apache ports

Also see [mediawiki service](Service_mediawiki.md)
and [apache/php service](Service_apachephp.md).

The MediaWiki server runs on a PHP and Apache stack.
Inside the MediaWiki container, Apache listens on 
port 8989. This port only connects to the nginx container,
so nginx is the only service that can connect to MediaWiki,
and only over port 8989.

This nginx-apache connection is not encrypted 
because it happens on the same machine. 

When the user connects to the wiki, for example at the url

```
https://charlesreid1.com/wiki/Nmap
```

the user's connection is with the nginx server.
The session is an https session happening over port 443
and signed by nginx's certificates.

If the user goes to 

```
http://charlesreid1.com/wiki/Nmap
```

on port 80, this is rewritten to

```
https://charlesreid1.com/wiki/Nmap
```

on port 443. In nginx, this is done with a 301:

```
server {
    listen 80;
    listen [::]:80;
    server_name charlesreid1.com;
    location / {
        return 301 https://charlesreid1.com$request_uri;
    }
}
```

Note that nginx plays the role of a central dispatcher 
in the charlesreid1 pod - all containers connect to
nginx and only nginx, while nginx exposes each container 
to the outside world via requests for various subdomains 
being redirected to different ports.



### phpmyadmin ports

Also see [phpmyadmin service](Service_phpmyadmin.md).

phpMyAdmin provides a web interface for MySQL databases.

This follows a similar pattern to the MediaWiki Apache container:

* The phpMyAdmin container is connected to the MySQL container
    via the docker network created by the `docker-compose` command
    (no container links needed)
* The phpMyAdmin container runs an HTTP web interface,
    and listens only for incoming requests from the local 
    network. Requests to phpMyAdmin are reverse-proxied 
    by the nginx container in this pod.
* Because phpMyAdmin is not a heavily-used tool in 
    daily tasks, and because it provides access to 
    sensitive data and operations, it should be 
    completely disabled from public access unless
    needed.

To control access to phpMyAdmin, 
configure the [nginx service](Service_nginx.md)
to whitelist certain IPs to access
phpMyAdmin (or shut off all access).


### mysql ports

Also see [mysql service](Service_mysql.md).

The MySQL container listens on port 3306 by default.
The container is only bound to the MediaWiki container, 
so MediaWiki is the only service that can access MySQL.


### gitea ports

Also see [gitea service](Service_gitea.md).

Requests for the subdomain `git.charlesreid1.com` 
are redirected to port 3000 on the docker internal
container network, where gitea is listening.

Like the MediaWiki and phpMyAdmin containers, this follows
the same reverse proxy pattern:

* The nginx service handles front-end requests and 
    reverse proxies those rquests to gitea over the 
    internal docker container network.
* Gitea listens to port 3000 and is bound to the 
    local docker network only.
* Gitea does not implement HTTP on the back end;
    nginx handles HTTPS with client on the front end.


### python file server ports

Also see [python files service](Service_pythonfiles.md).

We have a simple, lightweight Python HTTP server
that's run in a Docker container via the following
command:

```
python -m http.server -b <bind-address> 8080
```

This works because Python provides a built-in HTTP server
that, if no index.html file is present, will provide a 
directory listing. This is as simple as it gets,
as far as file servers go.

This follows the same reverse proxy pattern:

* Python HTTP server listens for incoming requests
    on the Docker network only. Client requests are 
    reverse proxied by nginx on the front end.
* The server does not handle HTTPS, this is also 
    handled by the nginx container on the frontend.
* The bind address and port of the Python HTTP server
    are set in the command line. The `<bind-address>`
    should be set to the name of the docker container image
    (`stormy_files`).

```
python -m http.server -b stormy_files 8080
```

This listens on port 8080 inside the 
python file server container `stormy_files`.

The nginx server reverse-proxies requests for 
[https://files.charlesreid1.com](https://files.charlesreid1.com)
and forwards them to the container.

Note: this container can be expanded to a container
that serves multiple directories on multilpe ports
by using twisted. See the 
[d-python-helium](https://git.charlesreid1.com/docker/d-python-helium)
repository for an example.

