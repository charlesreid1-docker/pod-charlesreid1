FROM mediawiki:1.39.12

EXPOSE 8989


# Install ImageMagick (used for image thumbnailing)
RUN apt-get update && \
    apt-get install -y imagemagick && \
    rm -rf /var/lib/apt/lists/*

# Copy skins, config files, and other particulars into container

# WARNING: DOCKER STUPIDITY AHEAD
# MediaWiki needs everything, everything, to be in one folder.
# Docker is totally incapable of mounting a file in a volume.
# I cannot update LocalSettings.php without clearing the cache.
# I can't bind-mount the skins dir, because then it's owned by root.
# I can't fix the fact that all bind-mounted dirs are owned by root, 
# because I can only add commands in THIS DOCKERFILE.
# and when you run the commands in this dockerfile, 
# YOU CANNOT SEE THE BIND-MOUNTED STUFF.

# Extensions (REL1_39 branches; EmbedVideo skipped for the 1.34 -> 1.39 upgrade)
COPY charlesreid1-config/mediawiki/extensions/Math                    /var/www/html/extensions/Math
COPY charlesreid1-config/mediawiki/extensions/ParserFunctions         /var/www/html/extensions/ParserFunctions
COPY charlesreid1-config/mediawiki/extensions/SyntaxHighlight_GeSHi   /var/www/html/extensions/SyntaxHighlight_GeSHi
RUN chown -R www-data:www-data /var/www/html/*

# Skins
COPY charlesreid1-config/mediawiki/skins /var/www/html/skins
RUN chown -R www-data:www-data /var/www/html/skins
RUN touch /var/www/html/skins

# MathJax 3.2.2 (self-hosted, served via Apache alias at /w/mathjax/*).
# Math extension runs in 'source' mode; MathJax renders client-side, so we
# never call out to restbase/mathoid. See LocalSettings.php.j2.
COPY charlesreid1-config/mediawiki/mathjax /var/www/html/mathjax
RUN chown -R www-data:www-data /var/www/html/mathjax

# Settings
COPY charlesreid1-config/mediawiki/LocalSettings.php /var/www/html/LocalSettings.php
RUN chown -R www-data:www-data /var/www/html/LocalSettings*
RUN chmod 600 /var/www/html/LocalSettings.php

# Apache conf file
COPY charlesreid1-config/apache/*.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite
RUN service apache2 restart

# PHP conf file
# https://hub.docker.com/_/php/
COPY php/php.ini /usr/local/etc/php/

# Start
CMD apache2-foreground
