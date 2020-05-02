# Apache + PHP

This describes the container-specific
details of the Apache part of the 
Apache-MediaWiki container.

Also see [MediaWiki](Service_mediawiki.md).

## Configuration Files and Folders

We have two Apache configuration files
to set up Apache:

* `ports.conf` sets the port Apache listens on
* `wiki.conf` sets the `<VirtualHost>` block for the wiki

## Where Does Stuff Live?

The `ports.conf` and `wiki.conf` configuration files
live in the `d-mediawiki` submodule
(see [docker/d-mediawiki](https://git.charlesreid1.com/docker/d-mediawiki)
on git.charlesreid1.com),
in the `charlesreid1-config`
sub-submodule (see [wiki/charlesreid1-config](https://git.charlesreid1.com/wiki/charlesreid1-config)
on git.charlesreid1.com),
in the `apache/` directory.

See [wiki/charlesreid1-config](https://git.charlesreid1.com/wiki/charlesreid1-config)
on git.charlesreid1.com.

## Getting Stuff Into The Container

Unlike MediaWiki, Apache has a sane way
of separating the static program files
from the instance-specific configuration
files.

We bind-mount the directory containing 
Apache `*.conf` files 
into the container at 
`/etc/nginx/conf.d`
via the following line
in the [pod-charlesreid1 
docker-compose file](https://git.charlesreid1.com/docker/pod-charlesreid1/src/branch/master/docker-compose.fixme.yml):

```
services:
  ...
  stormy_nginx:
    ...
    volumes:
      - "./d-nginx-charlesreid1/conf.d:/etc/nginx/conf.d:ro"
```

That's it!

