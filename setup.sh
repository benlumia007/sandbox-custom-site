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
fi