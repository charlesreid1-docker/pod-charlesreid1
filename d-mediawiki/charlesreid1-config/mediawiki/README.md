# mediawiki config files

In the `LocalSettings.php` file, which needs to have the MySQL
account credentials, we have the following:

```
## Database settings
$wgDBtype = "mysql";
$wgDBserver = getenv('MYSQL_HOST');
$wgDBname = getenv('MYSQL_DATABASE');
$wgDBuser = getenv('MYSQL_USER');
$wgDBpassword = getenv('MYSQL_PASSWORD');
```

This information comes from the environment. In our case,
this comes from a MediaWiki docker container (see the
[d-mediawiki](https://git.charlesreid1.com/docker/d-mediawiki)
repo.)
