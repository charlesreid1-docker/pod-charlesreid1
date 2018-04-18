# TODO

- network overlay
    - nginx can't reverse proxy to 10.5.0.2 b/c doesn't see it
    - need to have two networks:
        - one virtual private network set up by docker (default)
        - one host network only connected to nginx container

- extras in containers:
    - fail2ban
    - log rotation
    - log backups
- netdata on krash?
- plugging docker-compose into netdata?
- disk space
    - canary script
    - finer grained control and understanding of fs usage

- <s>rebuild and restart for slimmer python files container</s>
- <s>logging? messages? status?
    - want to avoid a few things:
    - giant pileup of gigabytes of logs, getting bit in the ass
    - giant pileup of container stuff, completely running out of space
    - second almost happened, at 97% or so</s>
