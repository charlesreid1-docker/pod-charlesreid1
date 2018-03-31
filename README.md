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

### Before You Go Further

Once you've gotten the whole fleet of containers up,
you should be ready to run charlesreid1.com.

First, though, you'll need to restore some files:

* Restore MySQL wikidb database from backup using scripts in `utils-mysql` dir
* Restore MediaWiki images dir from backup using scripts in `utils-mw` dir
* Restore Gitea database and avatars from backup using scripts in `utils-gitea` dir

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
            ...
        charlesreid1.blue-src/
            ...

```
mkdir -p /www/charlesreid1.blue
mkdir -p /www/charlesreid1.blue/htdocs
```

To make the 





Clone a local copy of the site repo (charlesreid1-src),
check out a copy of the gh-pages branch,
and bind mount it into the container.

Updating the site is a simple as 
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
