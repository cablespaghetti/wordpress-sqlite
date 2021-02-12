FROM wordpress:fpm-alpine

# Setup
ADD https://raw.githubusercontent.com/aaemnnosttv/wp-sqlite-db/master/src/db.php /usr/src/wordpress/wp-content/db.php

# Config
COPY config/wp-config.php /var/www/wp-config.php
RUN chown www-data:www-data /var/www/wp-config.php

# Create db volume
VOLUME ["/var/www/db"]

#RUN mkdir /var/www/db
#RUN chown www-data:www-data /var/www/db
