# Secrets

## MySQL Password

The MySQL password has to get into the MySQL 
and MediaWiki containers. To do this, we 
hard-code the MySQL password as an environment
variable in `docker-compose.yml`.

The file `docker-compose.fixme.yml` contains 
the placeholder `REPLACEME` where the MySQL 
password goes. 

To create a `docker-compose.yml` 
from `docker-compose.fixme.yml`:

```
$ sed "s/REPLACEME/YoFooThisIsYourNewPassword/" docker-compose.fixme.yml > docker-compose.yml
```

Great if you hard-code the password, but - 
wasn't that the whole thing 
we were trying to avoid?

Put the password into a file istead, 
then grab the password from that file
and do a find/replace on the docker 
compose file:

```
$ cat root.password
mysecretpassword

$ sed "s/REPLACEME/`cat root.password`/" docker-compose.fixme.yml > docker-compose.yml
```

The `docker-compose.yml` file and `root.password` files are both ignored 
by version control.

## Nginx SSL Certificates

The other secrets we need to get into the container are
the SSL certificates for the nginx container.

To generate the SSL certificates using Let's Encrypt,
use the script in the [certbot](https://git.charlesreid1.com/charlesreid1/certbot)
directory. These will be stored on the host machine
at `/etc/letsencrypt/live/example.com/*`.

To mount the certificates in the directory,
we bind-mount the entire `/etc/letsencrypt/` directory
into the container with the following line 
in the docker-compose file:

```
services:
  ...
  stormy_nginx:
    ...
    volumes:
      - "/etc/letsencrypt:/etc/letsencrypt"
    ...
``` 

Meanwhile, in the nginx configuration file 
that's mounted into the container, we have
the following in the SSL server blocks
(see [docker/d-nginx-charlesreid1](https://git.charlesreid1.com/docker/d-nginx-charlesreid1)):

```
server {
    # https://charlesreid1.com
    listen 443;
    listen [::]:443;
    server_name charlesreid1.com;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/charlesreid1.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/charlesreid1.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;

    ...
}
```

