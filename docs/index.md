# pod-charlesreid1

This repo contains a docker compose file 
for running the charlesreid1.com site.

The services are:

* [mediawiki](Service_mediawiki.md)
* [apache + php](Service_apachephp.md)
* [mysql](Service_mysql.md)
* [phpmyadmin](Service_phpmyadmin.md) (in progress)
* [nginx + ssl](Service_nginx.md) (in progress)
* [python](Service_pythonfiles.md) (in progress)
* [gitea](Service_gitea.md) (in progress)


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

See **[Backups.md](/Backups.md)** for coverage of backup and utility scripts.

`utils-backups` - backup utilities (use the scripts below; good for cron jobs)

`utils-mw` - mediawiki backup utilities

`utils-mysql` mysql backup utilities

## Domains and Ports

See **[Ports.md](/Ports.md)** for info about top-level domain names
and ports used by this docker pod.

The domains ports document covers:

* Domains
    * nginx domain handling
* Ports
    * nginx ports
    * mediawiki/apache ports
    * phpmyadmin ports
    * mysql ports
    * gitea ports
    * python file server ports

## Secrets

See **[Secrets.md](/Secrets.md)** for more info about getting secrets like 
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
