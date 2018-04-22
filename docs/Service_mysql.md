# MySQL Configuration Details

This is the most important part of the MediaWiki
portion of the charlesreid1 pod. MediaWiki stores
all of the content of the MediaWiki server,
so the MediaWiki and MySQL containers must 
communicate with one another.

## The Container

The MySQL container is straightforward, 
nothing fancy.

## Configuration Files and Folders

We don't have an extensive MySQL configuration.
The container demostrates how to mount a configuration
file into the container, but this is optional.

## Getting Stuff Into The Container (How To Seed MySQL?)

This section refers to scripts contained in 
the `utils-mysql` directory.

The MySQL data must come from a seed
(what we call a krash seed). This seed
consists of a prior backup of the MediaWiki
MySQL database, from which the database
can be restored.

There are both backup and restore scripts
in the repo under `utils-mysql`.

Running the `mysqldump` tool will dump 
database backup files in `.sql` format.
These can be created using the `dump_database.sh`
script.

These `.sql` files can be used to restore a 
MySQL database using the `restore_database.sh`.


## Utilities

There are utilities for MySQL in `utils-mysql`:

* `dump_databases.sh` - create an `..sql` dump file from a database
* `restore_database.sh` - restore a database from an `.sql` dump file



