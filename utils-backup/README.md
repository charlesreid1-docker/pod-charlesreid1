# backup utilities

-----

## daily 

Daily scripts maintain a rolling 7-day backup of files.

These go into the directory:

```
<backup-dir>/backups/daily/
```

### daily mysql

Daily MySQL backups of the wikidb database 
go into a wikidb folder:

```
<backup-dir>/backups/daily/wikidb_YYYY-MM-DD/wikidb.sql
```

### daily mediawiki



-----

## weekly

Daily scripts maintain a rolling 7-day backup.

### weekly mysql

Weekly MySQL backups of the wikidb database
go into a wikidb folder:

```
<backup-dir>/backups/weekly/wikidb_YYYY-MM-DD/wikidb.sql
```

### weekly mediawiki


