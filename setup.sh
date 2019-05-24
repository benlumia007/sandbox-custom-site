#!/bin/bash

plugins=`get_config_value 'plugins' ''`
type=`get_config_value 'type' 'single'`
title=`get_config_value 'title' "${domain}"`

if [[ "${type}" != "none" ]]; then
    # This should create the basic .conf file for a specific site when it is doing a provision.
    if [[ ! -f /etc/apache2/sites-available/${domain}.conf ]]; then
      echo "copying apache2.conf to /etc/apache2/sites-available/${domain}.conf"
      cp "/srv/config/apache/apache.conf" "/etc/apache2/sites-available/${domain}.conf"
      sed -i -e "s/{{DOMAIN}}/${domain}/g" "/etc/apache2/sites-available/${domain}.conf"
      a2ensite ${domain}.conf -q
    fi

    if [[ ! -d ${vm_dir}/public_html ]]; then
        echo "Creating ${vm_dir}/public_html"
        mkdir -p ${vm_dir}/public_html
    fi

    if [[ ! -f "/srv/www/${domain}/public_html/wp-config-sample.php" ]]; then
        cp "/srv/config/wordpress/wp-config.php" "/srv/www/${domain}/public_html/wp-config.php"
        cd ${vm_dir}/public_html
        noroot wp core download

        # Setup MySQL Database
        noroot mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${domain};"
        noroot mysql -u root -e "GRANT ALL PRIVILEGES ON ${domain}.* TO 'wp'@'localhost' IDENTIFIED BY 'wp';"
        noroot mysql -u root -e "FLUSH PRIVILEGES;"

        noroot sed -i "/DB_HOST/s/'[^']*'/'localhost'/2" wp-config.php
        noroot sed -i "/DB_NAME/s/'[^']*'/'${domain}'/2" wp-config.php
        noroot sed -i "/DB_USER/s/'[^']*'/'wp'/2" wp-config.php
        noroot sed -i "/DB_PASSWORD/s/'[^']*'/'wp'/2" wp-config.php

        # Installing WordPress
        echo "Install WordPress"
        noroot wp core install  --url=https://${domain}.test --title="${title}" --admin_user=admin --admin_password=password --admin_email=admin@${domain}.test
        noroot wp config shuffle-salts

        if [[ "${plugins}" != "none" ]]; then
          for plugin in ${plugins//- /$'\n'}; do
            if [[ "${plugin}" == "plugins" ]]; then
              echo ""
            else
              noroot wp plugin install ${plugin} --activate
            fi
          done
        fi

        echo ${title}
    fi
fi