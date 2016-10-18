#To uninstall the Docker package:
apt-get purge docker-engine

#To uninstall the Docker package and dependencies that are no longer needed:
apt-get autoremove --purge docker-engine

#delete all images, containers, and volumes
rm -rf /var/lib/docker
