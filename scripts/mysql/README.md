# myqsl utilities

These scripts use docker exec to run scripts inside the 
running MySQL container.

## dumping to backups

To create backups, use the `dump_database.sh` script,
and point it to a dumpfile to create:

```
dump_database.sh script: 
Dump a database to an SQL dump. 
 
       ./dump_database.sh <sql-dump-file> 
 
Example: 
 
       ./dump_database.sh /path/to/wikidb_dump.sql 
```

## restoring from backups

```
restore_database.sh script:
Restores a database from an SQL dump.

       ./restore_database.sh <sql-dump-file>

Example:

       ./restore_database.sh /path/to/wikidb_dump.sql"
```

