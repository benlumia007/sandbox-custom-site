#!/bin/bash

# This should create the basic .conf file for a specific site when it is doing a provision.
if [[ ! -f /etc/apache2/sites-available/${DOMAIN}.conf ]]; then
  echo "Copying apache2.conf    /etc/apache2/sites-available/${DOMAIN}.conf"
  cp /vagrant/config/apache/apache.conf /etc/apache2/sites-available/${DOMAIN}.conf
  sed -i -e "s/{{DOMAIN}}/${DOMAIN}/g" /etc/apache2/sites-available/${DOMAIN}.conf
  echo "enable ${DOMAIN}"
  a2ensite ${DOMAIN}.conf
  echo "restarting apache server"
  service apache2 restart
fi

if [[ ! -d ${VM_DIR} ]]; then
    echo -e "Creating ${VM_DIR}/public_html"
    mkdir -p ${VM_DIR}/public_html
fi

if [[ ! -f "/srv/www/${DOMAIN}/public_html/wp-config-sample.php" ]]; then
    cp "/srv/config/wordpress/wp-config.php" "/srv/www/${DOMAIN}/public_html/wp-config.php"
    cd ${VM_DIR}/public_html
    noroot wp core download

    # Setup MySQL Database
    noroot mysql -uroot -e "CREATE USER '${DOMAIN}'@'localhost' IDENTIFIED BY '${DOMAIN}';"
    noroot mysql -uroot -e "GRANT USAGE ON *.* TO '${DOMAIN}'@'localhost';"
    noroot mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${DOMAIN};"
    noroot mysql -uroot -e "GRANT ALL PRIVILEGES ON ${DOMAIN}.* TO '${DOMAIN}'@'localhost';"
    noroot mysql -uroot -e "FLUSH PRIVILEGES;"

    noroot sed -i "/DB_HOST/s/'[^']*'/'localhost'/2" wp-config.php
    noroot sed -i "/DB_NAME/s/'[^']*'/'${DOMAIN}'/2" wp-config.php
    noroot sed -i "/DB_USER/s/'[^']*'/'${DOMAIN}'/2" wp-config.php
    noroot sed -i "/DB_PASSWORD/s/'[^']*'/'${DOMAIN}'/2" wp-config.php

    # Installing WordPress
    echo "Install WordPress"
    noroot wp core install  --url=https://${DOMAIN}.test --title=${DOMAIN} --admin_user=admin --admin_password=password --admin_email=admin@${DOMAIN}.test
fi