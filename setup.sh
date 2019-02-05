#!/bin/bash

# This should create the basic .conf file for a specific site when it is doing a provision.
if [[ ! -f /etc/apache2/sites-available/${DOMAIN}.conf ]]; then
  echo "Copying apache2.conf    /etc/apache2/sites-available/${DOMAIN}.conf"
  cp "/srv/config/apache/apache.conf" "/etc/apache2/sites-available/${DOMAIN}.conf"
  sed -i -e "s/{{DOMAIN}}/${DOMAIN}/g" "/etc/apache2/sites-available/${DOMAIN}.conf"
  echo "enable ${DOMAIN}"
  a2ensite ${DOMAIN}.conf
  echo "restarting apache server"
  service apache2 restart
fi

if [[ ! -d ${VM_DIR}/public_html ]]; then
    echo "Creating ${VM_DIR}/public_html"
    mkdir -p ${VM_DIR}/public_html
fi

if [[ ! -f "/srv/www/${DOMAIN}/public_html/wp-config-sample.php" ]]; then
    cp "/srv/config/wordpress/wp-config.php" "/srv/www/${DOMAIN}/public_html/wp-config.php"
    cd ${VM_DIR}/public_html
    noroot wp core download

    # Setup MySQL Database
    noroot mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${DOMAIN};"
    noroot mysql -uroot -e "GRANT ALL PRIVILEGES ON ${DOMAIN}.* TO 'wp'@'localhost';"
    noroot mysql -uroot -e "FLUSH PRIVILEGES;"

    noroot sed -i "/DB_HOST/s/'[^']*'/'localhost'/2" wp-config.php
    noroot sed -i "/DB_NAME/s/'[^']*'/'${DOMAIN}'/2" wp-config.php
    noroot sed -i "/DB_USER/s/'[^']*'/'wp'/2" wp-config.php
    noroot sed -i "/DB_PASSWORD/s/'[^']*'/'wp'/2" wp-config.php

    # Installing WordPress
    echo "Install WordPress"
    noroot wp core install  --url=https://${DOMAIN}.test --title=${DOMAIN} --admin_user=admin --admin_password=password --admin_email=admin@${DOMAIN}.test
    echo
    # Download WordPress Importer
    echo "Download and Install WordPress Installer"
    noroot wp plugin install wordpress-importer --activate
    echo
    echo "Downloading Theme Unit Test..."
    noroot wget https://raw.githubusercontent.com/WPTRT/theme-unit-test/master/themeunittestdata.wordpress.xml
    echo
    echo "Importing Theme Unit Test, this will take a few minutes to complete"
    noroot wp import themeunittestdata.wordpress.xml --authors=skip
    noroot rm themeunittestdata.wordpress.xml
    echo
    echo "Install Addition Plugins"
    noroot wp plugin uninstall hello
    noroot wp plugin uninstall akismet
    noroot wp plugin install theme-check --activate
    noroot wp plugin install debug-bar --activate
    noroot wp plugin install debug-bar-console --activate
    noroot wp plugin install debug-bar-cron --activate
    noroot wp plugin install monster-widget --activate
    noroot wp plugin install regenerate-thumbnails --activate
    noroot wp plugin install jetpack --activate
    noroot wp plugin install developer --activate
    noroot wp plugin install query-monitor --activate
    noroot wp plugin install https://github.com/WPTRT/theme-sniffer/releases/download/0.1.5/theme-sniffer.0.1.5.zip --activate
fi

if [[ ! -d "/vagrant/certificates/${DOMAIN}" ]]; then
    mkdir -p "/vagrant/certificates/${DOMAIN}"
    cp "/srv/config/certificates/domain.ext" "/vagrant/certificates/${DOMAIN}/domain.ext"

    noroot openssl genrsa -out "/vagrant/certificates/${DOMAIN}/dev.key" 4096
    noroot openssl req -new -key "vagrant/certificates/${DOMAIN}/dev.key" -out "/vagrant/certifictes/${DOMAIN}/dev.csr" -subj "/CN=${DOMAIN}"
    noroot openssl x509 -req -in "/vagrant/certifictes/${DOMAIN}/dev.csr" -CA "/vagrant/certificates/ca/ca.key" -CAcreateserial -out "/vagrant/certificates/${DOMAIN}/dev.crt" -days 3650 -sha256 -extfile "/vagrant/certificates/${DOMAIN}/domain.ext"
fi