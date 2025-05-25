To get a shell in a container that has been created, before it is runnning in a pod, use `docker run`:

```
docker run --rm -it --entrypoint bash <image-name-or-id>

docker run --rm -it --entrypoint bash pod-charlesreid1_stormy_mediawiki
```

To get a shell in a container that is running in a pod, use `docker exec`:

```
docker exec -it <image-name> /bin/bash

docker exec -it stormy_mw /bin/bash
```

Also, if no changes are picking up, and you've already tried rebuilding the container image, try editing the Dockerfile.
