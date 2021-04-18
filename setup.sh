#!/bin/bash

plugins=`get_config_value 'plugins' ''`
themes=`get_config_value 'themes' ''`
type=`get_config_value 'type' 'single'`
title=`get_config_value 'title' "${domain}.test"`

echo ${type}
exit 1

if [[ "${type}" != "none" ]]; then
    if [[ ! -d ${vm_dir}/public_html ]]; then
        mkdir -p ${vm_dir}/public_html
    fi

    if [[ ! -f "/srv/www/${domain}/public_html/wp-config-sample.php" ]]; then
        cd ${vm_dir}/public_html
        noroot wp core download
        noroot wp config create --dbhost=localhost --dbname=${domain} --dbuser=wordpress --dbpass=wordpress

        # Setup MySQL Database
        noroot mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${domain};"
        noroot mysql -u root -e "CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'wordpress';"
        noroot mysql -u root -e "FLUSH PRIVILEGES;"

        if [[ "${title}" != "none" ]]; then
          for site_title in ${title}; do
            if [[ "${site_title}" == "title" ]]; then
              echo ""
            fi
          done
        fi

        # Installing WordPress
        echo "Install WordPress"
        noroot wp core install  --url="https://${domain}.test" --title="${site_title}" --admin_user=admin --admin_password=password --admin_email="admin@${domain}.test"
        noroot wp plugin delete akismet
        noroot wp plugin delete hello
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
    fi
fi
