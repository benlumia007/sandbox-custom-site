#!/bin/bash

plugins=`get_config_value 'plugins' ''`
themes=`get_config_value 'themes' ''`
type=`get_config_value 'type' ''`
constants=`get_config_value 'constants' ''`
title=`get_config_value 'title' "${domain}.test"`

if [[ "${type}" == "WordPress" ]]; then
    # Setup MySQL Database
    noroot mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${domain};"
    noroot mysql -u root -e "CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'wordpress';"
    noroot mysql -u root -e "GRANT ALL PRIVILEGES ON ${domain}.* to 'wordpress'@'%' WITH GRANT OPTION;"
    noroot mysql -u root -e "FLUSH PRIVILEGES;"
        
    if [[ ! -f "/srv/www/${domain}/public_html/wp-config-sample.php" ]]; then
        cd ${vm_dir}/public_html
        
        noroot wp core download --quiet
        noroot wp config create --dbhost=localhost --dbname=${domain} --dbuser=wordpress --dbpass=wordpress --quiet

        if [[ "${title}" != "none" ]]; then
          for site_title in ${title}; do
            if [[ "${site_title}" == "title" ]]; then
              echo ""
            fi
          done
        fi
        
        noroot wp core install  --url="https://${domain}.test" --title="${site_title}" --admin_user=admin --admin_password=password --admin_email="admin@${domain}.test" --quiet
        noroot wp plugin delete akismet --quiet
        noroot wp plugin delete hello --quiet
        noroot wp config shuffle-salts --quiet

        if [[ "${plugins}" != "none" ]]; then
          for plugin in ${plugins//- /$'\n'}; do
            if [[ "${plugin}" != "plugins" ]]; then
              noroot wp plugin install ${plugin} --activate --quiet
            fi
          done
        fi

        if [[ "${themes}" != "none" ]]; then
          for theme in ${themes//- /$'\n'}; do
            if [[ "${theme}" != "themes" ]]; then
              noroot wp theme install ${theme} --activate --quiet
            fi
          done
        fi

        if [[ "${constants}" != "none" ]]; then
          for const in ${constants//- /$'\n'}; do
            if [[ "${const}" != "constants" ]]; then
              noroot wp config set --type=constant ${const} --raw true --quiet
            fi
          done
        fi
    fi
elif [[ "${type}" == "ClassicPress" ]]; then
    # Setup MySQL Database
    noroot mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${domain};"
    noroot mysql -u root -e "CREATE USER IF NOT EXISTS 'classicpress'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'classicpress';"
    noroot mysql -u root -e "GRANT ALL PRIVILEGES ON ${domain}.* to 'classicpress'@'%' WITH GRANT OPTION;"
    noroot mysql -u root -e "FLUSH PRIVILEGES;"
    
    if [[ ! -f "${vm_dir}/public_html/wp-config-sample.php" ]]; then
          cd ${vm_dir}/public_html
          
          noroot wp core download https://www.classicpress.net/latest.zip --quiet
          noroot wp config create --dbhost=localhost --dbname=${domain} --dbuser=classicpress --dbpass=classicpress --quiet

        if [[ "${title}" != "none" ]]; then
          for site_title in ${title}; do
            if [[ "${site_title}" == "title" ]]; then
              echo ""
            fi
          done
        fi

          noroot wp core install  --url="https://${domain}.test" --title="${site_title}" --admin_user=admin --admin_password=password --admin_email="admin@${domain}.test" --quiet
          noroot wp config shuffle-salts --quiet

        if [[ "${plugins}" != "none" ]]; then
          for plugin in ${plugins//- /$'\n'}; do
            if [[ "${plugin}" != "plugins" ]]; then
              noroot wp plugin install ${plugin} --activate --quiet
            fi
          done
        fi

        if [[ "${themes}" != "none" ]]; then
          for theme in ${themes//- /$'\n'}; do
            if [[ "${theme}" != "themes" ]]; then
              noroot wp theme install ${theme} --activate --quiet
            fi
          done
        fi
    fi
else
  echo "custom"
fi
