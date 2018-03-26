# mediawiki utilities

These scripts use docker exec to run scripts inside the 
running MediaWiki container.

The main task is to import and export tar files
containing an `images/` directory.

Other files, such as skins or extensions, are installed 
in the container at build tie.

## backup wiki files 

The `backup_wikifiles.sh` scripts back up files to a tar file.
Use it as follows:

```
backup_wikifiles.sh script:
Create a tar file containing wiki files
from the stormy_mw container

       ./backup_wikifiles.sh <tar-file>

Example:

       ./backup_wikifiles.sh /path/to/wikifiles.tar.gz
```

This creates a tar file using the `images/` directory
and uses `docker copy` to copy the file out of the container
and onto the host.

## restore wiki files

The restore script takes a tar file created with the backup script,
and untars it to the wiki images directory.

```
restore_wikifiles.sh script:
Restore wiki files from a tar file
into the stormy_mw container

       ./restore_wikifiles.sh <tar-file>

Example:

        ./restore_wikifiles.sh /path/to/wikifiles.tar.gz
```

