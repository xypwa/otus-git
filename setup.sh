#!/bin/bash

TYPE=$1;
TSL=$2;
echo "Replication type: $TYPE";
echo "TSL: $TSL";
DB_NAME="majordomo";
APP_NODE_1='192.168.71.140';
APP_NODE_2='192.168.71.143';
REPLICA_IP='192.168.71.148';
systemctl stop mysql;

sed -i 's/^\(bind-address\s*=\s*\).*$/\10.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

GTID_MASTER_CONFIG="
server-id = 1
log-bin = mysql-bin
binlog_format = row
gtid-mode=ON
enforce-gtid-consistency
log-replica-updates
binlog_do_db = ${DB_NAME}
"

BINLOG_POS_MASTER_CONFIG="
server-id = 1
log_bin = mysql-bin
binlog_format = row
binlog_do_db = ${DB_NAME}
log-replica-updates
"


if [[ "${TYPE}" -eq '1' ]]; then
  echo "${GTID_MASTER_CONFIG}" >> /etc/mysql/mysql.conf.d/mysqld.cnf;
  sed -i "/^bind-address/a\require_secure_transport = ON" /etc/mysql/mysql.conf.d/mysqld.cnf
else
  echo "${BINLOG_POS_MASTER_CONFIG}" >> /etc/mysql/mysql.conf.d/mysqld.cnf;
fi;


systemctl start mysql;

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

#CREATE USER 'slave'@"${REPLICA_IP}" IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv';
#GRANT REPLICATION SLAVE ON *.* TO 'slave'@"${REPLICA_IP}";
#CREATE USER 'replicant'@"${REPLICA_IP}" IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv' REQUIRE SSL;
CREATE USER 'replicant'@"${REPLICA_IP}" IDENTIFIED WITH 'caching_sha2_password' BY 'qwertyzxv';
GRANT REPLICATION SLAVE ON *.* to 'replicant'@"${REPLICA_IP}";
FLUSH PRIVILEGES;
EOF

if [[ "${TYPE}" -eq "2" ]]; then
  status=(`mysql -u root -e "SHOW MASTER STATUS;"`);
  file="${status[5]}";
  position="${status[6]}";
  echo "$file" > binlog_file.output; echo "$position" > binlog_pos.output;
fi;

if [[ "$TSL" == "Y" || "$TSL" == 'y' ]]; then
  mkdir certs;
  cp /var/lib/mysql/*.pem ./certs/
  chown -R xypwa:xypwa ./certs;
fi;


#mysqldump --master-data -u root majordomo > majordomo.sql
#rsync -avz majordomo.sql xypwa@192.168.71.148:/home/xypwa/

service mysql restart;
