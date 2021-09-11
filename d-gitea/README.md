# d-gitea

This directory contains files for the gitea docker container
in the charlesreid1 docker pod.

See [pod-charlesreid1](https://git.charlesreid1.com/docker/pod-charlesreid1).

## Custom Directory

The custom directory contains the gitea configuration file, plus any other
custom files Gitea might need.

The `custom` directory is bind mounted to `/data/gitea` inside the container.

## Data Directory

The data directory contains any instance-specific gitea data.

The data directory is bind-mounted to `/app/gitea/data` in the container.

## Repository Drive

Gitea stores all of its repositories in a separate drive that is at
`/gitea_repositories` on the host machine.

The gitea repositories drive is bind-mounted to `/data/git/repositories` in the container.

### Rendering app.ini Template

The gitea configuration file is located at `custom/conf/app.ini`.

The app.ini configuration file is not provided, only a template is provided.
Use the top-level pod-charlesreid1 Makefile and scripts to render templates.
Use the top-level environment file to set variable values.
