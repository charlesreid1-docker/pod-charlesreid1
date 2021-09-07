# pod-charlesreid1 scripts

Contains scripts for the charlesreid1 docker pod.
Some scripts are called by Ansible, some scripts
are called by the Makefile.


# Template Scripts

These scripts are used to perform actions involving the Jinja templates.

## `apply_templates.py`

Render Jinja templates. Variable values come from environment variables.
This should be used with the `environment` file in the repo root.

## `clean_templates.py`

Cleans all rendered Jinja templates. Does not require environment variables.

This script is destructive! Be careful!


# Ansible Scripts

These scripts are used by ansible when setting up a machine
to run the charlesreid1 docker pod.

## `git_clone_www.py`

This script clones the charlesreid1.com live site contents
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


# Utilities

### `executioner.py`

This provides a utility function to display captured stdout
output as it is printed to the screen, rather than having to
wait until the command is finished to see the output.
