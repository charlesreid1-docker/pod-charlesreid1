To block IP address:

* Modify the nginx config file template at 
  `d-nginx-charlesreid1/conf.d/https.DOMAIN.conf.j2`
* Re-render the Jinja templates into config files via
  `make clean-templates && make templates`
* Stop and restart the pod service:
  `sudo systemctl stop pod-charlesreid1 && 
  sudo systemctl start pod-charlesreid1`
