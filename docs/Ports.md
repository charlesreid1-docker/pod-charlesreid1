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

### nginx domains

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

### mediawiki/apache ports

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

phpMyAdmin provides a web interface for MySQL databases.
Like the MediaWiki Apache container, 

### mysql ports

The MySQL container listens on port 3306 by default.
The container is only bound to the MediaWiki container, 
so MediaWiki is the only service that can access MySQL.

### gitea ports

Requests for the subdomain `git.charlesreid1.com` 
are redirected to port 3000, where gitea is listening.

The gitea container configuration is similar to the 
Apache container configuration. Gitea listens on 3000
in the container, while Apache listens on port 8989 
in the container.

Gitea listens on 
port 3000 but is only connected to the nginx container,
and the nginx container intercepts any requests 
for `git.charlesreid1.com` and forwards them to 3000.

port 3000

like apache on port 8989

### python file server ports

We have a simple, lightweight Python HTTP server
that's run in a Docker container with the following
command:

```
python -m http.server -b <bind-address> 8080
```

If there is no index.html, Python will 
provide a directory listing, and thus
a lightweight file server.

This is bound to a particular IP address -
in particular, the IP address of the 
Python file server container on the 
Docker private network. The 
`<bind-address>` piece above should
be replaced with the name of the container
(`stormy_files` in this case):

```
python -m http.server -b stormy_files 8080
```

This listens on port 8080 inside the 
python file server container `stormy_files`.

The nginx server then runs a reverse proxy,
serving requests to `files.charlesreid1.com`
on the frontend to the python files container,
port 8080, on the backend.


