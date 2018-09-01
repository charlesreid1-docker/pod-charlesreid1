# Gitea

Gitea is a self-hosted Github clone. It is written in Go, and 
provides a web interface and an API to interact with an instance
of a git server.

Gitea manages its own database, so to get data in and out of
Gitea, use its dump and load functionality (more below).

This page describes how the Gitea container is configured.

## Configuring Docker Container

To run gitea, we use a stock Gitea container image. We set
several options in the docker configuration:

* `USER_UID` and `USER_GID` are set to `1000` (this avoids some
  problems with files that would otherwise be owned by root)

* Set `restart: always` to restart the container when there
  is a failure

```
  stormy_gitea:
    image: gitea/gitea:latest
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
```

## Gitea Volumes

The Gitea container stores all of its data in `/data/` inside
the container.

When the container is launched, the `custom/` directory in
the [docker/d-gitea](https://git.charlesreid1.com/docker/d-gitea)
repository is mounted to `/data/gitea/`, which is the directory
that contains the files that are used to control the way that
Gitea pages look. These contain HTML templates used to render
different views in Gitea and templates in `custom/` will override
the default Gitea page templates.

A docker volume named `stormy_gitea_data` is also created and 
mounted at `/data/`. This is a persistent volume that will 
survive even if the container is shut down.

```
    volumes:
      - "stormy_gitea_data:/data"
      - "./d-gitea/custom/conf/app.ini:/data/gitea/conf/app.ini"
      - "./d-gitea/custom/public:/data/gitea/public"
      - "./d-gitea/custom/templates:/data/gitea/templates"
```

## Gitea Ports

Gitea provides both SSH and HTTPS interfaces, as it has its own
built-in web server and SSH server, as well as git server.

The server that is hosting the Gitea container and this Docker
pod already has an SSH server listening on port 22, so Gitea
listens for SSH connections _externally_ on port 222.

```
    ports:
      - "222:22"
```

Note that this _bypasses_ our d-nginx-charlesreid1 nginx container
entirely and allows clients to connect to Gitea directly.

The Gitea server listens for HTTP/HTTPS connections on port
3000, but that is by default only listening on the internal
Docker network, which is exactly how we want it. We want all
HTTP and HTTPS traffic to be handled by the front-end d-nginx-charlesreid1
container, and it will reverse-proxy HTTP/HTTPS requests to 
the Gitea container.

## Gitea Configuration Files

`app.ini` is the name of the configuration file used by Gitea.
An [example `app.ini` configuration file](https://git.charlesreid1.com/docker/d-gitea/src/branch/master/app.ini.sample) 
is contained in the [docker/d-gitea](https://git.charlesreid1.com/docker/d-gitea)
repository, as well as a script to
[make a configuration file](https://git.charlesreid1.com/docker/d-gitea/src/branch/master/make_app_ini.sh).

```
    volumes:
      - "stormy_gitea_data:/data"
      - "./d-gitea/custom/conf/app.ini:/data/gitea/conf/app.ini"
```


## Backups

### Backing Up Gitea

### Restoring Gitea



