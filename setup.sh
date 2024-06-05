#!/bin/bash

systemctl stop mysql;

sed -i 's/^\(bind-address\s*=\s*\).*$/\10.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "/^bind-address/a\require_secure_transport = ON" /etc/mysql/mysql.conf.d/mysqld.cnf

GTID_MASTER_CONFIG=<<EOF
server-id = 1
log-bin = mysql-bin
binlog_format = row
gtid-mode=ON
enforce-gtid-consistency
log-replica-updates
EOF
sed -i '$a\ '${GTID_MASTER_CONFIG}'' /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl start mysql;

APP_NODE_1='192.168.71.140';
APP_NODE_2='192.168.71.143';
SLAVE='192.168.71.148';
# настройка базы #

mysql -uroot <<EOF
CREATE DATABASE majordomo DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

CREATE USER 'majordomo'@"${APP_NODE_1}" IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv';
GRANT ALL PRIVILEGES ON majordomo.* TO 'majordomo'@"${APP_NODE_1}" WITH GRANT OPTION;
GRANT RELOAD, FLUSH_TABLES ON *.* TO 'majordomo'@"${APP_NODE_1}";

CREATE USER 'majordomo2'@"${APP_NODE_2}" IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv';
GRANT ALL PRIVILEGES ON majordomo.* TO 'majordomo2'@"${APP_NODE_2}" WITH GRANT OPTION;
GRANT RELOAD, FLUSH_TABLES ON *.* TO 'majordomo2'@"${APP_NODE_2}";

#CREATE USER 'xypwa@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv';
#GRANT ALL PRIVILEGES ON *.* TO 'xypwa'@'%' WITH GRANT OPTION;

CREATE USER 'slave'@"${SLAVE}" IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv';
GRANT REPLICATION SLAVE ON *.* TO 'slave'@"${SLAVE}";
FLUSH PRIVILEGES;
EOF

#read -rp "Choose replication type: GTID[1], Binlog position[2]" REPLICATION_TYPE;
#echo $REPLICATION_TYPE;
#mysqldump --all-databases -flush-privileges --single-transaction --flush-logs --triggers --routines --events -hex-blob --host=192.168.71.147 --port=3306 --user=root --password='' > mysqlbackup_dump.sql
mysqldump --all-databases -flush-privileges --single-transaction --flush-logs --triggers --routines --events -hex-blob > mysqlbackup_dump.sql
service mysql restart;
