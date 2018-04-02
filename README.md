# pod-charlesreid1

This repo contains a docker compose file 
for running the charlesreid1.com site.

The services are:
* mediawiki
* apache + php
* mysql
* phpmyadmin
* nginx (Let's Encrypt used offline for SSL certificates)
* python
* gitea


## Running

See **[Running.md](/Running.md)** for info about running this docker pod:
* Running the Docker Pod from Comand Line
* Running the Docker Pod as a Startup Service
* Workflow for Charlesreid1 Docker Pod Updates
* Restoring the Docker Pod from Backups

## Volumes

See **[Volumes.md](/Volumes.md)** for info about data and volumes 
used by this docker pod:
* Persistent Data Volumes
* nginx
    * nginx + lets encrypt ssl certificates
    * nginx static content
    * nginx bind-mounted files
* mysql
* mediawiki
    * mediawiki data volume
    * mediawiki bind-mounted files
* gitea
    * gitea data volume
    * gitea bind-mounted files
* python file server (pyfiles)
    * pyfiles directory


-----


### letsencrypt

### nginx

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

### mediawiki: Updating Skin/LocalSettings.php

Both the LocalSettings.php file and the skins directory are 
copied into the docker container when docker uses the Dockerfile 
to build the container.

If you need to update these files, you must stop and then start
the containers - restarting them will not update the settings file
or the skins directory.

Make your changes to `d-mediawiki/charlesreid1-config/mediawiki/skins/Bootstrap2/Bootstrap2.php`
and `d-mediawiki/charlesreid1-config/mediawiki/LocalSettings.php` as needed,
then update the charlesreid1 pod mediawiki docker image:

```
docker-compose build
docker-compose stop
docker-compose up
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
