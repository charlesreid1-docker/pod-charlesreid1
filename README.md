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

You can also rebuild the container using

```
docker-compose build
```
or, to do a really clean build,

```
docker-compose build --no-cache
```

(WARNING: if you have a lot of aptitude packages, this will re-download 
all of them, and is potentially really slow.)

You can restart all containers in a pod using the restart command:

```
docker-compose restart
```

Note: this will ***NOT*** pick up any changes to the 
container's Dockerfile or files copied into the container,
as this simply restarts the container ***without*** getting
an up-to-date container image first.

### Quick Start: Startup Service Version

If you want to run the pod as a startup service,
see the dotfiles/debian repository, in the services/
subdirectory. You will find a systemd service
that will start/stop the docker pod.

**`dockerpod-charlesereid1.service:`**

```
[Unit]
Description=charlesreid1 docker pod
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/local/bin/docker-compose -f /home/charles/codes/docker/pod-charlesreid1/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose  -f /home/charles/codes/docker/pod-charlesreid1/docker-compose.yml stop

[Install]
WantedBy=default.target
```

Now install the service to `/etc/systemd/system/dockerpod-charlesreid1.servce`,
and activate it:

```
sudo systemctl enable dockerpod-charlesreid1.service
```

Now you can start/stop the service with:

```
sudo systemctl (start|stop) dockerpod-charlesreid1.service
```

NOTE: if you need to debug the containers, 
or update any config files copied into the container,
be sure and stop the service before doing a 
`docker-compose stop` or a `docker-compose up --build`,
otherwise the pod will continually respawn.

### Before You Go Further

Once you've gotten the whole fleet of containers up,
you should be ready to run charlesreid1.com.

First, though, you'll need to restore some files:

* Restore MySQL wikidb database from backup using scripts in `utils-mysql` dir
* Restore MediaWiki images dir from backup using scripts in `utils-mw` dir
* Restore Gitea database and avatars from backup using scripts in `utils-gitea` dir



## Volumes

### are volumes persistent

Mostly.

When you're using docker-compose, volumes are persistent
through both `docker-compose stop` and `docker-compose down` commands.

The `docker-compose down` command will destroy everything including networks
and mounted files, while `docker-compose stop` will just stop the containers.

***DANGER - DANGER - DANGER***

If you want to remove the volumes, use `docker-compose down -v`.

```
docker-compose down -v   # DANGER!!!
```

To force removal of the volumes:

```
docker-compose down -v -f   # DANGER!!!
```


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
* on the host: `/www/charlesreid1.blue/htdocs/`
* source: `/www/charlesreid1.blue/charlesreid1.blue-src/`
* workflow: pelican make from the source dir, and copy the desired files to the htdocs dir
* we use the more cumbersome "by hand" method because it gives greater control over each site

Re letsencrypt:

* getting the container set up is a mess
* since certbot only needs to be run every few months, I just set up a dead simple script
* [certbot](https://charlesreid1.com:3000/charlesreid1/certbot)

Certs in nginx:

* again - dead simple script - creates one set of certs per subdomain
* nginx ssl configuration has one block per subdomain

Where should certs go?

* on host dir, certs sould be in `/etc/letsencrypt`

### htdocs

Here is how we set up the static content site for each site we are hosting:

Start by making a place for web content to live on this machine,
specifically the directory `/www`:

```
sudo mkdir -p /www
sudo chown charles:charles /www
```

Now, for each unique site, we do the following:

* Create a folder for that domain
* Inside the domain folder, create a source directory (git repo) and an htdocs directory (live html content)

The directory structure looks like this:

```
/www/
    charlesreid1.blue/
        htdocs/
            <web site static contents>
            ...
        charlesreid1.blue-src/
            <pelican files>
            ...

```

To make the 





Clone a local copy of the site repo (charlesreid1-src),
check out a copy of the gh-pages branch,
and bind mount it into the container.

Updating the site from htdocs is a simple as 
`git pull origin pages`.

(Well... ideally. But it's not that simple.
The `htdocs` dir must be owned by `www-data` 
so you have to run the git pull as that user.)

```
sudo -H -u www-data git pull origin pages
```

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
