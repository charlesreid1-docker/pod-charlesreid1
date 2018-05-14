# Dump Gitea Backup

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


