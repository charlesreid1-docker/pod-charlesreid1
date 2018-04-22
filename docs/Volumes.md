# Volumes

## Persistent Data Volumes

docker-compose volumes are mostly persistent, but they can
be deleted relatively easily.

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

To see the current list of docker volumes:

```
docker volume ls
```

You can also interact with the volumes individually
this way. Run `docker volume` for help.

-----

## nginx

The nginx service does not have any data volumes, 
but has several static files that are bind-mounted.
Most importantly, nginx handles the SSL certificates
for all subdomains.

-----

### nginx + lets encrypt ssl certificates

Rather than fuss with getting the letsencrypt 
docker image working, we made SSL certs by hand.

See [git.charlesreid1.com/charlesreid1/certbot](https://git.charlesreid1.com/charlesreid1/certbot)

Certbot will put the SSL certificates into
`/etc/letsencrypt/live/example.com`.

We bind-mount the entire `/etc/letsencrypt` directory
into the same location in the nginx container 
(see this volumes line in `docker-compose.yml`):

```
      - "/etc/letsencrypt:/etc/letsencrypt"
```

To renew certificates (every few months), just run the certbot script in the certbot repo.

### nginx static content

The main site hosted by nginx (charlesreid1.com) is served up 
from a directory of static content under version control.

This static content is bind-mounted and lives on the host 
(no data volume is used for nginx).

On the host, static site contents are stored at `/www/` 
with a directory structure and corresponding permissions
as follows:

```
/www/                                   # <-- owned by regular user

    charlesreid1.blue/                  # <-- owned by regular user
        charlesreid1.blue-src/          # <-- owned by regular user
            <pelican files>
        htdocs/                         # <-- owned by www-data
            <web site static contents>

    charlesreid1.red/                   # <-- owned by regular user
        charlesreid1.red-src/           # <-- owned by regular user
            <pelican files>
        htdocs/                         # <-- owned by www-data
            <web site static contents>

    charlesreid1.com/
        charlesreid1.com-src/
            <pelican files>
        htdocs/
            <web site static contents>

    ...
```

Each domain has its own directory, in which there is a source directory 
(git repository containing pelican files) and an htdocs directory
(git repository containing live hosted static content).

These are mounted in the container at the same location.
See the volumes section of the nginx container:

```
      - "/www/charlesreid1.blue/htdocs:/www/charlesreid1.blue/htdocs:ro"
      - "/www/charlesreid1.red/htdocs:/www/charlesreid1.red/htdocs:ro"
      - "/www/charlesreid1.com/htdocs:/www/charlesreid1.com/htdocs:ro"
```

The source and htdocs directories are separate branches of the same repo.
Each website has (TODO: will have) its own repository.

The `master` branch contains the source code for that repository,
mainly pelican files plus html/css/js.

The `pages` branch contains the static content to be hosted 
by the nginx web server.

Ownership makes dealing with this stuff a pain in the ass.
The `htdocs` dir must be owned/updated by `www-data`, 
so you need to update the git repo contents as that user:

```
sudo -H -u www-data git pull origin pages
```

### nginx bind-mounted files

We bind-mount a directory `conf.d` containing 
nginx configuration files into the container 
at `/etc/nginx/conf.d`, which is where nginx
automatically looks for and loads configuration 
files.

The custom nginx configuration files are split up
by protocol and subdomain, and can be found 
in the [d-nginx-charlesreid1](https://git.charlesreid1.com/docker/d-nginx-charlesreid1)
repository. From the `docker-compose.yml` file
nginx volumes directive:

```
      - "./d-nginx-charlesreid1/conf.d:/etc/nginx/conf.d:ro"
```

### other nginx bind-mounted files

The last remaining nginx file that is bind-mounted into the container
is `/etc/localtime`, which ensures our webserver's timestamps match 
the host's. In the nginx volumes directive:

```
      - "/etc/localtime:/etc/localtime:ro"
```

-----

## mysql

The MySQL database container is used by MediaWiki 
and stores its data on disk in a data volume.
Inside the conatiner all MySQL data lives at

```
/var/lib/mysql
```

This is mapped to a data volume, `stormy_mysql_data`.

There is no custom configuration of the MySQL database
at this time, but to add a custom config file,
mount it in the container via bind-mounting
by adding this to the volumes section of 
`docker-compose.yml`:

```
      - "./d-mysql/krash.mysql.cnf:/etc/mysql/conf.d/krash.mysql.cnf"
```

-----

## mediawiki

### mediawiki data volume

The MediaWiki container hosts all wiki files
from `/var/www/html` (in the MediaWiki container).

When the container is built from the Dockerfile, 
most of the customized MediaWiki files are copied
into the data volume. These include:

* `LocalSettings.php` - MediaWiki config file
* `skins/` directory
* `extensions/` directory

MediaWiki files are kept under version control in the 
[d-mediawiki](https://git.charlesreid1.com/docker/d-mediawiki)
repo.

The MediaWiki container uses a data volume called 
`stormy_mw_data`, which is mounted at `/var/www/html`
inside the container.

The docker-compose file takes care of creating the data volume.

### mediawiki bind-mounted files

(TODO: ambiguous how skins dir is mounted;
copying skins into container in Dockerfile,
and bind-mounting bootstrap2 at runtime.)

MediaWiki skins are kept under version control
in the [d-mediawiki](https://git.charlesreid1.com/docker/d-mediawiki)
repo.

The Bootstrap2 MediaWiki skin is bind-mounted into the container
at `/var/www/html/skins/Bootstrap2/`.

If you make changes to the skin or MediaWiki config files,
update the MediaWiki docker image as follows:

```
docker-compose build
docker-compose down
docker-compose up
```

-----

## gitea

### gitea data volume

### gitea bind-mounted files

-----

## python file server

### pyfiles directory

