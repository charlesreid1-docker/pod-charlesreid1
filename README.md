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

For information about running this docker pod: [Running.md](/Running.md)
* [Running the Docker Pod from Comand Line](/Running.md#RunningCLI)
* [Running the Docker Pod as a Startup Service](/Running.md#RunningService)
* [Workflow for Charlesreid1 Docker Pod Updates](/Running.md#Workflow)
* [Restoring the Docker Pod from Backups](/Running.md#Backups)

## Volumes

For more information about the volumes used in this docker pod: [Volumes.md](/Volumes.md)
* [Persistent Data Volumes](/Volumes.md#persistent)

* [nginx](/Volumes.md#nginx)
    * [nginx + lets encrypt ssl certificates](/Volumes.md#nginx-ssl)
    * [nginx static content](/Volumes.md#nginx-static)
    * [nginx bind-mounted files](/Volumes.md#nginx-files)

* [mysql](/Volumes.md#mysql)

* [mediawiki](/Volumes.md#mw)
    * [mediawiki data volume](/Volumes.md#mw-data)
    * [mediawiki bind-mounted files](/Volumes.md#mw-files)

* [gitea](/Volumes.md#gitea)
    * [gitea data volume](/Volumes.md#gitea-data)
    * [gitea bind-mounted files](/Volumes.md#gitea-files)

* [python file server (pyfiles)](/Volumes.md#pyfiles)
    * [pyfiles directory](/Volumes.md#pyfiles-dir)


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
