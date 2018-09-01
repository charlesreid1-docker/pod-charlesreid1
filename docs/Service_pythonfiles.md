# Python File Server

This page describes how pod-charlesreid1 provides a lightweight
HTTP file server that is reverse-proxied by nginx to provide
a dead-simple file hosting service at `files.charlesreid1.com`.

We use an alpine container with Python 3 for a minimal image
size. Python comes with a simple HTTP server built-in that 
will do the job for us, available through the `http.server`
module (or `SimpleHTTPServer` in Python 2):

```
python3 -m http.server 8081
```

We expose this to port 8081 locally, making the service available
on the Docker network and therefore available to be reverse-proxied
by the nginx container.

Files to be served up are located in `/www/files/` on the host,
which is bind-mounted to `/files` in the container.

