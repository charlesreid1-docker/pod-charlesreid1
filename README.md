# pod-charlesreid1

This repo contains a docker compose file 
for running the charlesreid1.com site.

See the documentation site here: <https://pages.charlesreid1.com/pod-charlesreid1>

Or visit [docs/index.md](/docs/index.md)

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

## Backups

There are a number of directories containing utility scripts - these are mostly 
dedicated to creating backups of any non-version-controlled data inside the container.

See **[Backups.md](Backups.md)** for coverage of backup and utility scripts.

`utils-backups` - backup utilities (use the scripts below; good for cron jobs)

`utils-mw` - mediawiki backup utilities

`utils-mysql` mysql backup utilities

## Domains

Domains and ports setup is described in the
[Domains and Ports](Ports.md) document. It covers:

* Domains
    * nginx domain handling
* Ports
    * nginx ports
    * mediawiki/apache ports
    * phpmyadmin ports
    * mysql ports
    * gitea ports
    * python file server ports

### Additional Port Info

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

Subdomains are served via reverse proxy on port 7777+. 

The webhook server is a flask server listening on port 50000.


## Secrets

See **[Secrets.md](Secrets.md)** for more info about getting secrets like 
passwords and sensitive files into various containers in the pod,
without leaking out the information.

* mysql database root password
* mediawiki mysql database root password
* gitea secret key and session id
* nginx ssl certificates

## Container-Specific Configuration Details

Each container has a different way of getting
configuration files into the container.
In the following documents we cover 
the specifics of each container.

* [mediawiki](Service_mediawiki.md)
* [apache + php](Service_apachephp.md)
* [mysql](Service_mysql.md)
* [phpmyadmin](Service_phpmyadmin.md) 
* [nginx + ssl](Service_nginx.md)
* [python](Service_pythonfiles.md)
* [gitea](Service_gitea.md)


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
