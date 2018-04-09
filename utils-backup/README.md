# backup utilities

-----

## daily 

Daily scripts maintain a rolling 7-day backup of files.

These go into the directory:

```
<backup-dir>/backups/daily/
```

### daily mysql

Daily MySQL backups of the wikidb database go into:

```
<backup-dir>/backups/daily/wikidb_YYYY-MM-DD/wikidb.sql
```

### daily mediawiki

Daily backups of MediaWiki images folder go into:

```
<backup-dir>/backups/daily/wikifiles_YYYY-MM-DD/wikifiles.tar.gz
```

### daily gitea

Daily backups of Gitea dump and avatars go into:

```
<backup-dir>/backups/daily/gitea_YYYY-MM-DD/gitea-dump-*.zip
<backup-dir>/backups/daily/gitea_YYYY-MM-DD/gitea-avatars.zip
```



-----

## weekly

Daily scripts maintain a rolling 7-day backup.

### weekly mysql wikidb

Weekly MySQL backups of the wikidb database go into `wikidb`:

```
<backup-dir>/backups/weekly/wikidb_YYYY-MM-DD/wikidb.sql
```

with monthly backups from the last Sunday of the month going into:

```
<backup-dir>/backups/monthly/wikidb_YYYY-MM-DD/wikidb.sql
```

### weekly mediawiki files

Weekly mediawiki backups of the images folder go into `wikifiles`:

```
<backup-dir>/backups/weekly/wikifiles_YYYY-MM-DD/wikifiles.tar.gz
```

with monthly backups from last Sunday of month going into:

```
<backup-dir>/backups/monthly/wikifiles_YYYY-MM-DD/wikifiles.tar.gz
```

### weekly gitea

Weekly backups of Gitea dump and avatars go into:

```
<backup-dir>/backups/weekly/gitea_YYYY-MM-DD/gitea-dump-*.zip
<backup-dir>/backups/weekly/gitea_YYYY-MM-DD/gitea-avatars.zip
```

with monthly backups going into:

```
<backup-dir>/backups/monthly/gitea_YYYY-MM-DD/gitea-dump-*.zip
<backup-dir>/backups/monthly/gitea_YYYY-MM-DD/gitea-avatars.zip
```



