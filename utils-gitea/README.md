# Gitea Dump/Restore Scripts

Fortunately, gitea provides a `gitea dump` command to create a backup.

Unfortunately, gitea does not provide a `gitea restore` command to restore from a backup.


## Quick Start

We provide a backup and restore script.

The backup script takes a directory as an argument,
and places two backup zip files at the specified location:

```
./backup_gitea.sh <target-dir>
```

Example:

```
$ ./backup_gitea.sh /path/to/backup/target/

$ ls /path/to/backup/target/
gitea-dump-000000.zip
gitea-avatars.zip
```

The restore script will take two zip files as inputs,
the dump zip and the avatars zip:

```
./backup_gitea.sh <gitea-dump-zip> <gitea-avatars-zip>
```

Example using some bash completion magic:

```
$ ./backup_gitea.sh /path/to/backup/target/gitea-{dump-00000,avatars}.zip
```

-----

## Dump Gitea Backup

Running the dump command creates two zip files.

The first zip file is created by gitea via `gitea dump`.

The second zip file is a directory in gitea containing user avatars 
(not backed up using the above `gitea dump` command).

### The gitea dump command

When you run `gitea dump`, gitea will create a single zip file archive
of the entire contents of the gitea site, in the current directory 
(where the `gitea dump` command was run from).

### The gitea dmp directory structure

The built-in `gitea dump` functionality will create a zip
that contains the following directory structure:

```
gitea-repo.zip
gitea-db.sql
custom/
log/
```

When the `gitea-repo.zip` folder is unzipped, it generates a `repositories/` folder
containing the contents of every git repo in the gitea site.

In a real gitea server, here is where these should go:

The `repositories/` dir should be at:

```
<gitea-base-dir>/repositories
```

The `custom/` dir should be at:

```
<gitea-base-dir>/bin/custom
```

The database file should be at:

```
<gitea-base-dir>/data/gitea-db.sql
```

The log should be at:

```
<gitea-base-dir>/log
```

If you are running gitea using docker,
`<gitea-base-dir>` will be `/data/gitea/`.

### The avatars directory

Not much to it, just create a zip file from the 
`avatars/` directory and move that zip file 
out of the container.

------

## Restore Gitea Backup

The restore script takes two separate arguments.

The first is the zip file created from the `gitea dump` command above.

The second is the zip file containing user avatars.

Not much more to it than that.

