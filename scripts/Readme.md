# pod-charlesreid1 scripts

Contains useful scripts for setting up and maintaining
the charlesreid1.com docker pod.

## TODO

Update:

- jinja templates
- apply template scripts
- executioner
- forever tasks and forever loops


## `dockerpod-charlesreid1.service`

This .service script is a systemd startup script that
is installed with pod-charlesreid1. This makes it 
possible to run the pod as a startup service.

## `git_clone_www.sh`

This script clones the charlesreid1.com live site contents
(under version control as the `gh-pages` branch of the
repo <https://git.charlesreid1.com/charlesreid1/charlesreid1.com>
and mirrored at 
<https://github.com/charlesreid1-docker/charlesreid1.com>)
to the directory `/www/` with the following directory
layout:

```
/www/charlesreid1.com/
                charlesreid1.com-src/   <-- clone of charlesreid1.com repo, src branch
                git/            <-- .git dir for charlesreid1.com repo gh-pages branch
                git.data/       <-- .git dir for charlesreid1-data
                htdocs/         <-- clone of charlesreid1.com repo gh-pages branch
                    data/       <-- clone of charlesreid1-data
```

## `git_pull_www.sh`

This script pulls the latest changes from the
`gh-pages` branch in the `/www/` folder cloned
with the `git_clone_www.sh` script.

## `git_clone_data.sh`

This clones the data repository (under version control
at <https://git.charlesreid1.com/data/charlesreid1>)
into the `/www` folder cloned with the `git_clone_www.sh`
script.

## `git_pull_data.sh`

This script pulls the latest changes to the
charlesreid1-data repository and updates the
`data/` folder in the `/www/charlesreid1.com/htdocs`
folder.

