#!/bin/bash

# This should create the basic .conf file for a specific site when it is doing a provision.
if [[ ! -f /etc/apache2/sites-available/${DOMAIN}.conf ]]; then
  echo "Copying apache2.conf    /etc/apache2/sites-available/${DOMAIN}.conf"
  cp /vagrant/config/apache-config/apache.conf /etc/apache2/sites-available/${DOMAIN}.conf
  sed -i -e "s/{{DOMAIN}}/${DOMAIN}/g" /etc/apache2/sites-available/${DOMAIN}.conf
  echo "restarting apache server"
  service apache2 restart
fi