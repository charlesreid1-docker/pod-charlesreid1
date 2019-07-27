# Quick Start

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
./restore_gitea.sh <gitea-dump-zip> <gitea-avatars-zip>
```

Example using some bash completion magic:

```
$ ./restore_gitea.sh /path/to/backup/target/gitea-{dump-00000,avatars}.zip
```

