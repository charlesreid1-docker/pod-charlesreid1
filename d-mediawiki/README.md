# d-mediawiki

This directory contains files used to run the MediaWiki container
for the charlesreid1.com wiki. The MediaWiki container consists of
a PHP-enabled Apache web server serving the MediaWiki application,
and storing data in a MySQL database (different container).

See [pod-charlesreid1](https://git.charelsreid1.com/docker/pod-charlesreid1).

## Directory Layout

This directory contains `charlesreid1-config`, which has both
MediaWiki and Apache configuration files.

## Creating Extensions Directory





## Summary

This directory contains a Dockerfile that modifies the 
official MediaWiki docker container. Before launching
the container, it specifies `/var/www/html` as a mounted volume, 
and it copies `LocalSettings.php`, the MediaWiki config file, 
from this repo into the container.

See [d-mysql repo](https://charlesreid1.com:3000/docker/d-mysql).

Also see [pod-charlesreid1](https://git.charlesreid1.com/docker/pod-charlesreid1.git)
for a working pod using this container.

## Docker Compose

To use this container as part of a pod, as with the charlesreid1.com wiki, 
see [pod-charlesreid1-wiki](https://charlesreid1.com:3000/docker/pod-charlesreid1-wiki).

## Troubleshooting

If you are seeing 404s on every page you try, it may be because 
your MediaWiki config file is set to redirect you to `/wiki/Main_Page`
but your web server is not set up to handle it.

See [this lin](https://www.mediawiki.org/wiki/Manual:Short_URL)
and the guide for [apache](https://www.mediawiki.org/wiki/Special:MyLanguage/Manual:Short_URL/Apache)
and [nginx](https://www.mediawiki.org/wiki/Special:MyLanguage/Manual:Short_URL/Nginx).


## Updating Settings

The LocalSettings.php file must be copied into the 
container, because we will end up bind-mounting the 
entire MediaWiki directory when the container is run
and we can't bind-mount a file inside a bind-mounted
directory.

Thus, to update LocalSettings.php, skins, or extensions,
you will need to re-make the Docker container.
Use the make rules to remake the Docker container:

```
make clean
make build
make run
```

## Submodule

The submodule `charlesreid1-config/`
contains configuration files for both
MediaWiki and Apache.

See the [wiki/charlesreid1-config](https://git.charlesreid1.com/wiki/charlesreid1-config)
repo for details.

To clone the submodule when you clone the repo,
include the `--recursive` flag:

```
git clone --recursive https://git.charlesreid1.com/docker/d-mediawiki.git
```

To check out the submodule after a shallow clone:

```
git submodule init
# or 
git submodule update --init 
```

To fetch changes to the submodule from the submodule's remote:

```
git submodule update --remote
```

