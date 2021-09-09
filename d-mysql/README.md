# d-mysql

This is the MySQL docker container used to run MySQL on charlesreid1.com.

See [pod-charlesreid1](https://git.charlesreid1.com/docker/pod-charlesreid1).

## Dockerfile

The Dockerfile is necessary to copy the MySQL root password into a file inside
the container. This file is used in automated scripts when we would have problems
getting the password via environment variables.
