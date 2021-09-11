# myqsl utilities

These scripts use docker exec to run scripts inside the 
running MySQL container.

## dump database

Use the `dump_database.sh` script to create a backup dump of the database:

```
       ./dump_database.sh <sql-dump-file> 
```

Example: 
 
```
       ./dump_database.sh /path/to/wikidb_dump.sql 
```

## restore database

Use the `restore_database.sh` script to restore the database from a dump file:

```
       ./restore_database.sh <sql-dump-file>
```

Example:

```
       ./restore_database.sh /path/to/wikidb_dump.sql"
```

