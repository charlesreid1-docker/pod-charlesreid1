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

### nginx + letsencrypt

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

Before running, you will need to create two external 
data volumes: one for MySQL, one for MediaWiki.

This is a pain because it creates an extra step outside of 
docker-compose, but it is necessary because it gives 
the operator more control over the data volumes.

Create the MySQL data volume (erase it first):

```
cd d-mysql/
./erase_mysql_data_volume.sh
./make_mysql_data_volume.sh
```

Create the MediaWiki data volume (erase it first):

```
cd d-mediawiki/
./erase_mw_volume.sh
./make_mw_volume.sh
```

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
