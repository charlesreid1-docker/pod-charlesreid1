# backup scripts

This directory contains several files for several services:

* Systemd .service file (Jinja template) to define a service that backs up files
* Systemd .timer file (Jinja template) to define a timer that runs the service on a schedule
* Shell script .sh that actually performs the backup operation and is called by the .service file

Use `make templates` in the top level of this repo to render
the Jinja templates using the environment variables in the
evnrionment file. That fixes the locations of the scripts
for the systemd service.

Use `make install` in the top level of this repo to install
the rendered service and timer files.
