#!/bin/bash

<<<<<<< HEAD
if [[ ! -f "/srv/www/${DOMAIN}/public_html/wp-config-sample.php" ]]; then
    cp "/srv/config/wordpress/wp-config.php" "/srv/www/${DOMAIN}/public_html/wp-config.php"
    noroot wp core download
fi
=======
echo "This is to verify if ${DOMAIN} (example) shows"
>>>>>>> develop
