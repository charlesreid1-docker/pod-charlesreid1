# MediaWiki Configuration Details

This describes the container-specific
details of the MediaWiki part of the 
Apache-MediaWiki container.

Also see [Apache + PHP](/Service_apachephp.md).

## The Container

This is based on a MediaWiki container image
that runs MediaWiki, PHP, and Apache all in one 
container.

The Apache server is reverse-proxied by nginx 
in the final pod configuration.

## Configuration Files and Folders

To set up the MediaWiki container,
we have to copy in the following files:

* One configuration file `LocalSettings.php`
* Two directories:
    * `extensions/`
    * `skins/`

Both `LocalSettings.php` and `skins/` are 
under version control.

The `extensions/` directory is assembled
from git repositories directly,
and so is not under version control.

## Where Does Stuff Live?

The `LocalSettings.php` file and `skins/` folder
live in the `d-mediawiki` submodule
(see [docker/d-mediawiki](https://git.charlesreid1.com/docker/d-mediawiki)
on git.charlesreid1.com),
in the `charlesreid1-config`
sub-submodule (see [wiki/charlesreid1-config](https://git.charlesreid1.com/wiki/charlesreid1-config)
on git.charlesreid1.com),
in the `mediawiki/` directory.

That's also where the `extensions/`
directory goes. There is also 
a script there called `build_extensions_dir.sh`
to clone copies of each MediaWiki extension.

Inside the MediaWiki container,
the live HTML directory is at 
`/var/www/html/`. That is where
`LocalSettings.php`, `skins/`, and `extensions/`
live in the container.

The `/var/www/html/` directory is
marked as a `VOLUME` in the Dockerfile
and is the mount point for a
docker data volume, `stormy_mediawiki_data`.

See [wiki/charlesreid1-config](https://git.charlesreid1.com/wiki/charlesreid1-config)
on git.charlesreid1.com.

## Getting Stuff Into The Container

The configuration files mentioned above
(LocalSettings, skins, and extensions)
must be coiped into the container at build time.

This is done in the MediaWiki Dockerfile - 
see [d-mediawiki](https://git.charlesreid1.com/docker/d-mediawiki).

Why don't we bind-mount them into the container?
We will have problems mounting files to a directory
that is itself a mount point. Since `/var/www/html/`
is a mount point for the MediaWiki container's data volume,
to keep the wiki's files persistent, 
we can't also bind-mount files at 
`/var/www/html/.`

Additionally, we have to change the permissions of 
`LocalSettings.pp` to 600 and change the ownership 
of all files in `/var/www/html/` to `www-data:www-data`,
the Apache web server user, so that it can 
serve up the wiki.

`LocalSettings.php` is copied into the container
at `/var/www/html/LocalSettings.php`.

`skins/` is copied into the container at 
`/var/www/html/skins/` (we use our own
customized theme, in the Bootstrap2 directory).

`extensions/` is copied into the container
at `/var/www/html/extensions/` 
(make sure you run `build_extensions_dir.sh` first!).

[`build_extensions_dir.sh`](https://git.charlesreid1.com/wiki/charlesreid1-config/src/branch/master/mediawiki/build_extensions_dir.sh)

## Enabling MediaWiki Math

Note that we have one last task to complete,
and that is enabling the math extensions so that 
we can add formulas to our wiki.

To do this, we have to add the following aptitude
packages to an `apt-get install` command in the 
Dockerfile:

```
RUN apt-get update && \
    apt-get install -y build-essential \
            dvipng \
            ocaml \
            ghostscript \
            imagemagick \
            texlive-latex-base \
            texlive-latex-extra \
            texlive-fonts-recommended \
            texlive-lang-greek \
            texlive-latex-recommended
```

(Note: ocaml is a language required to make
`texvc`, covered below.)

Next, we need to shim a make command 
into the container's entrypoint command,
before we run the Apache web server.

To enable equations and math, we need to make
a utility called `texvc` by running `make` in the 
Math extension directory. 

We modify the `CMD` directive in the Dockerfile,
which normally runs `apache2-foreground` 
in the stock MediaWiki container.

Change the original `CMD` from this:

```
CMD apache2-foreground
```

to this:

```
CMD cd /var/www/html/extensions/Math/math && make && apache2-foreground
```

## Updating Skin or LocalSettings.php

Note that if you update the MediaWiki skin 
or the LocalSettings.php file, 
you will need to rebuild the container
and restart it.

(It's a pain in the ass, but hard to avoid.)

Alternatively, you can use `docker cp` to
copy a new `LocalSettings.php` or 
skins directory into the running
MediaWiki container. These changes
will be reflected immediately in the 
wiki interface.

(Be careful with this method!!!)

Best of all possible worlds:
your `LocalSettings.php`
and `skins/` directory
is under version control,
as in [wiki/charlesreid1-config](https://git.charlesreid1.com/wiki/charlesreid1-config)
on git.charlesreid1.com,
and can be updated with a 
git push or git pull.

(This is not currently how
it is structured, as the 
skin and LocalSettings.php
files are not under version 
control in the container. 
This would be difficult for 
the same reason that it is 
difficult to bind-mount
a file directly into 
`/var/www/html` - because
it is also difficult 
to have a particular 
file under version control
when there are a 
large number of other files
in that directory.)

## A Way Out? A Path Forward? A Glimmer of Hope?

How might we fix this nested, nightarish mess?

A couple of things have to happen:

* Docker needs to provide better control over user ownership
    and file permissions for bind-mounted directories.
    There are some really ugly, hacky shims that are 
    required because the user permissions of everything
    are buggered from the start.

* MediaWiki needs to put user configuration files
    into a configuration folder. For example, 
    `nginx` looks in a folder `/etc/nginx/` for 
    any and all configuration files. This allows
    bind-mounting a configuration directory 
    to `/etc/nginx/` without complication.
    Unfortunately, MediaWiki mixes site-specific user files
    with generic, common-across-all-MediaWikis
    php files, making it difficult to version-control
    site-specific user files.

## Utilities

There are utilities for MediaWiki in `utils-mw`:

* `backup_wikifiles.sh` - back up wiki image files to a tarball
* `restore_wikifiles.sh` - restore backed up image files from a tarball
* `update_wikidb.sh` - one-time script to update the wiki database after a version bump

