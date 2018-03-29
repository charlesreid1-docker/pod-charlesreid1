# pod-charlesreid1

This repo contains a docker compose file 
for running the charlesreid1.com site.

The services are:
* MediaWiki (Apache + PHP + MediaWiki)
* MySQL
* phpMyAdmin

Additionally:
* nginx
* Lets Encrypt

Finally:
* gitea

## Quick Start

Run this sed one-liner to create the `docker-compose.yml` file 
with a hard-coded password:

```
$ sed "s/REPLACEME/YoFooThisIsYourNewPassword/" docker-compose.fixme.yml > docker-compose.yml
```

Now you can run the container pod with

```
docker-compose up
```

or, if you want to rebuild all the containers,

```
docker-compose up --build
```

## Volumes

### letsencrypt

Rather than fuss with getting the letsencrypt 
docker image working, and because our DNS provider
does not provide API integration, we decided to
get SSL certs by hand.

```
certbot certonly --non-interactive --agree-tos --email "melo@smallmelo.com" --apache -d "git.smallmelo.com"
```

### nginx

No data volumes are used.

* nginx static content is a bind-mounted host directory
* lets encrypt container generates site certs into bind-mounted host directory
* nginx certificates come from docker secrets (?)

```
  web:
    volumes:
      - ./letsencrypt_certs:/etc/nginx/certs
      - ./letsencrypt_www:/var/www/letsencrypt

  letsencrypt:
    image: certbot/certbot
    command: /bin/true
    volumes:
      - ./letsencrypt_certs:/etc/letsencrypt
      - ./letsencrypt_www:/var/www/letsencrypt
```

Clone a local copy of the site repo (charlesreid1-src),
check out a copy of the gh-pages branch,
and bind mount it into the container.

Updating the site is a ssimple as 
`git pull origin gh-pages`.

### mediawiki + mysql

The docker compose file will create two data volumes,
one for mediawiki and one for mysql.

These data volumes are resilient to `docker-compose stop`
and `docker-compose down`.

To remove the volumes, use `docker-compose down -v`.

To force removal of the volumes, use `docker-compose down -v -f`.

To check on the volumes, use

```
docker volumes ls
```


## Ports

The apache-mediawiki combination is running an apache service listening on port 8989.
This can be adjusted, but should be adjusted in the Dockerfile, `ports.conf`, and `wiki.conf`.

The apache service listens on all interfaces (hence `*:8989` in the apache conf file),
but there is no port mapping specified in `docker-compose.yml` so it does not listen 
on any public interfaces.

Thus, the wiki is not publicly accessible via port 8989, but the wiki is available via port 8989
to any container linked to, or connected to the same network as, the mediawiki apache container.

Meanwhile, the nginx container has a public interface listening on port 80 
and another listening on port 443. nginx listens for requests going to
the wiki, detected via the url resource prefix being `/w/` or `/wiki/`,
and acts as a reverse proxy, forwarding the requests to Apache.

The user transparently sees everything happening via port 80 or (preferrably) 443,
but on the backend nginx is passing along the URL request and returning the result.

## Secrets

### nginx + letsencrypt 

Secrets (certificates) are dealt with by mounting volumes and files.

Lets Encrypt generates certs in a container 
with a one-liner, dumps them to bind-mounted 
host directory.

### mediawiki + mysql

Gave up on Docker secrets, mainly because they are only available 
at runtime, and Docker provides no mechanism for build-time secrets.

Pretty tacky.

My hacky workaround: check in a docker-compose.yml template,
and a sed one-liner that replaces a MySQL root password 
placeholder with the real password.

```
$ sed "s/REPLACEME/YoFooThisIsYourNewPassword/" docker-compose.fixme.yml > docker-compose.yml
```

Great if you hard-code the password, but - wasn't that the whole thing 
we were trying to avoid?

Put the password into a file istead, then grab the password from that file
and do a find/replace on the docker compose file:

```
$ cat root.password
mysecretpassword

$ sed "s/REPLACEME/`cat root.password`/" docker-compose.fixme.yml > docker-compose.yml
```

The `docker-compose.yml` file and `root.password` files are both ignored 
by version control.

## Backups

See `utils-backups` for backup utilities.

See `utils-mw` for mediawiki utilities.

See `utils-mysql` for mysql utilities.

## Running

From your project directory, start up your application by running:

```
$ docker-compose up
```

If you want to rebuild the images (if you changed the Dockerfile),
use the `--build` flag:

```
$ docker-compose up --build
```

## Links

docker compose documentation:

* [getting started](https://docs.docker.com/compose/gettingstarted/#step-4-build-and-run-your-app-with-compose)
* [set environment variables in containers](https://docs.docker.com/compose/environment-variables/#set-environment-variables-in-containers)
* <s>[docker secrets](https://docs.docker.com/engine/swarm/secrets/)</s> (nope)
