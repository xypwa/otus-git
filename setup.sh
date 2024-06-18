#!/bin/bash

DB_MASTER_IP="192.168.71.147";

# установим хост #
sed -i 's/^\(127.0.0.1\s*\).*$/\1app-node/' /etc/hosts;
text="db_master_host $DB_MASTER_IP\n";
sed -i '$a '"$text"'' /etc/hosts;

# php config #
PHP_INI_PATH='/etc/php/7.4/apache2/php.ini';
PHP_INI_CLI_PATH='/etc/php/7.4/cli/php.ini';
sed -i 's/^\(short_open_tag\s*=\s*\).*$/\1On/' $PHP_INI_PATH; #short_open_tag = On
sed -i 's/^\(max_execution_time\s*=\s*\).*$/\190/' $PHP_INI_PATH; #max_execution_time = 90
sed -i 's/^\(max_input_time\s*=\s*\).*$/\1180/' $PHP_INI_PATH; #max_input_time = 180
sed -i 's/^\(max_post_size\s*=\s*\).*$/\1200M/' $PHP_INI_PATH; #max_post_size = 200M
sed -i 's/^\(upload_max_filesize\s*=\s*\).*$/\150M/' $PHP_INI_PATH; #upload_max_filesize = 50M
sed -i 's/^\(max_file_uploads\s*=\s*\).*$/\1150/' $PHP_INI_PATH; #max_file_uploads = 150
sed -i "/mysqli.default_host/s/$/${DB_MASTER_IP}/" $PHP_INI_PATH;

sed -i 's/^\(short_open_tag\s*=\s*\).*$/\1On/' $PHP_INI_CLI_PATH; #short_open_tag = On

# apache config #

cat <<'EOF' > /etc/apache2/sites-enabled/majordomo.conf
<VirtualHost *:80>
    Define root_domain app-node
    Define root_path /var/www/majordomo

    ServerName ${root_domain}
    DocumentRoot ${root_path}

    <Directory ${root_path}>
        AllowOverride All
    </Directory>
</VirtualHost>
EOF
rm /etc/apache2/sites-enabled/000-default.conf;
systemctl reload apache2;

# распаковка и установка majordomo #
APP_HOME_DIR='/var/www/majordomo';
mkdir $APP_HOME_DIR;

cp -r ~/majordomo_repo/majordomo/* $APP_HOME_DIR;
cp "$APP_HOME_DIR/config.php.sample" "$APP_HOME_DIR/config.php";

#sed -i "s/Define('DB_HOST', '.*');/Define('DB_HOST', 'localhost');/" "$APP_HOME_DIR/config.php";
sed -i "s/Define('DB_HOST', '.*');/Define('DB_HOST', \"${DB_MASTER_IP}\");/" "$APP_HOME_DIR/config.php";
sed -i "s/Define('DB_NAME', '.*');/Define('DB_NAME', 'majordomo');/" "$APP_HOME_DIR/config.php";
sed -i "s/Define('DB_USER', '.*');/Define('DB_USER', 'majordomo');/" "$APP_HOME_DIR/config.php";
sed -i "s/Define('DB_PASSWORD', '.*');/Define('DB_PASSWORD', 'qwertyzxv');/" "$APP_HOME_DIR/config.php";
sed -i '/echo "ALL CYCLES STARTED" . PHP_EOL;/a exit(1);' "$APP_HOME_DIR/cycle.php";

chown -R www-data:www-data $APP_HOME_DIR;

# установка #
php "$APP_HOME_DIR/cycle.php";
