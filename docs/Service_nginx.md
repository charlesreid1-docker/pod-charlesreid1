# Nginx

This describes the configuration of the main nginx container
for the charlesreid1.com pod.

<br />
<br />

## Configuration Files

The nginx container is critical to routing operations on
charlesreid1.com, so we cover how the configuration files
are split up and organized on this page, and include
a summary of each file below.


### Where are the nginx config files?

Nginx configuration files are located in the `d-nginx-charlesreid1`
submodule of this repository, which points to the
[docker/d-nginx-charlesreid1](https://git.charlesreid1.com/docker/d-nginx-charlesreid1)
repository.

Within that repository is the [`conf.d/`](https://git.charlesreid1.com/docker/d-nginx-charlesreid1/src/branch/master/conf.d)
folder, which contains several `.conf` files.


### What Files Are There?

We have three sets of files present:

HTTP config files that redirect HTTP traffic on port 80 to
be HTTPS traffic on port 443, one for each top-level domain
(charlesreid1.com, charlesreid1.blue, and charlesreid1.red):

* `http.com.charlesreid1.conf`
* `http.red.charlesreid1.conf`
* `http.blue.charlesreid1.conf`

HTTPS rules for charlesreid1.com endpoints (the wiki,
phpMyAdmin, and ignoring `.git` directories):

* `https.com.charlesreid1.conf`
* `https.red.charlesreid1.conf`
* `https.blue.charlesreid1.conf`

HTTPS rules for subdomains (pages.charlesreid1.com,
hooks.charlesreid1.com, bots.charlesreid1.com):

* `https.com.charlesreid1.subdomains.conf`
* `https.red.charlesreid1.subdomains.conf`
* `https.blue.charlesreid1.subdomains.conf`


### HTTP Config Files

The HTTP config files are listed below:

* `http.com.charlesreid1.conf`
* `http.red.charlesreid1.conf`
* `http.blue.charlesreid1.conf`

The HTTP config files do the following:

* Requests for port 80 (for a domain or subdomain) are always redirected
  to port 443 for the same domain/subdomain


### HTTPS Config Files

The HTTPS config files are listed below:

* `https.com.charlesreid1.conf`
* `https.red.charlesreid1.conf`
* `https.blue.charlesreid1.conf`

The HTTPS config files (without "subdomain" in their name) do the following:

* Requests for `/` are redirected to the htdocs folders mentioned above

* Requests for `/w/` or `/wiki/` are reverse-proxied to the local
  [Apache+PHP container](Service_apachephp.md) on port 8989

* (Optional) requests for `/phpMyAdmin/` are reverse-proxied to the local
  [phpMyAdmin container](Service_phpmyadmin.md) on port 80

* Requests for `git.charlesreid1.com` are reverse-proxied to the local
  [Gitea container](Service_gitea.md) on port 3000

* Requests for `files.charlesreid1.com` are reverse-proxied to the local
  [Python files](Service_pythonfiles.md) on port 8081


### HTTPS Subdomain Config Files

The HTTPS subdomain config files are listed below:

* `https.com.charlesreid1.subdomains.conf`
* `https.red.charlesreid1.subdomains.conf`
* `https.blue.charlesreid1.subdomains.conf`

The subdomains config files redirect requests for a set of subdomains
on charlesreid1.com, namely:

* `pages.charlesreid1.com`
* `hooks.charlesreid1.com`
* `bots.charlesreid1.com`

This charlesreid1.com docker pod will redirect requests for these subdomains
to another server running another docker pod, called the webhook docker pod,
available at [docker/pod-webhooks](https://git.charlesreid1.com/docker/pod-webhooks)).

The webhook docker pod runs an nginx server, both to serve up static sites that live
under the <https://pages.charlesreid1.com> domain, and to handle webhook traffic - the 
container also runs a Python webhook server that receives webhooks from git.charlesreid1.com,
which enables push-to-deploy functionality similar to Github Pages.

Also see <https://pages.charlesreid1.com/pod-webhooks/>.


### Why All The Config Files?

If everything is stuffed into a smaller number of
nginx config files, they become long and unwieldy,
and more prone to mistakes.

* HTTP config files only contain redirects
* HTTPS (no subdomain) config files handle 


### Getting Configuration Files Into Container

The configuration files are mounted into the container
by bind-mounting the `conf.d` folder of the `d-nginx-charlesreid1`
submodule at `/et/nginx/conf.d` in the container.

This is done in the [charlesreid1 pod docker-compose
file](https://git.charlesreid1.com/docker/pod-charlesreid1/src/branch/master/docker-compose.fixme.yml#L57).

<br />
<br />

## Static Content

The nginx container hosts static content, in addition to serving
as a reverse-proxy for several other services. This section covers
how static content is treated by the charlesreid1.com nginx
container

### Outside the Container: `/www/`

Static content hosted by the container is stored on the host
machine in `/www/`. 

Each site (e.g., charlesreid1.com) has its own folder, containing
the source for the static site and an htdocs folder containing the
static content actually being hosted.

Additionally, because the static content for the site is actually
contained on the `gh-pages` branch of [charlesreid1/charlesreid1.com](https://git.charlesreid1.com/charlesreid1/charlesreid1.com),
the `htodcs` folder is actually a git repository. When it is
cloned, it is cloned such that the git repo's contents go into 
`/www/charlesreid1.com/htdocs/` and the contents of the `.git`
folder go into `/www/charlesreid1.com/git`.

This allows the site static content to be updated to reflect the
contents of the `gh-pages` branch by pulling the latest upstream
changes into htdocs.

The directory structure used is as follows:

```
/www
    /charlesreid1.com
        /charlesreid1-src
            ...source for pelican site... 
        /htdocs
            ...static content...
        /git
            ...dot git folder...

    /charlesreid1.blue
        /charlesreid1-blue-src
            ...source for pelican site... 
        /htodcs
            ...static content...
        /git
            ...dot git folder...

    /charlesreid1.red
        /charlesreid1-red-src
            ...source for pelican site... 
        /htodcs
            ...static content...
        /git
            ...dot git folder...

```

This directory structure can be achieved using the following 
bash command:

```
REPOURL="https://git.charlesreid1.com/charlesreid1/charlesreid1.com.git"

git -C /www/example.com \
    clone \
    --separate-git-dir=git \
    -b gh-pages \
    $REPOURL htdocs
```

The [dotfiles/debian](https://git.charlesreid1.com/debian/dotfiles)
repository contains scripts for krash, which runs the charlesreid1.com
pod, to set up the directory structure as above, as well as scripts
to pull the latest changes from upstream for each of the live
web directories above.


### Inside the Container: `/usr/share/nginx/html`

Once the contents of the `/www/` directory have been set up,
the content can be made avialable inside the container by 
bind-mounting the htdocs directories into the `/www/` directory
inside the container. This is done with the following
volume directives in the [`docker-compose.yml` file](https://git.charlesreid1.com/docker/pod-charlesreid1/src/branch/master/docker-compose.fixme.yml#L60-L62):

```
    volumes:
      - "/www/charlesreid1.blue/htdocs:/www/charlesreid1.blue/htdocs:ro"
      - "/www/charlesreid1.red/htdocs:/www/charlesreid1.red/htdocs:ro"
      - "/www/charlesreid1.com/htdocs:/www/charlesreid1.com/htdocs:ro"
      ...
```

### Utility Scripts: Updating Site Contents

In the [`krash_scripts/` folder](https://git.charlesreid1.com/dotfiles/debian/src/branch/master/dotfiles/krash_scripts)
of the debian/dotfiles](https://git.charlesreid1.com/dotfiles/debian)
repository, there are several utility scripts to help with
setting up and updating this directory structure.

To set up the directory structure, use the [`git_clone_www.sh` script](https://git.charlesreid1.com/dotfiles/debian/src/branch/master/dotfiles/krash_scripts/git_clone_www.sh).

```
#!/bin/bash

REPOURL="https://git.charlesreid1.com/charlesreid1/charlesreid1.com.git"

git -C /www/example.com \
    clone \
    --separate-git-dir=git \
    -b gh-pages \
    $REPOURL htdocs
```

To update the contents of the `htdocs/` folder using the latest changes
on the `gh-pages` branch, use the [`git_pull_www.sh` script](https://git.charlesreid1.com/dotfiles/debian/src/branch/master/dotfiles/krash_scripts/git_pull_www.sh).

```
#!/bin/bash

git -C /www/example.com \
    --git-dir=git --work-tree=htdocs \
    pull origin gh-pages
```


<br />
<br />

## Domain Control

There are three top-level domains controlled by pod-charlesreid1:

* <https://charlesreid1.com>
* <https://charlesreid1.blue>
* <https://charlesreid1.red>

There are several subdomains available on charlesreid1.com.

Hosted on krash:

* <https://git.charlesreid1.com> - gitea service
* <https://files.charlesreid1.com> - static file hosting

Hosted on blackbeard:

* <https://pages.charlesreid1.com> - push-to-deploy static pages
* <https://hooks.charlesreid1.com> - webhook server
* <https://bots.charlesreid1.com> - info about bots



