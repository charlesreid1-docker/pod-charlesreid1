To update the MediaWiki skin:

- See the long angry rant in the Dockerfile
- You have to rebuild the whole container. Yup, stupid.
- Rebuild the MW container while the docker pod is still running (won't effect the docker pod)
- When finished rebuilding the MW container, restart the docker pod.

The skin currently in use is in `charlesreid1-config/mediawiki/skins/Bootstrap2`

To rebuild and then restart the pod:

```
# switch to main pod directory
cd ../

# rebuild all containers
docker-compose build

# stop and start the pod
sudo service pod-charlesreid1 stop
sudo service pod-charlesreid1 start
```

To verify that the skin has correcty been installed, you can check
the skin file inside the container. First, get a shell in the container:

```
docker exec -it stormy_mw /bin/bash
```

Once inside the container, the main web directory is `/var/www/html/`,
so the skins should be in `/var/www/html/skins/`. You can use `cat` to
print the file to the screen and verify it is correct.

