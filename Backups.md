# Backups

By competely containerizing charlesreid1.com,
all of the static files for running programs
come from docker container images, 
and all configuration files 
come from git repositories under version control at
[git.charlesreid1.com/docker](https://git.charlesreid1.com/docker).

That just leaves the core data for each service,
which is what the backup and restore scripts handle.
This service data consists of the following:

* MediaWiki MySQL database dump (.sql)
* MediaWiki images directory (.tar.gz)
* Gitea repository dump (.zip)
* Gitea avatar images (.zip)

These four files form a "seed" for charlesreid1.com.

## MySQL Backup/Restore Scripts

To create a MySQL backup, use the `utils-mysql/dump_database.sh` script.

```
dump_database.sh script:
Dump a database to an .sql file 
from the stormy_mysql container.

       ./dump_database.sh <sql-dump-file>

Example:

       ./dump_database.sh /path/to/wikidb_dump.sql

```

## MediaWiki Backup/Restore Scripts



```
backup_wikifiles.sh script:
Create a tar file containing wiki files
from the stormy_mw container

       ./backup_wikifiles.sh <tar-file>

Example:

       ./backup_wikifiles.sh /path/to/wikifiles.tar.gz
```

## Gitea Backup/Restore Scripts



# Utilities

## MySQL Utilities

## MediaWiki Utilities

## MySQL Utilities

