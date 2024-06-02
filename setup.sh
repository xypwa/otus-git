#!/bin/bash

#APP_NODE_1='192.168.71.140';
#APP_NODE_2='192.168.71.140';
# настройка базы #

mysql -uroot <<EOF
CREATE DATABASE majordomo DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE USER 'majordomo'@"${APP_NODE_1}" IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv';
GRANT ALL PRIVILEGES ON majordomo.* TO 'majordomo'@"${APP_NODE_1}" WITH GRANT OPTION;
GRANT RELOAD, FLUSH_TABLES ON *.* TO 'majordomo'@"${APP_NODE_1}";
FLUSH PRIVILEGES;
EOF

#sed -i "s/^\(bind-address\s*=\s*\).*$/\1$APP_NODE_1/" /etc/mysql/mysql.conf.d/mysqld.cnf; 
sed -i "s/^\(bind-address\s*=\s*\).*$/\10.0.0.0" /etc/mysql/mysql.conf.d/mysqld.cnf; 

service mysql restart;
