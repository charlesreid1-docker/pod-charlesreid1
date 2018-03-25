# pod-charlesreid1-wiki

This repo contains a docker compose file 
for running the charlesreid1.com wiki.

The services are:
* MediaWiki (Apache + PHP + MediaWiki)
* MySQL
* phpMyAdmin

## Secrets

MySQL requires an admin password.

There are some hacky ways to deal with this.

Docker secrets is a streamlined way of dealing with this.

Procedure:

* Create a MySQL password
* Create a docker secret with the MySQL password
* Pass secret into each container that needs it
* [link](https://docs.docker.com/compose/compose-file/#short-syntax-2)


## Running

From your project directory, start up your application by running:

```
docker-compose up
```

Don't forget to run your docker-compose up command with `--build` 
if you have already built the image previously, otherwise it will 
run the old image which may have not included the RUN a2enmod
rewrite statement.

## Links

docker compose documentation:

* [set environment variables in containers](https://docs.docker.com/compose/environment-variables/#set-environment-variables-in-containers)
* [docker secrets](https://docs.docker.com/engine/swarm/secrets/)
* [getting started](https://docs.docker.com/compose/gettingstarted/#step-4-build-and-run-your-app-with-compose)

